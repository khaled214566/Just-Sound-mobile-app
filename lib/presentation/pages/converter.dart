import 'package:flutter/material.dart';
import 'package:idgaf/core/models/downloader.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final _controller = TextEditingController();
  final _yt = YoutubeExplode();

  DownloadManager? _dm;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initManager();
  }

  Future<void> _initManager() async {
    final dm = await DownloadManager.create();
    if (mounted) setState(() => _dm = dm);
  }

  // ── URL parsing ────────────────────────────────────────────────────────────

  String? _extractVideoId(String input) {
    final trimmed = input.trim();
    try {
      // Short link: youtu.be/ID
      final uri = Uri.parse(trimmed);
      if (uri.host.contains('youtu.be')) return uri.pathSegments.first;
      // Standard: youtube.com/watch?v=ID
      if (uri.queryParameters.containsKey('v')) {
        return uri.queryParameters['v'];
      }
    } catch (_) {}
    // Plain video ID (11 chars)
    final idRegex = RegExp(r'^[a-zA-Z0-9_-]{11}$');
    if (idRegex.hasMatch(trimmed)) return trimmed;
    return null;
  }

  // ── Download trigger ───────────────────────────────────────────────────────

  Future<void> _onDownload() async {
  if (_dm == null) {
    setState(() => _error = 'Download manager not ready. Please wait...');
    return;
  }
  
  final videoId = _extractVideoId(_controller.text);
  if (videoId == null) {
    setState(() => _error = 'Invalid YouTube URL or video ID.');
    return;
  }

  // Check if already downloaded
  if (await _dm!.isDownloaded(videoId)) {
    setState(() => _error = 'This song is already downloaded.');
    return;
  }

  setState(() {
    _loading = true;
    _error = null;
  });

  try {
    // Fetch metadata so the file gets a proper title / tags
    final video = await _yt.videos.get(videoId);
    final song = {
      'videoId': videoId,
      'title': video.title,
      'artist': video.author,
      'album': 'YouTube',
      'thumbnailUrl': video.thumbnails.standardResUrl,
      'quality': 'high',
    };

    await _dm!.downloadSong(song);
    _controller.clear();
    
    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download started')),
      );
    }
  } on VideoUnavailableException {
    setState(() => _error = 'Video is unavailable or restricted.');
  } on YoutubeExplodeException catch (e) {
    setState(() => _error = 'YouTube error: ${e.message}');
  } catch (e) {
    setState(() => _error = 'Could not fetch video info. Check the URL and your internet connection.');
    debugPrint('Download error: $e');
  } finally {
    if (mounted) {
      setState(() => _loading = false);
    }
  }
}
  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Download',
          style: TextStyle(
            color: Color(0xFFEEEEEE),
            fontSize: 18,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildInputSection(),
          const SizedBox(height: 8),
          Expanded(child: _buildDownloadList()),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // URL field
          TextField(
            controller: _controller,
            style: const TextStyle(color: Color(0xFFEEEEEE), fontSize: 14),
            cursorColor: const Color(0xFFFF0000),
            decoration: InputDecoration(
              hintText: 'Paste YouTube URL or video ID…',
              hintStyle: const TextStyle(
                color: Color(0xFF555555),
                fontSize: 14,
              ),
              filled: true,
              fillColor: const Color(0xFF111111),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 16,
                        color: Color(0xFF555555),
                      ),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _error = null);
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _onDownload(),
          ),

          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Color(0xFFFF4444), fontSize: 12),
            ),
          ],

          const SizedBox(height: 12),

          // Download button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton(
              onPressed: _loading ? null : _onDownload,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFF0000),
                disabledBackgroundColor: const Color(0xFF3A1A1A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Download',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadList() {
    if (_dm == null) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF333333),
        ),
      );
    }
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: _dm!.downloadsNotifier,
      builder: (context, downloads, _) {
        final visible = downloads.reversed.toList();

        if (visible.isEmpty) {
          return const Center(
            child: Text(
              'No downloads yet',
              style: TextStyle(color: Color(0xFF444444), fontSize: 13),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: visible.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) => _DownloadTile(
            record: visible[i],
            progressNotifier: _dm!.getProgressNotifier(
              visible[i]['videoId'] as String,
            ),
            onCancel: () =>
                _dm!.cancelDownload(visible[i]['videoId'] as String),
            onDelete: () => _dm!.deleteSong(visible[i]['videoId'] as String),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _yt.close();
    _dm?.dispose();
    super.dispose();
  }
}

// ── Download tile ────────────────────────────────────────────────────────────

class _DownloadTile extends StatelessWidget {
  final Map<String, dynamic> record;
  final ValueNotifier<double>? progressNotifier;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const _DownloadTile({
    required this.record,
    required this.progressNotifier,
    required this.onCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = record['status'] as String? ?? '';
    final title = record['title'] as String? ?? 'Unknown';
    final artist = record['artist'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Status dot
              _StatusDot(status: status),
              const SizedBox(width: 10),

              // Title + artist
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFEEEEEE),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (artist.isNotEmpty)
                      Text(
                        artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),

              // Action icon
              if (status == DownloadStatus.downloading ||
                  status == DownloadStatus.queued)
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 16,
                    color: Color(0xFF666666),
                  ),
                  onPressed: onCancel,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              else if (status == DownloadStatus.downloaded)
                const Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: Color(0xFF44BB44),
                )
              else if (status == DownloadStatus.deleted)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Color(0xFF666666),
                  ),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),

          // Progress bar (only while downloading)
          if (status == DownloadStatus.downloading &&
              progressNotifier != null) ...[
            const SizedBox(height: 10),
            ValueListenableBuilder<double>(
              valueListenable: progressNotifier!,
              builder: (_, progress, __) => Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 2,
                      backgroundColor: const Color(0xFF2A2A2A),
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFFFF0000),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Color(0xFF555555),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Queued label
          if (status == DownloadStatus.queued) ...[
            const SizedBox(height: 6),
            const Text(
              'Queued',
              style: TextStyle(color: Color(0xFF555555), fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Status dot ───────────────────────────────────────────────────────────────

class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case DownloadStatus.downloading:
        color = const Color(0xFFFF0000);
        break;
      case DownloadStatus.downloaded:
        color = const Color(0xFF44BB44);
        break;
      case DownloadStatus.queued:
        color = const Color(0xFFFFAA00);
        break;
      default:
        color = const Color(0xFF444444);
    }

    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
