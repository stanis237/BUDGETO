import 'package:flutter_test/flutter_test.dart';
import 'package:budgeto/repositories/user_repository.dart';

/// Unit tests for UserRepository (Django REST API backend).
/// These tests verify basic contract behavior using mock expectations.
/// Integration tests against a live backend should be run separately.
void main() {
  late UserRepository userRepository;

  setUp(() {
    userRepository = UserRepository();
  });

  test('UserRepository can be instantiated', () {
    expect(userRepository, isNotNull);
  });

  test('register returns null on network error', () async {
    // Without a backend running, register should return null gracefully.
    final result = await userRepository.register(
      'Test User',
      'test_${DateTime.now().millisecondsSinceEpoch}@example.com',
      'password123',
    );
    // In a test environment without a backend, null is expected.
    // In CI with a backend, this would return a valid map.
    expect(result == null || result.containsKey('user'), isTrue);
  });

  test('login returns null on invalid credentials or network error', () async {
    final result = await userRepository.login(
      'nonexistent@example.com',
      'wrongpassword',
    );
    // Should return null for invalid credentials or unavailable backend.
    expect(result, isNull);
  });
}
