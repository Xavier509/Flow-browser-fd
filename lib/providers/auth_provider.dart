import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isEmailVerified => _user?.emailConfirmedAt != null;

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _user = response.user;
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: null, // Handle verification in app
      );
      _user = response.user;
      // Check if email confirmation is required
      if (_user != null && _user!.emailConfirmedAt == null) {
        // Email verification required
        // The user will need to verify their email before they can sign in
      }
    } catch (e) {
      // Handle error
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> resendVerificationEmail() async {
    if (_user?.email != null) {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: _user!.email!,
      );
    }
  }

  void initialize() {
    _user = Supabase.instance.client.auth.currentUser;
    notifyListeners();
  }
}