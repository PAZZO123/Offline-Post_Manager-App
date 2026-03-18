// lib/services/auth_service.dart

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _keyUserId   = 'session_user_id';
  static const String _keyUsername = 'session_username';

  final DatabaseHelper _db = DatabaseHelper();

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _hash(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }

  // ─── Register ─────────────────────────────────────────────────────────────

  /// Returns null on success, error message string on failure.
  Future<String?> register(String username, String password) async {
    if (username.trim().length < 3) return 'Username must be at least 3 characters';
    if (password.length < 6)        return 'Password must be at least 6 characters';

    try {
      final user = User(
        username:     username.trim(),
        passwordHash: _hash(password),
        createdAt:    _today(),
      );
      await _db.insertUser(user);
      return null; // success
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  // ─── Login ────────────────────────────────────────────────────────────────

  /// Returns null on success, error message string on failure.
  Future<String?> login(String username, String password) async {
    if (username.trim().isEmpty) return 'Please enter your username';
    if (password.isEmpty)        return 'Please enter your password';

    try {
      final user = await _db.getUserByUsername(username.trim());
      if (user == null)                   return 'User not found';
      if (user.passwordHash != _hash(password)) return 'Incorrect password';

      // Save session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt   (_keyUserId,   user.id!);
      await prefs.setString(_keyUsername, user.username);
      return null; // success
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  // ─── Session ──────────────────────────────────────────────────────────────

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyUserId);
  }

  Future<String?> getLoggedInUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUsername);
  }
}
