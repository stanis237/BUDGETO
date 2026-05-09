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
      id: map['id'],
      userId: map['user_id'],
      month: map['month'],
      year: map['year'],
      needs: (map['needs'] as num).toDouble(),
      expectations: (map['expectations'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at']),
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
