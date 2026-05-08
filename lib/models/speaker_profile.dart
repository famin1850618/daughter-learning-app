/// V3.12 听力多角色 TTS 元数据
///
/// audio_text 多角色对话（如 "A: Hello\nB: Hi"）按角色名映射到 SpeakerProfile，
/// _ListenButton 解析后串行调用 flutter_tts 并按 gender/age 切换 voice/pitch。
class SpeakerProfile {
  /// 'male' | 'female'
  final String gender;
  /// 'child' | 'teen' | 'adult'
  final String age;

  const SpeakerProfile({required this.gender, required this.age});

  Map<String, dynamic> toMap() => {'gender': gender, 'age': age};

  factory SpeakerProfile.fromMap(Map<String, dynamic> m) => SpeakerProfile(
        gender: (m['gender'] as String?) ?? 'female',
        age: (m['age'] as String?) ?? 'adult',
      );

  /// fallback pitch（在没有匹配 voice 时用）：
  /// male=0.9 / female=1.3，age=child 再 ×1.15。clamp [0.5, 2.0]
  double get fallbackPitch {
    double p = gender == 'male' ? 0.9 : 1.3;
    if (age == 'child') p *= 1.15;
    return p.clamp(0.5, 2.0);
  }

  static const defaultProfile = SpeakerProfile(gender: 'female', age: 'adult');
}
