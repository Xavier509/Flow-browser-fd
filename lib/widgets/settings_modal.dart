import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../screens/performance_page.dart';

class SettingsModal extends StatefulWidget {
  final VoidCallback onClose;
  final bool isMobile;

  const SettingsModal({
    super.key,
    required this.onClose,
    this.isMobile = false,
  });

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      constraints: BoxConstraints(
        maxWidth: isMobile ? double.infinity : 600,
        maxHeight: isMobile ? 600 : 700,
      ),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isMobile ? 20 : 0),
          topRight: Radius.circular(isMobile ? 20 : 0),
          bottomLeft: const Radius.circular(20),
          bottomRight: const Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.3 * 255).round()),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppConstants.primaryGradient,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isMobile ? 20 : 0),
                topRight: Radius.circular(isMobile ? 20 : 0),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),

          // Settings content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Privacy & Security
                  _buildSectionHeader('Privacy & Security'),
                  _buildSwitchTile(
                    'Block Trackers',
                    'Prevent tracking scripts from monitoring your activity',
                    settingsProvider.blockTrackers,
                    (value) => settingsProvider.toggleBlockTrackers(),
                  ),
                  _buildSwitchTile(
                    'Anti-Fingerprinting',
                    'Prevent websites from creating unique fingerprints',
                    settingsProvider.antiFingerprint,
                    (value) => settingsProvider.toggleAntiFingerprint(),
                  ),
                  _buildSwitchTile(
                    'Auto-Delete Cookies',
                    'Automatically clear cookies on browser close',
                    settingsProvider.autoDeleteCookies,
                    (value) => settingsProvider.toggleAutoDeleteCookies(),
                  ),

                  _buildSwitchTile(
                    'Advanced Ad Blocker',
                    'Aggressively block ads and intrusive trackers (may break some sites). Toggle to enable/disable.',
                    settingsProvider.adBlockerEnabled,
                    (value) => settingsProvider.toggleAdBlocker(),
                  ),

                  const SizedBox(height: 24),

                  // VPN & Proxy
                  _buildSectionHeader('VPN & Proxy'),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Note: Full VPN and proxy implementation requires native platform code (e.g., Android VPNService, iOS NEVPNManager). '
                      'Currently, toggles are for UI state only. Contact developer for native integration.',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                  _buildSwitchTile(
                    'Enable Proxy',
                    'Route traffic through a proxy server',
                    settingsProvider.proxyEnabled,
                    (value) => settingsProvider.toggleProxy(),
                  ),
                  _buildSwitchTile(
                    'Enable VPN',
                    'Connect to VPN for enhanced privacy',
                    settingsProvider.vpnEnabled,
                    (value) => settingsProvider.toggleVPN(),
                  ),

                  if (settingsProvider.vpnEnabled) ...[
                    const SizedBox(height: 16),
                    _buildDropdownTile(
                      'VPN Provider',
                      'Choose your VPN service',
                      settingsProvider.vpnProvider,
                      AppConstants.vpnProviders.map((p) => p.id).toList(),
                      AppConstants.vpnProviders.map((p) => p.name).toList(),
                      (value) => settingsProvider.setVpnProvider(value!),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Search & Navigation
                  _buildSectionHeader('Search & Navigation'),
                  _buildDropdownTile(
                    'Default Search Engine',
                    'Choose your preferred search engine',
                    settingsProvider.searchEngine,
                    AppConstants.searchEngines.keys.toList(),
                    AppConstants.searchEngines.keys.toList(),
                    (value) => settingsProvider.setSearchEngine(value!),
                  ),

                  _buildSwitchTile(
                    'Personalized Search Recommendations',
                    'Use your local history to surface recommended searches (can be toggled for privacy)',
                    settingsProvider.personalizedSearch,
                    (value) => settingsProvider.togglePersonalizedSearch(),
                  ),

                  const SizedBox(height: 12),

                  _buildSectionHeader('Full-Page Translation'),
                  _buildSwitchTile(
                    'Enable Full-Page Translation',
                    'Translate entire pages using Google Translate (opens translated page)',
                    settingsProvider.fullPageTranslation,
                    (value) => settingsProvider.toggleFullPageTranslation(),
                  ),
                  if (settingsProvider.fullPageTranslation) ...[
                    const SizedBox(height: 8),
                    _buildDropdownTile(
                      'Translation Language',
                      'Target language for translations',
                      settingsProvider.translationLanguage,
                      AppConstants.translationLanguages.values.toList(),
                      AppConstants.translationLanguages.keys.toList(),
                      (value) => settingsProvider.setTranslationLanguage(value!),
                    ),
                  ],

                  const SizedBox(height: 12),

                  _buildSwitchTile(
                    'Show Bookmarks on Home Page',
                    'Show your chosen bookmarks on the home/start page for quick access',
                    settingsProvider.showBookmarksOnHome,
                    (value) => settingsProvider.toggleShowBookmarksOnHome(),
                  ),

                  const SizedBox(height: 24),

                  // Appearance
                  _buildSectionHeader('Appearance'),
                  _buildSwitchTile(
                    'Dark Mode',
                    'Use dark theme for better visibility',
                    settingsProvider.isDarkMode,
                    (value) => settingsProvider.toggleDarkMode(),
                  ),

                  const SizedBox(height: 24),
                  _buildSectionHeader('Performance'),
                  _buildSwitchTile(
                    'Enable Performance Monitoring',
                    'Collect and display app/system performance metrics (may use extra resources)',
                    settingsProvider.performanceMonitoring,
                    (value) => settingsProvider.togglePerformanceMonitoring(),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        // Open performance page
                        Navigator.of(context).push(MaterialPageRoute(builder: (c) => PerformancePage()));
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: AppConstants.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Open Performance Page'),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppConstants.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.2),
        ),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withAlpha((0.7 * 255).round()),
            fontSize: 12,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppConstants.primaryColor,
        activeTrackColor: AppConstants.primaryColor.withAlpha((0.3 * 255).round()),
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    String value,
    List<String> values,
    List<String> displayNames,
    Function(String?) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade700.withAlpha((0.5 * 255).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppConstants.surfaceColor,
              style: const TextStyle(color: Colors.white),
              underline: const SizedBox(),
              items: List.generate(
                values.length,
                (index) => DropdownMenuItem(
                  value: values[index],
                  child: Text(displayNames[index]),
                ),
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}