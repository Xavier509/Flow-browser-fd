import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../providers/browser_provider.dart';
import '../models/workspace.dart';
import '../models/tab_group.dart';
import 'source_viewer_dialog.dart';

class BrowserTabs extends StatefulWidget {
  final WebViewController? webViewController;

  const BrowserTabs({super.key, this.webViewController});

  @override
  State<BrowserTabs> createState() => _BrowserTabsState();
}

class _BrowserTabsState extends State<BrowserTabs> {
  int? _draggedTabIndex;
  String? _draggedFromGroupId;
  Offset? _dragStartPosition;
  bool _isDraggingToNewWindow = false;
  int? _hoveredIndex;
  bool _showInsertionIndicator = false;
  double _insertionOffset = 0.0;

  void _showTabContextMenu(BuildContext context, Offset position, int tabIndex, BrowserProvider provider) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect rect = RelativeRect.fromRect(
      position & const Size(40, 40),
      Offset.zero & overlay.size,
    );

    List<PopupMenuEntry<String>> items = [
      PopupMenuItem(
        value: 'group',
        child: const Row(
          children: [
            Icon(Icons.group_add, size: 18),
            SizedBox(width: 8),
            Text('Create Tab Group'),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'new_window',
        child: const Row(
          children: [
            Icon(Icons.open_in_new, size: 18),
            SizedBox(width: 8),
            Text('Move to New Window'),
          ],
        ),
      ),
    ];

    // Add groups if they exist
    if (provider.currentWorkspace.tabGroups.isNotEmpty) {
      items.add(const PopupMenuDivider());
      items.addAll(provider.currentWorkspace.tabGroups.map((group) => PopupMenuItem<String>(
        value: 'add_to_group_${group.id}',
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Color(group.color),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text('Add to ${group.name}'),
          ],
        ),
      )).toList());
      items.add(const PopupMenuDivider());
    }

    // Add other options
    items.addAll([
      PopupMenuItem(
        value: 'duplicate',
        child: const Row(
          children: [
            Icon(Icons.content_copy, size: 18),
            SizedBox(width: 8),
            Text('Duplicate Tab'),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'close_right',
        child: const Row(
          children: [
            Icon(Icons.close, size: 18),
            SizedBox(width: 8),
            Text('Close Tabs to Right'),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'close_left',
        child: const Row(
          children: [
            Icon(Icons.close, size: 18),
            SizedBox(width: 8),
            Text('Close Tabs to Left'),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'close_others',
        child: const Row(
          children: [
            Icon(Icons.close, size: 18),
            SizedBox(width: 8),
            Text('Close Other Tabs'),
          ],
        ),
      ),
    ]);

    showMenu(
      context: context,
      position: rect,
      items: items,
    ).then((value) {
      if (value != null) {
        _handleTabMenuAction(context, value, tabIndex, provider);
      }
    });
  }

  void _handleTabMenuAction(BuildContext context, String action, int tabIndex, BrowserProvider provider) {
    if (action.startsWith('add_to_group_')) {
      final groupId = action.replaceFirst('add_to_group_', '');
      provider.addTabToGroup(provider.tabs[tabIndex].id, groupId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tab added to group')),
      );
      return;
    }

    switch (action) {
      case 'new_window':
        _moveTabToNewWindow(context, provider, tabIndex);
        break;
      case 'close':
        provider.closeTab(tabIndex);
        break;
      case 'duplicate':
        _duplicateTab(context, provider, tabIndex);
        break;
      case 'group':
        _groupSimilarTabs(context, provider, tabIndex);
        break;
      case 'close_right':
        _closeTabsToRight(provider, tabIndex);
        break;
      case 'close_left':
        _closeTabsToLeft(provider, tabIndex);
        break;
      case 'close_others':
        _closeOtherTabs(provider, tabIndex);
        break;
    }
  }

  void _groupSimilarTabs(BuildContext context, BrowserProvider provider, int tabIndex) {
    _showCreateGroupDialog(context, provider, [tabIndex]);
  }

  void _showCreateGroupDialog(BuildContext context, BrowserProvider provider, List<int> tabIndices) {
    String groupName = '';
    int selectedColor = Colors.blue.value;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Tab Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'Enter group name',
                ),
                onChanged: (value) => groupName = value,
              ),
              const SizedBox(height: 16),
              const Text('Choose Color:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.yellow,
                  Colors.purple,
                  Colors.orange,
                  Colors.pink,
                  Colors.teal,
                ].map((color) => GestureDetector(
                  onTap: () => setState(() => selectedColor = color.value),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(
                        color: selectedColor == color.value ? Colors.black : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (groupName.isNotEmpty) {
                  provider.createTabGroup(groupName, selectedColor, tabIndices);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Created group "$groupName"')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _moveTabToNewWindow(BuildContext context, BrowserProvider provider, int tabIndex) {
    final tab = provider.tabs[tabIndex];
    provider.createWorkspace('New Window', 'window', Colors.blue.value);
    provider.switchWorkspace(provider.workspaces.length - 1);
    provider.tabs.clear();
    provider.tabs.add(tab);
    provider.notifyListeners();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tab moved to new window')),
    );
  }

  void _duplicateTab(BuildContext context, BrowserProvider provider, int tabIndex) {
    provider.duplicateTab(tabIndex);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tab duplicated')),
    );
  }

  void _closeTabsToRight(BrowserProvider provider, int tabIndex) {
    final tabsToRemove = <int>[];
    for (int i = tabIndex + 1; i < provider.tabs.length; i++) {
      tabsToRemove.add(i);
    }
    // Remove in reverse order to maintain indices
    for (final index in tabsToRemove.reversed) {
      provider.closeTab(index);
    }
  }

  void _closeTabsToLeft(BrowserProvider provider, int tabIndex) {
    final tabsToRemove = <int>[];
    for (int i = 0; i < tabIndex; i++) {
      tabsToRemove.add(i);
    }
    // Remove in reverse order to maintain indices
    for (final index in tabsToRemove.reversed) {
      provider.closeTab(index);
    }
  }

  void _closeOtherTabs(BrowserProvider provider, int tabIndex) {
    final tabsToRemove = <int>[];
    for (int i = 0; i < provider.tabs.length; i++) {
      if (i != tabIndex) {
        tabsToRemove.add(i);
      }
    }
    // Remove in reverse order to maintain indices
    for (final index in tabsToRemove.reversed) {
      provider.closeTab(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final browserProvider = Provider.of<BrowserProvider>(context);

    // Get tabs that are not in any group
    final groupedTabIds = browserProvider.currentWorkspace.tabGroups
        .expand((group) => group.tabIds)
        .toSet();

    final ungroupedTabs = <int>[];
    for (int i = 0; i < browserProvider.tabs.length; i++) {
      if (!groupedTabIds.contains(browserProvider.tabs[i].id)) {
        ungroupedTabs.add(i);
      }
    }

    return Container(
      height: 40,
      color: Colors.grey[200],
      child: Row(
        children: [
          // Tab Groups (always on the left)
          ...browserProvider.currentWorkspace.tabGroups.map((group) {
            final groupTabs = group.tabIds
                .map((tabId) => browserProvider.tabs.indexWhere((tab) => tab.id == tabId))
                .where((index) => index != -1)
                .toList();

            return Row(
              children: [
                // Group header with drag target
                DragTarget<int>(
                  onAcceptWithDetails: (details) {
                    final draggedIndex = details.data;
                    final draggedTab = browserProvider.tabs[draggedIndex];
                    // Add tab to group
                    browserProvider.addTabToGroup(draggedTab.id, group.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Tab added to ${group.name}')),
                    );
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isHoveringDrop = candidateData.isNotEmpty;
                    return GestureDetector(
                      onTap: () => browserProvider.toggleTabGroup(group.id),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isHoveringDrop
                              ? Color(group.color).withAlpha((0.4 * 255).round())
                              : Color(group.color).withAlpha((0.2 * 255).round()),
                          border: Border.all(
                            color: isHoveringDrop ? Color(group.color) : Color(group.color),
                            width: isHoveringDrop ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(
                              group.name,
                              style: TextStyle(
                                color: Color(group.color),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Icon(
                              group.isCollapsed ? Icons.expand_more : Icons.expand_less,
                              size: 16,
                              color: Color(group.color),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Group tabs (only show if not collapsed)
                if (!group.isCollapsed)
                  ...groupTabs.map((index) {
                    final tab = browserProvider.tabs[index];
                    return GestureDetector(
                      onTap: () => browserProvider.switchTab(index),
                      onSecondaryTapDown: (details) => _showTabContextMenu(context, details.globalPosition, index, browserProvider),
                      child: Container(
                        width: 150,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: browserProvider.currentTabIndex == index
                              ? Colors.white
                              : Colors.grey[300],
                          border: Border.all(color: Color(group.color), width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                tab.title ?? tab.url ?? 'New Tab',
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 14),
                              onPressed: () => browserProvider.closeTab(index),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
              ],
            );
          }).toList(),

          // Ungrouped tabs
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: ungroupedTabs.length + 1, // +1 for new tab button
                  itemBuilder: (context, listIndex) {
                    if (listIndex == ungroupedTabs.length) {
                      // New Tab Button
                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add, size: 20),
                          onPressed: () => browserProvider.addTab(),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),
                      );
                    }

                    final index = ungroupedTabs[listIndex];
                    final tab = browserProvider.tabs[index];
                    final isDragging = _draggedTabIndex == index;

                    return LongPressDraggable<int>(
                      data: index,
                      delay: const Duration(milliseconds: 200), // Shorter long press delay
                      feedback: Material(
                        child: Container(
                          width: 150,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha((0.3 * 255).round()),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            tab.title ?? tab.url ?? 'New Tab',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      onDragStarted: () {
                        setState(() {
                          _draggedTabIndex = index;
                          _dragStartPosition = null; // Will be set in onDragEnd if needed
                        });
                      },
                      onDraggableCanceled: (velocity, offset) => setState(() => _draggedTabIndex = null),
                      onDragEnd: (details) {
                        setState(() => _draggedTabIndex = null);
                        // Check if dragged far enough to create new window
                        if (_dragStartPosition != null) {
                          final distance = (details.offset - _dragStartPosition!).distance;
                          if (distance > 200) { // Threshold for creating new window
                            _moveTabToNewWindow(context, browserProvider, index);
                          }
                        }
                      },
                      childWhenDragging: Container(
                        width: 150,
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[400]?.withAlpha((0.5 * 255).round()),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: DragTarget<int>(
                        onAcceptWithDetails: (details) {
                          final draggedIndex = details.data;
                          if (draggedIndex != index) {
                            // Reorder tabs
                            final draggedTab = browserProvider.tabs[draggedIndex];
                            browserProvider.tabs.removeAt(draggedIndex);
                            final newIndex = draggedIndex < index ? index - 1 : index;
                            browserProvider.tabs.insert(newIndex, draggedTab);
                            browserProvider.reorderTabs(browserProvider.tabs);
                          }
                        },
                        builder: (context, candidateData, rejectedData) {
                          final isHoveringDrop = candidateData.isNotEmpty;
                          return GestureDetector(
                            onTap: () => browserProvider.switchTab(index),
                            onSecondaryTapDown: (details) => _showTabContextMenu(context, details.globalPosition, index, browserProvider),
                            child: Container(
                              width: 150,
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: browserProvider.currentTabIndex == index
                                    ? Colors.white
                                    : isHoveringDrop
                                        ? Colors.blue[100]
                                        : Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                                border: isHoveringDrop ? Border.all(color: Colors.blue, width: 2) : null,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      tab.title ?? tab.url ?? 'New Tab',
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: () => browserProvider.closeTab(index),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                // Drag target for creating new window
                if (_draggedTabIndex != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 100,
                    child: DragTarget<int>(
                      onAcceptWithDetails: (details) {
                        final draggedIndex = details.data;
                        _moveTabToNewWindow(context, browserProvider, draggedIndex);
                      },
                      builder: (context, candidateData, rejectedData) {
                        final isHovering = candidateData.isNotEmpty;
                        return Container(
                          decoration: BoxDecoration(
                            color: isHovering ? Colors.blue.withAlpha((0.3 * 255).round()) : Colors.transparent,
                            border: Border(
                              left: BorderSide(
                                color: isHovering ? Colors.blue : Colors.grey,
                                width: isHovering ? 3 : 1,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.open_in_new,
                              color: isHovering ? Colors.blue : Colors.grey,
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}