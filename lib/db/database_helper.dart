import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/dog.dart';

class DatabaseHelper {
  static const _dbName = 'doggie_database.db';
  static const _dbVersion = 1;
  static const _table = 'dogs';

  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) => db.execute(
        'CREATE TABLE $_table(id INTEGER PRIMARY KEY, name TEXT, age INTEGER)',
      ),
    );
  }

  Future<void> insertDog(Dog dog) async {
    final db = await database;
    await db.insert(
      _table,
      dog.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Dog>> getDogs() async {
    final db = await database;
    final maps = await db.query(_table);
    return List.generate(
      maps.length,
      (i) => Dog(
        id: maps[i]['id'] as int,
        name: maps[i]['name'] as String,
        age: maps[i]['age'] as int,
      ),
    );
  }

  Future<void> updateDog(Dog dog) async {
    final db = await database;
    await db.update(_table, dog.toMap(), where: 'id = ?', whereArgs: [dog.id]);
  }

  Future<void> deleteDog(int id) async {
    final db = await database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
