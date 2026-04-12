import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  static const String _key = 'pyq_auth_token';
  static const String _keyExpiry = 'pyq_token_expiry';

  /// Save token with expiry information
  Future<void> save(String token, {DateTime? expiresAt}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, token);
      if (expiresAt != null) {
        await prefs.setString(_keyExpiry, expiresAt.toIso8601String());
      }
    } catch (e) {
      throw TokenStorageException('Failed to save token: $e');
    }
  }

  /// Get stored token
  Future<String?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_key);
    } catch (e) {
      throw TokenStorageException('Failed to retrieve token: $e');
    }
  }

  /// Check if token is valid (not expired)
  Future<bool> isValid() async {
    try {
      final token = await read();
      if (token == null) return false;
      final prefs = await SharedPreferences.getInstance();
      final expiryStr = prefs.getString(_keyExpiry);
      if (expiryStr == null) return true;
      final expiry = DateTime.parse(expiryStr);
      return DateTime.now().isBefore(expiry);
    } catch (e) {
      return false;
    }
  }

  /// Delete token
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      await prefs.remove(_keyExpiry);
    } catch (e) {
      throw TokenStorageException('Failed to clear storage: $e');
    }
  }
}

class TokenStorageException implements Exception {
  final String message;
  TokenStorageException(this.message);

  @override
  String toString() => 'TokenStorageException: $message';
}
