import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/browser_provider.dart';
import '../models/workspace.dart';
import '../utils/constants.dart';

class WorkspacesModal extends StatefulWidget {
  final VoidCallback onClose;
  final bool isMobile;

  const WorkspacesModal({
    super.key,
    required this.onClose,
    this.isMobile = false,
  });

  @override
  State<WorkspacesModal> createState() => _WorkspacesModalState();
}

class _WorkspacesModalState extends State<WorkspacesModal> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedIcon = 'work';
  int _selectedColor = 0xFF22d3ee;

  final List<String> _icons = [
    'work', 'person', 'research', 'shopping', 'entertainment', 'social'
  ];

  final List<int> _colors = [
    0xFF22d3ee, // cyan
    0xFF3b82f6, // blue
    0xFFa855f7, // purple
    0xFFec4899, // pink
    0xFF10b981, // green
    0xFFf59e0b, // amber
    0xFFef4444, // red
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _createWorkspace() {
    if (_nameController.text.isEmpty) return;

    final browserProvider = context.read<BrowserProvider>();
    browserProvider.createWorkspace(
      _nameController.text,
      _selectedIcon,
      _selectedColor,
    );

    _nameController.clear();
    setState(() {
      _selectedIcon = 'work';
      _selectedColor = 0xFF22d3ee;
    });
  }

  void _switchWorkspace(int index) {
    final browserProvider = context.read<BrowserProvider>();
    browserProvider.switchWorkspace(index);
    widget.onClose();
  }

  void _deleteWorkspace(int index) {
    final browserProvider = context.read<BrowserProvider>();
    if (browserProvider.workspaces.length > 1) {
      browserProvider.deleteWorkspace(index);
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'work':
        return Icons.work_outline;
      case 'person':
        return Icons.person_outline;
      case 'research':
        return Icons.school_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'entertainment':
        return Icons.videogame_asset_outlined;
      case 'social':
        return Icons.people_outline;
      default:
        return Icons.folder_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final browserProvider = context.watch<BrowserProvider>();
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      constraints: BoxConstraints(
        maxWidth: isMobile ? double.infinity : 700,
        maxHeight: isMobile ? 600 : 500,
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
                  Icons.workspaces,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Workspaces',
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

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Existing workspaces
                  const Text(
                    'Your Workspaces',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ...List.generate(
                    browserProvider.workspaces.length,
                    (index) {
                      final workspace = browserProvider.workspaces[index];
                      final isActive = index == browserProvider.activeWorkspaceIndex;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Color(workspace.color).withAlpha((0.2 * 255).round())
                              : Colors.grey.shade800.withAlpha((0.3 * 255).round()),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive
                                ? Color(workspace.color)
                                : AppConstants.primaryColor.withAlpha((0.2 * 255).round()),
                            width: isActive ? 2 : 1,
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(workspace.color).withAlpha((0.2 * 255).round()),
                            child: Icon(
                              _getIconData(workspace.icon),
                              color: Color(workspace.color),
                            ),
                          ),
                          title: Text(
                            workspace.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            '${workspace.tabs.length} tab${workspace.tabs.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.white.withAlpha((0.7 * 255).round()),
                            ),
                          ),
                          trailing: browserProvider.workspaces.length > 1
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteWorkspace(index),
                                )
                              : null,
                          onTap: () => _switchWorkspace(index),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Create new workspace
                  const Text(
                    'Create New Workspace',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name input
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Workspace Name',
                      labelStyle: TextStyle(color: AppConstants.primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppConstants.primaryColor.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppConstants.primaryColor.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppConstants.primaryColor),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade800.withAlpha((0.3 * 255).round()),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Icon selection
                  const Text(
                    'Choose Icon',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _icons.map((icon) {
                      final isSelected = icon == _selectedIcon;
                      return InkWell(
                        onTap: () => setState(() => _selectedIcon = icon),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppConstants.primaryColor.withAlpha((0.2 * 255).round())
                                : Colors.grey.shade800.withAlpha((0.3 * 255).round()),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppConstants.primaryColor
                                  : Colors.transparent,
                            ),
                          ),
                          child: Icon(
                            _getIconData(icon),
                            color: isSelected ? AppConstants.primaryColor : Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Color selection
                  const Text(
                    'Choose Color',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _colors.map((color) {
                      final isSelected = color == _selectedColor;
                      return InkWell(
                        onTap: () => setState(() => _selectedColor = color),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(color),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Color(color).withAlpha((0.5 * 255).round()),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Create button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nameController.text.isEmpty ? null : _createWorkspace,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Create Workspace',
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
}
