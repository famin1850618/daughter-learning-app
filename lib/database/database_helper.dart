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
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createAllTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 新增 curriculum 表
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
        CREATE INDEX IF NOT EXISTS idx_curriculum_subject_grade
        ON curriculum (subject, grade)
      ''');

      // study_plans 新增 chapter_id 和 knowledge_point 字段
      await db.execute('ALTER TABLE study_plans ADD COLUMN chapter_id INTEGER');
      await db.execute('ALTER TABLE study_plans ADD COLUMN grade INTEGER NOT NULL DEFAULT 6');
      await db.execute('ALTER TABLE study_plans ADD COLUMN knowledge_point TEXT');
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
      CREATE TABLE study_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject INTEGER NOT NULL,
        grade INTEGER NOT NULL DEFAULT 6,
        chapter_id INTEGER,
        knowledge_point TEXT,
        title TEXT NOT NULL,
        description TEXT,
        due_date TEXT NOT NULL,
        type INTEGER NOT NULL,
        status INTEGER NOT NULL DEFAULT 0,
        estimated_minutes INTEGER NOT NULL DEFAULT 30,
        created_at TEXT NOT NULL,
        FOREIGN KEY (chapter_id) REFERENCES curriculum (id)
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
    await db.execute('CREATE INDEX idx_questions_subject_grade ON questions (subject, grade)');
    await db.execute('CREATE INDEX idx_plans_due_date ON study_plans (due_date)');
    await db.execute('CREATE INDEX idx_records_question ON practice_records (question_id)');
  }
}
