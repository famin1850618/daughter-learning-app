/// 奖励条目（V3.7 起持久化每次获得的星星）
class Reward {
  final int? id;
  final String source; // practice / weekly_test / monthly_test / bonus
  final double stars;
  final DateTime earnedAt;
  final String? sessionId;
  final String? note;
  final String userId;

  Reward({
    this.id,
    required this.source,
    required this.stars,
    required this.earnedAt,
    this.sessionId,
    this.note,
    this.userId = 'local',
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'source': source,
        'stars': stars,
        'earned_at': earnedAt.toIso8601String(),
        'session_id': sessionId,
        'note': note,
        'user_id': userId,
      };

  factory Reward.fromMap(Map<String, dynamic> m) => Reward(
        id: m['id'] as int?,
        source: m['source'] as String,
        stars: (m['stars'] as num).toDouble(),
        earnedAt: DateTime.parse(m['earned_at'] as String),
        sessionId: m['session_id'] as String?,
        note: m['note'] as String?,
        userId: (m['user_id'] as String?) ?? 'local',
      );
}

/// 中文显示用
String rewardSourceLabel(String source) {
  switch (source) {
    case 'practice':
      return '平时练习';
    case 'weekly_test':
      return '周测';
    case 'monthly_test':
      return '月测';
    case 'bonus':
      return '满分加成';
    default:
      return source;
  }
}
