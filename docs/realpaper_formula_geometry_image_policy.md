# Realpaper Formula And Geometry Image Policy

Last updated: 2026-07-22

This policy records the agreed handling rules for importing math real-paper questions whose source docx stores formulas and diagrams as embedded images.

## Core Rules

- Formulas should be recognized and rewritten as TeX in `content`, `options`, `answer`, and `explanation`.
- Geometry, graph, table, floor-plan, and other visual diagrams should use the original image extracted from the docx package.
- Do not redraw geometry diagrams by hand for import. Redrawing is allowed only as a separate, explicitly reviewed repair when the original embedded image is unusable.
- Do not use PDF page screenshots for docx-origin questions when the docx embedded image is available.
- Do not infer missing formulas or diagram data from the answer. If the source image/text cannot support reconstruction, keep the question skipped.

## Source Priority

1. Use `word/media/*` from the docx package, as extracted under `.cache/docx/<sha1>/media/`.
2. For original PNG/JPEG images, preserve the extracted raster image as a `data:image/...;base64,...` URL.
3. For WMF/EMF diagrams, convert the embedded vector file to PNG with the extraction tool, then use that PNG. Record the original source name in `_image_source`.
4. Use PDF screenshots only when no docx-origin image exists and the source file is PDF-only.

## Formula Handling

- Inline formula images need an image marker sequence before OCR, for example: `已知[IMG:image12]，求[IMG:image13]`.
- OCR output must be normalized to TeX, for example `$2.8\\times 10^4$`, `$m-n=4c$`, or `$h=80+3x$`.
- Choice options that are formula images must become normal text options with prefixes such as `A. $...$`.
- Fill answers should avoid symbols the app input method cannot reasonably enter. If needed, convert the question to `choice` or `subjective`.
- Any formula recovered from OCR must be traceable to the source image and not contradicted by the raw answer/explanation.

## Geometry And Diagram Handling

- Put the question diagram in `image_data` and set `_image_verified=true` only after visually checking that the image matches the question.
- Record provenance with `_image_source`, for example `docx:word/media/image82.png -> .cache/docx/<sha1>/media/image82.png`.
- If a diagram is in the answer section rather than the question stem, do not place it in `image_data` unless the student needs it to answer.
- Pure construction/drawing questions should be imported as `subjective` only when the app workflow can accept a drawn answer or parent/AI review. Otherwise keep them skipped with reason `drawing_construction_only`.
- Pure image options should use `option_images` with text options `A.`, `B.`, etc. after visual verification of each option.

## Validation Requirements

- Every imported image question must pass `tools/realpaper/validate.py <batch> --full`.
- `--image-content-match` should not report the new question; this requires `_image_verified=true`.
- `question_bank/<source>.json` and `assets/data/batches/<source>.json` must be byte-identical.
- `question_bank/index.json` must update the source entry count and `batch_hash`.
- `STATUS.md` should record the batch result and any known residual risk.

## Current Trial Results

- `realpaper_g7_math_beishida_qz_yantian_001` question 12: imported on 2026-07-21 using docx embedded `image82.png` as the geometry diagram. The explanation uses TeX for `$m-n=4c$`. Validation passed.
- `realpaper_g7_math_beishida_qz_yantian_001` question 16: imported on 2026-07-22 as a pure drawing `subjective` question. The stem uses docx embedded `image124.png`; the reference answer is described from docx answer image `image126.png`. Validation passed.
- `realpaper_g7_math_beishida_qz_yantian_001` question 18: imported on 2026-07-22 using docx embedded `image136.png` as the floor-plan diagram. Only subquestion 18(1) is imported because subquestion 18(2) has missing known conditions and numeric answer in the text layer. Validation passed.
