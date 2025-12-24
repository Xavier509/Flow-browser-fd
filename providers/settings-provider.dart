import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class SettingsProvider with ChangeNotifier {
  final Box _settingsBox = Hive.box('settings');
  
  bool _proxyEnabled = false;
  bool _vpnEnabled = false;
  String _vpnProvider = 'mullvad';
  bool _antiFingerprint = true;
  bool _blockTrackers = true;
  bool _autoDeleteCookies = true;
  String _securityLevel = 'maximum';
  String _searchEngine = 'Google';
  
  SettingsProvider() {
    _loadSettings();
  }
  
  // Getters
  bool get proxyEnabled => _proxyEnabled;
  bool get vpnEnabled => _vpnEnabled;
  String get vpnProvider => _vpnProvider;
  bool get antiFingerprint => _antiFingerprint;
  bool get blockTrackers => _blockTrackers;
  bool get autoDeleteCookies => _autoDeleteCookies;
  String get securityLevel => _securityLevel;
  String get searchEngine => _searchEngine;
  
  void _loadSettings() {
    _proxyEnabled = _settingsBox.get('proxyEnabled', defaultValue: false);
    _vpnEnabled = _settingsBox.get('vpnEnabled', defaultValue: false);
    _vpnProvider = _settingsBox.get('vpnProvider', defaultValue: 'mullvad');
    _antiFingerprint = _settingsBox.get('antiFingerprint', defaultValue: true);
    _blockTrackers = _settingsBox.get('blockTrackers', defaultValue: true);
    _autoDeleteCookies = _settingsBox.get('autoDeleteCookies', defaultValue: true);
    _securityLevel = _settingsBox.get('securityLevel', defaultValue: 'maximum');
    _searchEngine = _settingsBox.get('searchEngine', defaultValue: 'Google');
    notifyListeners();
  }
  
  void toggleProxy() {
    _proxyEnabled = !_proxyEnabled;
    _settingsBox.put('proxyEnabled', _proxyEnabled);
    notifyListeners();
  }
  
  void toggleVPN() {
    _vpnEnabled = !_vpnEnabled;
    _settingsBox.put('vpnEnabled', _vpnEnabled);
    notifyListeners();
  }
  
  void setVpnProvider(String provider) {
    _vpnProvider = provider;
    _settingsBox.put('vpnProvider', provider);
    notifyListeners();
  }
  
  void toggleAntiFingerprint() {
    _antiFingerprint = !_antiFingerprint;
    _settingsBox.put('antiFingerprint', _antiFingerprint);
    notifyListeners();
  }
  
  void toggleBlockTrackers() {
    _blockTrackers = !_blockTrackers;
    _settingsBox.put('blockTrackers', _blockTrackers);
    notifyListeners();
  }
  
  void toggleAutoDeleteCookies() {
    _autoDeleteCookies = !_autoDeleteCookies;
    _settingsBox.put('autoDeleteCookies', _autoDeleteCookies);
    notifyListeners();
  }
  
  void setSecurityLevel(String level) {
    _securityLevel = level;
    _settingsBox.put('securityLevel', level);
    notifyListeners();
  }
  
  void setSearchEngine(String engine) {
    _searchEngine = engine;
    _settingsBox.put('searchEngine', engine);
    notifyListeners();
  }
}

// providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  User? _user;
  bool _isLoading = false;
  String? _error;
  
  AuthProvider() {
    _checkUser();
  }
  
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  
  Future<void> _checkUser() async {
    _user = _supabase.auth.currentUser;
    notifyListeners();
  }
  
  Future<void> signUp(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      _user = response.user;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      _user = response.user;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
