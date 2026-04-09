import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  static Database? _database;

  factory FavoritesService() {
    return _instance;
  }

  FavoritesService._internal();

  // 🔥 Initialize database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'favorites.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE favorites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            filePath TEXT UNIQUE NOT NULL,
            title TEXT NOT NULL,
            artist TEXT NOT NULL,
            addedAt INTEGER NOT NULL
          )
          ''');
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
        'addedAt': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    } catch (e) {
      print('Error adding favorite: $e');
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
    } catch (e) {
      print('Error removing favorite: $e');
    }
  }

  // 🔥 Check if song is favorite
  Future<bool> isFavorite(String filePath) async {
    final db = await database;
    try {
      final result = await db.query(
        'favorites',
        where: 'filePath = ?',
        whereArgs: [filePath],
      );
      return result.isNotEmpty;
    } catch (e) {
      print('Error checking favorite: $e');
      return false;
    }
  }

  // 🔥 Get all favorites
  Future<List<Map<String, dynamic>>> getAllFavorites() async {
    final db = await database;
    try {
      final result = await db.query('favorites', orderBy: 'addedAt DESC');
      return result;
    } catch (e) {
      print('Error getting favorites: $e');
      return [];
    }
  }

  // 🔥 Get favorite IDs (for quick checking in ListView)
  Future<Set<String>> getFavoriteFilePaths() async {
    final db = await database;
    try {
      final result = await db.query('favorites', columns: ['filePath']);
      return result.map((row) => row['filePath'] as String).toSet();
    } catch (e) {
      print('Error getting favorite file paths: $e');
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
      print('Error getting favorites count: $e');
      return 0;
    }
  }

  // 🔥 Clear all favorites
  Future<void> clearAllFavorites() async {
    final db = await database;
    try {
      await db.delete('favorites');
    } catch (e) {
      print('Error clearing favorites: $e');
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
