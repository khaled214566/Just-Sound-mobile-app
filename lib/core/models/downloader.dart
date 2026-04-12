import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:audiotags/audiotags.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

// ---------------------------------------------------------------------------
// STATUS CONSTANTS
// ---------------------------------------------------------------------------

class DownloadStatus {
  static const String queued = 'QUEUED';
  static const String downloading = 'DOWNLOADING';
  static const String downloaded = 'DOWNLOADED';
  static const String deleted = 'DELETED';
}

// ---------------------------------------------------------------------------
// EXCEPTIONS
// ---------------------------------------------------------------------------

class DownloadCancelledException implements Exception {
  final String videoId;
  DownloadCancelledException(this.videoId);
}

// ---------------------------------------------------------------------------
// DOWNLOAD MANAGER
// ---------------------------------------------------------------------------

/// Manages downloading YouTube audio tracks to
/// [saveDirectory] (default: /storage/emulated/0/Download).
///
/// Persists download state in a Hive box named [hiveBoxName].
/// Exposes [downloadsNotifier] so the UI can react to status changes,
/// and per-song progress via [getProgressNotifier].
///
/// The resulting files are readable by [SongLoader.loadSongs()] with no
/// extra configuration — just make sure [saveDirectory] matches the path
/// in [SongLoader.dirsToSearch].
class DownloadManager {
  // ── Configuration ────────────────────────────────────────────────────────

  static const String hiveBoxName = 'DOWNLOADS';
  static const String saveDirectory = '/storage/emulated/0/Download';
  static const int maxConcurrent = 3;

  // ── Internal state ────────────────────────────────────────────────────────

  final Box _box;
  final YoutubeExplode _yt = YoutubeExplode();

  /// All persisted download records (including completed / deleted).
  final ValueNotifier<List<Map<String, dynamic>>> downloadsNotifier =
      ValueNotifier([]);

  final Queue<Map<String, dynamic>> _queue = Queue();
  final Set<String> _active = {};
  final Map<String, ValueNotifier<double>> _progress = {};

  // ── Constructor & factory ─────────────────────────────────────────────────

  DownloadManager._(this._box) {
    _cleanStaleStatuses();
    _refresh();
    _box.listenable().addListener(_refresh);
  }

  static Future<DownloadManager> create() async {
    await Hive.openBox(hiveBoxName);
    return DownloadManager._(Hive.box(hiveBoxName));
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Returns the stored record for [videoId], or null if not found.
  Map<String, dynamic>? getRecord(String videoId) => _box.get(videoId) != null
      ? Map<String, dynamic>.from(_box.get(videoId) as Map)
      : null;

  /// Live progress 0.0→1.0 for an in-progress download, or null if idle.
  ValueNotifier<double>? getProgressNotifier(String videoId) =>
      _progress[videoId];

  /// Whether [videoId] has a usable downloaded file on disk.
  Future<bool> isDownloaded(String videoId) async {
    final record = getRecord(videoId);
    if (record == null) return false;
    if (record['status'] != DownloadStatus.downloaded) return false;
    final path = record['filePath'] as String?;
    return path != null && File(path).existsSync();
  }

  /// Enqueues [song] for download.
  ///
  /// [song] must contain at minimum:
  ///   - `videoId`  (String) — YouTube video ID
  ///   - `title`    (String)
  ///
  /// Optional but recommended:
  ///   - `artist`       (String)
  ///   - `album`        (String)
  ///   - `thumbnailUrl` (String) — used to embed cover art
  ///   - `quality`      (String) — `'high'` (default) or `'low'`
  Future<void> downloadSong(Map<String, dynamic> song) async {
    final videoId = song['videoId'] as String?;
    assert(videoId != null && videoId.isNotEmpty, 'song must have a videoId');

    // Skip if already active or queued
    if (_active.contains(videoId)) return;
    if (_queue.any((s) => s['videoId'] == videoId)) return;

    // If previously downloaded and file still exists, nothing to do
    if (await isDownloaded(videoId!)) return;

    if (_active.length >= maxConcurrent) {
      _queue.add(song);
      await _setStatus(videoId, DownloadStatus.queued, extra: song);
      return;
    }

    _active.add(videoId);
    _runDownload(song); // intentionally not awaited — runs in background
  }

  /// Cancels an in-progress or queued download and removes its file if any.
  Future<void> cancelDownload(String videoId) async {
    _queue.removeWhere((s) => s['videoId'] == videoId);
    _active.remove(videoId); // causes _ensureActive to throw on next check
    final record = getRecord(videoId);
    if (record != null) {
      final path = record['filePath'] as String?;
      if (path != null && File(path).existsSync()) await File(path).delete();
      await _setStatus(videoId, DownloadStatus.deleted);
    }
  }

  /// Removes the stored record and deletes the file from disk.
  Future<void> deleteSong(String videoId) async {
    await cancelDownload(videoId);
    await _box.delete(videoId);
  }

  // ── Download pipeline ─────────────────────────────────────────────────────

  Future<void> _runDownload(Map<String, dynamic> song) async {
    final videoId = song['videoId'] as String;
    try {
      await _setStatus(videoId, DownloadStatus.downloading, extra: song);
      _progress[videoId]?.dispose();
      _progress[videoId] = ValueNotifier(0.0);

      // 1. Check permissions
      if (!await _requestStoragePermission()) {
        throw Exception('Storage permission denied.');
      }

      // 2. Resolve YouTube audio stream
      final quality = (song['quality'] as String?)?.toLowerCase() ?? 'high';
      final streamInfo = await _resolveStream(videoId, quality);
      _ensureActive(videoId);

      // 3. Stream bytes with progress tracking
      final total = streamInfo.size.totalBytes;
      final bytes = await _streamWithProgress(videoId, streamInfo, total);
      _ensureActive(videoId);

      // 4. Write file to disk
      final filePath = await _saveFile(song, bytes);
      _ensureActive(videoId);

      // 5. Embed metadata tags
      await _writeTags(filePath, song);

      // 6. Mark done
      await _setStatus(
        videoId,
        DownloadStatus.downloaded,
        extra: {...song, 'filePath': filePath},
      );
    } on DownloadCancelledException {
      debugPrint('[$videoId] Download cancelled.');
    } catch (e, stackTrace) {
      debugPrint('[$videoId] Download failed: $e');
      debugPrint('Stack trace: $stackTrace');
      await _setStatus(videoId, DownloadStatus.deleted);
    } finally {
      _active.remove(videoId);
      _progress[videoId]?.dispose();
      _progress.remove(videoId);
      _startNext();
    }
  }

  void _ensureActive(String videoId) {
    if (!_active.contains(videoId)) throw DownloadCancelledException(videoId);
  }

  void _startNext() {
    if (_queue.isNotEmpty && _active.length < maxConcurrent) {
      final next = _queue.removeFirst();
      _active.add(next['videoId'] as String);
      _runDownload(next);
    }
  }

  // ── YouTube helpers ───────────────────────────────────────────────────────

  Future<AudioOnlyStreamInfo> _resolveStream(
    String videoId,
    String quality,
  ) async {
    final manifest = await _yt.videos.streamsClient.getManifest(
      videoId,
      requireWatchPage: true,
      ytClients: [YoutubeApiClient.androidVr],
    );

    // Prefer mp4 (AAC/m4a) container so audiotags can embed artwork
    final streams = manifest.audioOnly
        .where((s) => s.container == StreamContainer.mp4)
        .sortByBitrate()
        .toList();

    if (streams.isEmpty) throw Exception('No mp4 audio stream found.');

    // high → highest bitrate (last after sortByBitrate asc), low → lowest
    return quality == 'low' ? streams.first : streams.last;
  }

  Future<Uint8List> _streamWithProgress(
    String videoId,
    AudioOnlyStreamInfo info,
    int total,
  ) async {
    final builder = BytesBuilder();
    final stream = _yt.videos.streamsClient.get(info);

    await for (final chunk in stream) {
      _ensureActive(videoId);
      builder.add(chunk);
      _progress[videoId]?.value = total > 0 ? builder.length / total : 0.0;
    }

    return builder.takeBytes();
  }

  // ── File I/O helpers ──────────────────────────────────────────────────────

  Future<String> _saveFile(Map<String, dynamic> song, Uint8List bytes) async {
    final dir = Directory(saveDirectory);
    if (!dir.existsSync()) dir.createSync(recursive: true);

    // Sanitise title for use as filename
    final raw = (song['title'] as String? ?? 'unknown')
        .replaceAll(RegExp(r'[\\/*?:"<>|]'), '')
        .trim();

    // Avoid collisions
    File file = File('${dir.path}/$raw.m4a');
    int i = 1;
    while (file.existsSync()) {
      file = File('${dir.path}/$raw($i).m4a');
      i++;
    }

    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> _writeTags(String filePath, Map<String, dynamic> song) async {
    try {
      Picture? picture;
      final thumbUrl = song['thumbnailUrl'] as String?;
      if (thumbUrl != null && thumbUrl.isNotEmpty) {
        final res = await http.get(Uri.parse(thumbUrl));
        if (res.statusCode == 200) {
          picture = Picture(
            bytes: res.bodyBytes,
            pictureType: PictureType.coverFront,
          );
        }
      }

      final tag = Tag(
        title: song['title'] as String?,
        trackArtist: song['artist'] as String?,
        album: song['album'] as String?,
        pictures: picture != null ? [picture] : [],
      );

      await AudioTags.write(filePath, tag);
    } catch (e) {
      debugPrint('Tag writing failed (file is still saved): $e');
    }
  }

  // ── Permissions ───────────────────────────────────────────────────────────

  Future<bool> _requestStoragePermission() async {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) return true;
    if (Platform.isIOS) return true;

    if (Platform.isAndroid) {
      // Detect SDK version via os.version string
      final ver =
          int.tryParse(
            Platform.operatingSystemVersion.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          30;

      final perm = ver >= 30
          ? Permission.manageExternalStorage
          : Permission.storage;

      if (await perm.isGranted) return true;
      final result = await perm.request();
      if (!result.isGranted) await openAppSettings();
      return result.isGranted;
    }
    return false;
  }

  // ── Hive helpers ──────────────────────────────────────────────────────────

  Future<void> _setStatus(
    String videoId,
    String status, {
    Map<String, dynamic>? extra,
  }) async {
    final existing = _box.get(videoId) != null
        ? Map<String, dynamic>.from(_box.get(videoId) as Map)
        : <String, dynamic>{};

    final updated = {
      ...existing,
      if (extra != null) ...extra,
      'videoId': videoId,
      'status': status,
      if (status == DownloadStatus.downloaded)
        'downloadDate': DateTime.now().millisecondsSinceEpoch,
    };

    await _box.put(videoId, updated);
  }

  void _refresh() {
    downloadsNotifier.value = _box.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  /// On startup, any record stuck in DOWNLOADING/QUEUED (from a crashed
  /// session) is reset to DELETED so it can be re-queued by the user.
  Future<void> _cleanStaleStatuses() async {
    final toFix = <String, Map>{};
    for (final key in _box.keys) {
      final record = Map<String, dynamic>.from(_box.get(key) as Map);
      final status = record['status'] as String?;
      if (status == DownloadStatus.downloading ||
          status == DownloadStatus.queued) {
        record['status'] = DownloadStatus.deleted;
        toFix[key.toString()] = record;
      }
    }
    if (toFix.isNotEmpty) await _box.putAll(toFix);
  }

  void dispose() {
    _yt.close();
    for (final n in _progress.values) {
      n.dispose();
    }
    downloadsNotifier.dispose();
  }
}
