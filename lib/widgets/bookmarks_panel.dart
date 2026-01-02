import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/browser_provider.dart';
import '../providers/auth_provider.dart';
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
    final authProvider = context.watch<AuthProvider>();

    Widget content = Container(
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor.withAlpha((0.95 * 255).round()),
        border: Border(
          left: BorderSide(
            color: AppConstants.primaryColor.withAlpha((0.3 * 255).round()),
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
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add, color: AppConstants.primaryColor),
                      tooltip: 'Add current page',
                      onPressed: () {
                        final currentUrl = provider.currentTab.url;
                        if (!provider.isBookmarked(currentUrl)) {
                          provider.addBookmark();
                          if (!authProvider.isAuthenticated) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Bookmark saved locally. Sign in to sync across devices.')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Bookmark added and synced')),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Already bookmarked')),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppConstants.primaryColor),
                      onPressed: onClose,
                    ),
                  ],
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
                        color: AppConstants.primaryColor.withAlpha((0.5 * 255).round()),
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
                            color: AppConstants.primaryColor.withAlpha((0.5 * 255).round()),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(bookmark.pinned ? Icons.push_pin : Icons.push_pin_outlined, size: 18),
                              color: bookmark.pinned ? AppConstants.primaryColor : Colors.white70,
                              onPressed: () {
                                provider.toggleBookmarkPinned(bookmark.id);
                                if (!authProvider.isAuthenticated) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pinned locally. Sign in to sync across devices.')));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated bookmark')));
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              color: Colors.red,
                              onPressed: () => provider.removeBookmark(bookmark.id),
                            ),
                          ],
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
