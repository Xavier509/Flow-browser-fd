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
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add, color: AppConstants.primaryColor),
                      tooltip: 'Add current page',
                      onPressed: () {
                        if (!authProvider.isAuthenticated) {
                          // Show auth modal
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Sign In Required'),
                              content: const Text('You need to be signed in to save bookmarks. Would you like to sign in or create an account?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    // Open auth modal - this would need to be passed as a callback
                                    // For now, show a snackbar
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please sign in from the top right menu')),
                                    );
                                  },
                                  child: const Text('Sign In'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                        
                        final currentUrl = provider.currentTab.url;
                        if (!provider.isBookmarked(currentUrl)) {
                          provider.addBookmark();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Bookmark added')),
                          );
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
