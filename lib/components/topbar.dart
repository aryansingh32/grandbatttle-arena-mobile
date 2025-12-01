import 'package:flutter/material.dart';
import 'package:grand_battle_arena/items/circularavatar.dart';
import 'package:grand_battle_arena/models/notification_model.dart';
import 'package:grand_battle_arena/models/wallet_model.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';
import 'package:grand_battle_arena/services/api_service.dart';
import 'package:grand_battle_arena/services/firebase_auth_service.dart';
import 'package:shimmer/shimmer.dart';

class TopBar extends StatefulWidget {
  const TopBar({super.key});

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  String userName = "User";
  String userProfileImage = 'assets/images/download.webp';
  List<NotificationModel> notifications = [];
  bool _isLoadingNotifications = false;
  int unreadNotificationCount = 0;
  
  // 🔥 NEW: Wallet state
  int currentCoins = 0;
  bool _isLoadingCoins = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadNotifications();
    _loadWalletBalance(); // 🔥 NEW: Load coins
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuthService.currentUser;
      if (user != null) {
        setState(() {
          userName = user.displayName ?? user.email?.split('@')[0] ?? "User";
          userProfileImage = user.photoURL ?? 'assets/images/download.webp';
        });
      }

      final userProfile = await ApiService.getUserProfile();
      if (mounted) {
        setState(() {
          // Only update if we don't already have a display name
          if (FirebaseAuthService.currentUser?.displayName == null) {
            userName = userProfile.userName ?? userName;
          }
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // 🔥 NEW: Load wallet balance
  Future<void> _loadWalletBalance() async {
    try {
      final user = FirebaseAuthService.currentUser;
      if (user == null) return;

      final wallet = await ApiService.getWallet(user.uid);
      if (mounted) {
        setState(() {
          currentCoins = wallet.coins ?? 0;
          _isLoadingCoins = false;
        });
      }
    } catch (e) {
      print('Error loading wallet balance: $e');
      if (mounted) {
        setState(() => _isLoadingCoins = false);
      }
    }
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoadingNotifications = true);
    
    try {
      final notificationData = await ApiService.getNotifications();
      if (mounted) {
        setState(() {
          notifications = notificationData;
          _updateUnreadCount(); // 🔥 FIXED: Use helper method
          _isLoadingNotifications = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingNotifications = false);
      print('Error loading notifications: $e');
    }
  }

  // 🔥 NEW: Helper to update unread count
  void _updateUnreadCount() {
    unreadNotificationCount = notifications
        .where((notification) => !(notification.isRead ?? false))
        .length;
  }

  Future<void> _markNotificationAsRead(int notificationId) async {
    try {
      await ApiService.markNotificationAsRead(notificationId);
      
      // 🔥 FIXED: Update local state properly
      setState(() {
        final index = notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          notifications[index].isRead = true;
          _updateUnreadCount(); // Update badge count
        }
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // 🔥 NEW: Clear all notifications
  Future<void> _clearAllNotifications() async {
    if (notifications.isEmpty) return;

    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Clear All Notifications?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'This will mark all notifications as read.',
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Clear All', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Mark all unread notifications as read
      final unreadIds = notifications
          .where((n) => !(n.isRead ?? false))
          .map((n) => n.id)
          .toList();

      for (final id in unreadIds) {
        await ApiService.markNotificationAsRead(id);
      }

      // Update local state
      setState(() {
        for (var notification in notifications) {
          notification.isRead = true;
        }
        _updateUnreadCount();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('All notifications cleared'),
              ],
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error clearing notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear notifications'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center, // 🔥 FIXED: Proper alignment
        children: [
          // Left side: Profile and Welcome text
          Row(
            crossAxisAlignment: CrossAxisAlignment.center, // 🔥 FIXED: Align items
            children: [
              CircularProfile(
                navigationLocation: '/profile',
                imageLink: userProfileImage,
                isNetwork: userProfileImage.startsWith('http'),
              ),
              SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min, // 🔥 FIXED: Prevent overflow
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome",
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      letterSpacing: 1,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    userName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      letterSpacing: 1,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ],
          ),
          
          // Right side: Coins and Notifications
          Row(
            crossAxisAlignment: CrossAxisAlignment.center, // 🔥 FIXED: Align items
            children: [
              // 🔥 NEW: Coin balance display
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/wallet'),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/icons/dollar.png',
                        height: 18,
                        width: 18,
                      ),
                      SizedBox(width: 6),
                      _isLoadingCoins
                          ? SizedBox(
                              width: 30,
                              height: 12,
                              child: Shimmer.fromColors(
                                baseColor: Colors.grey[700]!,
                                highlightColor: Colors.grey[500]!,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              currentCoins.toString().replaceAllMapped(
                                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                    (Match m) => '${m[1]},',
                                  ),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(width: 12),
              
              // Notification bell with badge
              GestureDetector(
                onTap: () => _showNotificationBottomSheet(context),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center, // 🔥 FIXED: Center the icon
                        padding: EdgeInsets.all(4),
                        child: Image.asset('assets/icons/bell.png'),
                      ),
                    if (unreadNotificationCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            ),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            unreadNotificationCount > 9
                                ? '9+'
                                : unreadNotificationCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNotificationBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  // Drag indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header with title and actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Notifications',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (unreadNotificationCount > 0) ...[
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$unreadNotificationCount new',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        // 🔥 NEW: Clear all button
                        if (notifications.isNotEmpty)
                          TextButton.icon(
                            onPressed: () async {
                              await _clearAllNotifications();
                              setModalState(() {}); // Update modal state
                            },
                            icon: Icon(
                              Icons.clear_all,
                              color: Theme.of(context).colorScheme.secondary,
                              size: 18,
                            ),
                            label: Text(
                              'Clear All',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(color: Colors.grey[800], thickness: 1),
                  ),

                  // Notification List
                  Expanded(
                    child: _isLoadingNotifications
                        ? Center(
                            child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          )
                        : notifications.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.notifications_off_outlined,
                                      size: 64,
                                      color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No notifications yet',
                                      style: TextStyle(
                                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'We\'ll notify you when something arrives',
                                      style: TextStyle(
                                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () async {
                                  await _loadNotifications();
                                  setModalState(() {});
                                },
                                color: Theme.of(context).colorScheme.secondary,
                                child: ListView.builder(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: notifications.length,
                                  itemBuilder: (context, index) {
                                    final notification = notifications[index];
                                    final isRead = notification.isRead ?? false;

                                    return Dismissible(
                                      key: Key(notification.id.toString()),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: EdgeInsets.only(right: 20),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                        ),
                                      ),
                                      onDismissed: (direction) {
                                        // Mark as read when dismissed
                                        if (!isRead) {
                                          _markNotificationAsRead(notification.id);
                                        }
                                        setModalState(() {
                                          notifications.removeAt(index);
                                        });
                                      },
                                      child: Card(
                                        color: isRead
                                            ? Theme.of(context).cardColor
                                            : Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                        margin: EdgeInsets.only(bottom: 8),
                                        elevation: isRead ? 0 : 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: BorderSide(
                                            color: isRead
                                                ? Colors.transparent
                                                : Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: ListTile(
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          leading: CircleAvatar(
                                            backgroundColor: isRead
                                                ? Theme.of(context).disabledColor
                                                : Theme.of(context).colorScheme.secondary,
                                            child: Icon(
                                              _getNotificationIcon(notification.type),
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                          title: Text(
                                            notification.title ?? 'Notification',
                                            style: TextStyle(
                                              color: Theme.of(context).textTheme.bodyLarge?.color,
                                              fontWeight: isRead
                                                  ? FontWeight.normal
                                                  : FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(height: 4),
                                              Text(
                                                notification.message ?? 'No message',
                                                style: TextStyle(
                                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                                  fontSize: 12,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 6),
                                              Text(
                                                _formatNotificationTime(
                                                    notification.createdAt),
                                                style: TextStyle(
                                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                          onTap: () {
                                            // 🔥 FIXED: Mark as read when tapped
                                            if (!isRead) {
                                              _markNotificationAsRead(notification.id);
                                              setModalState(() {
                                                notification.isRead = true;
                                                _updateUnreadCount();
                                              });
                                            }
                                            _handleNotificationTap(notification);
                                          },
                                          trailing: !isRead
                                              ? Container(
                                                  width: 10,
                                                  height: 10,
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).colorScheme.secondary,
                                                    shape: BoxShape.circle,
                                                  ),
                                                )
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'tournament':
      case 'tournament_credentials':
      case 'tournament_reminder':
      case 'tournament_update':
        return Icons.sports_esports;
      case 'wallet':
      case 'wallet_transaction':
      case 'reward_distribution':
        return Icons.account_balance_wallet;
      case 'achievement':
        return Icons.emoji_events;
      case 'system':
        return Icons.info_outline;
      default:
        return Icons.notifications;
    }
  }

  String _formatNotificationTime(String? dateString) {
    if (dateString == null) return '';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 7) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateString;
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    final type = notification.type?.toLowerCase();
    final data = notification.data;

    switch (type) {
      case 'tournament':
      case 'tournament_credentials':
      case 'tournament_reminder':
      case 'tournament_update':
        if (data != null && data['tournamentId'] != null) {
          Navigator.pushNamed(
            context,
            '/tournament-detail',
            arguments: data['tournamentId'],
          );
        }
        break;
      case 'wallet':
      case 'wallet_transaction':
      case 'reward_distribution':
        Navigator.pushNamed(context, '/wallet');
        break;
      case 'achievement':
        Navigator.pushNamed(context, '/profile');
        break;
      default:
        // Handle general notifications
        break;
    }
  }
}