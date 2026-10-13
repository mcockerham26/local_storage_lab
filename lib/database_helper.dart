
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String table = 'my_table';
  static const String columnId = '_id';
  static const String columnName = 'name';
  static const String columnAge = 'age';

  Database? _database;

  Database get db {
    if (_database == null) {
      throw StateError('Database has not been initialized.');
    }
    return _database!;
  }

  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    final databasePath = join(
      directory.path,
      'MyDatabase.db',
    );

    _database = await openDatabase(
      databasePath,
      version: 2,

      onConfigure: (database) async {
        await database.execute(
          'PRAGMA foreign_keys = ON',
        );
      },

      onCreate: (database, version) async {
        await _createGuestTable(database);
        await _createFolderTables(database);
      },

      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createFolderTables(database);
        }
      },
    );

    // Ensures the missing index is added to an
    // existing version-2 database without deleting data.
    await _createFolderTables(db);
  }

  // Original Part I guest table
  Future<void> _createGuestTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS my_table (
        _id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        age INTEGER NOT NULL
      )
    ''');
  }

  // Activity 09 folder and card tables
  Future<void> _createFolderTables(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await database.execute('''
      CREATE TABLE IF NOT EXISTS cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        suit TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        image_ref TEXT,
        folder_id INTEGER NOT NULL,
        FOREIGN KEY (folder_id)
          REFERENCES folders(id)
          ON DELETE CASCADE
      )
    ''');

    // Required index for efficient card lookup
    await database.execute('''
      CREATE INDEX IF NOT EXISTS idx_cards_folder_id
      ON cards(folder_id)
    ''');
  }

  // ----------------------------
  // PART I: GUEST OPERATIONS
  // ----------------------------

  Future<int> insert(Map<String, dynamic> row) async {
    return await db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    return await db.query(
      table,
      orderBy: '_id ASC',
    );
  }

  Future<int> queryRowCount() async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM $table',
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> update(Map<String, dynamic> row) async {
    return await db.update(
      table,
      row,
      where: '_id = ?',
      whereArgs: [row[columnId]],
    );
  }

  Future<int> delete(int id) async {
    return await db.delete(
      table,
      where: '_id = ?',
      whereArgs: [id],
    );
  }

  // ----------------------------
  // FOLDER OPERATIONS
  // ----------------------------

  Future<int> insertFolder(String name) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw ArgumentError('Folder name cannot be empty.');
    }

    final existing = await db.query(
      'folders',
      columns: ['id'],
      where: 'name = ?',
      whereArgs: [cleanName],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      throw StateError(
        'A folder with this name already exists.',
      );
    }

    return await db.insert('folders', {
      'name': cleanName,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getFolders() async {
    return await db.rawQuery('''
      SELECT
        f.id,
        f.name,
        f.created_at,
        COUNT(c.id) AS card_count
      FROM folders f
      LEFT JOIN cards c
        ON c.folder_id = f.id
      GROUP BY f.id, f.name, f.created_at
      ORDER BY f.id DESC
    ''');
  }

  Future<int> updateFolder(int id, String name) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw ArgumentError('Folder name cannot be empty.');
    }

    final existing = await db.query(
      'folders',
      columns: ['id'],
      where: 'name = ? AND id != ?',
      whereArgs: [cleanName, id],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      throw StateError(
        'A folder with this name already exists.',
      );
    }

    return await db.update(
      'folders',
      {'name': cleanName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteFolder(int id) async {
    return await db.transaction((transaction) async {
      await transaction.delete(
        'cards',
        where: 'folder_id = ?',
        whereArgs: [id],
      );

      return await transaction.delete(
        'folders',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  // ----------------------------
  // CARD OPERATIONS
  // ----------------------------

  Future<int> insertCard(Map<String, dynamic> card) async {
    final title = (card['title'] as String).trim();

    if (title.isEmpty) {
      throw ArgumentError('Card title cannot be empty.');
    }

    return await db.insert(
      'cards',
      {
        ...card,
        'title': title,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getCards(
      int folderId,
      ) async {
    return await db.query(
      'cards',
      where: 'folder_id = ?',
      whereArgs: [folderId],
      orderBy: 'id DESC',
    );
  }

  Future<int> updateCard(
      int id,
      Map<String, dynamic> values,
      ) async {
    final title = (values['title'] as String).trim();

    if (title.isEmpty) {
      throw ArgumentError('Card title cannot be empty.');
    }

    return await db.update(
      'cards',
      {
        ...values,
        'title': title,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCard(int id) async {
    return await db.delete(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ----------------------------
  // READ-ONLY DIAGNOSTICS
  // ----------------------------

  Future<int> getDatabaseVersion() async {
    final rows = await db.rawQuery(
      'PRAGMA user_version',
    );

    return rows.first['user_version'] as int;
  }

  Future<List<Map<String, dynamic>>> getTableNames() async {
    return await db.rawQuery('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
      ORDER BY name
    ''');
  }

  Future<List<Map<String, dynamic>>> getForeignKeys() async {
    return await db.rawQuery(
      'PRAGMA foreign_key_list(cards)',
    );
  }

  Future<List<Map<String, dynamic>>> getIndexes() async {
    return await db.rawQuery(
      'PRAGMA index_list(cards)',
    );
  }

  Future<int> getForeignKeyStatus() async {
    final rows = await db.rawQuery(
      'PRAGMA foreign_keys',
    );

    return rows.first['foreign_keys'] as int;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
