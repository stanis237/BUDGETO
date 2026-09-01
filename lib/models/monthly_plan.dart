class MonthlyPlan {
  final String id;
  final String userId;
  final int month;
  final int year;
  final double needs;
  final double expectations;
  final DateTime createdAt;

  MonthlyPlan({
    required this.id,
    required this.userId,
    required this.month,
    required this.year,
    required this.needs,
    required this.expectations,
    required this.createdAt,
  });

  factory MonthlyPlan.fromMap(Map<String, dynamic> map) {
    return MonthlyPlan(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? map['user']?.toString() ?? '',
      month: int.tryParse(map['month']?.toString() ?? '1') ?? 1,
      year: int.tryParse(map['year']?.toString() ?? DateTime.now().year.toString()) ?? DateTime.now().year,
      needs: double.tryParse(map['needs']?.toString() ?? '0') ?? 0.0,
      expectations: double.tryParse(map['expectations']?.toString() ?? '0') ?? 0.0,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'month': month,
      'year': year,
      'needs': needs,
      'expectations': expectations,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
