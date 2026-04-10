import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  static Database? _database;

  factory FavoritesService() => _instance;
  FavoritesService._internal();

  final ValueNotifier<Set<String>> favoriteFilePathsNotifier = ValueNotifier(
    {},
  );

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    await _loadFavoritesIntoNotifier();
    return _database!;
  }

  Future<void> _loadFavoritesIntoNotifier() async {
    final paths = await getFavoriteFilePaths();
    favoriteFilePathsNotifier.value = paths;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'favorites.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE favorites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            filePath TEXT UNIQUE NOT NULL,
            title TEXT NOT NULL,
            artist TEXT NOT NULL,
            artwork BLOB,
            downloadDate INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          // Check whether the old table has an addedAt column (v2 may or may
          // not have it depending on whether the previous migration ran).
          final cols = await db.rawQuery(
            "PRAGMA table_info(favorites)",
          );
          final hasAddedAt = cols.any((c) => c['name'] == 'addedAt');

          await db.execute('''
            CREATE TABLE favorites_temp (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              filePath TEXT UNIQUE NOT NULL,
              title TEXT NOT NULL,
              artist TEXT NOT NULL,
              artwork BLOB,
              downloadDate INTEGER NOT NULL
            )
          ''');

          if (hasAddedAt) {
            await db.execute('''
              INSERT INTO favorites_temp (id, filePath, title, artist, artwork, downloadDate)
              SELECT id, filePath, title, artist, artwork, addedAt FROM favorites
            ''');
          } else {
            await db.execute('''
              INSERT INTO favorites_temp (id, filePath, title, artist, artwork, downloadDate)
              SELECT id, filePath, title, artist, artwork, 0 FROM favorites
            ''');
          }

          await db.execute('DROP TABLE favorites');
          await db.execute('ALTER TABLE favorites_temp RENAME TO favorites');
        }
      },
    );
  }

  Future<void> addFavorite(Map<String, dynamic> song) async {
    final db = await database;
    try {
      // ensure downloadDate is an int (milliseconds)
      int downloadDate;
      if (song['downloadDate'] is DateTime) {
        downloadDate =
            (song['downloadDate'] as DateTime).millisecondsSinceEpoch;
      } else if (song['downloadDate'] is int) {
        downloadDate = song['downloadDate'];
      } else {
        downloadDate = DateTime.now().millisecondsSinceEpoch;
      }

      await db.insert('favorites', {
        'filePath': song['filePath'],
        'title': song['title'],
        'artist': song['artist'],
        'artwork': song['artwork'],
        'downloadDate': downloadDate,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // reload notifier from DB to stay in sync
      await _loadFavoritesIntoNotifier();
    } catch (e) {
      debugPrint('Error adding favorite: $e');
    }
  }

  Future<void> removeFavorite(String filePath) async {
    final db = await database;
    try {
      await db.delete(
        'favorites',
        where: 'filePath = ?',
        whereArgs: [filePath],
      );
      await _loadFavoritesIntoNotifier();
    } catch (e) {
      debugPrint('Error removing favorite: $e');
    }
  }

  bool isFavorite(String filePath) =>
      favoriteFilePathsNotifier.value.contains(filePath);

  Future<List<Map<String, dynamic>>> getAllFavorites() async {
    final db = await database;
    try {
      final result = await db.query('favorites', orderBy: 'downloadDate DESC');
      return result;
    } catch (e) {
      debugPrint('Error getting favorites: $e');
      return [];
    }
  }

  Future<Set<String>> getFavoriteFilePaths() async {
    final db = await database;
    try {
      final result = await db.query('favorites', columns: ['filePath']);
      return result.map((row) => row['filePath'] as String).toSet();
    } catch (e) {
      debugPrint('Error getting favorite file paths: $e');
      return {};
    }
  }

  Future<int> getFavoritesCount() async {
    final db = await database;
    try {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM favorites',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      debugPrint('Error getting favorites count: $e');
      return 0;
    }
  }

  Future<void> clearAllFavorites() async {
    final db = await database;
    try {
      await db.delete('favorites');
      await _loadFavoritesIntoNotifier();
    } catch (e) {
      debugPrint('Error clearing favorites: $e');
    }
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
