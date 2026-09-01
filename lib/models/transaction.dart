class TransactionModel {
  final String id;
  final String userId;
  final double amount;
  final String type; // 'income' | 'expense'
  final String categoryId;
  final String accountId;
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
    required this.accountId,
    this.description,
    required this.date,
    required this.createdAt,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) => TransactionModel(
    id: map['id']?.toString() ?? '',
    userId: map['user_id']?.toString() ?? map['user']?.toString() ?? '',
    amount: double.tryParse(map['amount']?.toString() ?? '0') ?? 0.0,
    type: map['type']?.toString() ?? 'expense',
    categoryId: map['category_id']?.toString() ?? map['category']?.toString() ?? '',
    accountId: map['account_id']?.toString() ?? map['account']?.toString() ?? 'default_account',
    description: map['description']?.toString(),
    date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
    createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
    categoryName: map['category_name']?.toString(),
    categoryIcon: map['category_icon']?.toString(),
    categoryColor: map['category_color']?.toString(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'amount': amount,
    'type': type,
    'category_id': categoryId,
    'account_id': accountId,
    'description': description,
    'date': date.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };
}
