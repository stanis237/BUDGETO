class TransactionModel {
  final String id;
  final String userId;
  final double amount;
  final String type; // 'income' | 'expense'
  final String categoryId;
  final String? description;
  final DateTime date;
  final DateTime createdAt;
  // Joined
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.description,
    required this.date,
    required this.createdAt,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) => TransactionModel(
    id: map['id'],
    userId: map['user_id'],
    amount: (map['amount'] as num).toDouble(),
    type: map['type'],
    categoryId: map['category_id'],
    description: map['description'],
    date: DateTime.parse(map['date']),
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
    'date': date.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };
}
