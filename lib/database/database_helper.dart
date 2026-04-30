import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'learning_app.db'),
      version: 5,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createAllTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // 迁移到 v3：用 plan_groups + plan_items 替换 study_plans
      await db.execute('DROP TABLE IF EXISTS study_plans');

      // 新增课程体系表（v2可能已存在）
      await db.execute('''
        CREATE TABLE IF NOT EXISTS curriculum (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          subject TEXT NOT NULL,
          grade INTEGER NOT NULL,
          chapter_name TEXT NOT NULL,
          order_index INTEGER NOT NULL DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS plan_groups (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type INTEGER NOT NULL,
          parent_id INTEGER,
          start_date TEXT NOT NULL,
          end_date TEXT NOT NULL,
          status INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          FOREIGN KEY (parent_id) REFERENCES plan_groups(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS plan_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          day_plan_id INTEGER NOT NULL,
          chapter_id INTEGER NOT NULL,
          chapter_name TEXT NOT NULL,
          subject_name TEXT NOT NULL,
          subject_emoji TEXT NOT NULL DEFAULT '📚',
          grade INTEGER NOT NULL,
          knowledge_point TEXT,
          status INTEGER NOT NULL DEFAULT 0,
          completed_at TEXT,
          origin_month_plan_id INTEGER,
          origin_week_plan_id INTEGER,
          FOREIGN KEY (day_plan_id) REFERENCES plan_groups(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('CREATE INDEX IF NOT EXISTS idx_curriculum_subject_grade ON curriculum (subject, grade)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_plan_groups_dates ON plan_groups (type, start_date, end_date)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_plan_items_day ON plan_items (day_plan_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_plan_items_chapter ON plan_items (chapter_id)');
    }
    if (oldVersion < 4) {
      // v4: 清理之前因外键未启用导致的孤立记录
      await db.execute(
        'DELETE FROM plan_items WHERE day_plan_id NOT IN (SELECT id FROM plan_groups)',
      );
      await db.execute(
        'DELETE FROM plan_groups WHERE parent_id IS NOT NULL AND parent_id NOT IN (SELECT id FROM plan_groups)',
      );
    }
    if (oldVersion < 5) {
      // v5: 清空课程表，由 _seedDatabase 重新填充（对齐各教材实际章节）
      await db.execute('DELETE FROM curriculum');
    }
  }

  Future<void> _createAllTables(Database db) async {
    await db.execute('''
      CREATE TABLE curriculum (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject TEXT NOT NULL,
        grade INTEGER NOT NULL,
        chapter_name TEXT NOT NULL,
        order_index INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE plan_groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type INTEGER NOT NULL,
        parent_id INTEGER,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        status INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (parent_id) REFERENCES plan_groups(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE plan_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day_plan_id INTEGER NOT NULL,
        chapter_id INTEGER NOT NULL,
        chapter_name TEXT NOT NULL,
        subject_name TEXT NOT NULL,
        subject_emoji TEXT NOT NULL DEFAULT '📚',
        grade INTEGER NOT NULL,
        knowledge_point TEXT,
        status INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT,
        origin_month_plan_id INTEGER,
        origin_week_plan_id INTEGER,
        FOREIGN KEY (day_plan_id) REFERENCES plan_groups(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject INTEGER NOT NULL,
        grade INTEGER NOT NULL,
        chapter TEXT NOT NULL,
        content TEXT NOT NULL,
        type INTEGER NOT NULL,
        difficulty INTEGER NOT NULL,
        options TEXT,
        answer TEXT NOT NULL,
        explanation TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE practice_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_id INTEGER NOT NULL,
        user_answer TEXT NOT NULL,
        is_correct INTEGER NOT NULL,
        practiced_at TEXT NOT NULL,
        FOREIGN KEY (question_id) REFERENCES questions (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount INTEGER NOT NULL,
        reason TEXT NOT NULL,
        earned_at TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_curriculum_subject_grade ON curriculum (subject, grade)');
    await db.execute('CREATE INDEX idx_plan_groups_dates ON plan_groups (type, start_date, end_date)');
    await db.execute('CREATE INDEX idx_plan_items_day ON plan_items (day_plan_id)');
    await db.execute('CREATE INDEX idx_plan_items_chapter ON plan_items (chapter_id)');
    await db.execute('CREATE INDEX idx_questions_subject_grade ON questions (subject, grade)');
    await db.execute('CREATE INDEX idx_records_question ON practice_records (question_id)');
  }
}
