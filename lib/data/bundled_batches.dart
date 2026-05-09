/// V3.12.9_fix: 导出 bundled batch asset 路径列表
///
/// main.dart 启动钩子和设置页"重建题库"按钮共用同一份。
/// 旧版用 AssetManifest.json 反射查找在新版 Flutter 行为不稳定，
/// 改用 hardcoded list 保稳定 + 可控。
const bundledBatchAssets = <String>[
  // V3.9 Cambridge English (PET A2-C1, R1-R4)
  'assets/data/batches/batch_2026_05_07_g6_english_pet_r1.json',
  'assets/data/batches/batch_2026_05_08_g6_english_pet_r2.json',
  'assets/data/batches/batch_2026_05_08_g6_english_pet_r3.json',
  'assets/data/batches/batch_2026_05_08_g6_english_pet_r4.json',
  // V3.12.7 语文六下部编版真题第三轮 6 卷 96 题
  'assets/data/batches/realpaper_g6_chinese_bubian_qizhong_002.json',
  'assets/data/batches/realpaper_g6_chinese_bubian_qizhong_003.json',
  'assets/data/batches/realpaper_g6_chinese_bubian_qizhong_004.json',
  'assets/data/batches/realpaper_g6_chinese_bubian_qizhong_008.json',
  'assets/data/batches/realpaper_g6_chinese_bubian_qimo_quanzhen_001.json',
  'assets/data/batches/realpaper_g6_chinese_bubian_qimo_moni_004.json',
  // V3.12.20.1 D 批语文期中卷5
  'assets/data/batches/realpaper_g6_chinese_bubian_qizhong_005.json',
  // V3.12.7 数学六下北师大版真题第三轮 5 卷 205 题
  'assets/data/batches/realpaper_g6_math_beishida_d1_guoguan_001.json',
  'assets/data/batches/realpaper_g6_math_beishida_d2_guoguan_001.json',
  'assets/data/batches/realpaper_g6_math_beishida_qizhong_001.json',
  'assets/data/batches/realpaper_g6_math_beishida_qimo_001.json',
  'assets/data/batches/realpaper_g6_math_beishida_xsc_beijing_001.json',
];
