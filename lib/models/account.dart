class AccountModel {
  final String id;
  final String userId;
  final String name;
  final String type; // 'cash' | 'bank' | 'mobile_money' | 'card'
  final double balance;
  final String? icon;
  final String color;
  final DateTime createdAt;

  AccountModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.balance,
    this.icon,
    required this.color,
    required this.createdAt,
  });

  factory AccountModel.fromMap(Map<String, dynamic> map) => AccountModel(
        id: map['id']?.toString() ?? '',
        userId: map['user_id']?.toString() ?? map['user']?.toString() ?? '',
        name: map['name']?.toString() ?? 'Compte',
        type: map['type']?.toString() ?? 'cash',
        balance: double.tryParse(map['balance']?.toString() ?? '0') ?? 0.0,
        icon: map['icon']?.toString(),
        color: map['color']?.toString() ?? '0xFF2563EB',
        createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'type': type,
        'balance': balance,
        'icon': icon,
        'color': color,
        'created_at': createdAt.toIso8601String(),
      };
}
