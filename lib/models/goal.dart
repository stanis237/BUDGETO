class GoalModel {
  final String id;
  final String userId;
  final String title;
  final double targetAmount;
  double currentAmount;
  final DateTime? deadline;
  final String? imageKey;
  final DateTime createdAt;

  GoalModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    this.imageKey,
    required this.createdAt,
  });

  factory GoalModel.fromMap(Map<String, dynamic> map) => GoalModel(
    id: map['id']?.toString() ?? '',
    userId: map['user_id']?.toString() ?? map['user']?.toString() ?? '',
    title: map['title']?.toString() ?? '',
    targetAmount: double.tryParse(map['target_amount']?.toString() ?? '0') ?? 0.0,
    currentAmount: double.tryParse(map['current_amount']?.toString() ?? '0') ?? 0.0,
    deadline: map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
    imageKey: map['image_key']?.toString(),
    createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'target_amount': targetAmount,
    'current_amount': currentAmount,
    'deadline': deadline?.toIso8601String(),
    'image_key': imageKey,
    'created_at': createdAt.toIso8601String(),
  };

  double get percentage => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0;
  double get remaining => (targetAmount - currentAmount).clamp(0, double.infinity);
  bool get isCompleted => currentAmount >= targetAmount;
}
