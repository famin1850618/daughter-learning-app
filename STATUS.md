# Daughter Learning App Status

Last updated: 2026-07-22

## Rollback Origin

The preserved rollback origin is the V3.36.2 app state before the Codex overdue-plan iteration.

- Source repo: `/home/faminwsl/daughter_learning_app`
- Preserved commit: `34444a4f1425fb168454752ba2c357196cc35b8d`
- Local tag: `rollback/v3.36.2-origin-20260721`
- Source bundle: `/mnt/d/AI_Workspace/Planning/app_backups/v3_36_2_origin_20260721/daughter_learning_app_v3_36_2_origin.bundle`
- APK backup: `/mnt/d/AI_Workspace/Planning/app_backups/v3_36_2_origin_20260721/planning_v3_36_2_debug_origin.apk`
- APK SHA256: `cb5975f60b8319637ef8fd368c16f9ef1759a627f1e1853cc8db4ff2150ddc3e`

Do not modify the rollback origin. Future app iterations should keep the newest two generated app versions; after two later iterations, remove the oldest non-origin generated version in sequence.

## Current Iteration

- Version: `3.37.0+73`
- Main change: in-app overdue-plan reminder and rollover into today's best-fit plan container.
- Debug APK: `/mnt/d/AI_Workspace/Planning/planning_v3_37_0_debug.apk`
- APK SHA256: `db0dad2f282ef84b63b7747c09027f10ac70184a6f309f4a3e6b31bca32e12c2`
- API keys: this APK embeds the DeepSeek grading key and Qwen handwriting/OCR key from the Planning key files.
- Keyed build command: `tools/build_debug_with_embedded_keys.sh`

For future debug APKs, use `tools/build_debug_with_embedded_keys.sh` rather than plain `flutter build apk --debug`. The script reads `/mnt/d/AI_Workspace/Planning/deepseek.txt` and `/mnt/d/AI_Workspace/Planning/qwen.txt`, passes them through a temporary `--dart-define-from-file`, deletes the temporary define file, and copies the APK back to the Planning directory under the versioned `planning_v*_debug.apk` name.

## Directory Map

- `/home/faminwsl/daughter_learning_app`: Flutter source repo.
- `/mnt/d/AI_Workspace/Planning`: working artifacts, APKs, scan logs, source exam papers, API-key text files, and backups.
- `question_bank/`: CDN-facing static question batches and `index.json`.
- `assets/data/`: local asset data root; current question loading is CDN-first rather than bundled-batch first.

## Current Architecture

- App framework: Flutter with Provider.
- Local storage: SQLite through `sqflite`.
- Main data tables: questions, practice records, plan groups/items, rewards, assessments, review requests, curriculum, knowledge points.
- Plan model: month plans contain week plans; week plans contain day plans; all actual plan items are attached to day plans.
- Practice flow: question sessions write `practice_records`, issue rewards, trigger plan auto-completion when score is at least 80%, and sync learning data if configured.
- Reward flow: correct answers earn stars; normal practice, weekly tests, and monthly tests have pass/perfect bonuses.
- Review flow: appeals, subjective grading, and AI-dispute questions enter the parent review queue.
- AI grading:
  - Choice and exact-match questions use local matching first.
  - Fill/calculation/judgment misses can be rechecked by DeepSeek.
  - Subjective questions can be graded by DeepSeek.
  - Proof questions can use handwriting image -> Qwen OCR -> DeepSeek thinking-mode grading in the background.
  - Drawing-only questions use self-evaluation with retained answer images.

## Question Bank

Current `question_bank/index.json` version: 152.

- Batch entries: 104
- Total questions: 3730
- By subject from index: math 1962, chinese 968, english 800
- By type from parsed question JSON: choice 1710, fill 1210, subjective 708, judgment 102
- With images: 704
- With audio: 95

Real-paper scanning for grade 6 Chinese and math is effectively complete for the selected true-exam campaign. Remaining source docs in `scan_skip.txt` are mainly duplicates, answer-only files, topical compilations, or mock/prediction papers held out by decision.

Grade 7 Shenzhen wave 1 was imported on 2026-07-21:

- `realpaper_g7_math_beishida_qz_yantian_001`: 盐田区 2024-2025 七上期中数学, 6 questions. Questions 12, 16, and 18 are geometry/original-image trials using docx embedded images as `image_data`, `_image_verified=true`; formulas in explanations are written in TeX. Question 16 is a pure drawing `subjective` item. Question 18 imports only subquestion (1); subquestion (2) remains skipped because key known conditions and numeric answers are missing in the text layer.
- `realpaper_g7_math_beishida_qm_shenzhong_001`: 深圳中学 2024-2025 七下期末数学, 4 conservative text-only questions.
- `realpaper_g7_chinese_renjiao_qz_shenzhen48_001`: 深圳48校联考 2023-2024 七上期中语文, 17 questions.
- `realpaper_g7_chinese_renjiao_qm_luohu_001`: 罗湖区 2024-2025 七下期末语文, 8 questions.

The four G7 batches are double-written to `question_bank/` and `assets/data/batches/`, registered in `question_bank/index.json`, and pass the realpaper full validator plus cross-batch/material/common-prefix/group-chapter checks. Formula and geometry image handling is standardized in `docs/realpaper_formula_geometry_image_policy.md`. The two math papers have many formulas, options, tables, and figures stored as WMF/PNG with missing text layer; skipped math questions should be revisited only after formula/image recognition and visual verification.

## Known Risks

- Plan completion still depends on exact subject/grade/chapter/KP matching; naming drift can cause missed auto-completion.
- Overdue-plan rollover is now a separate app service, but it is an in-app reminder/confirmation flow rather than an Android background notification.
- API keys and archived secret files exist under the Planning working directory. Do not print, commit, or copy their contents into reports.
- Older Claude memory files contain useful history but are not all current. Treat this file and the source code as the current entry points.
