import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:lucky_lucky/models/ball_info.dart';

class DatabaseService {
  static const String _databaseName = 'ssq_database.db';
  static const int _databaseVersion = 1;
  static const String _tableName = 'ssq_table';
  static const _maxConnectionAttempts = 3;

  static final DatabaseService _instance = DatabaseService._internal();
  Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<void> initialize() async {
    await database;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), _databaseName);
    print('数据库路径: $path');

    bool dbExists = await databaseExists(path);
    print('数据库是否存在: $dbExists');

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        qh TEXT PRIMARY KEY,
        hong_one TEXT NOT NULL,
        hong_two TEXT NOT NULL,
        hong_three TEXT NOT NULL,
        hong_four TEXT NOT NULL,
        hong_five TEXT NOT NULL,
        hong_six TEXT NOT NULL,
        lan_ball TEXT NOT NULL,
        kj_time TEXT NOT NULL,
        zhou TEXT NOT NULL
      )
    ''');
  }

  Future<void> insertBalls(List<BallInfo> balls) async {
    final db = await database;
    final batch = db.batch();

    for (var ball in balls) {
      final Map<String, dynamic> map = {
        'qh': ball.qh,
        'kj_time': ball.kjTime,
        'hong_one': ball.redBalls[0].toString(),
        'hong_two': ball.redBalls[1].toString(),
        'hong_three': ball.redBalls[2].toString(),
        'hong_four': ball.redBalls[3].toString(),
        'hong_five': ball.redBalls[4].toString(),
        'hong_six': ball.redBalls[5].toString(),
        'lan_ball': ball.blueBall.toString(),
        'zhou': ball.zhou,
      };
      batch.insert(
        _tableName,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<BallInfo>> getBalls(int offset, int limit) async {
    print('DatabaseService: 开始查询数据，offset: $offset, limit: $limit');
    final db = await database;

    // 检查表是否存在
    final tables = await db.query('sqlite_master',
        where: 'type = ? AND name = ?', whereArgs: ['table', _tableName]);
    print('DatabaseService: 表是否存在: ${tables.isNotEmpty}');

    if (tables.isEmpty) {
      print('DatabaseService: 表不存在，返回空列表');
      return [];
    }

    // 获取总记录数
    final countResult =
        await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    final totalCount = countResult.first['count'] as int;
    print('DatabaseService: 表中的总记录数: $totalCount');

    // 检查是否还有更多数据
    if (offset >= totalCount) {
      print('DatabaseService: 已到达数据末尾，返回空列表');
      return [];
    }

    // 计算实际需要获取的记录数
    final actualLimit =
        (offset + limit) > totalCount ? (totalCount - offset) : limit;
    print('DatabaseService: 实际需要获取的记录数: $actualLimit');

    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'qh DESC',
      limit: actualLimit,
      offset: offset,
    );

    print('DatabaseService: 查询到${maps.length}条记录');
    return maps.map((map) => BallInfo.fromMap(map)).toList();
  }

  Future<BallInfo?> getBallByQh(String qh) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'qh = ?',
        whereArgs: [qh],
      );

      if (maps.isEmpty) return null;
      return BallInfo.fromMap(maps.first);
    } catch (e) {
      throw Exception('获取数据失败: $e');
    }
  }

  Future<bool> isBallExists(String qh) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'qh = ?',
        whereArgs: [qh],
      );
      return maps.isNotEmpty;
    } catch (e) {
      print('检查期号是否存在失败: $e');
      throw Exception('检查期号是否存在失败: $e');
    }
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }

  Future<String> getLatestQh() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'qh DESC',
      limit: 1,
    );

    if (maps.isEmpty) return '';
    return maps.first['qh'] as String;
  }

  Future<String> getOldestQh() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'qh ASC',
      limit: 1,
    );

    if (maps.isEmpty) return '';
    return maps.first['qh'] as String;
  }

  Future<int> getCount() async {
    final db = await database;
    final List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}

class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);

  @override
  String toString() => message;
}
