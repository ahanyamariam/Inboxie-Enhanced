import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/models/user_settings_model.dart';
import 'package:app/models/usage_stats_model.dart';
import 'package:app/models/notification_settings_model.dart';
import 'package:app/models/label_config_model.dart';
import 'package:app/models/bucket_config_model.dart';
import 'package:app/services/intelligence_service.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Database? _database;
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await database; // Trigger DB init
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'inboxie.db');

    print('═══════════════════════════════════════');
    print('DATABASE PATH: $path');
    print('═══════════════════════════════════════');

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE emails (
            id TEXT PRIMARY KEY,
            threadId TEXT,
            senderName TEXT,
            senderEmail TEXT,
            subject TEXT,
            snippet TEXT,
            timestamp INTEGER,
            bucket TEXT DEFAULT 'low',
            priorityScore INTEGER DEFAULT 0,
            priorityLabel TEXT DEFAULT 'low',
            isActionable INTEGER DEFAULT 0,
            isRead INTEGER DEFAULT 0,
            status TEXT DEFAULT 'open',
            syncedAt INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE user_profile (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT,
            displayName TEXT,
            photoUrl TEXT,
            lastSyncTimestamp INTEGER
          )
        ''');

        print('Database tables created (v2)!');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE emails ADD COLUMN priorityLabel TEXT");
          print('Migrated DB to v2: added priorityLabel column');

          // Backfill: re-score existing emails with the new engine
          final vipSenders = _prefs?.getStringList('vip_senders') ?? [];
          final existingEmails = await db.query('emails');
          for (var email in existingEmails) {
            final analysis = IntelligenceService.analyze(
              subject: (email['subject'] as String?) ?? '',
              snippet: (email['snippet'] as String?) ?? '',
              from: (email['senderEmail'] as String?) ?? '',
              vipSenders: vipSenders,
              emailTimestamp: (email['timestamp'] as int?) ?? 0,
            );
            await db.update(
              'emails',
              {
                'priorityScore': analysis['priorityScore'],
                'priorityLabel': analysis['priorityLabel'],
                'bucket': analysis['bucket'],
                'isActionable': analysis['isActionable'] ? 1 : 0,
              },
              where: 'id = ?',
              whereArgs: [email['id']],
            );
          }
          print('Backfilled ${existingEmails.length} emails with new priority scores');
        }
        if (oldVersion < 3) {
          // v3: Re-score all emails with the enhanced priority engine
          final vipSenders = _prefs?.getStringList('vip_senders') ?? [];
          final rows = await db.query('emails');
          for (var email in rows) {
            final analysis = IntelligenceService.analyze(
              subject: (email['subject'] as String?) ?? '',
              snippet: (email['snippet'] as String?) ?? '',
              from: (email['senderEmail'] as String?) ?? '',
              vipSenders: vipSenders,
              emailTimestamp: (email['timestamp'] as int?) ?? 0,
            );
            await db.update(
              'emails',
              {
                'priorityScore': analysis['priorityScore'],
                'priorityLabel': analysis['priorityLabel'],
                'bucket': analysis['bucket'],
                'isActionable': analysis['isActionable'] ? 1 : 0,
              },
              where: 'id = ?',
              whereArgs: [email['id']],
            );
          }
          print('v3 migration: Re-scored ${rows.length} emails with new priority engine');
        }
      },
    );
  }

  // ==========================================
  // USER METHODS
  // ==========================================

  Future<void> saveUserProfile({
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    final db = await database;
    await db.delete('user_profile');
    await db.insert('user_profile', {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'lastSyncTimestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ==========================================
  // EMAIL SAVE METHODS
  // ==========================================

  Future<void> saveEmail(Map<String, dynamic> emailData) async {
    final db = await database;
    await db.insert(
      'emails',
      emailData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveEmails(List<Map<String, dynamic>> emails) async {
    final db = await database;
    final batch = db.batch();
    for (var email in emails) {
      batch.insert('emails', email, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
    print('Saved ${emails.length} emails to database');
  }

  // ==========================================
  // EMAIL READ METHODS
  // ==========================================

  Future<List<Map<String, dynamic>>> getAllEmails() async {
    final db = await database;
    return await db.query(
      'emails',
      orderBy: 'priorityScore DESC, timestamp DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getActionableEmails() async {
    final db = await database;
    return await db.query(
      'emails',
      where: 'isActionable = ? AND status = ?',
      whereArgs: [1, 'open'],
      orderBy: 'priorityScore DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getEmailsByBucket(String bucket) async {
    final db = await database;
    return await db.query(
      'emails',
      where: 'bucket = ?',
      whereArgs: [bucket],
      orderBy: 'timestamp DESC',
    );
  }

  Future<bool> emailExists(String id) async {
    final db = await database;
    final result = await db.query(
      'emails',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<int> getEmailCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM emails');
    return result.first['count'] as int;
  }

  // ==========================================
  // EMAIL UPDATE METHODS
  // ==========================================

  Future<void> markAsRead(String id) async {
    final db = await database;
    await db.update('emails', {'isRead': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markAsDone(String id) async {
    final db = await database;
    await db.update('emails', {'status': 'done'}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateBucket(String id, String newBucket) async {
    final db = await database;
    await db.update('emails', {'bucket': newBucket}, where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // CLEAR METHODS
  // ==========================================

  Future<void> clearAllEmails() async {
    final db = await database;
    await db.delete('emails');
    print('All emails cleared');
  }

  Future<void> clearEmailCache() async {
    await clearAllEmails();
  }

  // ==========================================
  // SETTINGS & THEME (SharedPreferences)
  // ==========================================

  String getThemeMode() {
    return _prefs?.getString('theme_mode') ?? 'system';
  }

  Future<void> setThemeMode(String theme) async {
    await _prefs?.setString('theme_mode', theme);
  }

  UserSettingsModel loadSettings({
    String? email,
    String? displayName,
    String? photoUrl,
  }) {
    if (_prefs == null) return const UserSettingsModel();

    return UserSettingsModel(
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      prioritySensitivity: PrioritySensitivity.values[_prefs!.getInt('priority_sensitivity') ?? 1],
      smartDetectionEnabled: _prefs!.getBool('smart_detection') ?? true,
      privacyMode: PrivacyMode.values[_prefs!.getInt('privacy_mode') ?? 1],
      newsletterDigestEnabled: _prefs!.getBool('newsletter_digest') ?? true,
      syncFrequency: SyncFrequency.values[_prefs!.getInt('sync_frequency') ?? 1],
      themeMode: _prefs!.getString('theme_mode') ?? 'system',
      defaultTab: _prefs!.getString('default_tab') ?? 'action',
      hapticFeedbackEnabled: _prefs!.getBool('haptic_feedback') ?? true,
      vipSenders: _prefs!.getStringList('vip_senders') ?? [],
      mutedSenders: _prefs!.getStringList('muted_senders') ?? [],
    );
  }

  Future<void> setPrioritySensitivity(PrioritySensitivity value) async {
    await _prefs?.setInt('priority_sensitivity', value.index);
  }

  Future<void> setSmartDetection(bool value) async {
    await _prefs?.setBool('smart_detection', value);
  }

  Future<void> setPrivacyMode(PrivacyMode value) async {
    await _prefs?.setInt('privacy_mode', value.index);
  }

  Future<void> setNewsletterDigest(bool value) async {
    await _prefs?.setBool('newsletter_digest', value);
  }

  Future<void> setSyncFrequency(SyncFrequency value) async {
    await _prefs?.setInt('sync_frequency', value.index);
  }

  Future<void> setHapticFeedback(bool value) async {
    await _prefs?.setBool('haptic_feedback', value);
  }

  Future<void> setDefaultTab(String value) async {
    await _prefs?.setString('default_tab', value);
  }

  // ==========================================
  // VIP & MUTED SENDERS
  // ==========================================

  List<String> getVipSenders() {
    return _prefs?.getStringList('vip_senders') ?? [];
  }

  Future<void> addVipSender(String email) async {
    final list = getVipSenders();
    if (!list.contains(email)) {
      list.add(email);
      await _prefs?.setStringList('vip_senders', list);
    }
  }

  Future<void> removeVipSender(String email) async {
    final list = getVipSenders();
    if (list.remove(email)) {
      await _prefs?.setStringList('vip_senders', list);
    }
  }

  List<String> getMutedSenders() {
    return _prefs?.getStringList('muted_senders') ?? [];
  }

  Future<void> addMutedSender(String email) async {
    final list = getMutedSenders();
    if (!list.contains(email)) {
      list.add(email);
      await _prefs?.setStringList('muted_senders', list);
    }
  }

  Future<void> removeMutedSender(String email) async {
    final list = getMutedSenders();
    if (list.remove(email)) {
      await _prefs?.setStringList('muted_senders', list);
    }
  }

  // ==========================================
  // USAGE STATS
  // ==========================================

  UsageStats getUsageStats() {
    final jsonStr = _prefs?.getString('usage_stats');
    if (jsonStr == null) return const UsageStats();
    try {
      return UsageStats.fromJson(json.decode(jsonStr));
    } catch (e) {
      return const UsageStats();
    }
  }

  Future<void> saveUsageStats(UsageStats stats) async {
    await _prefs?.setString('usage_stats', json.encode(stats.toJson()));
  }

  // ==========================================
  // NOTIFICATION SETTINGS
  // ==========================================

  NotificationSettings getNotificationSettings() {
    final jsonStr = _prefs?.getString('notification_settings');
    if (jsonStr == null) return const NotificationSettings();
    try {
      return NotificationSettings.fromJson(json.decode(jsonStr));
    } catch (e) {
      return const NotificationSettings();
    }
  }

  Future<void> setNotificationSettings(NotificationSettings settings) async {
    await _prefs?.setString('notification_settings', json.encode(settings.toJson()));
  }

  // ==========================================
  // LABEL CONFIG
  // ==========================================

  LabelConfig getLabelConfig() {
    final jsonStr = _prefs?.getString('label_config');
    if (jsonStr == null) return const LabelConfig();
    try {
      return LabelConfig.fromJson(json.decode(jsonStr));
    } catch (e) {
      return const LabelConfig();
    }
  }

  Future<void> _saveLabelConfig(LabelConfig config) async {
    await _prefs?.setString('label_config', json.encode(config.toJson()));
  }

  Future<void> updatePriorityLabel(String id, String label) async {
    final config = getLabelConfig();
    LabelConfig newConfig;
    switch (id.toLowerCase()) {
      case 'urgent':
        newConfig = config.copyWith(urgentLabel: label);
        break;
      case 'important':
        newConfig = config.copyWith(importantLabel: label);
        break;
      case 'low':
        newConfig = config.copyWith(lowLabel: label);
        break;
      default:
        return;
    }
    await _saveLabelConfig(newConfig);
  }

  Future<void> updatePriorityColor(String id, String hex) async {
    final config = getLabelConfig();
    LabelConfig newConfig;
    switch (id.toLowerCase()) {
      case 'urgent':
        newConfig = config.copyWith(urgentColor: hex);
        break;
      case 'important':
        newConfig = config.copyWith(importantColor: hex);
        break;
      case 'low':
        newConfig = config.copyWith(lowColor: hex);
        break;
      default:
        return;
    }
    await _saveLabelConfig(newConfig);
  }

  Future<void> updateActionLabel(String id, String label) async {
    final config = getLabelConfig();
    LabelConfig newConfig;
    switch (id.toLowerCase()) {
      case 'needs_reply':
        newConfig = config.copyWith(needsReplyLabel: label);
        break;
      case 'waiting':
        newConfig = config.copyWith(waitingLabel: label);
        break;
      case 'no_action':
        newConfig = config.copyWith(noActionLabel: label);
        break;
      default:
        return;
    }
    await _saveLabelConfig(newConfig);
  }

  Future<void> updateActionColor(String id, String hex) async {
    final config = getLabelConfig();
    LabelConfig newConfig;
    switch (id.toLowerCase()) {
      case 'needs_reply':
        newConfig = config.copyWith(needsReplyColor: hex);
        break;
      case 'waiting':
        newConfig = config.copyWith(waitingColor: hex);
        break;
      case 'no_action':
        newConfig = config.copyWith(noActionColor: hex);
        break;
      default:
        return;
    }
    await _saveLabelConfig(newConfig);
  }

  Future<void> resetLabelConfig() async {
    await _prefs?.remove('label_config');
  }

  // ==========================================
  // BUCKET CONFIG
  // ==========================================

  BucketConfig getBucketConfig() {
    final jsonStr = _prefs?.getString('bucket_config');
    if (jsonStr == null) return BucketConfig.defaults();
    try {
      return BucketConfig.fromJson(json.decode(jsonStr));
    } catch (e) {
      return BucketConfig.defaults();
    }
  }

  Future<void> _saveBucketConfig(BucketConfig config) async {
    await _prefs?.setString('bucket_config', json.encode(config.toJson()));
  }

  Future<void> reorderBuckets(int oldIndex, int newIndex) async {
    final config = getBucketConfig();
    final buckets = List<BucketItem>.from(config.sortedBuckets);
    
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = buckets.removeAt(oldIndex);
    buckets.insert(newIndex, item);

    // Update orders
    final updatedBuckets = <BucketItem>[];
    for (int i = 0; i < buckets.length; i++) {
      updatedBuckets.add(buckets[i].copyWith(order: i));
    }

    await _saveBucketConfig(BucketConfig(buckets: updatedBuckets));
  }

  Future<void> toggleBucketVisibility(String id) async {
    final config = getBucketConfig();
    final updatedBuckets = config.buckets.map((b) {
      if (b.id == id) {
        return b.copyWith(isVisible: !b.isVisible);
      }
      return b;
    }).toList();
    await _saveBucketConfig(BucketConfig(buckets: updatedBuckets));
  }

  Future<void> renameBucket(String id, String name) async {
    final config = getBucketConfig();
    final updatedBuckets = config.buckets.map((b) {
      if (b.id == id) {
        return b.copyWith(name: name);
      }
      return b;
    }).toList();
    await _saveBucketConfig(BucketConfig(buckets: updatedBuckets));
  }

  Future<void> updateBucketIcon(String id, String icon) async {
    final config = getBucketConfig();
    final updatedBuckets = config.buckets.map((b) {
      if (b.id == id) {
        return b.copyWith(icon: icon);
      }
      return b;
    }).toList();
    await _saveBucketConfig(BucketConfig(buckets: updatedBuckets));
  }

  Future<void> resetBucketConfig() async {
    await _prefs?.remove('bucket_config');
  }

  SharedPreferences get prefs => _prefs!;
}