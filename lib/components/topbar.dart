import 'package:flutter/material.dart';
import 'package:grand_battle_arena/items/circularavatar.dart';
import 'package:grand_battle_arena/models/notification_model.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';
import 'package:grand_battle_arena/services/api_service.dart';
import 'package:grand_battle_arena/services/firebase_auth_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadNotifications();
  }

  Future<void> _loadUserData() async {
    try {
      // Get user data from Firebase Auth
      final user = FirebaseAuthService.currentUser;
      if (user != null) {
        setState(() {
          userName = user.displayName ?? user.email?.split('@')[0] ?? "User";
          userProfileImage = user.photoURL ?? 'assets/images/download.webp';
        });
      }

      // Optionally, get additional user data from your API
      final userProfile = await ApiService.getUserProfile();
      if (mounted) {
      setState(() {
        userName = userProfile.userName ?? userName;
        // Add more user data as needed
      });}
    } catch (e) {
      print('Error loading user data: $e');
      // Keep default values
    }
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoadingNotifications = true);
    
    try {
      final notificationData = await ApiService.getNotifications();
      if (mounted) {
      setState(() {
        notifications = notificationData;
        unreadNotificationCount = notifications
            .where((notification) => !(notification.isRead ?? false))
            .length;
        _isLoadingNotifications = false;
      });}
    } catch (e) {
      setState(() => _isLoadingNotifications = false);
      print('Error loading notifications: $e');
    }
  }

  Future<void> _markNotificationAsRead(int notificationId) async {
    try {
      await ApiService.markNotificationAsRead(notificationId);
      // Update local state
      setState(() {
        final index = notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          notifications[index].isRead = true;
          unreadNotificationCount = notifications
              .where((notification) => !(notification.isRead ?? false))
              .length;
        }
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CircularProfile(
            navigationLocation: '/profile',
            imageLink: userProfileImage,
            isNetwork: userProfileImage.startsWith('http'),
          ),
          SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome",
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  color: Appcolor.white,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 2),
              Text(
                userName,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Appcolor.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          Spacer(), // Better than fixed width Container
          
          // Notification bell with badge
          GestureDetector(
            onTap: () => _showNotificationBottomSheet(context),
            child: Stack(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset('assets/icons/bell.png'),
                ),
                if (unreadNotificationCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadNotificationCount > 9 ? '9+' : unreadNotificationCount.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
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
    );
  }

  void _showNotificationBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Appcolor.cardsColor,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (context) {
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
                    color: Appcolor.secondaryW50,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notifications',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (unreadNotificationCount > 0)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Appcolor.secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$unreadNotificationCount new',
                          style: TextStyle(
                            color: Appcolor.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Divider
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(color: Colors.grey),
              ),

              // Notification List
              Expanded(
                child: _isLoadingNotifications
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Appcolor.secondary,
                      ),
                    )
                  : notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off,
                              size: 64,
                              color: Appcolor.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No notifications yet',
                              style: TextStyle(
                                color: Appcolor.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadNotifications,
                        color: Appcolor.secondary,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final notification = notifications[index];
                            final isRead = notification.isRead ?? false;
                            
                            return Card(
                              color: isRead 
                                ? Appcolor.cardsColor
                                : Appcolor.cardsColor.withOpacity(0.8),
                              margin: EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isRead 
                                    ? Appcolor.grey 
                                    : Appcolor.secondary,
                                  child: Icon(
                                    _getNotificationIcon(notification.type),
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  notification.title ?? 'Notification',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: isRead 
                                      ? FontWeight.normal 
                                      : FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notification.message ?? 'No message',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _formatNotificationTime(notification.createdAt),
                                      style: TextStyle(
                                        color: Appcolor.grey,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  if (!isRead) {
                                    _markNotificationAsRead(notification.id);
                                  }
                                  // Handle notification tap (navigate to relevant screen)
                                  _handleNotificationTap(notification);
                                },
                                trailing: !isRead
                                  ? Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Appcolor.secondary,
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : null,
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
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'tournament':
        return Icons.sports_esports;
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'achievement':
        return Icons.emoji_events;
      case 'system':
        return Icons.info;
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

      if (difference.inDays > 0) {
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
    final type = notification.type;
    final data = notification.data;

    switch (type) {
      case 'tournament':
        if (data != null && data['tournamentId'] != null) {
          Navigator.pushNamed(
            context, 
            '/tournament-detail',
            arguments: data['tournamentId'],
          );
        }
        break;
      case 'wallet':
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