import 'package:flutter/material.dart';
import 'package:grand_battle_arena/components/mybookingscroller.dart';
import 'package:grand_battle_arena/models/slots_model.dart';
import 'package:grand_battle_arena/models/user_model.dart';
import 'package:grand_battle_arena/models/wallet_model.dart';
import 'package:grand_battle_arena/services/api_service.dart';
import 'package:grand_battle_arena/services/auth_state_manager.dart';
import 'package:grand_battle_arena/services/firebase_auth_service.dart';
import 'package:grand_battle_arena/services/notification_service.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';
import 'package:grand_battle_arena/theme/theme_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:grand_battle_arena/pages/support_page.dart';
import 'package:grand_battle_arena/pages/terms_page.dart';
import 'package:url_launcher/url_launcher.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  bool _debugMode = false; // Add debug mode to help troubleshoot

  UserModel? _user;
  WalletModel? _wallet;
  List<SlotsModel> _bookedSlots = [];

  // Animation controller for shimmer effect
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    // Add a small delay to ensure Firebase is properly initialized
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _loadProfileData();
      }
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    // Reset state before fetching
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final firebaseUID = FirebaseAuthService.getCurrentUserUID();
      if (firebaseUID == null) {
        throw Exception("User is not authenticated. Please log in again.");
      }

      // Try simple approach first (without timeout)
      try {
        print("Fetching profile data...");
        final results = await Future.wait([
          ApiService.getUserProfile(),
          ApiService.getWallet(firebaseUID),
          ApiService.getMyBookings(),
        ]);

        if (mounted) {
          setState(() {
            _user = results[0] as UserModel;
            _wallet = results[1] as WalletModel;
            _bookedSlots = results[2] as List<SlotsModel>;
            _isLoading = false;
            _error = null;
          });
          print("Profile data loaded successfully");
        }
        return; // Exit if successful
      } catch (e) {
        print("First attempt failed: $e");
        // Continue to individual fetching below
      }

      // If that fails, try fetching individually
      UserModel? user;
      WalletModel? wallet;
      List<SlotsModel> bookedSlots = [];

      // Fetch user profile first as it's most critical
      user = await ApiService.getUserProfile();
      print("User profile loaded");

      // Fetch wallet data
      wallet = await ApiService.getWallet(firebaseUID);
      print("Wallet data loaded");

      // Fetch bookings (can fail silently)
      try {
        bookedSlots = await ApiService.getMyBookings();
        print("Bookings loaded");
      } catch (e) {
        print("Bookings failed to load: $e");
        bookedSlots = [];
      }

      if (mounted) {
        setState(() {
          _user = user;
          _wallet = wallet;
          _bookedSlots = bookedSlots;
          _isLoading = false;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      print("API Exception: ${e.message}");
      if (mounted) {
        setState(() {
          _error = "Server error: ${e.message}";
          _isLoading = false;
        });
      }
    } catch (e) {
      print("General Exception: $e");
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? _buildShimmerLoading()
          : _error != null
              ? _buildErrorState()
              : _buildProfileContent(),
    );
  }

  Widget _buildShimmerLoading() {
    return CustomScrollView(
      slivers: [
        _buildShimmerAppBar(),
        SliverToBoxAdapter(child: _buildShimmerStatsCard()),
        _buildShimmerSectionHeader(),
        _buildShimmerBookingsList(),
        _buildShimmerSectionHeader(),
        _buildShimmerActionsList(),
      ],
    );
  }

  Widget _buildShimmerAppBar() {
    return SliverAppBar(
      expandedHeight: 200.0,
      backgroundColor: Theme.of(context).cardColor,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildShimmerContainer(80, 80, isCircular: true),
            const SizedBox(height: 12),
            _buildShimmerContainer(120, 20),
            const SizedBox(height: 8),
            _buildShimmerContainer(150, 14),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerStatsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildShimmerStatItem(),
          _buildShimmerStatItem(),
          _buildShimmerStatItem(),
        ],
      ),
    );
  }

  Widget _buildShimmerStatItem() {
    return Column(
      children: [
        _buildShimmerContainer(28, 28, isCircular: true),
        const SizedBox(height: 8),
        _buildShimmerContainer(40, 18),
        const SizedBox(height: 4),
        _buildShimmerContainer(60, 12),
      ],
    );
  }

  Widget _buildShimmerSectionHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: _buildShimmerContainer(120, 20),
      ),
    );
  }

  Widget _buildShimmerBookingsList() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 200,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildShimmerContainer(double.infinity, 200),
        ),
      ),
    );
  }

  Widget _buildShimmerActionsList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildShimmerActionTile(),
        childCount: 3,
      ),
    );
  }

  Widget _buildShimmerActionTile() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: _buildShimmerContainer(24, 24, isCircular: true),
        title: _buildShimmerContainer(100, 16),
        trailing: _buildShimmerContainer(16, 16),
      ),
    );
  }

  Widget _buildShimmerContainer(double width, double height, {bool isCircular = false}) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: isCircular ? BorderRadius.circular(height / 2) : BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [
                Appcolor.grey.withOpacity(0.3),
                Appcolor.grey.withOpacity(0.1),
                Appcolor.grey.withOpacity(0.3),
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 + _shimmerController.value * 2, 0.0),
              end: Alignment(1.0 + _shimmerController.value * 2, 0.0),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Appcolor.cardsColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.error_outline, 
                color: Colors.redAccent, 
                size: 60
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: const TextStyle(
                color: Appcolor.white, 
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Appcolor.cardsColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _error ?? 'An unknown error occurred.',
                style: const TextStyle(
                  color: Appcolor.grey, 
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
  ])));
  }

  Widget _buildProfileContent() {
    final user = _user;
    final wallet = _wallet;
    if (user == null || wallet == null) return _buildErrorState();

    return RefreshIndicator(
      onRefresh: _loadProfileData,
      color: Theme.of(context).colorScheme.secondary,
      backgroundColor: Theme.of(context).cardColor,
      child: CustomScrollView(
        slivers: [
          _buildSliverAppBar(user),
          SliverToBoxAdapter(child: _buildStatsCard(wallet)),
          SliverToBoxAdapter(child: _buildAccountDetails(user, wallet)),
          _buildSectionHeader("My Bookings"),
          const SliverToBoxAdapter(
            child: MyBookingsScroller(),
          ),
          _buildSectionHeader("Account"),
          _buildActionsList(),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(UserModel user) {
    return SliverAppBar(
      expandedHeight: 200.0,
      backgroundColor: Theme.of(context).cardColor,
      iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          FirebaseAuth.instance.currentUser?.displayName ?? user.userName,
          style: TextStyle(color: Theme.of(context).appBarTheme.titleTextStyle?.color, fontSize: 16.0),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).cardColor,
                Theme.of(context).cardColor.withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: 'profile_avatar',
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: const AssetImage('assets/images/download.webp'),
                  backgroundColor: Appcolor.primary,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                FirebaseAuth.instance.currentUser?.displayName ?? user.userName,
                style: const TextStyle(
                  color: Appcolor.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Appcolor.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  user.email,
                  style: const TextStyle(
                    color: Appcolor.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(WalletModel wallet) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            value: _bookedSlots.length.toString(),
            label: "Tournaments",
            icon: Icons.sports_esports,
            color: Colors.blueAccent,
          ),
          _buildVerticalDivider(),
          _buildStatItem(
            value: NumberFormat.compact().format(wallet.coins),
            label: "Coins",
            icon: Icons.monetization_on,
            color: Colors.amber,
          ),
          _buildVerticalDivider(),
          _buildStatItem(
            value: DateFormat('MMM yyyy').format(_user!.createdAt),
            label: "Member Since",
            icon: Icons.calendar_today,
            color: Colors.greenAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDetails(UserModel user, WalletModel wallet) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Details',
            style: TextStyle(
              color: Appcolor.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Username', user.userName),
          _buildDetailRow('Email', user.email),
          _buildDetailRow('UID', user.firebaseUserUID),
          _buildDetailRow('Coins', NumberFormat.compact().format(wallet.coins ?? 0)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: Appcolor.grey,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: Appcolor.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Appcolor.grey.withOpacity(0.3),
    );
  }

  Widget _buildStatItem({
    required String value, 
    required String label, 
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Appcolor.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Appcolor.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Appcolor.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.sentiment_dissatisfied, 
                  color: Appcolor.grey, 
                  size: 50
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  color: Appcolor.grey, 
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverList _buildBookingsList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final slot = _bookedSlots[index];
          return _BookingHistoryCard(slot: slot);
        },
        childCount: _bookedSlots.length,
      ),
    );
  }

  SliverList _buildActionsList() {
    return SliverList(
      delegate: SliverChildListDelegate([
        _ActionTile(
          icon: Icons.system_update_alt,
          title: "Check for Updates",
          subtitle: "Verify you're on the latest build",
          onTap: _checkForUpdates,
        ),
        _ActionTile(
          icon: Icons.notifications_active,
          title: "Refresh Notifications",
          subtitle: "Resend your FCM token to the server",
          onTap: _refreshNotificationToken,
        ),
        _ActionTile(
          icon: Icons.history,
          title: "Transaction History",
          subtitle: "View your coin transactions",
          onTap: () {
            Navigator.pushNamed(context, '/wallet');
          },
        ),
        _ActionTile(
          icon: Icons.help_outline,
          title: "Help & Support",
          subtitle: "FAQ and Contact Us",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SupportPage()),
            );
          },
        ),
        _ActionTile(
          icon: Icons.description,
          title: "Terms and Conditions",
          subtitle: "Read our terms of service",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TermsPage()),
            );
          },
        ),
        Consumer<ThemeManager>(
          builder: (context, themeManager, _) {
            return SwitchListTile(
              title: Text(
                "Show Quick Filters",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                "Show filter buttons on Home screen",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
              ),
              value: themeManager.showFilterGrid,
              onChanged: (value) => themeManager.toggleFilterGrid(value),
              secondary: Icon(
                Icons.grid_view,
                color: Theme.of(context).iconTheme.color,
              ),
              activeColor: Theme.of(context).colorScheme.secondary,
              tileColor: Theme.of(context).cardColor,
            );
          },
        ),
        _ActionTile(
          icon: Icons.palette,
          title: "Appearance",
          subtitle: "Customize app theme",
          onTap: () => _showThemeSettings(context),
        ),
        _ActionTile(
          icon: Icons.logout,
          title: "Log Out",
          subtitle: "Sign out of your account",
          color: Colors.redAccent,
          onTap: () async {
            // Show confirmation dialog
            final shouldLogOut = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Appcolor.cardsColor,
                title: const Text(
                  'Confirm Logout',
                  style: TextStyle(color: Appcolor.white),
                ),
                content: const Text(
                  'Are you sure you want to log out?',
                  style: TextStyle(color: Appcolor.grey),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Appcolor.grey),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    child: const Text(
                      'Log Out',
                      style: TextStyle(color: Appcolor.white),
                    ),
                  ),
                ],
              ),
            );

            if (shouldLogOut == true && context.mounted) {
              await context.read<AuthStateManager>().signOut();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            }
          },
        ),
      ]),
    );
  }

  Future<void> _refreshNotificationToken() async {
    try {
      await NotificationService.sendTokenToServer();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification token refreshed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh notifications: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _checkForUpdates() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      final storeUri = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.esport.grand_battle_arena',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Current version: ${info.version}+${info.buildNumber}'),
          action: SnackBarAction(
            label: 'Open Store',
            onPressed: () async {
              if (!await launchUrl(storeUri, mode: LaunchMode.externalApplication)) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not open the store listing'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking for updates: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  }

  void _showThemeSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<ThemeManager>(
          builder: (context, themeManager, _) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select Theme",
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildThemeOption(
                    context,
                    themeManager,
                    AppThemeType.dark,
                    "Dark Mode",
                    Icons.dark_mode,
                  ),
                  _buildThemeOption(
                    context,
                    themeManager,
                    AppThemeType.light,
                    "Modern Light",
                    Icons.light_mode,
                  ),
                  _buildThemeOption(
                    context,
                    themeManager,
                    AppThemeType.futuristic,
                    "Futuristic",
                    Icons.science,
                  ),
                  _buildThemeOption(
                    context,
                    themeManager,
                    AppThemeType.dynamic,
                    "Dynamic",
                    Icons.auto_awesome,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeManager themeManager,
    AppThemeType theme,
    String title,
    IconData icon,
  ) {
    final isSelected = themeManager.currentTheme == theme;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.secondary : Appcolor.grey),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Theme.of(context).textTheme.bodyLarge?.color : Appcolor.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.secondary)
          : null,
      onTap: () {
        themeManager.setTheme(theme);
        Navigator.pop(context);
      },
    );
  }


// Enhanced booking history card
class _BookingHistoryCard extends StatelessWidget {
  final SlotsModel slot;
  const _BookingHistoryCard({required this.slot});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Appcolor.cardsColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Appcolor.secondary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Appcolor.secondary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.gamepad, 
            color: Appcolor.secondary,
            size: 24,
          ),
        ),
        title: Text(
          'Tournament #${slot.tournamentId}',
          style: const TextStyle(
            color: Appcolor.white, 
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Player: ${slot.playerName ?? "N/A"}',
              style: const TextStyle(color: Appcolor.grey, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Appcolor.secondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Slot ${slot.slotNumber}',
                style: const TextStyle(
                  color: Appcolor.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Appcolor.grey,
          size: 16,
        ),
      ),
    );
  }
}

// Enhanced action tile
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tileColor = color ?? Appcolor.white;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Appcolor.cardsColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (color ?? Appcolor.secondary).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: tileColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: tileColor, size: 24),
        ),
        title: Text(
          title, 
          style: TextStyle(
            color: tileColor, 
            fontWeight: FontWeight.w600,
            fontSize: 16,
          )
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: const TextStyle(
                  color: Appcolor.grey,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: Icon(
          Icons.arrow_forward_ios, 
          color: tileColor.withOpacity(0.7), 
          size: 16
        ),
        onTap: onTap,
      ),
    );
  }
}