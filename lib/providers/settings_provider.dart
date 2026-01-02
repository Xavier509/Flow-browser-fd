import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:flutter/services.dart';

class SettingsProvider with ChangeNotifier {
  final Box _settingsBox = Hive.box('settings');
  static const MethodChannel _platform = MethodChannel('com.flow.browser/vpn_proxy');
  
  bool _proxyEnabled = false;
  bool _vpnEnabled = false;
  String _vpnProvider = 'mullvad';
  bool _antiFingerprint = true;
  bool _blockTrackers = true;
  bool _autoDeleteCookies = true;
  String _securityLevel = 'maximum';
  String _searchEngine = 'Google';
  bool _isDarkMode = false;

  // New features
  bool _personalizedSearch = true; // personalized recommendations
  bool _fullPageTranslation = true;
  String _translationLanguage = 'en';
  bool _adBlockerEnabled = true;
  bool _performanceMonitoring = false;
  bool _showBookmarksOnHome = true;
  
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
  bool get isDarkMode => _isDarkMode;

  // New getters
  bool get personalizedSearch => _personalizedSearch;
  bool get fullPageTranslation => _fullPageTranslation;
  String get translationLanguage => _translationLanguage;
  bool get adBlockerEnabled => _adBlockerEnabled;
  bool get performanceMonitoring => _performanceMonitoring;
  bool get showBookmarksOnHome => _showBookmarksOnHome;
  
  void _loadSettings() {
    _proxyEnabled = _settingsBox.get('proxyEnabled', defaultValue: false);
    _vpnEnabled = _settingsBox.get('vpnEnabled', defaultValue: false);
    _vpnProvider = _settingsBox.get('vpnProvider', defaultValue: 'mullvad');
    _antiFingerprint = _settingsBox.get('antiFingerprint', defaultValue: true);
    _blockTrackers = _settingsBox.get('blockTrackers', defaultValue: true);
    _autoDeleteCookies = _settingsBox.get('autoDeleteCookies', defaultValue: true);
    _securityLevel = _settingsBox.get('securityLevel', defaultValue: 'maximum');
    _searchEngine = _settingsBox.get('searchEngine', defaultValue: 'Google');
    _isDarkMode = _settingsBox.get('isDarkMode', defaultValue: false);

    // Load new settings
    _personalizedSearch = _settingsBox.get('personalizedSearch', defaultValue: true);
    _fullPageTranslation = _settingsBox.get('fullPageTranslation', defaultValue: true);
    _translationLanguage = _settingsBox.get('translationLanguage', defaultValue: 'en');
    _adBlockerEnabled = _settingsBox.get('adBlockerEnabled', defaultValue: true);
    _performanceMonitoring = _settingsBox.get('performanceMonitoring', defaultValue: false);
    _showBookmarksOnHome = _settingsBox.get('showBookmarksOnHome', defaultValue: true);

    notifyListeners();
  }
  
  void toggleProxy() async {
    _proxyEnabled = !_proxyEnabled;
    _settingsBox.put('proxyEnabled', _proxyEnabled);
    try {
      await _platform.invokeMethod('toggleProxy', {'enabled': _proxyEnabled});
    } catch (e) {
      // Handle error
    }
    notifyListeners();
  }
  
  void toggleVPN() async {
    _vpnEnabled = !_vpnEnabled;
    _settingsBox.put('vpnEnabled', _vpnEnabled);
    try {
      await _platform.invokeMethod('toggleVPN', {'enabled': _vpnEnabled, 'provider': _vpnProvider});
    } catch (e) {
      // Handle error
    }
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

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _settingsBox.put('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  // New setters/toggles
  void togglePersonalizedSearch() {
    _personalizedSearch = !_personalizedSearch;
    _settingsBox.put('personalizedSearch', _personalizedSearch);
    notifyListeners();
  }

  void toggleFullPageTranslation() {
    _fullPageTranslation = !_fullPageTranslation;
    _settingsBox.put('fullPageTranslation', _fullPageTranslation);
    notifyListeners();
  }

  void setTranslationLanguage(String lang) {
    _translationLanguage = lang;
    _settingsBox.put('translationLanguage', lang);
    notifyListeners();
  }

  void toggleAdBlocker() {
    _adBlockerEnabled = !_adBlockerEnabled;
    _settingsBox.put('adBlockerEnabled', _adBlockerEnabled);
    notifyListeners();
  }

  void togglePerformanceMonitoring() {
    _performanceMonitoring = !_performanceMonitoring;
    _settingsBox.put('performanceMonitoring', _performanceMonitoring);
    notifyListeners();
  }

  void toggleShowBookmarksOnHome() {
    _showBookmarksOnHome = !_showBookmarksOnHome;
    _settingsBox.put('showBookmarksOnHome', _showBookmarksOnHome);
    notifyListeners();
  }
}
