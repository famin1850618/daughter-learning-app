import '../models/knowledge_point.dart';

/// V3.9 Cambridge 英语 KP 清单（PET / FCE / CAE Foundation）
///
/// **全英文环境** —— Famin 决策：英语 subject 下 KP / category 全英文，
/// 强化沉浸式语言环境。详见 `docs/cambridge_english_kp_draft.md`。
///
/// 体系映射：
///   - Grade 6 → PET (B1)
///   - Grade 7 → FCE Entry-Mid (B2)
///   - Grade 8 → FCE Mid-High (B2)
///   - Grade 9 → CAE Foundation (C1 entry, no advanced Writing/complex Listening)
///
/// **Categories — 4 类（学科领域维度，题型不做 category）：**
///   - Vocabulary
///   - Grammar
///   - Reading
///   - Listening
///
/// 题型由 `Question.type` (choice/fill) 表达；
/// Cambridge Part 由 `Question.chapter` 字段标记（如 `"FCE Part 3"`）。
///
/// **Writing 暂不出**（等接入 AI 评分 API；详见 `project_writing_pending.md`）
const List<KnowledgePoint> cambridgeEnglishKpSeed = [
  // ════════════════════════════════════════════════════
  // PET (B1) — Grade 6 (20 KP)
  // ════════════════════════════════════════════════════

  // ── PET Vocabulary (6) ──
  KnowledgePoint(
      subject: '英语', category: 'Vocabulary', name: 'Family & Relationships', introducedGrade: 6),
  KnowledgePoint(
      subject: '英语', category: 'Vocabulary', name: 'Travel & Holidays', introducedGrade: 6),
  KnowledgePoint(
      subject: '英语', category: 'Vocabulary', name: 'School & Study', introducedGrade: 6),
  KnowledgePoint(
      subject: '英语', category: 'Vocabulary', name: 'Food & Daily Life', introducedGrade: 6),
  KnowledgePoint(
      subject: '英语', category: 'Vocabulary', name: 'Hobbies & Leisure', introducedGrade: 6),
  KnowledgePoint(
      subject: '英语', category: 'Vocabulary', name: 'Shopping & Money', introducedGrade: 6),

  // ── PET Grammar (9) ──
  KnowledgePoint(
      subject: '英语', category: 'Grammar', name: 'Present Simple', introducedGrade: 6),
  KnowledgePoint(
      subject: '英语', category: 'Grammar', name: 'Present Continuous', introducedGrade: 6),
  KnowledgePoint(
      subject: '英语', category: 'Grammar', name: 'Past Simple', introducedGrade: 6),
  KnowledgePoint(
      subject: '英语', category: 'Grammar', name: 'Past Continuous', introducedGrade: 6),
  KnowledgePoint(
      subject: '英语', category: 'Grammar', name: 'Present Perfect (basic)', introducedGrade: 6),
  KnowledgePoint(
      subject: '英语',
      category: 'Grammar',
      name: 'Future Tenses (will / going to / Present Continuous)',
      introducedGrade: 6),
  KnowledgePoint(
      subject: '英语',
      category: 'Grammar',
      name: 'Modals (can/could/should/might/must)',
      introducedGrade: 6),
  KnowledgePoint(
      subject: '英语',
      category: 'Grammar',
      name: 'Comparatives & Superlatives',
      introducedGrade: 6),
  KnowledgePoint(
      subject: '英语', category: 'Grammar', name: 'Conditionals 0 & 1', introducedGrade: 6),

  // ── PET Reading (3) ──
  KnowledgePoint(
      subject: '英语', category: 'Reading', name: 'Scanning for detail', introducedGrade: 6),
  KnowledgePoint(
      subject: '英语', category: 'Reading', name: 'Skimming for gist', introducedGrade: 6),
  KnowledgePoint(
      subject: '英语',
      category: 'Reading',
      name: 'Inferring meaning from context',
      introducedGrade: 6),

  // ── PET Listening (2) ──
  KnowledgePoint(
      subject: '英语', category: 'Listening', name: 'Listening for gist', introducedGrade: 6),
  KnowledgePoint(
      subject: '英语', category: 'Listening', name: 'Listening for detail', introducedGrade: 6),

  // ════════════════════════════════════════════════════
  // FCE (B2) — Grade 7 & 8 (27 new KP)
  // ════════════════════════════════════════════════════

  // ── FCE Vocabulary (7 new) ──
  KnowledgePoint(
      subject: '英语', category: 'Vocabulary', name: 'Work & Career', introducedGrade: 7),
  KnowledgePoint(
      subject: '英语', category: 'Vocabulary', name: 'Technology & Digital', introducedGrade: 7),
  KnowledgePoint(
      subject: '英语', category: 'Vocabulary', name: 'Health & Fitness', introducedGrade: 7),
  KnowledgePoint(
      subject: '英语', category: 'Vocabulary', name: 'Environment & Nature', introducedGrade: 7),
  KnowledgePoint(
      subject: '英语', category: 'Vocabulary', name: 'Media & Entertainment', introducedGrade: 7),
  KnowledgePoint(
      subject: '英语', category: 'Vocabulary', name: 'City & Community', introducedGrade: 7),
  KnowledgePoint(
      subject: '英语', category: 'Vocabulary', name: 'Word Choice (Cloze)', introducedGrade: 7),

  // ── FCE Grammar (14 new) ──
  KnowledgePoint(
      subject: '英语', category: 'Grammar', name: 'Present Perfect Continuous', introducedGrade: 7),
  KnowledgePoint(
      subject: '英语', category: 'Grammar', name: 'Past Perfect', introducedGrade: 7),
  KnowledgePoint(
      subject: '英语',
      category: 'Grammar',
      name: 'Past Perfect Continuous',
      introducedGrade: 7),
  KnowledgePoint(
      subject: '英语',
      category: 'Grammar',
      name: 'Future Perfect & Future Continuous',
      introducedGrade: 7),
  KnowledgePoint(
      subject: '英语',
      category: 'Grammar',
      name: 'Conditionals 2 / 3 / Mixed',
      introducedGrade: 7),
  KnowledgePoint(
      subject: '英语',
      category: 'Grammar',
      name: 'Modals Perfect (could have / should have / must have)',
      introducedGrade: 7),
  KnowledgePoint(
      subject: '英语', category: 'Grammar', name: 'Passive (all tenses)', introducedGrade: 7),
  KnowledgePoint(
      subject: '英语',
      category: 'Grammar',
      name: 'Reported Speech (all tenses & verbs)',
      introducedGrade: 7),
  KnowledgePoint(
      subject: '英语',
      category: 'Grammar',
      name: 'Relative Clauses (defining / non-defining)',
      introducedGrade: 7),
  KnowledgePoint(
      subject: '英语',
      category: 'Grammar',
      name: 'Linking Words (although / despite / however / whereas)',
      introducedGrade: 7),
  KnowledgePoint(
      subject: '英语',
      category: 'Grammar',
      name: 'Phrasal Verbs (high-frequency)',
      introducedGrade: 7),
  KnowledgePoint(
      subject: '英语', category: 'Grammar', name: 'Word Formation', introducedGrade: 7),
  KnowledgePoint(
      subject: '英语',
      category: 'Grammar',
      name: 'Sentence Transformation',
      introducedGrade: 7),
  KnowledgePoint(subject: '英语', category: 'Grammar', name: 'Open Cloze', introducedGrade: 7),

  // ── FCE Reading (4 new) ──
  KnowledgePoint(
      subject: '英语', category: 'Reading', name: "Inferring author's stance", introducedGrade: 7),
  KnowledgePoint(
      subject: '英语',
      category: 'Reading',
      name: 'Identifying logical relationships',
      introducedGrade: 7),
  KnowledgePoint(
      subject: '英语', category: 'Reading', name: 'Text Coherence', introducedGrade: 7),
  KnowledgePoint(
      subject: '英语', category: 'Reading', name: 'Multiple Matching', introducedGrade: 7),

  // ── FCE Listening (2 new) ──
  KnowledgePoint(
      subject: '英语',
      category: 'Listening',
      name: 'Listening for opinion & attitude',
      introducedGrade: 7),
  KnowledgePoint(
      subject: '英语', category: 'Listening', name: 'Multi-speaker listening', introducedGrade: 7),

  // ════════════════════════════════════════════════════
  // CAE Foundation (C1 entry) — Grade 9 (18 new KP)
  // ════════════════════════════════════════════════════

  // ── CAE Vocabulary (5 new) ──
  KnowledgePoint(
      subject: '英语', category: 'Vocabulary', name: 'Abstract Concepts', introducedGrade: 9),
  KnowledgePoint(
      subject: '英语',
      category: 'Vocabulary',
      name: 'Tech Deepening (AI / Privacy / Automation)',
      introducedGrade: 9),
  KnowledgePoint(
      subject: '英语', category: 'Vocabulary', name: 'Social Issues', introducedGrade: 9),
  KnowledgePoint(
      subject: '英语', category: 'Vocabulary', name: 'Economics & Finance', introducedGrade: 9),
  KnowledgePoint(
      subject: '英语',
      category: 'Vocabulary',
      name: 'Cultural Differences & Globalization',
      introducedGrade: 9),

  // ── CAE Grammar (7 new — C1 entry) ──
  KnowledgePoint(
      subject: '英语',
      category: 'Grammar',
      name: 'Inversion (never / rarely / only when / hardly)',
      introducedGrade: 9),
  KnowledgePoint(
      subject: '英语',
      category: 'Grammar',
      name: 'Subjunctive & Hypothetical Past',
      introducedGrade: 9),
  KnowledgePoint(
      subject: '英语',
      category: 'Grammar',
      name: 'Gerund vs Infinitive (verbs of preference)',
      introducedGrade: 9),
  KnowledgePoint(
      subject: '英语',
      category: 'Grammar',
      name: 'Participle Clauses & Absolute Structures',
      introducedGrade: 9),
  KnowledgePoint(
      subject: '英语',
      category: 'Grammar',
      name: 'Cleft Sentences (It is X that... / What X is...)',
      introducedGrade: 9),
  KnowledgePoint(
      subject: '英语',
      category: 'Grammar',
      name: 'Complex Conditionals (mixed tenses)',
      introducedGrade: 9),
  KnowledgePoint(
      subject: '英语',
      category: 'Grammar',
      name: 'Advanced Linking (nonetheless / albeit / insofar as)',
      introducedGrade: 9),

  // ── CAE Reading (5 new — Advanced) ──
  KnowledgePoint(
      subject: '英语',
      category: 'Reading',
      name: 'Identifying implied meaning',
      introducedGrade: 9),
  KnowledgePoint(
      subject: '英语',
      category: 'Reading',
      name: 'Distinguishing similar options',
      introducedGrade: 9),
  KnowledgePoint(
      subject: '英语',
      category: 'Reading',
      name: 'Recognizing irony & sarcasm',
      introducedGrade: 9),
  KnowledgePoint(
      subject: '英语', category: 'Reading', name: 'Paragraph main idea', introducedGrade: 9),
  KnowledgePoint(
      subject: '英语', category: 'Reading', name: 'Cross-text Matching', introducedGrade: 9),

  // ── CAE Listening (1 new — light) ──
  KnowledgePoint(
      subject: '英语',
      category: 'Listening',
      name: 'Academic conversation (light, no full lecture)',
      introducedGrade: 9),
];
