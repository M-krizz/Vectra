/// Incentive model
class Incentive {
  final String id;
  final String title;
  final String description;
  final double rewardAmount;
  final int currentProgress;
  final int targetProgress;
  final DateTime? expiresAt;
  final bool isCompleted;

  Incentive({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardAmount,
    required this.currentProgress,
    required this.targetProgress,
    this.expiresAt,
    required this.isCompleted,
  });

  double get progressPercentage => (currentProgress / targetProgress).clamp(0.0, 1.0);

  factory Incentive.fromJson(Map<String, dynamic> json) {
    return Incentive(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      rewardAmount: (json['rewardAmount'] as num).toDouble(),
      currentProgress: json['currentProgress'] as int,
      targetProgress: json['targetProgress'] as int,
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String) : null,
      isCompleted: json['isCompleted'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'rewardAmount': rewardAmount,
      'currentProgress': currentProgress,
      'targetProgress': targetProgress,
      'expiresAt': expiresAt?.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }
}
