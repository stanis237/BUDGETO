import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';

class AuthProvider extends ChangeNotifier {
  final UserRepository _repo = UserRepository();
  final _storage = const FlutterSecureStorage();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  String get currency => _currentUser?.currency ?? 'EUR';

  Future<void> init() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      _currentUser = await _repo.getCurrentUser();
      notifyListeners();
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    final result = await _repo.register(name, email, password);
    _isLoading = false;
    
    if (result == null) {
      _error = 'Cet email est déjà utilisé ou erreur serveur.';
      notifyListeners();
      return false;
    }
    
    await _saveTokens(result['tokens']);
    _currentUser = result['user'];
    notifyListeners();
    return true;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    final result = await _repo.login(email, password);
    _isLoading = false;
    
    if (result == null) {
      _error = 'Email ou mot de passe incorrect.';
      notifyListeners();
      return false;
    }
    
    await _saveTokens(result['tokens']);
    _currentUser = result['user'];
    notifyListeners();
    return true;
  }

  Future<void> loginAsGuest() async {
    _currentUser = UserModel(
      id: 'guest',
      name: 'Invité',
      email: '',
      passwordHash: '',
      currency: 'EUR',
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateName(String name) async {
    // Left empty or can add an API endpoint for it later
  }

  Future<void> updateCurrency(String currency) async {
    if (_currentUser == null) return;
    await _repo.updateCurrency(currency);
    _currentUser = _currentUser!.copyWith(currency: currency);
    notifyListeners();
  }

  Future<List<UserModel>> getAllUsers() async {
    // Only current user for now in API logic
    if (_currentUser != null) return [_currentUser!];
    return [];
  }

  Future<void> switchUser(UserModel user) async {
    // Not applicable in the same way with JWTs, skipped for now
  }

  Future<void> _saveTokens(Map<String, dynamic> tokens) async {
    await _storage.write(key: 'access_token', value: tokens['access']);
    await _storage.write(key: 'refresh_token', value: tokens['refresh']);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
