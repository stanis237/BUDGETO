import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../core/database/database_helper.dart';
import '../models/user.dart';

class UserRepository {
  final DatabaseHelper _db = DatabaseHelper();
  final _uuid = const Uuid();

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<UserModel?> register(String name, String email, String password) async {
    final existing = await _db.query('users', where: 'email = ?', whereArgs: [email]);
    if (existing.isNotEmpty) return null;

    final user = UserModel(
      id: _uuid.v4(),
      name: name,
      email: email,
      passwordHash: _hashPassword(password),
      currency: 'EUR',
      createdAt: DateTime.now(),
    );
    await _db.insert('users', user.toMap());
    return user;
  }

  Future<UserModel?> login(String email, String password) async {
    final results = await _db.query(
      'users',
      where: 'email = ? AND password_hash = ?',
      whereArgs: [email, _hashPassword(password)],
    );
    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  Future<UserModel?> getUserById(String id) async {
    final results = await _db.query('users', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  Future<List<UserModel>> getAllUsers() async {
    final results = await _db.query('users', orderBy: 'created_at DESC');
    return results.map((e) => UserModel.fromMap(e)).toList();
  }

  Future<void> updateUser(UserModel user) async {
    await _db.update('users', user.toMap(), 'id = ?', [user.id]);
  }

  Future<void> updateCurrency(String userId, String currency) async {
    await _db.update('users', {'currency': currency}, 'id = ?', [userId]);
  }
}
