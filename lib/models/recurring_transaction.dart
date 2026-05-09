class RecurringTransactionModel {
  final String id;
  final String userId;
  final double amount;
  final String type; // 'income' | 'expense'
  final String categoryId;
  final String? description;
  final String period; // 'daily', 'weekly', 'monthly', 'yearly'
  final DateTime startDate;
  final DateTime nextDate;
  final DateTime createdAt;

  // Joined from categories
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;

  RecurringTransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.description,
    required this.period,
    required this.startDate,
    required this.nextDate,
    required this.createdAt,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  factory RecurringTransactionModel.fromMap(Map<String, dynamic> map) =>
      RecurringTransactionModel(
        id: map['id'],
        userId: map['user_id'],
        amount: (map['amount'] as num).toDouble(),
        type: map['type'],
        categoryId: map['category_id'],
        description: map['description'],
        period: map['period'],
        startDate: DateTime.parse(map['start_date']),
        nextDate: DateTime.parse(map['next_date']),
        createdAt: DateTime.parse(map['created_at']),
        categoryName: map['category_name'],
        categoryIcon: map['category_icon'],
        categoryColor: map['category_color'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'amount': amount,
        'type': type,
        'category_id': categoryId,
        'description': description,
        'period': period,
        'start_date': startDate.toIso8601String(),
        'next_date': nextDate.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}
