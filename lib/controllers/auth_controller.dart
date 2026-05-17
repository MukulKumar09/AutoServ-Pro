// lib/controllers/auth_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class AuthController extends ChangeNotifier {
  final FirebaseService _service;
  StreamSubscription<User?>? _authSub;
  bool _disposed = false;

  AuthController(this._service) { _init(); }

  UserModel? _currentUser;
  bool _isLoading   = false;
  String? _error;
  bool _initialized = false;

  UserModel? get currentUser  => _currentUser;
  bool get isLoading          => _isLoading;
  String? get errorMessage    => _error;
  bool get isLoggedIn         => _currentUser != null;
  bool get initialized        => _initialized;
  bool get isAdmin            => _currentUser?.role == UserRole.admin;
  bool get isAdvisor          => _currentUser?.role == UserRole.serviceAdvisor;
  bool get isAccountant       => _currentUser?.role == UserRole.accountant;

  void _init() {
    _authSub = _service.authStateChanges.listen((User? user) async {
      if (user != null) {
        try {
          _currentUser = await _service.getUserProfile(user.uid);
        } catch (_) {
          _currentUser = null;
        }
      } else {
        _currentUser = null;
      }
      _initialized = true;
      _notify();
    });
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    _notify();
    try {
      final cred = await _service.signIn(email.trim(), password);
      _currentUser = await _service.getUserProfile(cred.user!.uid);
      // Block if account inactive
      if (_currentUser != null && !_currentUser!.isActive) {
        await _service.signOut();
        _currentUser = null;
        _error = 'Your account has been deactivated. Contact admin.';
        _isLoading = false;
        _notify();
        return false;
      }
      _isLoading = false;
      _notify();
      return _currentUser != null;
    } on FirebaseAuthException catch (e) {
      _error = _mapError(e.code);
      _isLoading = false;
      _notify();
      return false;
    } catch (e) {
      _error = 'Unexpected error. Please try again.';
      _isLoading = false;
      _notify();
      return false;
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    _currentUser = null;
    _notify();
  }

  void clearError() { _error = null; _notify(); }

  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'Account disabled. Contact admin.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Login failed. Check credentials.';
    }
  }

  void _notify() { if (!_disposed) notifyListeners(); }

  @override
  void dispose() {
    _disposed = true;
    _authSub?.cancel();
    super.dispose();
  }
}
