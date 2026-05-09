class BudgetModel {
  final String id;
  final String userId;
  final String categoryId;
  final double amount;
  final int month;
  final int year;
  // Joined
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  double spent;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.month,
    required this.year,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.spent = 0,
  });

  factory BudgetModel.fromMap(Map<String, dynamic> map) => BudgetModel(
    id: map['id'],
    userId: map['user_id'],
    categoryId: map['category_id'],
    amount: (map['amount'] as num).toDouble(),
    month: map['month'],
    year: map['year'],
    categoryName: map['category_name'],
    categoryIcon: map['category_icon'],
    categoryColor: map['category_color'],
    spent: (map['spent'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'category_id': categoryId,
    'amount': amount,
    'month': month,
    'year': year,
  };

  double get percentage => amount > 0 ? (spent / amount).clamp(0.0, 1.0) : 0;
  double get remaining => (amount - spent).clamp(0, double.infinity);
}
