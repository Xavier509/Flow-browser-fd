// widgets/bookmarks_panel.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/browser_provider.dart';
import '../utils/constants.dart';

class BookmarksPanel extends StatelessWidget {
  final VoidCallback onClose;
  final bool isMobile;

  const BookmarksPanel({
    super.key,
    required this.onClose,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BrowserProvider>();

    Widget content = Container(
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor.withOpacity(0.95),
        border: Border(
          left: BorderSide(
            color: AppConstants.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bookmarks',
                  style: TextStyle(
                    color: AppConstants.primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppConstants.primaryColor),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.bookmarks.isEmpty
                ? Center(
                    child: Text(
                      'No bookmarks yet',
                      style: TextStyle(
                        color: AppConstants.primaryColor.withOpacity(0.5),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: provider.bookmarks.length,
                    itemBuilder: (context, index) {
                      final bookmark = provider.bookmarks[index];
                      return ListTile(
                        leading: const Icon(
                          Icons.language,
                          color: AppConstants.primaryColor,
                          size: 20,
                        ),
                        title: Text(
                          bookmark.title,
                          style: const TextStyle(
                            color: AppConstants.primaryColor,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          bookmark.url,
                          style: TextStyle(
                            color: AppConstants.primaryColor.withOpacity(0.5),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          color: Colors.red,
                          onPressed: () => provider.removeBookmark(bookmark.id),
                        ),
                        onTap: () {
                          provider.navigateToUrl(bookmark.url);
                          onClose();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );

    if (isMobile) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: content,
      );
    }

    return content;
  }
}

// widgets/settings_modal.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/browser_provider.dart';
import '../utils/constants.dart';

class SettingsModal extends StatelessWidget {
  final VoidCallback onClose;
  final bool isMobile;

  const SettingsModal({
    super.key,
    required this.onClose,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final browserProvider = context.watch<BrowserProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: isMobile
            ? const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              )
            : BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: AppConstants.primaryColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppConstants.primaryColor),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    'Security & Privacy',
                    Icons.lock,
                    [
                      _buildToggle(
                        'Proxy Protection',
                        'Route through proxy',
                        settingsProvider.proxyEnabled,
                        () => settingsProvider.toggleProxy(),
                      ),
                      _buildVpnToggle(context, settingsProvider),
                      _buildToggle(
                        'Anti-Fingerprinting',
                        'Randomize fingerprint',
                        settingsProvider.antiFingerprint,
                        () => settingsProvider.toggleAntiFingerprint(),
                      ),
                      _buildToggle(
                        'Block Trackers',
                        'Block ads & trackers',
                        settingsProvider.blockTrackers,
                        () => settingsProvider.toggleBlockTrackers(),
                      ),
                      _buildDropdown(
                        'Security Level',
                        settingsProvider.securityLevel,
                        ['maximum', 'high', 'medium', 'low'],
                        (value) => settingsProvider.setSecurityLevel(value!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    'Browser Info',
                    Icons.info,
                    [
                      _buildInfoRow('Version', '2.0.0'),
                      _buildInfoRow('Platform', 'Flutter'),
                      _buildInfoRow(
                        'Workspaces',
                        browserProvider.workspaces.length.toString(),
                      ),
                      _buildInfoRow(
                        'Total Tabs',
                        browserProvider.workspaces
                            .fold(0, (sum, w) => sum + w.tabs.length)
                            .toString(),
                      ),
                      _buildInfoRow(
                        'Bookmarks',
                        browserProvider.bookmarks.length.toString(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppConstants.primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: AppConstants.primaryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildToggle(
    String title,
    String subtitle,
    bool value,
    VoidCallback onChanged,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppConstants.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppConstants.primaryColor.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (_) => onChanged(),
            activeColor: value ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildVpnToggle(BuildContext context, SettingsProvider provider) {
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VPN Protection',
                      style: TextStyle(
                        color: AppConstants.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Connect through VPN',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: provider.vpnEnabled,
                onChanged: (_) => provider.toggleVPN(),
                activeColor: Colors.green,
              ),
            ],
          ),
          if (provider.vpnEnabled) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: provider.vpnProvider,
              decoration: InputDecoration(
                labelText: 'VPN Provider',
                labelStyle: const TextStyle(color: AppConstants.primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppConstants.primaryColor.withOpacity(0.3),
                  ),
                ),
              ),
              dropdownColor: AppConstants.surfaceColor,
              style: const TextStyle(color: Colors.white),
              items: AppConstants.vpnProviders.map((provider) {
                return DropdownMenuItem(
                  value: provider.id,
                  child: Text(provider.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) provider.setVpnProvider(value);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
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
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppConstants.primaryColor),
          border: InputBorder.none,
        ),
        dropdownColor: AppConstants.surfaceColor,
        style: const TextStyle(color: Colors.white),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item.toUpperCase()),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppConstants.primaryColor.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppConstants.primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// widgets/workspaces_modal.dart - Similar pattern for workspace management
// widgets/mobile_menu.dart - Drawer menu for mobile
// widgets/ai_assistant_panel.dart - AI features panel

// These follow similar patterns to above components
// See the full implementation in your project
