/// 当前应用版本号。
///
/// **同步规则**：每次发版必须同时更新两处：
/// 1. 本文件的 [kAppVersion] / [kAppBuildDate] 常量（app 内显示）
/// 2. `pubspec.yaml` 的 `version:` 字段（影响 packageInfo / Android versionName / APK 文件名）
///
/// 两处不一致时以本文件为准（UI 显示），但发 APK 时 pubspec 也要 bump 否则
/// versionCode 不递增、用户系统升级提示失效。
const String kAppVersion = 'V3.24.8';
const String kAppBuildDate = '2026-05-18';
