import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';

class AuthProvider extends ChangeNotifier {
  final UserRepository _repo = UserRepository();
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  String get currency => _currentUser?.currency ?? 'EUR';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('current_user_id');
    if (userId != null) {
      _currentUser = await _repo.getUserById(userId);
      notifyListeners();
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final user = await _repo.register(name, email, password);
    _isLoading = false;
    if (user == null) {
      _error = 'Cet email est déjà utilisé.';
      notifyListeners();
      return false;
    }
    await _saveSession(user.id);
    _currentUser = user;
    notifyListeners();
    return true;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final user = await _repo.login(email, password);
    _isLoading = false;
    if (user == null) {
      _error = 'Email ou mot de passe incorrect.';
      notifyListeners();
      return false;
    }
    await _saveSession(user.id);
    _currentUser = user;
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateName(String name) async {
    if (_currentUser == null) return;
    final updated = _currentUser!.copyWith(name: name);
    await _repo.updateUser(updated);
    _currentUser = updated;
    notifyListeners();
  }

  Future<void> updateCurrency(String currency) async {
    if (_currentUser == null) return;
    await _repo.updateCurrency(_currentUser!.id, currency);
    _currentUser = _currentUser!.copyWith(currency: currency);
    notifyListeners();
  }

  Future<List<UserModel>> getAllUsers() => _repo.getAllUsers();

  Future<void> switchUser(UserModel user) async {
    await _saveSession(user.id);
    _currentUser = user;
    notifyListeners();
  }

  Future<void> _saveSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', userId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
