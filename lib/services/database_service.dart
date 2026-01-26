import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'potato_timer.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 激励内容表
    await db.execute('''
      CREATE TABLE motivations (
        id INTEGER PRIMARY KEY,
        title TEXT,
        content TEXT,
        type TEXT NOT NULL,
        isPublic INTEGER DEFAULT 0,
        viewCount INTEGER DEFAULT 0,
        likeCount INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        authorId INTEGER,
        authorNickname TEXT,
        authorAvatarUrl TEXT,
        isLiked INTEGER DEFAULT 0,
        isFavorited INTEGER DEFAULT 0,
        localOnly INTEGER DEFAULT 0,
        needsSync INTEGER DEFAULT 0,
        syncError TEXT,
        deletedAt TEXT
      )
    ''');

    // 激励媒体表
    await db.execute('''
      CREATE TABLE motivation_media (
        id INTEGER PRIMARY KEY,
        motivationId INTEGER NOT NULL,
        type TEXT NOT NULL,
        url TEXT NOT NULL,
        thumbnailUrl TEXT,
        localPath TEXT,
        FOREIGN KEY (motivationId) REFERENCES motivations(id) ON DELETE CASCADE
      )
    ''');

    // 激励标签表
    await db.execute('''
      CREATE TABLE motivation_tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        motivationId INTEGER NOT NULL,
        tag TEXT NOT NULL,
        FOREIGN KEY (motivationId) REFERENCES motivations(id) ON DELETE CASCADE
      )
    ''');

    // 目标表
    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL,
        isPublic INTEGER DEFAULT 0,
        enableTimer INTEGER DEFAULT 0,
        durationMinutes INTEGER DEFAULT 10,
        reminderTime TEXT,
        totalHours INTEGER DEFAULT 0,
        completedHours REAL DEFAULT 0,
        morningReminderTime TEXT DEFAULT '09:00:00',
        afternoonReminderTime TEXT DEFAULT '14:00:00',
        sessionDurationMinutes INTEGER DEFAULT 240,
        streakDays INTEGER DEFAULT 0,
        totalCompletedDays INTEGER DEFAULT 0,
        lastCompletedDate TEXT,
        status TEXT DEFAULT 'active',
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        authorId INTEGER,
        authorNickname TEXT,
        authorAvatarUrl TEXT,
        localOnly INTEGER DEFAULT 0,
        needsSync INTEGER DEFAULT 0,
        syncError TEXT,
        deletedAt TEXT
      )
    ''');

    // 目标完成记录表
    await db.execute('''
      CREATE TABLE goal_completions (
        id INTEGER PRIMARY KEY,
        goalId INTEGER NOT NULL,
        completedAt TEXT NOT NULL,
        durationMinutes INTEGER DEFAULT 0,
        notes TEXT,
        localOnly INTEGER DEFAULT 0,
        needsSync INTEGER DEFAULT 0,
        FOREIGN KEY (goalId) REFERENCES goals(id) ON DELETE CASCADE
      )
    ''');

    // 目标激励关联表
    await db.execute('''
      CREATE TABLE goal_motivations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goalId INTEGER NOT NULL,
        motivationId INTEGER NOT NULL,
        FOREIGN KEY (goalId) REFERENCES goals(id) ON DELETE CASCADE,
        FOREIGN KEY (motivationId) REFERENCES motivations(id) ON DELETE CASCADE,
        UNIQUE(goalId, motivationId)
      )
    ''');

    // 创建索引
    await db.execute('CREATE INDEX idx_motivations_type ON motivations(type)');
    await db.execute('CREATE INDEX idx_motivations_sync ON motivations(needsSync)');
    await db.execute('CREATE INDEX idx_motivations_deleted ON motivations(deletedAt)');
    await db.execute('CREATE INDEX idx_goals_type ON goals(type)');
    await db.execute('CREATE INDEX idx_goals_status ON goals(status)');
    await db.execute('CREATE INDEX idx_goals_sync ON goals(needsSync)');
    await db.execute('CREATE INDEX idx_goals_deleted ON goals(deletedAt)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 未来版本升级时使用
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('motivation_tags');
    await db.delete('motivation_media');
    await db.delete('motivations');
    await db.delete('goal_motivations');
    await db.delete('goal_completions');
    await db.delete('goals');
  }
}

