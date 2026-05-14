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
      version: 30,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createAllTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 30) {
      // v30: V3.24 家长审核加 issue_type 字段（题目有误/答案有误/半主观题/无问题）
      // approve 后写 audit feedback log 让 agent 处理（题库修订工作流）
      try {
        await db.execute('ALTER TABLE review_requests ADD COLUMN issue_type TEXT');
      } catch (_) {/* 已有则跳 */}
    }

    if (oldVersion < 29) {
      // v29: V3.23 总复习章并入综合练习（Famin 2026-05-13 决策："总复习没什么边界，都放综合练习"）
      // 1. curriculum 表：删数学 g6 总复习章（如还在）
      // 2. questions 表 chapter rename：总复习 → 综合练习
      // 3. questions 表 KP 兜底：总复习/X → 综合练习（单段）
      // 4. knowledge_points 表残留清理：删数学总复习 6 KP + 删语文 g8/g9 综合性学习 5 KP（v28 兜底未删 g8/g9 grade 时残留）
      try {
        await db.execute('''
          DELETE FROM curriculum
          WHERE subject = '数学' AND chapter_name = '总复习'
        ''');
        await db.execute('''
          UPDATE questions
          SET chapter = '综合练习'
          WHERE chapter = '总复习'
        ''');
        await db.execute('''
          UPDATE questions
          SET knowledge_point = '综合练习'
          WHERE knowledge_point LIKE '总复习/%'
        ''');
        await db.execute('''
          DELETE FROM knowledge_points
          WHERE category = '总复习'
        ''');
        // 兜底 v28 未清的 g8/g9 综合性学习 KP（v28 只做 subject='语文' AND category='综合性学习'，本无 grade 限定，但保险重做）
        await db.execute('''
          DELETE FROM knowledge_points
          WHERE subject = '语文' AND category = '综合性学习'
        ''');
      } catch (_) {/* 已迁过则跳 */}
    }

    if (oldVersion < 28) {
      // v28: V3.22 章节/KP 重构（Famin 2026-05-13 决策，spec md = ~/AI_Workspace/Planning/v3_22_chapter_kp_rules.md）
      // 1. 语文阅读理解 6→2 KP（删主旨段意/人物形象分析/说明方法/其它），保留现代文阅读/材料阅读
      // 2. 语文删综合性学习章 + 6 KP
      // 3. 语文加综合练习章（与数理化对齐，KP 单段无斜杠）
      // 4. questions 表 chapter rename：综合性学习 → 综合练习
      // 5. questions 表 KP 兜底：阅读理解 4 个废弃 KP → 阅读理解/现代文阅读；综合性学习/X → 综合练习
      // 6. KP 表残留清理 + curriculum 表残留清理
      // 备注：V3.22 走全清重扫路径，questions 表数据会被 worker 重扫覆盖。本 migration 只是 fallback。
      try {
        // 1. curriculum 表：语文综合性学习 chapter → 综合练习（orderIndex 同步改 99）
        await db.execute('''
          UPDATE curriculum
          SET chapter_name = '综合练习', order_index = 99
          WHERE subject = '语文' AND chapter_name = '综合性学习'
        ''');
        // 2. questions 表 chapter rename：综合性学习 → 综合练习（语文）
        await db.execute('''
          UPDATE questions
          SET chapter = '综合练习'
          WHERE chapter = '综合性学习'
        ''');
        // 3. questions 表 KP 兜底：阅读理解 4 个废弃 KP → 阅读理解/现代文阅读
        await db.execute('''
          UPDATE questions
          SET knowledge_point = '阅读理解/现代文阅读'
          WHERE knowledge_point IN (
            '阅读理解/主旨段意',
            '阅读理解/人物形象分析',
            '阅读理解/说明方法',
            '阅读理解/其它'
          )
        ''');
        // 4. questions 表 KP 兜底：综合性学习/X → 综合练习
        await db.execute('''
          UPDATE questions
          SET knowledge_point = '综合练习'
          WHERE knowledge_point LIKE '综合性学习/%'
        ''');
        // 5. knowledge_points 表残留清理：删综合性学习 category
        await db.execute('''
          DELETE FROM knowledge_points
          WHERE subject = '语文' AND category = '综合性学习'
        ''');
        // 6. knowledge_points 表残留清理：删阅读理解 4 个废弃 KP
        await db.execute('''
          DELETE FROM knowledge_points
          WHERE subject = '语文' AND category = '阅读理解' AND name IN (
            '主旨段意', '人物形象分析', '说明方法', '其它'
          )
        ''');
      } catch (_) {/* 已迁过则跳 */}
    }

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
      // v17: V3.12 第六批 OCR 抢救语文 122 题原本只标 _unverified_v312（暂存待 reviewer 重写）。
      // V3.12.3 起按 .realpaper-spec.md §9.1 "识别不清直接放弃"原则，v18 一并删除。
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
    if (oldVersion < 18) {
      // v18: V3.12.3 完全删除老题（Famin 决策：经常因老题引发 bug，识别不清直接放弃）
      // 删除范围：
      //   - V3.8.3 / V3.10 标 _deprecated 的 12 卷 cron AI 出语数英（外研社英语 + 部编/北师大语数）
      //   - V3.12.1 标 _unverified_v312 的 3 卷 OCR 抢救语文（122 题）
      // _ 是 SQLite LIKE 单字符通配符；'%_deprecated' 末尾匹配任意字符 + "deprecated"
      // 实际数据中只有 source 末尾确实是 "_deprecated" 的会被命中
      try {
        await db.delete('questions',
            where: "source LIKE '%_deprecated' OR source LIKE '%_unverified%'");
      } catch (_) {/* 已无数据则跳过 */}
    }

    if (oldVersion < 19) {
      // v19: V3.12.7 batch_hash 机制（题数 bug 底层修复）
      // 1. questions 表加 batch_hash 字段
      // 2. 删除六下数学/语文 realpaper 题：让 V3.12.6 重扫的 batch 在下次启动重新 import
      try {
        await db.execute('ALTER TABLE questions ADD COLUMN batch_hash TEXT');
      } catch (_) {/* 已加过则跳 */}
      try {
        await db.delete('questions',
            where: "source LIKE 'realpaper_g6_math_%' OR source LIKE 'realpaper_g6_chinese_%'");
      } catch (_) {/* 无数据 */}
    }

    if (oldVersion < 21) {
      // v21: V3.12.22 A3 加 option_images 列（choice 选项图：折线行程图/几何图选项等）
      try {
        await db.execute('ALTER TABLE questions ADD COLUMN option_images TEXT');
      } catch (_) {/* 已加过则跳 */}
    }

    if (oldVersion < 22) {
      // v22: V3.13 加 ai_dispute_json 列。worker 入库时若发现答案算法冲突写此字段。
      try {
        await db.execute('ALTER TABLE questions ADD COLUMN ai_dispute_json TEXT');
      } catch (_) {/* 已加过则跳 */}
    }

    if (oldVersion < 26) {
      // v26: 阶段一 V3.20.3 部分得分 + 半主观 schema
      // - questions.is_semi_subjective: worker 入库标记的半主观题（词义解释/概括/赏析等）
      // - practice_records.partial_score: 多空题部分得分（0.0-1.0），单空题与 is_correct 一致
      // 旧 record 用 CASE 推断 partial_score：is_correct=1 → 1.0, =0 → 0.0
      try {
        await db.execute('ALTER TABLE questions ADD COLUMN is_semi_subjective INTEGER NOT NULL DEFAULT 0');
      } catch (_) {/* 已存在则跳 */}
      try {
        await db.execute('ALTER TABLE practice_records ADD COLUMN partial_score REAL');
        // 老 record 默认按 is_correct 转
        await db.execute('UPDATE practice_records SET partial_score = CASE WHEN is_correct=1 THEN 1.0 ELSE 0.0 END WHERE partial_score IS NULL');
      } catch (_) {/* 已存在则跳 */}
    }

    if (oldVersion < 27) {
      // v27: V3.21 KP 极简化（每章 ≤5 KP + 其它）+ 综合练习 一级 KP（单段）
      // 1. chapter 表：旧 `小升初综合` `中考综合` → `综合练习`（数学 g6/g9, 物理 g9, 化学 g9）
      //    + 新建物理 g8 `综合练习`
      // 2. KP 表：删旧不在 V3.21 清单的 KP；新 KP 由 _seedReferenceData() insertIfMissing 补
      //    旧"综合练习/小升初综合" "综合练习/中考综合" → 删（保留新一级 `综合练习` name=''）
      // 3. questions 表：chapter='小升初综合'/'中考综合' → '综合练习'
      //    knowledge_point 跨章组合题统一 → 数据层后续 V3.21.3 脚本处理 batch JSON 后重导
      //    DB 层只做 chapter rename
      try {
        // 1. chapter 表 rename
        await db.execute('''
          UPDATE curriculum
          SET chapter_name = '综合练习'
          WHERE chapter_name IN ('小升初综合', '中考综合')
        ''');
        // 2. questions 表 chapter rename（数据层 batch JSON V3.21.3 同步改）
        await db.execute('''
          UPDATE questions
          SET chapter = '综合练习'
          WHERE chapter IN ('小升初综合', '中考综合')
        ''');
        // 3. questions 表 knowledge_point 旧 综合练习/X → 综合练习（单段）
        await db.execute('''
          UPDATE questions
          SET knowledge_point = '综合练习'
          WHERE knowledge_point IN ('综合练习/小升初综合', '综合练习/中考综合')
        ''');
        // 4. KP 表残留清理：删旧"综合练习/小升初综合"等子 KP
        await db.execute('''
          DELETE FROM knowledge_points
          WHERE category = '综合练习' AND name != ''
        ''');
        // 5. 语文 KP 表残留：删不在 V3.21 6×7 新清单的语文 KP
        //    新清单见 knowledge_points_seed.dart V3.21 section。这里用 NOT IN 白名单删旧 KP。
        await db.execute('''
          DELETE FROM knowledge_points
          WHERE subject = '语文' AND full_path NOT IN (
            '字词/字音字形','字词/词语理解','字词/近义词反义词','字词/成语运用','字词/字词积累','字词/其它',
            '句子和语法/修辞','句子和语法/句子衔接','句子和语法/句式转换','句子和语法/关联词运用','句子和语法/病句与标点','句子和语法/其它',
            '阅读理解/现代文阅读','阅读理解/材料阅读','阅读理解/主旨段意','阅读理解/人物形象分析','阅读理解/说明方法','阅读理解/其它',
            '古诗文/古诗词鉴赏','古诗文/文言文阅读','古诗文/文言文比较阅读','古诗文/文言实词','古诗文/文言句子翻译','古诗文/其它',
            '文学常识/中国古代作家作品','文学常识/中国现代作家作品','文学常识/外国作家作品','文学常识/文化常识','文学常识/名著与作品','文学常识/其它',
            '综合性学习/综合实践','综合性学习/生活常识','综合性学习/信息提取','综合性学习/口语交际','综合性学习/实践活动设计','综合性学习/其它',
            '写作/应用文写作','写作/记叙文写作','写作/说明文写作','写作/议论文写作','写作/半命题写作','写作/其它'
          )
        ''');
        // 6. 数学 g6 KP 残留：删旧 category（比和比例 / 正反比例 / 数学综合）旧 KP
        //    新 V3.21 category 名：比例 / 正比例和反比例 / 数学好玩
        await db.execute('''
          DELETE FROM knowledge_points
          WHERE subject = '数学' AND category IN ('比和比例','正反比例','数学综合')
        ''');
        // 7. 数学 g6 KP：删旧名（圆柱的认识 / 圆锥的认识 / 化简比 / 求比值 等已被合并）
        await db.execute('''
          DELETE FROM knowledge_points
          WHERE subject = '数学' AND full_path IN (
            '圆柱与圆锥/圆柱的认识','圆柱与圆锥/圆锥的认识'
          )
        ''');
      } catch (_) {/* 已迁过则跳 */}
    }

    if (oldVersion < 25) {
      // v25: V3.19.16 fill 多空答案 schema 加固
      // 修 worker 误用 `|||`（同空多种等价写法）做多空分隔 → app displayAnswer 取 first
      // 只显第 1 段的 bug。新增 answer_blanks 列存 JSON List<String>，多空题各自给。
      try {
        await db.execute('ALTER TABLE questions ADD COLUMN answer_blanks TEXT');
      } catch (_) {/* 已存在则跳 */}
    }

    if (oldVersion < 24) {
      // v24: V3.18 章节体系简化（Famin 7 chapter 决策）—— 老 chapter 表残留清理
      // 问题: curriculum_dao.insertIfMissing 用 INSERT OR IGNORE 只加新的不删老的。
      // V3.14 简化后 seed 只有 7 个语文 chapter，但老用户 db 里还有 13+ 个老的
      // （修辞/句式与标点/现代文阅读/课文与名著/名著阅读/语法/语法与句式/小升初综合/中考综合）
      // → app 章节列表显示老旧体系，跟 V3.18 v2 题库匹配不上。
      //
      // 修法：DELETE 不在新 seed 中的 chapter + 同步清 KP 老命名残留
      // （新 seed 用 7 chapter 命名，老 KP "修辞/比喻"等已无对应入库题）
      try {
        // 语文 chapter: 删不在 7 个标准里的（V3.14 简化）
        await db.execute('''
          DELETE FROM curriculum
          WHERE subject = '语文' AND chapter_name NOT IN
            ('字词','句子和语法','阅读理解','古诗文','文学常识','综合性学习','写作')
        ''');
        // 数学 chapter 不动（数学 chapter 没简化过）
        // KP 表: 删语文老 category 残留
        await db.execute('''
          DELETE FROM knowledge_points
          WHERE subject = '语文' AND category NOT IN
            ('字词','句子和语法','阅读理解','古诗文','文学常识','综合性学习','写作')
        ''');
      } catch (_) {/* 已删过则跳 */}
    }

    if (oldVersion < 23) {
      // v23: V3.13 修正（Famin 反馈）—— AI dispute 题不让小孩做，直接进家长审核。
      // review_requests.practice_record_id 改 nullable（aiDispute 不关联做题）。
      // SQLite 不支持直接 ALTER COLUMN nullable → 重建表。
      try {
        await db.execute('''
          CREATE TABLE review_requests_v23 (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            request_type TEXT NOT NULL,
            question_id INTEGER NOT NULL,
            practice_record_id INTEGER,
            session_id TEXT,
            user_answer TEXT NOT NULL DEFAULT '',
            standard_answer TEXT,
            status TEXT NOT NULL DEFAULT 'pending',
            child_note TEXT,
            parent_note TEXT,
            parent_score TEXT,
            created_at TEXT NOT NULL,
            reviewed_at TEXT,
            FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
            FOREIGN KEY (practice_record_id) REFERENCES practice_records(id) ON DELETE SET NULL
          )
        ''');
        await db.execute('''
          INSERT INTO review_requests_v23
          (id, request_type, question_id, practice_record_id, session_id, user_answer,
           standard_answer, status, child_note, parent_note, parent_score, created_at, reviewed_at)
          SELECT id, request_type, question_id, practice_record_id, session_id, user_answer,
                 standard_answer, status, child_note, parent_note, parent_score, created_at, reviewed_at
          FROM review_requests
        ''');
        await db.execute('DROP TABLE review_requests');
        await db.execute('ALTER TABLE review_requests_v23 RENAME TO review_requests');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_review_requests_status ON review_requests (status)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_review_requests_question ON review_requests (question_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_review_requests_record ON review_requests (practice_record_id)');
      } catch (e) {
        // 失败兜底：旧 review_requests 仍可用（NOT NULL 约束在），新 aiDispute INSERT 会失败但不崩
      }
    }

    if (oldVersion < 20) {
      // v20: V3.12.8 兜底——再次强制清掉所有 realpaper_g6 题（含可能漏的英语）
      // V3.12.7 实测：用户装 final.apk 后题数仍接近旧值，说明 v18→v19 升级在某些设备没正确执行。
      // v20 作为兜底：无论之前 batch_hash 机制是否生效，强制清 realpaper_g6 旧数据 + 重 import。
      // 同时清 V3.6/V3.10 cron 时期的老 source（外研社、cron AI 出题等历史残留）。
      try {
        await db.delete('questions', where: "source LIKE 'realpaper_g6_%'");
      } catch (_) {}
      try {
        // 老 cron / 外研社 / V3.7.6 R2 等 batch_2026_05_*g6_* 仅保留 PET R1-R4
        await db.delete('questions',
            where: "source LIKE 'batch_2026_05_%g6_%' AND source NOT LIKE '%pet_r%'");
      } catch (_) {}
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
        option_images TEXT,
        answer TEXT NOT NULL,
        explanation TEXT,
        image_data TEXT,
        audio_text TEXT,
        speakers_json TEXT,
        round INTEGER,
        group_id TEXT,
        group_order INTEGER,
        ai_dispute_json TEXT,
        source TEXT DEFAULT 'pregenerated',
        batch_hash TEXT,
        user_id TEXT DEFAULT 'local',
        answer_blanks TEXT,
        is_semi_subjective INTEGER NOT NULL DEFAULT 0
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
        partial_score REAL,
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
        practice_record_id INTEGER,
        session_id TEXT,
        user_answer TEXT NOT NULL DEFAULT '',
        standard_answer TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        child_note TEXT,
        parent_note TEXT,
        parent_score TEXT,
        issue_type TEXT,
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
