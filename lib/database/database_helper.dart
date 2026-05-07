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
      version: 10,
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
      await db.execute('DELETE FROM curriculum');
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE questions ADD COLUMN knowledge_point TEXT');
      await db.execute("ALTER TABLE questions ADD COLUMN source TEXT DEFAULT 'pregenerated'");
      await db.execute('ALTER TABLE practice_records ADD COLUMN time_spent INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE practice_records ADD COLUMN used_hint INTEGER DEFAULT 0');
    }
    if (oldVersion < 7) {
      // v7: 引入两层 KP 体系 + 各业务表加 user_id 预留（为 V3.7 账号系统铺路）
      // 纪律：仅 ADD/CREATE，绝不 DELETE 业务数据（自此版起 app 进入正式使用）
      await db.execute('''
        CREATE TABLE IF NOT EXISTS knowledge_points (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          subject TEXT NOT NULL,
          category TEXT NOT NULL,
          name TEXT NOT NULL,
          full_path TEXT NOT NULL,
          introduced_grade INTEGER,
          UNIQUE(subject, full_path)
        )
      ''');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_kp_subject ON knowledge_points (subject)');

      // user_id 预留：现有数据全打 'local' 标，V3.7 登录时迁移到真实 user_id
      for (final t in const [
        'questions',
        'practice_records',
        'points',
        'plan_groups',
        'plan_items',
      ]) {
        try {
          await db.execute("ALTER TABLE $t ADD COLUMN user_id TEXT DEFAULT 'local'");
        } catch (_) {
          // 列已存在的容错（避免重复迁移）
        }
      }
    }
    if (oldVersion < 8) {
      // v8: V3.7 奖励系统 + 周月测评（仅 ADD/CREATE）
      await db.execute('''
        CREATE TABLE IF NOT EXISTS rewards (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          source TEXT NOT NULL,
          stars REAL NOT NULL,
          earned_at TEXT NOT NULL,
          session_id TEXT,
          note TEXT,
          user_id TEXT DEFAULT 'local'
        )
      ''');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_rewards_earned_at ON rewards (earned_at)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_rewards_source ON rewards (source)');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS assessments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type INTEGER NOT NULL,
          period_key TEXT NOT NULL,
          status INTEGER NOT NULL DEFAULT 0,
          score INTEGER NOT NULL DEFAULT 0,
          total INTEGER NOT NULL DEFAULT 0,
          taken_at TEXT,
          user_id TEXT DEFAULT 'local'
        )
      ''');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_assessments_period ON assessments (type, period_key)');
    }
    if (oldVersion < 9) {
      // v9: 练习中断恢复（V3.7.1）
      await db.execute('''
        CREATE TABLE IF NOT EXISTS practice_sessions (
          id INTEGER PRIMARY KEY,
          questions_json TEXT,
          current_index INTEGER,
          score INTEGER,
          kind INTEGER,
          session_active INTEGER,
          session_id TEXT,
          hint_shown INTEGER,
          reward_claimed INTEGER,
          last_reward_json TEXT,
          saved_at TEXT
        )
      ''');
    }
    if (oldVersion < 10) {
      // v10: 题目支持图形（SVG/base64 image）和听力朗读文本，V3.7.6
      try {
        await db.execute('ALTER TABLE questions ADD COLUMN image_data TEXT');
      } catch (_) {/* 已存在 */}
      try {
        await db.execute('ALTER TABLE questions ADD COLUMN audio_text TEXT');
      } catch (_) {/* 已存在 */}
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
        knowledge_point TEXT,
        content TEXT NOT NULL,
        type INTEGER NOT NULL,
        difficulty INTEGER NOT NULL,
        options TEXT,
        answer TEXT NOT NULL,
        explanation TEXT,
        image_data TEXT,
        audio_text TEXT,
        source TEXT DEFAULT 'pregenerated',
        user_id TEXT DEFAULT 'local'
      )
    ''');

    await db.execute('''
      CREATE TABLE practice_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_id INTEGER NOT NULL,
        user_answer TEXT NOT NULL,
        is_correct INTEGER NOT NULL,
        practiced_at TEXT NOT NULL,
        time_spent INTEGER DEFAULT 0,
        used_hint INTEGER DEFAULT 0,
        user_id TEXT DEFAULT 'local',
        FOREIGN KEY (question_id) REFERENCES questions (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount INTEGER NOT NULL,
        reason TEXT NOT NULL,
        earned_at TEXT NOT NULL,
        user_id TEXT DEFAULT 'local'
      )
    ''');

    await db.execute('''
      CREATE TABLE knowledge_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject TEXT NOT NULL,
        category TEXT NOT NULL,
        name TEXT NOT NULL,
        full_path TEXT NOT NULL,
        introduced_grade INTEGER,
        UNIQUE(subject, full_path)
      )
    ''');

    await db.execute('''
      CREATE TABLE rewards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source TEXT NOT NULL,
        stars REAL NOT NULL,
        earned_at TEXT NOT NULL,
        session_id TEXT,
        note TEXT,
        user_id TEXT DEFAULT 'local'
      )
    ''');

    await db.execute('''
      CREATE TABLE assessments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type INTEGER NOT NULL,
        period_key TEXT NOT NULL,
        status INTEGER NOT NULL DEFAULT 0,
        score INTEGER NOT NULL DEFAULT 0,
        total INTEGER NOT NULL DEFAULT 0,
        taken_at TEXT,
        user_id TEXT DEFAULT 'local'
      )
    ''');

    await db.execute('''
      CREATE TABLE practice_sessions (
        id INTEGER PRIMARY KEY,
        questions_json TEXT,
        current_index INTEGER,
        score INTEGER,
        kind INTEGER,
        session_active INTEGER,
        session_id TEXT,
        hint_shown INTEGER,
        reward_claimed INTEGER,
        last_reward_json TEXT,
        saved_at TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_rewards_earned_at ON rewards (earned_at)');
    await db.execute('CREATE INDEX idx_rewards_source ON rewards (source)');
    await db.execute('CREATE INDEX idx_assessments_period ON assessments (type, period_key)');
    await db.execute('CREATE INDEX idx_curriculum_subject_grade ON curriculum (subject, grade)');
    await db.execute('CREATE INDEX idx_plan_groups_dates ON plan_groups (type, start_date, end_date)');
    await db.execute('CREATE INDEX idx_plan_items_day ON plan_items (day_plan_id)');
    await db.execute('CREATE INDEX idx_plan_items_chapter ON plan_items (chapter_id)');
    await db.execute('CREATE INDEX idx_questions_subject_grade ON questions (subject, grade)');
    await db.execute('CREATE INDEX idx_records_question ON practice_records (question_id)');
    await db.execute('CREATE INDEX idx_kp_subject ON knowledge_points (subject)');
  }
}
