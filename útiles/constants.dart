import 'package:flutter/material.dart';

class AppConstants {
  // Supabase Configuration
  static const String supabaseUrl = 'https://ttkttetepaqvexmhymvq.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR0a3R0ZXRlcGFxdmV4bWh5bXZxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY0MzM4MTAsImV4cCI6MjA4MjAwOTgxMH0.7e1ZT-VOLm3P_V1ndcGSnP4oUtLkCwUwVQGuVkWuMdY';
  
  // Colors
  static const Color primaryColor = Color(0xFF22d3ee);
  static const Color secondaryColor = Color(0xFF3b82f6);
  static const Color tertiaryColor = Color(0xFFa855f7);
  static const Color backgroundColor = Color(0xFF0f172a);
  static const Color surfaceColor = Color(0xFF1e293b);
  static const Color darkBackground = Color(0xFF020617);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, secondaryColor],
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [backgroundColor, Color(0xFF1e1b4b)],
  );
  
  // VPN Providers
  static const List<VpnProvider> vpnProviders = [
    VpnProvider(id: 'mullvad', name: 'Mullvad VPN', type: 'wireguard'),
    VpnProvider(id: 'proton', name: 'ProtonVPN', type: 'wireguard'),
    VpnProvider(id: 'nordvpn', name: 'NordVPN', type: 'wireguard'),
    VpnProvider(id: 'expressvpn', name: 'ExpressVPN', type: 'https'),
    VpnProvider(id: 'custom', name: 'Custom VPN', type: 'custom'),
  ];
  
  // Search Engines
  static const Map<String, String> searchEngines = {
    'Google': 'https://www.google.com/search?q=',
    'DuckDuckGo': 'https://duckduckgo.com/?q=',
    'Bing': 'https://www.bing.com/search?q=',
    'Brave': 'https://search.brave.com/search?q=',
  };
  
  // Default Search Engine
  static const String defaultSearchEngine = 'Google';
  
  // Tracker Blocklist
  static const List<String> trackerBlocklist = [
    'doubleclick.net',
    'googlesyndication.com',
    'google-analytics.com',
    'facebook.com/tr',
    'connect.facebook.net',
    'twitter.com/i/adsct',
    'ads.',
    'ad.',
    'analytics.',
    'tracking.',
    'tracker.',
  ];
}

class VpnProvider {
  final String id;
  final String name;
  final String type;
  
  const VpnProvider({
    required this.id,
    required this.name,
    required this.type,
  });
}

class WorkspacePreset {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String description;
  
  const WorkspacePreset({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });
  
  static const List<WorkspacePreset> presets = [
    WorkspacePreset(
      id: 'work',
      name: 'Work',
      icon: Icons.work_outline,
      color: AppConstants.secondaryColor,
      description: 'Professional browsing',
    ),
    WorkspacePreset(
      id: 'personal',
      name: 'Personal',
      icon: Icons.person_outline,
      color: AppConstants.tertiaryColor,
      description: 'Personal activities',
    ),
    WorkspacePreset(
      id: 'research',
      name: 'Research',
      icon: Icons.school_outlined,
      color: Colors.green,
      description: 'Deep research mode',
    ),
    WorkspacePreset(
      id: 'shopping',
      name: 'Shopping',
      icon: Icons.shopping_bag_outlined,
      color: Colors.pink,
      description: 'Online shopping',
    ),
    WorkspacePreset(
      id: 'entertainment',
      name: 'Entertainment',
      icon: Icons.videogame_asset_outlined,
      color: Colors.orange,
      description: 'Gaming & videos',
    ),
    WorkspacePreset(
      id: 'social',
      name: 'Social',
      icon: Icons.people_outline,
      color: AppConstants.primaryColor,
      description: 'Social media',
    ),
  ];
}
