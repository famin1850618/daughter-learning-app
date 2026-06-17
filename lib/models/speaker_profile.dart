/// V3.12 听力多角色 TTS 元数据
///
/// audio_text 多角色对话（如 "A: Hello\nB: Hi"）按角色名映射到 SpeakerProfile，
/// _ListenButton 解析后串行调用 flutter_tts 并按 gender/age 切换 voice/pitch。
class SpeakerProfile {
  /// 'male' | 'female'
  final String gender;
  /// 'child' | 'teen' | 'adult'
  final String age;

  /// V3.27: 命题/渲染时按场景定住的具名 en-GB 音色（如 'en-GB-SoniaNeural'）。
  /// 仅服务端预渲染用；客户端播放走预渲染 mp3（audio_hash），不读此字段。
  final String? voice;

  const SpeakerProfile({required this.gender, required this.age, this.voice});

  Map<String, dynamic> toMap() =>
      {'gender': gender, 'age': age, if (voice != null) 'voice': voice};

  factory SpeakerProfile.fromMap(Map<String, dynamic> m) => SpeakerProfile(
        gender: (m['gender'] as String?) ?? 'female',
        age: (m['age'] as String?) ?? 'adult',
        voice: m['voice'] as String?,
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
