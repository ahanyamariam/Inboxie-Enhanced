import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/services/storage_service.dart';
import 'package:app/models/user_settings_model.dart';
import 'package:app/features/profile/widgets/profile_header.dart';
import 'package:app/features/profile/widgets/settings_section.dart';
import 'package:app/features/profile/widgets/settings_tile.dart';
import 'package:app/features/profile/screens/vip_senders_screen.dart';
import 'package:app/features/profile/screens/muted_senders_screen.dart';
import 'package:app/features/home/widgets/bottom_nav.dart';
import 'package:app/features/home/buckets_page.dart';
import 'package:app/features/splash/presentation/pages/splash_screen.dart';
import 'package:app/features/profile/screens/bucket_customization_screen.dart';
import 'package:app/features/profile/screens/label_customization_screen.dart';
import 'package:app/features/profile/screens/email_label_management_screen.dart';
import 'package:app/features/profile/screens/notification_settings_screen.dart';
import 'package:app/features/profile/screens/usage_stats_screen.dart';
import 'package:app/main.dart' show changeTheme;

class ProfileScreen extends StatefulWidget {
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final String? accessToken;

  const ProfileScreen({
    super.key,
    this.displayName,
    this.email,
    this.photoUrl,
    this.accessToken,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StorageService _storage = StorageService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  late UserSettingsModel _settings;
  String _appVersion = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppVersion();
  }

  void _loadSettings() {
    setState(() {
      _settings = _storage.loadSettings(
        email: widget.email,
        displayName: widget.displayName,
        photoUrl: widget.photoUrl,
      );
    });
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  // ============ HAPTIC FEEDBACK ============
  void _triggerHaptic() {
    if (_settings.hapticFeedbackEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  // ============ NAVIGATION ============
  void _onBottomNavTap(int index) {
    _triggerHaptic();
    switch (index) {
      case 0:
        Navigator.of(context).popUntil((route) => route.isFirst);
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BucketsPage(
              accessToken: widget.accessToken ?? '',
              userEmail: widget.email ?? '',
              userDisplayName: widget.displayName,
              userPhotoUrl: widget.photoUrl,
            ),
          ),
        );
        break;
      case 2:
        // Already on Profile
        break;
    }
  }

  // ============ URL LAUNCHER ============
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open $url'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ============ SELECTION DIALOGS ============

  void _showPrioritySensitivitySelector() {
    _triggerHaptic();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SelectorSheet<PrioritySensitivity>(
        title: 'Priority Sensitivity',
        subtitle: 'How aggressively should Inboxie flag emails as urgent?',
        options: PrioritySensitivity.values,
        selectedOption: _settings.prioritySensitivity,
        labelBuilder: (option) {
          switch (option) {
            case PrioritySensitivity.low:
              return 'Low';
            case PrioritySensitivity.normal:
              return 'Normal';
            case PrioritySensitivity.high:
              return 'High';
          }
        },
        subtitleBuilder: (option) {
          switch (option) {
            case PrioritySensitivity.low:
              return 'Only flag truly critical emails';
            case PrioritySensitivity.normal:
              return 'Balanced detection (recommended)';
            case PrioritySensitivity.high:
              return 'Flag more emails as important';
          }
        },
        onSelect: (option) async {
          _triggerHaptic();
          await _storage.setPrioritySensitivity(option);
          _loadSettings();
        },
      ),
    );
  }

  void _showPrivacyModeSelector() {
    _triggerHaptic();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SelectorSheet<PrivacyMode>(
        title: 'Privacy Mode',
        subtitle: 'Control what email data is stored on your device.',
        options: PrivacyMode.values,
        selectedOption: _settings.privacyMode,
        labelBuilder: (option) {
          switch (option) {
            case PrivacyMode.none:
              return 'None';
            case PrivacyMode.summary:
              return 'Summaries Only';
            case PrivacyMode.full:
              return 'Full Content';
          }
        },
        subtitleBuilder: (option) {
          switch (option) {
            case PrivacyMode.none:
              return 'No email content stored locally';
            case PrivacyMode.summary:
              return 'Only AI-generated summaries stored';
            case PrivacyMode.full:
              return 'Full email content cached for offline';
          }
        },
        onSelect: (option) async {
          _triggerHaptic();
          await _storage.setPrivacyMode(option);
          _loadSettings();
        },
      ),
    );
  }

  void _showSyncFrequencySelector() {
    _triggerHaptic();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SelectorSheet<SyncFrequency>(
        title: 'Sync Frequency',
        subtitle: 'How often should Inboxie check for new emails?',
        options: SyncFrequency.values,
        selectedOption: _settings.syncFrequency,
        labelBuilder: (option) {
          switch (option) {
            case SyncFrequency.fiveMin:
              return '5 minutes';
            case SyncFrequency.fifteenMin:
              return '15 minutes';
            case SyncFrequency.thirtyMin:
              return '30 minutes';
            case SyncFrequency.manual:
              return 'Manual only';
          }
        },
        subtitleBuilder: (option) {
          switch (option) {
            case SyncFrequency.fiveMin:
              return 'Most frequent, uses more battery';
            case SyncFrequency.fifteenMin:
              return 'Balanced (recommended)';
            case SyncFrequency.thirtyMin:
              return 'Less frequent, saves battery';
            case SyncFrequency.manual:
              return 'Only sync when you refresh';
          }
        },
        onSelect: (option) async {
          _triggerHaptic();
          await _storage.setSyncFrequency(option);
          _loadSettings();
        },
      ),
    );
  }

  void _showThemeSelector() {
    _triggerHaptic();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SelectorSheet<String>(
        title: 'Theme',
        subtitle: 'Choose your preferred app appearance.',
        options: const ['system', 'light', 'dark'],
        selectedOption: _settings.themeMode,
        labelBuilder: (option) {
          switch (option) {
            case 'light':
              return 'Light';
            case 'dark':
              return 'Dark';
            default:
              return 'System';
          }
        },
        subtitleBuilder: (option) {
          switch (option) {
            case 'light':
              return 'Always use light mode';
            case 'dark':
              return 'Always use dark mode';
            default:
              return 'Follow system settings';
          }
        },
        iconBuilder: (option) {
          switch (option) {
            case 'light':
              return Icons.light_mode_rounded;
            case 'dark':
              return Icons.dark_mode_rounded;
            default:
              return Icons.phone_android_rounded;
          }
        },
        onSelect: (option) async {
          _triggerHaptic();
          await changeTheme(option);
          _loadSettings();
        },
      ),
    );
  }

  void _showDefaultTabSelector() {
    _triggerHaptic();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SelectorSheet<String>(
        title: 'Default Tab',
        subtitle: 'Which tab should open when you launch the app?',
        options: const ['action', 'all', 'urgent'],
        selectedOption: _settings.defaultTab,
        labelBuilder: (option) {
          switch (option) {
            case 'all':
              return 'All Emails';
            case 'urgent':
              return 'Urgent';
            default:
              return 'Action';
          }
        },
        subtitleBuilder: (option) {
          switch (option) {
            case 'all':
              return 'Show all emails first';
            case 'urgent':
              return 'Show urgent emails first';
            default:
              return 'Show emails needing action (recommended)';
          }
        },
        onSelect: (option) async {
          _triggerHaptic();
          await _storage.setDefaultTab(option);
          _loadSettings();
        },
      ),
    );
  }

  // ============ ACTIONS ============

  Future<void> _clearLocalData() async {
    _triggerHaptic();
    final isDark = AppColors.isDark(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getSurface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear Local Data?',
          style: TextStyle(color: AppColors.getTextPrimary(context)),
        ),
        content: Text(
          'This will delete all cached emails. Your settings and sender lists will be preserved.',
          style: TextStyle(color: AppColors.getTextSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      await _storage.clearEmailCache();

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Local data cleared'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    _triggerHaptic();
    final isDark = AppColors.isDark(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getSurface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sign Out?',
          style: TextStyle(color: AppColors.getTextPrimary(context)),
        ),
        content: Text(
          'You will be disconnected from Gmail. Your settings will be preserved for when you sign back in.',
          style: TextStyle(color: AppColors.getTextSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      await _googleSignIn.signOut();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      bottomNavigationBar: BottomNav(currentIndex: 3, onTap: _onBottomNavTap),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            )
          : CustomScrollView(
              slivers: [
                // Profile Header
                SliverToBoxAdapter(
                  child: ProfileHeader(
                    displayName: widget.displayName,
                    email: widget.email,
                    photoUrl: widget.photoUrl,
                    isConnected: true,
                  ),
                ),

                // Settings Content
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // ==================== CUSTOMIZATION ====================
                      SettingsSection(
                        title: 'Customization',
                        children: [
                          SettingsTile(
                            icon: Icons.grid_view_rounded,
                            iconColor: Colors.blueAccent,
                            iconBackgroundColor: Colors.blueAccent.withValues(alpha: 
                              0.1,
                            ),
                            title: 'Inbox Buckets',
                            subtitle: 'Reorder, rename, or hide tabs',
                            showArrow: true,
                            onTap: () {
                              _triggerHaptic();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const BucketCustomizationScreen(),
                                ),
                              );
                            },
                          ),
                          SettingsTile(
                            icon: Icons.label_rounded,
                            iconColor: Colors.orangeAccent,
                            iconBackgroundColor: Colors.orangeAccent
                                .withValues(alpha: 0.1),
                            title: 'Smart Labels',
                            subtitle: 'Customize priority & action tags',
                            showArrow: true,
                            onTap: () {
                              _triggerHaptic();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const LabelCustomizationScreen(),
                                ),
                              );
                            },
                          ),
                          SettingsTile(
                            icon: Icons.category_rounded,
                            iconColor: Colors.teal,
                            iconBackgroundColor: Colors.teal.withValues(alpha:
                              0.1,
                            ),
                            title: 'Email Classification',
                            subtitle: 'Manage email labels & keywords',
                            showArrow: true,
                            onTap: () {
                              _triggerHaptic();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const EmailLabelManagementScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ==================== INTELLIGENCE ====================
                      SettingsSection(
                        title: 'Intelligence',
                        children: [
                          SettingsTile(
                            icon: Icons.insights_rounded,
                            iconColor: Colors.purpleAccent,
                            iconBackgroundColor: Colors.purpleAccent
                                .withValues(alpha: 0.1),
                            title: 'Usage Stats',
                            subtitle: 'See how much time you\'ve saved',
                            showArrow: true,
                            onTap: () {
                              _triggerHaptic();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const UsageStatsScreen(),
                                ),
                              );
                            },
                          ),
                          SettingsSelectorTile(
                            icon: Icons.speed_rounded,
                            iconColor: Colors.orange,
                            iconBackgroundColor: Colors.orange.withValues(alpha: 0.1),
                            title: 'Priority Sensitivity',
                            subtitle: 'How aggressively to flag urgent emails',
                            value: _settings.prioritySensitivityLabel,
                            onTap: _showPrioritySensitivitySelector,
                          ),
                          SettingsToggleTile(
                            icon: Icons.psychology_rounded,
                            iconColor: Colors.purple,
                            iconBackgroundColor: Colors.purple.withValues(alpha: 0.1),
                            title: 'Smart Detection',
                            subtitle: 'AI-powered email analysis',
                            value: _settings.smartDetectionEnabled,
                            onChanged: (value) async {
                              _triggerHaptic();
                              await _storage.setSmartDetection(value);
                              _loadSettings();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ==================== EMAIL PREFERENCES ====================
                      SettingsSection(
                        title: 'Email Preferences',
                        children: [
                          SettingsToggleTile(
                            icon: Icons.newspaper_rounded,
                            iconColor: Colors.blue,
                            iconBackgroundColor: Colors.blue.withValues(alpha: 0.1),
                            title: 'Newsletter Digest',
                            subtitle: 'Bundle newsletters together',
                            value: _settings.newsletterDigestEnabled,
                            onChanged: (value) async {
                              _triggerHaptic();
                              await _storage.setNewsletterDigest(value);
                              _loadSettings();
                            },
                          ),
                          SettingsSelectorTile(
                            icon: Icons.sync_rounded,
                            iconColor: Colors.teal,
                            iconBackgroundColor: Colors.teal.withValues(alpha: 0.1),
                            title: 'Sync Frequency',
                            subtitle: 'How often to check for new emails',
                            value: _settings.syncFrequencyLabel,
                            onTap: _showSyncFrequencySelector,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ==================== PRIVACY ====================
                      SettingsSection(
                        title: 'Privacy',
                        children: [
                          SettingsSelectorTile(
                            icon: Icons.shield_rounded,
                            iconColor: Colors.green,
                            iconBackgroundColor: Colors.green.withValues(alpha: 0.1),
                            title: 'Privacy Mode',
                            subtitle: _settings.privacyModeDescription,
                            value: _settings.privacyModeLabel,
                            onTap: _showPrivacyModeSelector,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ==================== SENDER MANAGEMENT ====================
                      SettingsSection(
                        title: 'Sender Management',
                        children: [
                          SettingsCountTile(
                            icon: Icons.star_rounded,
                            iconColor: AppColors.accentYellow,
                            iconBackgroundColor: AppColors.accentYellow
                                .withValues(alpha: 0.15),
                            title: 'VIP Senders',
                            subtitle: 'Always prioritize these senders',
                            count: _settings.vipSenders.length,
                            onTap: () async {
                              _triggerHaptic();
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const VipSendersScreen(),
                                ),
                              );
                              _loadSettings();
                            },
                          ),
                          SettingsCountTile(
                            icon: Icons.volume_off_rounded,
                            iconColor: Colors.grey,
                            iconBackgroundColor: Colors.grey.withValues(alpha: 0.1),
                            title: 'Muted Senders',
                            subtitle: 'Route to Low Value bucket',
                            count: _settings.mutedSenders.length,
                            onTap: () async {
                              _triggerHaptic();
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MutedSendersScreen(),
                                ),
                              );
                              _loadSettings();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ==================== APP SETTINGS ====================
                      SettingsSection(
                        title: 'App',
                        children: [
                          SettingsSelectorTile(
                            icon: Icons.palette_rounded,
                            iconColor: Colors.indigo,
                            iconBackgroundColor: Colors.indigo.withValues(alpha: 0.1),
                            title: 'Theme',
                            subtitle: 'App appearance',
                            value: _settings.themeModeLabel,
                            onTap: _showThemeSelector,
                          ),
                          SettingsTile(
                            icon: Icons.notifications_active_rounded,
                            iconColor: Colors.pink,
                            iconBackgroundColor: Colors.pink.withValues(alpha: 0.1),
                            title: 'Notifications',
                            subtitle: 'Manage alerts & quiet hours',
                            showArrow: true,
                            onTap: () {
                              _triggerHaptic();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const NotificationSettingsScreen(),
                                ),
                              );
                            },
                          ),
                          SettingsSelectorTile(
                            icon: Icons.tab_rounded,
                            iconColor: Colors.cyan,
                            iconBackgroundColor: Colors.cyan.withValues(alpha: 0.1),
                            title: 'Default Tab',
                            subtitle: 'Tab shown when app opens',
                            value: _settings.defaultTabLabel,
                            onTap: _showDefaultTabSelector,
                          ),
                          SettingsToggleTile(
                            icon: Icons.vibration_rounded,
                            iconColor: Colors.pink,
                            iconBackgroundColor: Colors.pink.withValues(alpha: 0.1),
                            title: 'Haptic Feedback',
                            subtitle: 'Vibration on actions',
                            value: _settings.hapticFeedbackEnabled,
                            onChanged: (value) async {
                              if (value) HapticFeedback.lightImpact();
                              await _storage.setHapticFeedback(value);
                              _loadSettings();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ==================== LEGAL ====================
                      SettingsSection(
                        title: 'Legal',
                        children: [
                          SettingsTile(
                            icon: Icons.privacy_tip_outlined,
                            iconColor: Colors.blueGrey,
                            iconBackgroundColor: Colors.blueGrey.withValues(alpha: 
                              0.1,
                            ),
                            title: 'Privacy Policy',
                            showArrow: true,
                            onTap: () {
                              _triggerHaptic();
                              _launchUrl('https://yourapp.com/privacy');
                            },
                          ),
                          SettingsTile(
                            icon: Icons.description_outlined,
                            iconColor: Colors.blueGrey,
                            iconBackgroundColor: Colors.blueGrey.withValues(alpha: 
                              0.1,
                            ),
                            title: 'Terms of Service',
                            showArrow: true,
                            onTap: () {
                              _triggerHaptic();
                              _launchUrl('https://yourapp.com/terms');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ==================== SUPPORT ====================
                      SettingsSection(
                        title: 'Support',
                        children: [
                          SettingsTile(
                            icon: Icons.star_rate_rounded,
                            iconColor: Colors.amber,
                            iconBackgroundColor: Colors.amber.withValues(alpha: 0.1),
                            title: 'Rate Inboxie',
                            subtitle: 'Love the app? Let us know!',
                            showArrow: true,
                            onTap: _showRateDialog,
                          ),
                          SettingsTile(
                            icon: Icons.feedback_rounded,
                            iconColor: Colors.teal,
                            iconBackgroundColor: Colors.teal.withValues(alpha: 0.1),
                            title: 'Send Feedback',
                            subtitle: 'Report a bug or suggest features',
                            showArrow: true,
                            onTap: _showFeedbackDialog,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ==================== ABOUT ====================
                      SettingsSection(
                        title: 'About',
                        children: [
                          SettingsTile(
                            icon: Icons.info_outline_rounded,
                            title: 'Version',
                            trailing: Text(
                              _appVersion.isNotEmpty ? _appVersion : '...',
                              style: TextStyle(
                                color: AppColors.getTextSecondary(context),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ==================== DATA & ACCOUNT ====================
                      SettingsSection(
                        title: 'Data & Account',
                        children: [
                          SettingsTile(
                            icon: Icons.cleaning_services_rounded,
                            iconColor: Colors.orange,
                            iconBackgroundColor: Colors.orange.withValues(alpha: 0.1),
                            title: 'Clear Local Data',
                            subtitle: 'Delete cached emails',
                            showArrow: true,
                            onTap: _clearLocalData,
                          ),
                          SettingsTile(
                            icon: Icons.logout_rounded,
                            title: 'Sign Out',
                            subtitle: 'Disconnect from Gmail',
                            isDestructive: true,
                            showArrow: true,
                            onTap: _signOut,
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Footer
                      Text(
                        'Made with ❤️ for your inbox',
                        style: TextStyle(
                          color: AppColors.getTextSecondary(context),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _showRateDialog() {
    _triggerHaptic();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getSurface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Enjoying Inboxie?',
          style: TextStyle(color: AppColors.getTextPrimary(context)),
        ),
        content: Text(
          'If you love using Inboxie, please take a moment to rate us on the App Store. It helps us a lot!',
          style: TextStyle(color: AppColors.getTextSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Not now',
              style: TextStyle(color: AppColors.getTextSecondary(context)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // In a real app, integrate launch_review or similar package
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you for rating!')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.primaryBlue),
            child: const Text('Rate Now'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    _triggerHaptic();
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getSurface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Send Feedback',
          style: TextStyle(color: AppColors.getTextPrimary(context)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'We read every piece of feedback. Let us know how we can improve.',
              style: TextStyle(
                color: AppColors.getTextSecondary(context),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              style: TextStyle(color: AppColors.getTextPrimary(context)),
              decoration: InputDecoration(
                hintText: 'Your thoughts...',
                hintStyle: TextStyle(
                  color: AppColors.getTextSecondary(context),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primaryBlue,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.getTextSecondary(context)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feedback sent! Thank you.')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.primaryBlue),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

// ==================== REUSABLE SELECTOR SHEET ====================

class _SelectorSheet<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<T> options;
  final T selectedOption;
  final String Function(T) labelBuilder;
  final String Function(T)? subtitleBuilder;
  final IconData Function(T)? iconBuilder;
  final Function(T) onSelect;

  const _SelectorSheet({
    required this.title,
    this.subtitle,
    required this.options,
    required this.selectedOption,
    required this.labelBuilder,
    this.subtitleBuilder,
    this.iconBuilder,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.getTextPrimary(context),
            ),
          ),

          // Subtitle
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getTextSecondary(context),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Options
          ...options.map((option) {
            final isSelected = option == selectedOption;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: isSelected
                    ? AppColors.primaryBlue.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    onSelect(option);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : (isDark
                                  ? Colors.white24
                                  : Colors.grey.withValues(alpha: 0.2)),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Icon (if provided)
                        if (iconBuilder != null) ...[
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryBlue.withValues(alpha: 0.1)
                                  : (isDark
                                        ? Colors.white12
                                        : Colors.grey.withValues(alpha: 0.1)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              iconBuilder!(option),
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : (isDark ? Colors.white70 : Colors.grey),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],

                        // Label and subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                labelBuilder(option),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: AppColors.getTextPrimary(context),
                                ),
                              ),
                              if (subtitleBuilder != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  subtitleBuilder!(option),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.getTextSecondary(context),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Check mark (if selected)
                        if (isSelected)
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryBlue,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
