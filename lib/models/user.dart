class UserModel {
  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final String currency;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.currency,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'password_hash': passwordHash,
    'currency': currency,
    'created_at': createdAt.toIso8601String(),
  };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    id: map['id'],
    name: map['name'],
    email: map['email'],
    passwordHash: map['password_hash'],
    currency: map['currency'] ?? 'EUR',
    createdAt: DateTime.parse(map['created_at']),
  );

  UserModel copyWith({String? name, String? currency}) => UserModel(
    id: id,
    name: name ?? this.name,
    email: email,
    passwordHash: passwordHash,
    currency: currency ?? this.currency,
    createdAt: createdAt,
  );
}
