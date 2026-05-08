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
      version: 17,
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
    if (oldVersion < 11) {
      // v11: 难度档（V3.8）—— 1=基础 / 2=中等 / 3=较难 / 4=竞赛
      try {
        await db.execute('ALTER TABLE questions ADD COLUMN round INTEGER');
      } catch (_) {/* 已存在 */}
      try {
        await db.execute('CREATE INDEX IF NOT EXISTS idx_questions_round ON questions (round)');
      } catch (_) {}
    }
    if (oldVersion < 12) {
      // v12: 系列题分组（V3.8.2）
      try {
        await db.execute('ALTER TABLE questions ADD COLUMN group_id TEXT');
      } catch (_) {/* 已存在 */}
      try {
        await db.execute('ALTER TABLE questions ADD COLUMN group_order INTEGER');
      } catch (_) {}
      try {
        await db.execute('CREATE INDEX IF NOT EXISTS idx_questions_group ON questions (group_id)');
      } catch (_) {}

      // V3.8.2: 这些 source 的题被重生成或全审，清掉旧版让新 assets 重新导入。
      // 同时清相关 practice_records（先关 FK 约束，删后开回）。
      const reseedSources = [
        'batch_2026_05_07_g6_math_r3',     // R3 数学整体重生成
        'batch_2026_05_07_g6_chinese_r3',  // R3 语文整体重生成
        'batch_2026_05_07_g6_english_r3',  // R3 英语整体重生成
        'batch_2026_05_06_g6_chinese',     // R1 语文 Agent 全审改写
        'batch_2026_05_07_g6_chinese_r2',  // R2 语文 Agent 全审改写
      ];
      try {
        await db.execute('PRAGMA foreign_keys = OFF');
        for (final src in reseedSources) {
          final ids = await db.rawQuery(
              'SELECT id FROM questions WHERE source = ?', [src]);
          if (ids.isNotEmpty) {
            final idList = ids.map((m) => m['id']).toList();
            final ph = List.filled(idList.length, '?').join(',');
            await db.delete('practice_records',
                where: 'question_id IN ($ph)', whereArgs: idList);
            await db.delete('questions',
                where: 'source = ?', whereArgs: [src]);
          }
        }
        await db.execute('PRAGMA foreign_keys = ON');
      } catch (_) {/* 忽略，迁移失败不影响 v12 schema 变更 */}
    }
    if (oldVersion < 13) {
      // v13: V3.8.3
      // 1) 申诉与主观题评分共用表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS review_requests (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          request_type TEXT NOT NULL,
          question_id INTEGER NOT NULL,
          practice_record_id INTEGER NOT NULL,
          session_id TEXT,
          user_answer TEXT NOT NULL,
          standard_answer TEXT,
          status TEXT NOT NULL DEFAULT 'pending',
          child_note TEXT,
          parent_note TEXT,
          parent_score TEXT,
          created_at TEXT NOT NULL,
          reviewed_at TEXT,
          user_id TEXT DEFAULT 'local'
        )
      ''');
      try {
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_review_requests_status ON review_requests (status)');
      } catch (_) {}
      try {
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_review_requests_question ON review_requests (question_id)');
      } catch (_) {}
      try {
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_review_requests_record ON review_requests (practice_record_id)');
      } catch (_) {}

      // 2) practice_records 加 session_id（申诉副作用要重判 session 通过状态用）
      try {
        await db.execute('ALTER TABLE practice_records ADD COLUMN session_id TEXT');
      } catch (_) {}
      try {
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_records_session ON practice_records (session_id)');
      } catch (_) {}

      // 3) practice_sessions 加暂停字段（计时暂停）
      try {
        await db.execute(
            'ALTER TABLE practice_sessions ADD COLUMN paused_total_ms INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE practice_sessions ADD COLUMN paused_at TEXT');
      } catch (_) {}

      // 4) 老外研社英语题包标记 deprecated（V3.9 转 Cambridge 体系，老题不抽但保留）
      const deprecatedEnglishSources = [
        'batch_2026_05_06_g6_english',
        'batch_2026_05_07_g6_english_r2',
        'batch_2026_05_07_g6_english_r3',
        'batch_2026_05_08_g7_english_r1',
      ];
      for (final src in deprecatedEnglishSources) {
        try {
          await db.update(
            'questions',
            {'source': '${src}_deprecated'},
            where: 'source = ?',
            whereArgs: [src],
          );
        } catch (_) {/* 忽略 */}
      }
    }
    if (oldVersion < 14) {
      // v14: V3.10 全面转向 —— cron AI 出的语数题包全部 deprecated
      // 8 个 batch（语数六下 R1+R2+R3 + 初一 R1）
      // 老题字段（chapter / type / KP）不动，仅改 source 加 _deprecated 后缀。
      // 抽题 SQL 已加 source NOT LIKE '%_deprecated' 过滤，故老题不再被抽到。
      const deprecatedCronSources = [
        'batch_2026_05_06_g6_math',
        'batch_2026_05_06_g6_chinese',
        'batch_2026_05_07_g6_math_r2',
        'batch_2026_05_07_g6_chinese_r2',
        'batch_2026_05_07_g6_math_r3',
        'batch_2026_05_07_g6_chinese_r3',
        'batch_2026_05_08_g7_math_r1',
        'batch_2026_05_08_g7_chinese_r1',
      ];
      for (final src in deprecatedCronSources) {
        try {
          await db.update(
            'questions',
            {'source': '${src}_deprecated'},
            where: 'source = ?',
            whereArgs: [src],
          );
        } catch (_) {/* 忽略 */}
      }
    }
    if (oldVersion < 15) {
      // v15: V3.11 真题切换收尾
      // 1) 删 curriculum 老语文 42 章 + 老英语 24 章 = 66 行（与 curriculum_seed.dart 同步）
      // 2) 创建数据归档表（重置进度时落档，7 天内可回滚）
      // 3) 真正的"自动清零"动作不在 SQL 迁移层做，由 DataResetService 在 main.dart 启动时
      //    凭 SharedPreferences 标志触发一次（这样 service 初始化齐全 + 走统一归档路径）。

      const deletedChineseChapters = [
        // g6 老 6 单元
        '第一单元：民风民俗', '第二单元：外国名著', '第三单元：真情流露',
        '第四单元：革命精神', '第五单元：科学精神', '第六单元：难忘小学生活',
        // g7 老 12 单元
        '七上·第一单元：四季美景', '七上·第二单元：至爱亲情', '七上·第三单元：学习生活',
        '七上·第四单元：人生之舟', '七上·第五单元：动物与人', '七上·第六单元：想象之翼',
        '七下·第一单元：群星闪耀', '七下·第二单元：家国情怀', '七下·第三单元：凡人小事',
        '七下·第四单元：修身正己', '七下·第五单元：哲思与志趣', '七下·第六单元：探险与科学',
        // g8 老 12 单元
        '八上·第一单元：新闻阅读', '八上·第二单元：回忆往事', '八上·第三单元：山川美景',
        '八上·第四单元：情感哲思', '八上·第五单元：文明的印迹', '八上·第六单元：情操与志趣',
        '八下·第一单元：民俗风情', '八下·第二单元：自然科学', '八下·第三单元：古代山水',
        '八下·第四单元：演讲口语', '八下·第五单元：山水游记', '八下·第六单元：古代哲思',
        // g9 老 12 单元
        '九上·第一单元：诗歌鉴赏', '九上·第二单元：议论文·思辨', '九上·第三单元：山水古文',
        '九上·第四单元：小说阅读', '九上·第五单元：议论文·创新', '九上·第六单元：古典小说',
        '九下·第一单元：现代诗歌', '九下·第二单元：小说人物', '九下·第三单元：先秦诸子',
        '九下·第四单元：文艺理论', '九下·第五单元：戏剧阅读', '九下·第六单元：古代史传',
      ];
      for (final n in deletedChineseChapters) {
        try {
          await db.delete('curriculum',
              where: 'subject = ? AND chapter_name = ?', whereArgs: ['语文', n]);
        } catch (_) {}
      }

      const deletedEnglishChapters = [
        // g6 老 6 章
        '词汇积累（小学核心1500词）', '一般现在时与现在进行时', '一般过去时',
        '简单句与句型转换', '日常交际用语', '基础阅读理解',
        // g7 老 6 章
        '词汇扩展（初中核心词2000词）', '一般将来时与情态动词', '比较级与最高级',
        'there be 句型与介词', '阅读理解：记叙文', '写作：简单段落',
        // g8 老 6 章
        '词汇扩展（3000词）', '现在完成时', '被动语态',
        '宾语从句', '阅读理解：说明文与议论文', '写作：应用文（书信/邮件）',
        // g9 老 6 章
        '词汇扩展（4000词）', '定语从句', '各类从句综合',
        '阅读理解：综合题型', '写作：议论文与说明文', '听力与口语表达',
      ];
      for (final n in deletedEnglishChapters) {
        try {
          await db.delete('curriculum',
              where: 'subject = ? AND chapter_name = ?', whereArgs: ['英语', n]);
        } catch (_) {}
      }

      // 数据归档表（DataResetService 用）
      await db.execute('''
        CREATE TABLE IF NOT EXISTS data_reset_archives (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          batch_id TEXT NOT NULL UNIQUE,
          created_at TEXT NOT NULL,
          reason TEXT,
          stats_json TEXT,
          rolled_back_at TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS data_reset_rows (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          archive_batch_id TEXT NOT NULL,
          table_name TEXT NOT NULL,
          row_json TEXT NOT NULL
        )
      ''');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_archive_rows_batch ON data_reset_rows (archive_batch_id)');
    }
    if (oldVersion < 16) {
      // v16: V3.12 听力多角色 TTS。questions 加 speakers_json 列存
      // {role: {gender, age}} 映射，_ListenButton 解析 audioText 后按角色切 voice/pitch。
      try {
        await db.execute('ALTER TABLE questions ADD COLUMN speakers_json TEXT');
      } catch (_) {/* 列已存在则忽略 */}
    }
    if (oldVersion < 17) {
      // v17: V3.12 第六批 OCR 抢救语文 122 题标 _unverified_v312。
      // 详见 docs/realpaper_quality_rules.md §6（多模态 OCR 抢救发现幻觉编造伪题）
      // _activeSourceFilter 自动过滤 → 这些题用户不会再抽到，直到 reviewer agent 重写
      const ocrRescueSources = [
        'realpaper_g6_chinese_bubian_d4_kp1_001',
        'realpaper_g6_chinese_bubian_d5_kp1_001',
        'realpaper_g6_chinese_bubian_d6_kp1_001',
      ];
      for (final src in ocrRescueSources) {
        try {
          await db.update(
            'questions',
            {'source': '${src}_unverified_v312'},
            where: 'source = ?',
            whereArgs: [src],
          );
        } catch (_) {/* 已迁移则跳过 */}
      }
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
        speakers_json TEXT,
        round INTEGER,
        group_id TEXT,
        group_order INTEGER,
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
        session_id TEXT,
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
        paused_total_ms INTEGER DEFAULT 0,
        paused_at TEXT,
        saved_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE review_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        request_type TEXT NOT NULL,
        question_id INTEGER NOT NULL,
        practice_record_id INTEGER NOT NULL,
        session_id TEXT,
        user_answer TEXT NOT NULL,
        standard_answer TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        child_note TEXT,
        parent_note TEXT,
        parent_score TEXT,
        created_at TEXT NOT NULL,
        reviewed_at TEXT,
        user_id TEXT DEFAULT 'local'
      )
    ''');

    // V3.11: 数据重置归档（DataResetService 用，7 天内可回滚）
    await db.execute('''
      CREATE TABLE data_reset_archives (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        batch_id TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL,
        reason TEXT,
        stats_json TEXT,
        rolled_back_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE data_reset_rows (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        archive_batch_id TEXT NOT NULL,
        table_name TEXT NOT NULL,
        row_json TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_archive_rows_batch ON data_reset_rows (archive_batch_id)');

    await db.execute('CREATE INDEX idx_rewards_earned_at ON rewards (earned_at)');
    await db.execute('CREATE INDEX idx_rewards_source ON rewards (source)');
    await db.execute('CREATE INDEX idx_assessments_period ON assessments (type, period_key)');
    await db.execute('CREATE INDEX idx_curriculum_subject_grade ON curriculum (subject, grade)');
    await db.execute('CREATE INDEX idx_plan_groups_dates ON plan_groups (type, start_date, end_date)');
    await db.execute('CREATE INDEX idx_plan_items_day ON plan_items (day_plan_id)');
    await db.execute('CREATE INDEX idx_plan_items_chapter ON plan_items (chapter_id)');
    await db.execute('CREATE INDEX idx_questions_subject_grade ON questions (subject, grade)');
    await db.execute('CREATE INDEX idx_questions_round ON questions (round)');
    await db.execute('CREATE INDEX idx_questions_group ON questions (group_id)');
    await db.execute('CREATE INDEX idx_records_question ON practice_records (question_id)');
    await db.execute('CREATE INDEX idx_records_session ON practice_records (session_id)');
    await db.execute('CREATE INDEX idx_kp_subject ON knowledge_points (subject)');
    await db.execute('CREATE INDEX idx_review_requests_status ON review_requests (status)');
    await db.execute('CREATE INDEX idx_review_requests_question ON review_requests (question_id)');
    await db.execute('CREATE INDEX idx_review_requests_record ON review_requests (practice_record_id)');
  }
}
