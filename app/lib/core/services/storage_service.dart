import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/core/models/user_settings_model.dart';
import 'package:app/core/models/label_config_model.dart';
import 'package:app/core/models/bucket_config_model.dart';
import 'package:app/core/models/notification_settings_model.dart';
import 'package:app/core/models/usage_stats_model.dart';

class StorageService {
  // ==================== EXISTING KEYS ====================
  static const String _keyPrioritySensitivity = 'priority_sensitivity';
  static const String _keySmartDetection = 'smart_detection';
  static const String _keyPrivacyMode = 'privacy_mode';
  static const String _keyNewsletterDigest = 'newsletter_digest';
  static const String _keyAutoArchive = 'auto_archive';
  static const String _keySyncFrequency = 'sync_frequency';
  static const String _keyVipSenders = 'vip_senders';
  static const String _keyMutedSenders = 'muted_senders';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyDefaultTab = 'default_tab';
  static const String _keyHapticFeedback = 'haptic_feedback';

  // ==================== NEW KEYS FOR PHASE 3 ====================
  static const String _keyLabelConfig = 'label_config';
  static const String _keyBucketConfig = 'bucket_config';
  static const String _keyNotificationSettings = 'notification_settings';
  static const String _keyUsageStats = 'usage_stats';
  static const String _keyRateAppLastPrompt = 'rate_app_last_prompt';
  static const String _keyRateAppRated = 'rate_app_rated';
  static const String _keyRateAppDismissCount = 'rate_app_dismiss_count';
  static const String _keyRateAppActionCount = 'rate_app_action_count';

  SharedPreferences? _prefs;

  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  /// Initialize SharedPreferences - call this once at app startup
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance
  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ==================== PRIORITY SENSITIVITY ====================

  Future<void> setPrioritySensitivity(PrioritySensitivity value) async {
    await prefs.setString(_keyPrioritySensitivity, value.name);
  }

  PrioritySensitivity getPrioritySensitivity() {
    final value = prefs.getString(_keyPrioritySensitivity);
    if (value == null) return PrioritySensitivity.normal;
    return PrioritySensitivity.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PrioritySensitivity.normal,
    );
  }

  // ==================== SMART DETECTION ====================

  Future<void> setSmartDetection(bool value) async {
    await prefs.setBool(_keySmartDetection, value);
  }

  bool getSmartDetection() {
    return prefs.getBool(_keySmartDetection) ?? true;
  }

  // ==================== PRIVACY MODE ====================

  Future<void> setPrivacyMode(PrivacyMode value) async {
    await prefs.setString(_keyPrivacyMode, value.name);
  }

  PrivacyMode getPrivacyMode() {
    final value = prefs.getString(_keyPrivacyMode);
    if (value == null) return PrivacyMode.summary;
    return PrivacyMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PrivacyMode.summary,
    );
  }

  // ==================== NEWSLETTER DIGEST ====================

  Future<void> setNewsletterDigest(bool value) async {
    await prefs.setBool(_keyNewsletterDigest, value);
  }

  bool getNewsletterDigest() {
    return prefs.getBool(_keyNewsletterDigest) ?? true;
  }

  // ==================== AUTO ARCHIVE ====================

  Future<void> setAutoArchive(bool value) async {
    await prefs.setBool(_keyAutoArchive, value);
  }

  bool getAutoArchive() {
    return prefs.getBool(_keyAutoArchive) ?? false;
  }

  // ==================== SYNC FREQUENCY ====================

  Future<void> setSyncFrequency(SyncFrequency value) async {
    await prefs.setString(_keySyncFrequency, value.name);
  }

  SyncFrequency getSyncFrequency() {
    final value = prefs.getString(_keySyncFrequency);
    if (value == null) return SyncFrequency.fifteenMin;
    return SyncFrequency.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SyncFrequency.fifteenMin,
    );
  }

  // ==================== VIP SENDERS ====================

  Future<void> setVipSenders(List<String> senders) async {
    await prefs.setStringList(_keyVipSenders, senders);
  }

  List<String> getVipSenders() {
    return prefs.getStringList(_keyVipSenders) ?? [];
  }

  Future<void> addVipSender(String email) async {
    final senders = getVipSenders();
    if (!senders.contains(email.toLowerCase())) {
      senders.add(email.toLowerCase());
      await setVipSenders(senders);
    }
  }

  Future<void> removeVipSender(String email) async {
    final senders = getVipSenders();
    senders.remove(email.toLowerCase());
    await setVipSenders(senders);
  }

  bool isVipSender(String email) {
    return getVipSenders().contains(email.toLowerCase());
  }

  // ==================== MUTED SENDERS ====================

  Future<void> setMutedSenders(List<String> senders) async {
    await prefs.setStringList(_keyMutedSenders, senders);
  }

  List<String> getMutedSenders() {
    return prefs.getStringList(_keyMutedSenders) ?? [];
  }

  Future<void> addMutedSender(String email) async {
    final senders = getMutedSenders();
    if (!senders.contains(email.toLowerCase())) {
      senders.add(email.toLowerCase());
      await setMutedSenders(senders);
    }
  }

  Future<void> removeMutedSender(String email) async {
    final senders = getMutedSenders();
    senders.remove(email.toLowerCase());
    await setMutedSenders(senders);
  }

  bool isMutedSender(String email) {
    return getMutedSenders().contains(email.toLowerCase());
  }

  // ==================== THEME MODE ====================

  Future<void> setThemeMode(String value) async {
    await prefs.setString(_keyThemeMode, value);
  }

  String getThemeMode() {
    return prefs.getString(_keyThemeMode) ?? 'system';
  }

  // ==================== DEFAULT TAB ====================

  Future<void> setDefaultTab(String value) async {
    await prefs.setString(_keyDefaultTab, value);
  }

  String getDefaultTab() {
    return prefs.getString(_keyDefaultTab) ?? 'action';
  }

  // ==================== HAPTIC FEEDBACK ====================

  Future<void> setHapticFeedback(bool value) async {
    await prefs.setBool(_keyHapticFeedback, value);
  }

  bool getHapticFeedback() {
    return prefs.getBool(_keyHapticFeedback) ?? true;
  }

  // ==================== LOAD ALL SETTINGS ====================

  UserSettingsModel loadSettings({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
  }) {
    return UserSettingsModel(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      prioritySensitivity: getPrioritySensitivity(),
      smartDetectionEnabled: getSmartDetection(),
      privacyMode: getPrivacyMode(),
      newsletterDigestEnabled: getNewsletterDigest(),
      autoArchiveEnabled: getAutoArchive(),
      syncFrequency: getSyncFrequency(),
      vipSenders: getVipSenders(),
      mutedSenders: getMutedSenders(),
      themeMode: getThemeMode(),
      defaultTab: getDefaultTab(),
      hapticFeedbackEnabled: getHapticFeedback(),
    );
  }

  // ============================================================
  // ==================== PHASE 3: LABEL CONFIG =================
  // ============================================================

  Future<void> setLabelConfig(LabelConfig config) async {
    await prefs.setString(_keyLabelConfig, jsonEncode(config.toJson()));
  }

  LabelConfig getLabelConfig() {
    final jsonString = prefs.getString(_keyLabelConfig);
    if (jsonString == null) return const LabelConfig();
    try {
      return LabelConfig.fromJson(jsonDecode(jsonString));
    } catch (e) {
      return const LabelConfig();
    }
  }

  Future<void> updatePriorityLabel(String priority, String newLabel) async {
    final config = getLabelConfig();
    LabelConfig updated;
    switch (priority.toLowerCase()) {
      case 'urgent':
        updated = config.copyWith(urgentLabel: newLabel);
        break;
      case 'important':
        updated = config.copyWith(importantLabel: newLabel);
        break;
      case 'low':
        updated = config.copyWith(lowLabel: newLabel);
        break;
      default:
        return;
    }
    await setLabelConfig(updated);
  }

  Future<void> updateActionLabel(String action, String newLabel) async {
    final config = getLabelConfig();
    LabelConfig updated;
    switch (action.toLowerCase()) {
      case 'needs_reply':
        updated = config.copyWith(needsReplyLabel: newLabel);
        break;
      case 'waiting':
        updated = config.copyWith(waitingLabel: newLabel);
        break;
      case 'no_action':
        updated = config.copyWith(noActionLabel: newLabel);
        break;
      default:
        return;
    }
    await setLabelConfig(updated);
  }

  Future<void> updatePriorityColor(String priority, String hexColor) async {
    final config = getLabelConfig();
    LabelConfig updated;
    switch (priority.toLowerCase()) {
      case 'urgent':
        updated = config.copyWith(urgentColor: hexColor);
        break;
      case 'important':
        updated = config.copyWith(importantColor: hexColor);
        break;
      case 'low':
        updated = config.copyWith(lowColor: hexColor);
        break;
      default:
        return;
    }
    await setLabelConfig(updated);
  }

  Future<void> updateActionColor(String action, String hexColor) async {
    final config = getLabelConfig();
    LabelConfig updated;
    switch (action.toLowerCase()) {
      case 'needs_reply':
        updated = config.copyWith(needsReplyColor: hexColor);
        break;
      case 'waiting':
        updated = config.copyWith(waitingColor: hexColor);
        break;
      case 'no_action':
        updated = config.copyWith(noActionColor: hexColor);
        break;
      default:
        return;
    }
    await setLabelConfig(updated);
  }

  Future<void> resetLabelConfig() async {
    await setLabelConfig(const LabelConfig());
  }

  // ============================================================
  // ==================== PHASE 3: BUCKET CONFIG ================
  // ============================================================

  Future<void> setBucketConfig(BucketConfig config) async {
    await prefs.setString(_keyBucketConfig, jsonEncode(config.toJson()));
  }

  BucketConfig getBucketConfig() {
    final jsonString = prefs.getString(_keyBucketConfig);
    if (jsonString == null) return BucketConfig.defaults();
    try {
      final config = BucketConfig.fromJson(jsonDecode(jsonString));
      return config.buckets.isEmpty ? BucketConfig.defaults() : config;
    } catch (e) {
      return BucketConfig.defaults();
    }
  }

  Future<void> renameBucket(String bucketId, String newName) async {
    final config = getBucketConfig();
    final updatedBuckets = config.buckets.map((bucket) {
      if (bucket.id == bucketId) {
        return bucket.copyWith(name: newName);
      }
      return bucket;
    }).toList();
    await setBucketConfig(config.copyWith(buckets: updatedBuckets));
  }

  Future<void> updateBucketIcon(String bucketId, String iconName) async {
    final config = getBucketConfig();
    final updatedBuckets = config.buckets.map((bucket) {
      if (bucket.id == bucketId) {
        return bucket.copyWith(icon: iconName);
      }
      return bucket;
    }).toList();
    await setBucketConfig(config.copyWith(buckets: updatedBuckets));
  }

  Future<void> toggleBucketVisibility(String bucketId) async {
    final config = getBucketConfig();
    final updatedBuckets = config.buckets.map((bucket) {
      if (bucket.id == bucketId) {
        return bucket.copyWith(isVisible: !bucket.isVisible);
      }
      return bucket;
    }).toList();
    await setBucketConfig(config.copyWith(buckets: updatedBuckets));
  }

  Future<void> reorderBuckets(int oldIndex, int newIndex) async {
    final config = getBucketConfig();
    final buckets = List<BucketItem>.from(config.sortedBuckets);

    if (newIndex > oldIndex) newIndex--;

    final item = buckets.removeAt(oldIndex);
    buckets.insert(newIndex, item);

    // Update order values
    final updatedBuckets = buckets.asMap().entries.map((entry) {
      return entry.value.copyWith(order: entry.key);
    }).toList();

    await setBucketConfig(config.copyWith(buckets: updatedBuckets));
  }

  Future<void> resetBucketConfig() async {
    await setBucketConfig(BucketConfig.defaults());
  }

  // ============================================================
  // =============== PHASE 3: NOTIFICATION SETTINGS =============
  // ============================================================

  Future<void> setNotificationSettings(NotificationSettings settings) async {
    await prefs.setString(
        _keyNotificationSettings, jsonEncode(settings.toJson()));
  }

  NotificationSettings getNotificationSettings() {
    final jsonString = prefs.getString(_keyNotificationSettings);
    if (jsonString == null) return const NotificationSettings();
    try {
      return NotificationSettings.fromJson(jsonDecode(jsonString));
    } catch (e) {
      return const NotificationSettings();
    }
  }

  Future<void> updateNotificationSetting({
    bool? enabled,
    bool? urgentEmails,
    bool? importantEmails,
    bool? lowPriorityEmails,
    bool? needsActionReminders,
    bool? waitingFollowUps,
    bool? deadlineReminders,
    int? reminderFrequencyHours,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? dailyDigestEnabled,
    String? dailyDigestTime,
  }) async {
    final current = getNotificationSettings();
    final updated = current.copyWith(
      enabled: enabled,
      urgentEmails: urgentEmails,
      importantEmails: importantEmails,
      lowPriorityEmails: lowPriorityEmails,
      needsActionReminders: needsActionReminders,
      waitingFollowUps: waitingFollowUps,
      deadlineReminders: deadlineReminders,
      reminderFrequencyHours: reminderFrequencyHours,
      quietHoursEnabled: quietHoursEnabled,
      quietHoursStart: quietHoursStart,
      quietHoursEnd: quietHoursEnd,
      soundEnabled: soundEnabled,
      vibrationEnabled: vibrationEnabled,
      dailyDigestEnabled: dailyDigestEnabled,
      dailyDigestTime: dailyDigestTime,
    );
    await setNotificationSettings(updated);
  }

  Future<void> resetNotificationSettings() async {
    await setNotificationSettings(const NotificationSettings());
  }

  // ============================================================
  // ==================== PHASE 3: USAGE STATS ==================
  // ============================================================

  Future<void> setUsageStats(UsageStats stats) async {
    await prefs.setString(_keyUsageStats, jsonEncode(stats.toJson()));
  }

  UsageStats getUsageStats() {
    final jsonString = prefs.getString(_keyUsageStats);
    if (jsonString == null) {
      // Initialize with first used time
      final initial = UsageStats(firstUsed: DateTime.now());
      setUsageStats(initial);
      return initial;
    }
    try {
      return UsageStats.fromJson(jsonDecode(jsonString));
    } catch (e) {
      return UsageStats(firstUsed: DateTime.now());
    }
  }

  Future<void> incrementStat(String statName, [int amount = 1]) async {
    final stats = getUsageStats();
    final json = stats.toJson();
    json[statName] = (json[statName] as int? ?? 0) + amount;
    await setUsageStats(UsageStats.fromJson(json));
  }

  Future<void> incrementRepliesSent() async {
    await incrementStat('repliesSent');
    await incrementStat('minutesSaved', 3); // Estimate: 3 mins saved per reply
    await _incrementDailyAction();
  }

  Future<void> incrementSnoozed() async {
    await incrementStat('emailsSnoozed');
    await incrementStat('minutesSaved', 1);
    await _incrementDailyAction();
  }

  Future<void> incrementMarkedDone() async {
    await incrementStat('emailsMarkedDone');
    await incrementStat('minutesSaved', 2);
    await _incrementDailyAction();
  }

  Future<void> incrementEmailsProcessed([int count = 1]) async {
    await incrementStat('totalEmailsProcessed', count);
  }

  Future<void> incrementNeedsActionSurfaced([int count = 1]) async {
    await incrementStat('needsActionSurfaced', count);
  }

  Future<void> incrementNewslettersFiltered([int count = 1]) async {
    await incrementStat('newslettersFiltered', count);
    await incrementStat('minutesSaved', count);
  }

  Future<void> incrementLowValueFiltered([int count = 1]) async {
    await incrementStat('lowValueFiltered', count);
  }

  Future<void> incrementDeadlinesDetected() async {
    await incrementStat('deadlinesDetected');
  }

  Future<void> incrementQuestionsDetected() async {
    await incrementStat('questionsDetected');
  }

  Future<void> updateLastSync() async {
    final stats = getUsageStats();
    await setUsageStats(stats.copyWith(lastSync: DateTime.now()));
  }

  Future<void> _incrementDailyAction() async {
    final stats = getUsageStats();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final dailyActions = Map<String, int>.from(stats.dailyActions);
    dailyActions[today] = (dailyActions[today] ?? 0) + 1;
    await setUsageStats(stats.copyWith(dailyActions: dailyActions));
  }

  Future<void> resetUsageStats() async {
    await setUsageStats(UsageStats(firstUsed: DateTime.now()));
  }

  // ============================================================
  // ==================== PHASE 3: RATE APP =====================
  // ============================================================

  Future<void> setRateAppRated(bool value) async {
    await prefs.setBool(_keyRateAppRated, value);
  }

  bool getRateAppRated() {
    return prefs.getBool(_keyRateAppRated) ?? false;
  }

  Future<void> setRateAppLastPrompt(int timestamp) async {
    await prefs.setInt(_keyRateAppLastPrompt, timestamp);
  }

  int? getRateAppLastPrompt() {
    return prefs.getInt(_keyRateAppLastPrompt);
  }

  Future<void> incrementRateAppDismissCount() async {
    final count = prefs.getInt(_keyRateAppDismissCount) ?? 0;
    await prefs.setInt(_keyRateAppDismissCount, count + 1);
  }

  int getRateAppDismissCount() {
    return prefs.getInt(_keyRateAppDismissCount) ?? 0;
  }

  Future<void> incrementRateAppActionCount() async {
    final count = prefs.getInt(_keyRateAppActionCount) ?? 0;
    await prefs.setInt(_keyRateAppActionCount, count + 1);
  }

  int getRateAppActionCount() {
    return prefs.getInt(_keyRateAppActionCount) ?? 0;
  }

  Future<void> resetRateAppData() async {
    await prefs.remove(_keyRateAppRated);
    await prefs.remove(_keyRateAppLastPrompt);
    await prefs.remove(_keyRateAppDismissCount);
    await prefs.remove(_keyRateAppActionCount);
  }

  // ============================================================
  // ==================== CLEAR ALL DATA ========================
  // ============================================================

  Future<void> clearAllData() async {
    await prefs.clear();
  }

  /// Clear only email-related cached data (not settings)
  Future<void> clearEmailCache() async {
    // Add keys for email cache here when you implement caching
    // For now, this is a placeholder
  }

  // ============================================================
  // ==================== RESET TO DEFAULTS =====================
  // ============================================================

  Future<void> resetToDefaults() async {
    // Original settings
    await setPrioritySensitivity(PrioritySensitivity.normal);
    await setSmartDetection(true);
    await setPrivacyMode(PrivacyMode.summary);
    await setNewsletterDigest(true);
    await setAutoArchive(false);
    await setSyncFrequency(SyncFrequency.fifteenMin);
    await setVipSenders([]);
    await setMutedSenders([]);
    await setThemeMode('system');
    await setDefaultTab('action');
    await setHapticFeedback(true);

    // Phase 3 settings
    await resetLabelConfig();
    await resetBucketConfig();
    await resetNotificationSettings();
    // Note: We don't reset usage stats on defaults reset
  }

  // ============================================================
  // ==================== PHASE 3 HELPER GETTERS ================
  // ============================================================

  /// Get the count of customized labels (non-default)
  int getCustomizedLabelCount() {
    final config = getLabelConfig();
    final defaults = const LabelConfig();
    int count = 0;

    if (config.urgentLabel != defaults.urgentLabel) count++;
    if (config.importantLabel != defaults.importantLabel) count++;
    if (config.lowLabel != defaults.lowLabel) count++;
    if (config.needsReplyLabel != defaults.needsReplyLabel) count++;
    if (config.waitingLabel != defaults.waitingLabel) count++;
    if (config.noActionLabel != defaults.noActionLabel) count++;

    return count;
  }

  /// Get the count of visible buckets
  int getVisibleBucketCount() {
    return getBucketConfig().visibleBuckets.length;
  }

  /// Check if notifications are enabled
  bool areNotificationsEnabled() {
    return getNotificationSettings().enabled;
  }

  /// Get formatted time saved string
  String getFormattedTimeSaved() {
    return getUsageStats().formattedTimeSaved;
  }

  /// Check if should show rate app prompt
  bool shouldShowRateAppPrompt() {
    // Already rated
    if (getRateAppRated()) return false;

    // Too many dismissals (max 3)
    if (getRateAppDismissCount() >= 3) return false;

    // Not enough actions yet (min 10)
    if (getRateAppActionCount() < 10) return false;

    // Check if enough time has passed since last prompt (14 days)
    final lastPrompt = getRateAppLastPrompt();
    if (lastPrompt != null) {
      final daysSincePrompt =
          DateTime.now().millisecondsSinceEpoch - lastPrompt;
      if (daysSincePrompt < 14 * 24 * 60 * 60 * 1000) return false;
    }

    return true;
  }
}