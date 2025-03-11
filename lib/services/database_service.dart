import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:lucky_lucky/models/ball_info.dart';
import 'dart:math';

class DatabaseService {
  static Database? _database;
  static const String tableName = 'lottery_balls';
  static const String _databaseName = 'ssq_database.db';

  Future<Database> get database async {
    if (_database != null) return _database!;
    await initialize();
    return _database!;
  }

  Future<void> initialize() async {
    if (_database != null) return;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    _database = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            qh INTEGER PRIMARY KEY,
            kj_time TEXT,
            zhou TEXT,
            red_balls TEXT,
            blue_ball INTEGER
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          // 创建临时表
          await db.execute('''
            CREATE TABLE ${tableName}_temp (
              qh INTEGER PRIMARY KEY,
              kj_time TEXT,
              zhou TEXT,
              red_balls TEXT,
              blue_ball INTEGER
            )
          ''');

          // 复制数据，将红球合并为一个字段
          await db.execute('''
            INSERT INTO ${tableName}_temp 
            SELECT 
              qh,
              kj_time,
              zhou,
              (hong_one || ',' || hong_two || ',' || hong_three || ',' || 
               hong_four || ',' || hong_five || ',' || hong_six) as red_balls,
              lan_ball as blue_ball
            FROM $tableName
          ''');

          // 删除旧表
          await db.execute('DROP TABLE $tableName');

          // 重命名临时表
          await db
              .execute('ALTER TABLE ${tableName}_temp RENAME TO $tableName');
        }
      },
    );
  }

  Future<List<BallInfo>> getAllBalls() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'qh DESC',
    );

    // Debug: 打印前5条数据
    if (maps.isNotEmpty) {
      print('数据库中的前5条数据:');
      for (var i = 0; i < min(5, maps.length); i++) {
        print('Record $i: ${maps[i]}');
      }
    }

    return List.generate(maps.length, (i) {
      return BallInfo.fromJson(maps[i]);
    });
  }

  Future<List<BallInfo>> getBalls(int offset, int limit) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'qh DESC',
      limit: limit,
      offset: offset,
    );
    return List.generate(maps.length, (i) => BallInfo.fromJson(maps[i]));
  }

  Future<void> insertBalls(List<BallInfo> balls) async {
    final db = await database;
    final batch = db.batch();
    for (var ball in balls) {
      batch.insert(
        tableName,
        ball.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<BallInfo?> getLatestBall() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'kj_time DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return BallInfo.fromJson(maps.first);
  }

  Future<int> getLatestQh() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'kj_time DESC',
      limit: 1,
    );

    if (maps.isEmpty) return 0;
    return maps.first['qh'] as int;
  }

  Future<int> getCount() async {
    final db = await database;
    final List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<BallInfo>> getBallsByDateRange(
      DateTime startDate, DateTime endDate) async {
    final db = await database;
    final startDateStr = startDate.toIso8601String().split('T')[0];
    final endDateStr = endDate.toIso8601String().split('T')[0];

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'kj_time BETWEEN ? AND ?',
      whereArgs: [startDateStr, endDateStr],
      orderBy: 'kj_time DESC',
    );

    return List.generate(maps.length, (i) {
      return BallInfo.fromJson(maps[i]);
    });
  }

  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  Future<int> getLastQh() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      tableName,
      columns: ['qh'],
      orderBy: 'qh DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first['qh'] as int;
    }
    return 0;
  }

  Future<void> insertBall(BallInfo ball) async {
    final db = await database;
    await db.insert(
      tableName,
      {
        'qh': ball.qh,
        'kj_time': ball.kjTime,
        'zhou': ball.zhou,
        'red_balls': ball.redBalls.join(','),
        'blue_ball': ball.blueBall,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<BallInfo>> getLastNBalls(int n) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'qh DESC',
      limit: n,
    );
    return List.generate(maps.length, (i) => BallInfo.fromJson(maps[i]));
  }

  Future<List<int>> findQhGaps() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      columns: ['qh'],
      orderBy: 'qh ASC',
    );

    List<int> gaps = [];
    if (maps.isEmpty) return gaps;

    for (int i = 0; i < maps.length - 1; i++) {
      int currentQh = maps[i]['qh'] as int;
      int nextQh = maps[i + 1]['qh'] as int;

      if (nextQh - currentQh > 1) {
        // 添加中间缺失的期号，但不打印
        for (int gap = currentQh + 1; gap < nextQh; gap++) {
          gaps.add(gap);
        }
      }
    }

    return gaps;
  }
}

class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);

  @override
  String toString() => message;
}
