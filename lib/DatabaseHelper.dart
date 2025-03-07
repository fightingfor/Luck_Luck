import 'dart:async';
import 'dart:ffi';
import 'package:lucky_lucky/models/ball_info.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static const _databaseName = "ssq_database.db";
  static const _databaseVersion = 1;
  static const _tableName = "allBalls";

  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database?> get database async {
    if (_database != null) {
      return _database;
    }
    _database = await _initDatabases();
    return _database;
  }

  Future<Database> _initDatabases() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE $_tableName(
            id INTEGER PRIMARY KEY,
        qh TEXT,
        kj_time TEXT,
        zhou TEXT,
        hong_one INTEGER,
        hong_two INTEGER,
        hong_three INTEGER,
        hong_four INTEGER,
        hong_five INTEGER,
        hong_six INTEGER,
        lan_ball INTEGER
    )
    ''');
  }

  ///插入数据
  Future<int> insertBall(BallInfo ballInfo) async {
    Database? db = await database;

    if (db == null) {
      return -1;
    }
    // 定义插入 SQL 语句
    String sql = '''
    INSERT INTO $_tableName (qh, kj_time, zhou, hong_one, hong_two, hong_three, hong_four, hong_five, hong_six, lan_ball)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  ''';
    // 插入数据的字段值
    List<Object?> arguments = [
      ballInfo.qh,
      ballInfo.kjTime,
      ballInfo.zhou,
      ballInfo.redBalls[0],
      ballInfo.redBalls[1],
      ballInfo.redBalls[2],
      ballInfo.redBalls[3],
      ballInfo.redBalls[4],
      ballInfo.redBalls[5],
      ballInfo.blueBall
    ];

    // 插入数据并获取插入的行ID
    int insertedId = await db.rawInsert(sql, arguments);
    return insertedId;
  }

  ///查询所有数据
  Future<List<BallInfo>> getAllBalls(int offset, int limit) async {
    Database? db = await database;
    if (db == null) {
      return List.empty();
    }
    final List<Map<String, dynamic>> maps =
        await db.query(_tableName, orderBy: "qh", offset: offset, limit: limit);
    return List.generate(maps.length, (index) {
      return BallInfo.fromJson(maps[index]);
    });
  }

  /// 根据 期数查询 一期
  Future<BallInfo?> getBallByQh(String qh) async {
    Database? db = await database;
    if (db == null) {
      return null;
    }
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'qh = ?',
      whereArgs: [qh],
    );
    if (maps.isNotEmpty) {
      return BallInfo.fromJson(maps.first);
    } else {
      return null;
    }
  }

  ///根据期数删除某一期数据
  Future<int> deleteBall(String qh) async {
    Database? db = await database;
    if (db == null) {
      return -1;
    }
    return await db.delete(_tableName, where: 'qh = ?', whereArgs: [qh]);
  }

  ///检查数据库表是否为空
  Future<bool> isTableEmpty() async {
    Database? db = await database;
    if (db == null) {
      return true;
    }
    final count = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM $_tableName"),
    );

    return count == 0;
  }
}
