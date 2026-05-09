import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:budgeto/repositories/user_repository.dart';
import 'package:budgeto/models/user.dart';
import 'package:budgeto/core/database/database_helper.dart';
import 'dart:io';

void main() {
  late UserRepository userRepository;

  setUpAll(() {
    // Initialize FFI for SQLite tests on desktop/CLI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    userRepository = UserRepository();
    final db = await DatabaseHelper().database;
    await db.execute('DELETE FROM users');
  });

  tearDown(() async {
    final db = await DatabaseHelper().database;
    await db.execute('DELETE FROM users');
  });

  test('L\'inscription (register) enregistre correctement l\'utilisateur dans la base de données', () async {
    final name = 'Test User';
    final email = 'test@example.com';
    final password = 'password123';

    final user = await userRepository.register(name, email, password);

    expect(user, isNotNull);
    expect(user!.name, name);
    expect(user.email, email);
    
    // Verify it actually saved to DB
    final savedUser = await userRepository.getUserById(user.id);
    expect(savedUser, isNotNull);
    expect(savedUser!.email, email);
  });

  test('La connexion (login) récupère correctement l\'utilisateur enregistré', () async {
    final name = 'Test Login';
    final email = 'login@example.com';
    final password = 'password123';

    // Register first
    await userRepository.register(name, email, password);

    // Try to login with correct credentials
    final loggedInUser = await userRepository.login(email, password);
    expect(loggedInUser, isNotNull);
    expect(loggedInUser!.name, name);

    // Try to login with incorrect password
    final failedLoginUser = await userRepository.login(email, 'wrongpassword');
    expect(failedLoginUser, isNull);
    
    // Try to login with non-existent email
    final notFoundUser = await userRepository.login('notfound@example.com', password);
    expect(notFoundUser, isNull);
  });
  
  test('L\'inscription échoue si l\'email existe déjà', () async {
    final name = 'Test Duplicate';
    final email = 'duplicate@example.com';
    final password = 'password123';

    // First registration
    final user1 = await userRepository.register(name, email, password);
    expect(user1, isNotNull);

    // Second registration with same email
    final user2 = await userRepository.register('Other Name', email, 'newpassword');
    expect(user2, isNull); // Should return null because email already exists
  });
}
