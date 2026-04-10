import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  static Database? _database;

  factory FavoritesService() {
    return _instance;
  }

  FavoritesService._internal();

  // 🔥 Reactive notifier for favorite file paths
  final ValueNotifier<Set<String>> favoriteFilePathsNotifier =
      ValueNotifier<Set<String>>({});

  // 🔥 Initialize database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    // Load initial favorites into notifier
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
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE favorites (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          filePath TEXT UNIQUE NOT NULL,
          title TEXT NOT NULL,
          artist TEXT NOT NULL,
          artwork BLOB,               
          addedAt INTEGER NOT NULL
        )
      ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE favorites ADD COLUMN artwork BLOB');
        }
      },
    );
  }

  // 🔥 Add to favorites
  Future<void> addFavorite(Map<String, dynamic> song) async {
    final db = await database;
    try {
      await db.insert('favorites', {
        'filePath': song['filePath'],
        'title': song['title'],
        'artist': song['artist'],
        'artwork': song['artwork'],
        'addedAt': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      // Update notifier
      final newSet = Set<String>.from(favoriteFilePathsNotifier.value);
      newSet.add(song['filePath'] as String);
      favoriteFilePathsNotifier.value = newSet;
    } catch (e) {
      debugPrint('Error adding favorite: $e');
    }
  }

  // 🔥 Remove from favorites
  Future<void> removeFavorite(String filePath) async {
    final db = await database;
    try {
      await db.delete(
        'favorites',
        where: 'filePath = ?',
        whereArgs: [filePath],
      );

      // Update notifier
      final newSet = Set<String>.from(favoriteFilePathsNotifier.value);
      newSet.remove(filePath);
      favoriteFilePathsNotifier.value = newSet;
    } catch (e) {
      debugPrint('Error removing favorite: $e');
    }
  }

  // 🔥 Check if song is favorite (can be used directly from notifier)
  bool isFavorite(String filePath) {
    return favoriteFilePathsNotifier.value.contains(filePath);
  }

  // 🔥 Get all favorites (with artwork, etc.)
  Future<List<Map<String, dynamic>>> getAllFavorites() async {
    final db = await database;
    try {
      final result = await db.query('favorites', orderBy: 'addedAt DESC');
      return result;
    } catch (e) {
      debugPrint('Error getting favorites: $e');
      return [];
    }
  }

  // 🔥 Get favorite file paths only (used internally)
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

  // 🔥 Get favorites count
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

  // 🔥 Clear all favorites
  Future<void> clearAllFavorites() async {
    final db = await database;
    try {
      await db.delete('favorites');
      favoriteFilePathsNotifier.value = {};
    } catch (e) {
      debugPrint('Error clearing favorites: $e');
    }
  }

  // 🔥 Close database
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
