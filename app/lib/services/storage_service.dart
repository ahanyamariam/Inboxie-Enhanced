import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/models/user_settings_model.dart';
import 'package:app/models/usage_stats_model.dart';
import 'package:app/models/notification_settings_model.dart';
import 'package:app/models/label_config_model.dart';
import 'package:app/models/bucket_config_model.dart';
import 'package:app/models/email_label_model.dart';


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
      version: 10,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT,
            displayName TEXT,
            photoUrl TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE user_metadata (
            user_id INTEGER PRIMARY KEY,
            lastSyncTimestamp INTEGER,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE threads (
            thread_id TEXT PRIMARY KEY,
            user_id INTEGER,
            subject TEXT,
            lastUpdatedTimestamp INTEGER,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE emails (
            id TEXT PRIMARY KEY,
            thread_id TEXT,
            senderName TEXT,
            senderEmail TEXT,
            subject TEXT,
            snippet TEXT,
            timestamp INTEGER,
            bucket TEXT DEFAULT 'inbox',
            label TEXT DEFAULT 'personal',
            priorityScore INTEGER DEFAULT 0,
            priorityLabel TEXT DEFAULT 'low',
            isActionable INTEGER DEFAULT 0,
            isRead INTEGER DEFAULT 0,
            status TEXT DEFAULT 'open',
            syncedAt INTEGER,
            signals TEXT DEFAULT '[]',
            aiSummary TEXT,
            replySuggestions TEXT,
            FOREIGN KEY (thread_id) REFERENCES threads(thread_id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE attachments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email_id TEXT,
            fileName TEXT,
            mimeType TEXT,
            sizeBytes INTEGER,
            FOREIGN KEY (email_id) REFERENCES emails(id) ON DELETE CASCADE
          )
        ''');

        print('Database tables created (v10 — normalized schema)!');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // ──────────────────────────────────────
        // Legacy migrations (v2–v9) for users
        // who haven't updated in a while
        // ──────────────────────────────────────
        if (oldVersion < 2) {
          try { await db.execute("ALTER TABLE emails ADD COLUMN priorityLabel TEXT"); } catch (_) {}
        }
        if (oldVersion < 4) {
          try { await db.execute("ALTER TABLE emails ADD COLUMN signals TEXT DEFAULT '[]'"); } catch (_) {}
        }
        if (oldVersion < 6) {
          try { await db.execute("ALTER TABLE emails ADD COLUMN label TEXT DEFAULT 'personal'"); } catch (_) {}
        }
        if (oldVersion < 9) {
          try { await db.execute("ALTER TABLE emails ADD COLUMN aiSummary TEXT"); } catch (_) {}
          try { await db.execute("ALTER TABLE emails ADD COLUMN replySuggestions TEXT"); } catch (_) {}
        }

        // ──────────────────────────────────────
        // v10: FULL SCHEMA REORGANIZATION
        // ──────────────────────────────────────
        if (oldVersion < 10) {
          print('v10 migration: Starting schema reorganization...');

          // 1. Create new tables
          await db.execute('''
            CREATE TABLE IF NOT EXISTS users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              email TEXT,
              displayName TEXT,
              photoUrl TEXT
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS user_metadata (
              user_id INTEGER PRIMARY KEY,
              lastSyncTimestamp INTEGER,
              FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS threads (
              thread_id TEXT PRIMARY KEY,
              user_id INTEGER,
              subject TEXT,
              lastUpdatedTimestamp INTEGER,
              FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS attachments (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              email_id TEXT,
              fileName TEXT,
              mimeType TEXT,
              sizeBytes INTEGER,
              FOREIGN KEY (email_id) REFERENCES emails(id) ON DELETE CASCADE
            )
          ''');

          // 2. Migrate user_profile → users + user_metadata
          try {
            final profiles = await db.query('user_profile');
            for (var profile in profiles) {
              final userId = await db.insert('users', {
                'email': profile['email'],
                'displayName': profile['displayName'],
                'photoUrl': profile['photoUrl'],
              });
              await db.insert('user_metadata', {
                'user_id': userId,
                'lastSyncTimestamp': profile['lastSyncTimestamp'],
              });
            }
            await db.execute('DROP TABLE IF EXISTS user_profile');
            print('v10: Migrated ${profiles.length} user profiles → users + user_metadata');
          } catch (e) {
            print('v10: user_profile migration skipped ($e)');
          }

          // 3. Populate threads from existing emails
          try {
            final emails = await db.query('emails');
            final seenThreads = <String>{};
            for (var email in emails) {
              final threadId = (email['threadId'] as String?) ?? (email['thread_id'] as String?) ?? '';
              if (threadId.isNotEmpty && seenThreads.add(threadId)) {
                await db.insert('threads', {
                  'thread_id': threadId,
                  'subject': email['subject'] ?? '',
                  'lastUpdatedTimestamp': email['timestamp'] ?? 0,
                }, conflictAlgorithm: ConflictAlgorithm.ignore);
              }
            }
            print('v10: Created ${seenThreads.length} thread records');
          } catch (e) {
            print('v10: Thread population skipped ($e)');
          }

          // 4. Rename threadId → thread_id in emails table
          try {
            await db.execute('''
              CREATE TABLE emails_new (
                id TEXT PRIMARY KEY,
                thread_id TEXT,
                senderName TEXT,
                senderEmail TEXT,
                subject TEXT,
                snippet TEXT,
                timestamp INTEGER,
                bucket TEXT DEFAULT 'inbox',
                label TEXT DEFAULT 'personal',
                priorityScore INTEGER DEFAULT 0,
                priorityLabel TEXT DEFAULT 'low',
                isActionable INTEGER DEFAULT 0,
                isRead INTEGER DEFAULT 0,
                status TEXT DEFAULT 'open',
                syncedAt INTEGER,
                signals TEXT DEFAULT '[]',
                aiSummary TEXT,
                replySuggestions TEXT,
                FOREIGN KEY (thread_id) REFERENCES threads(thread_id) ON DELETE CASCADE
              )
            ''');
            await db.execute('''
              INSERT INTO emails_new (id, thread_id, senderName, senderEmail, subject, snippet, timestamp, bucket, label, priorityScore, priorityLabel, isActionable, isRead, status, syncedAt, signals, aiSummary, replySuggestions)
              SELECT id, threadId, senderName, senderEmail, subject, snippet, timestamp, bucket, label, priorityScore, priorityLabel, isActionable, isRead, status, syncedAt, signals, aiSummary, replySuggestions
              FROM emails
            ''');
            await db.execute('DROP TABLE emails');
            await db.execute('ALTER TABLE emails_new RENAME TO emails');
            print('v10: Migrated emails table (threadId → thread_id)');
          } catch (e) {
            print('v10: Emails table migration skipped ($e)');
          }

          print('v10 migration: Schema reorganization complete!');
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
    // Upsert into users table
    await db.delete('users');
    await db.delete('user_metadata');
    final userId = await db.insert('users', {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
    });
    await db.insert('user_metadata', {
      'user_id': userId,
      'lastSyncTimestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ==========================================
  // EMAIL SAVE METHODS
  // ==========================================

  Future<void> saveEmail(Map<String, dynamic> emailData) async {
    final db = await database;
    // Upsert thread
    final threadId = emailData['thread_id'] as String? ?? '';
    if (threadId.isNotEmpty) {
      await db.insert('threads', {
        'thread_id': threadId,
        'subject': emailData['subject'] ?? '',
        'lastUpdatedTimestamp': emailData['timestamp'] ?? 0,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await db.insert(
      'emails',
      emailData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveEmails(List<Map<String, dynamic>> emails) async {
    final db = await database;
    final batch = db.batch();
    // Upsert threads first
    final seenThreads = <String>{};
    for (var email in emails) {
      final threadId = email['thread_id'] as String? ?? '';
      if (threadId.isNotEmpty && seenThreads.add(threadId)) {
        batch.insert('threads', {
          'thread_id': threadId,
          'subject': email['subject'] ?? '',
          'lastUpdatedTimestamp': email['timestamp'] ?? 0,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      batch.insert('emails', email, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    try {
      await batch.commit(noResult: true);
      print('✅ Saved ${emails.length} emails to database');
    } catch (e) {
      print('❌ Batch save failed: $e');
      // Fallback: save one by one to identify the problematic email
      for (var email in emails) {
        try {
          await saveEmail(email);
        } catch (e2) {
          print('❌ Single save failed for ${email['id']}: $e2');
        }
      }
    }
  }

  // ==========================================
  // ATTACHMENT METHODS
  // ==========================================

  Future<void> saveAttachment({
    required String emailId,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
  }) async {
    final db = await database;
    await db.insert('attachments', {
      'email_id': emailId,
      'fileName': fileName,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
    });
  }

  Future<List<Map<String, dynamic>>> getAttachments(String emailId) async {
    final db = await database;
    return await db.query(
      'attachments',
      where: 'email_id = ?',
      whereArgs: [emailId],
    );
  }

  // ==========================================
  // EMAIL READ METHODS
  // ==========================================

  Future<List<Map<String, dynamic>>> getAllEmails() async {
    final db = await database;
    return await db.query(
      'emails',
      orderBy: 'timestamp DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getOpenEmails() async {
    final db = await database;
    return await db.query(
      'emails',
      where: 'status = ?',
      whereArgs: ['open'],
      orderBy: 'timestamp DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getHandledEmails() async {
    final db = await database;
    return await db.query(
      'emails',
      where: 'status = ?',
      whereArgs: ['handled'],
      orderBy: 'timestamp DESC',
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
    if (bucket == 'handled') {
      return await getHandledEmails();
    }

    final db = await database;
    return await db.query(
      'emails',
      where: 'bucket = ? AND status = ?',
      whereArgs: [bucket, 'open'],
      orderBy: 'timestamp DESC',
    );
  }

  Future<Map<String, int>> getBucketCounts() async {
    final db = await database;
    
    // Count open emails by bucket
    final openResults = await db.rawQuery(
      "SELECT bucket, COUNT(*) as count FROM emails WHERE status = 'open' GROUP BY bucket"
    );
    
    // Count total handled emails
    final handledResult = await db.rawQuery(
      "SELECT COUNT(*) as count FROM emails WHERE status = 'handled'"
    );

    final counts = <String, int>{};
    for (var row in openResults) {
      counts[row['bucket'] as String] = row['count'] as int;
    }
    
    if (handledResult.isNotEmpty) {
      counts['handled'] = handledResult.first['count'] as int;
    }
    
    return counts;
  }

  Future<List<Map<String, dynamic>>> getEmailsByLabel(String label) async {
    final db = await database;
    return await db.query(
      'emails',
      where: 'label = ?',
      whereArgs: [label],
      orderBy: 'timestamp DESC',
    );
  }

  Future<Map<String, int>> getLabelCounts() async {
    final db = await database;
    final results = await db.rawQuery(
      'SELECT label, COUNT(*) as count FROM emails GROUP BY label'
    );
    final counts = <String, int>{};
    for (var row in results) {
      final label = row['label'] as String? ?? 'personal';
      counts[label] = row['count'] as int;
    }
    return counts;
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

  Future<Map<String, dynamic>?> getEmailById(String id) async {
    final db = await database;
    final result = await db.query(
      'emails',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
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
    await db.update(
      'emails',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAsHandled(String id) async {
    final db = await database;
    await db.update(
      'emails',
      {'status': 'handled'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAsUnread(String id) async {
    final db = await database;
    await db.update('emails', {'isRead': 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateReadStatus(String id, bool isRead) async {
    final db = await database;
    await db.update('emails', {'isRead': isRead ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markAsDone(String id) async {
    final db = await database;
    await db.update('emails', {'status': 'done'}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateBucket(String id, String newBucket) async {
    final db = await database;
    await db.update('emails', {'bucket': newBucket}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateAiData(String id, {String? aiSummary, List<String>? replySuggestions}) async {
    final db = await database;
    final data = <String, dynamic>{};
    if (aiSummary != null) data['aiSummary'] = aiSummary;
    if (replySuggestions != null) data['replySuggestions'] = replySuggestions.join('||');
    if (data.isNotEmpty) {
      await db.update('emails', data, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<List<Map<String, dynamic>>> getEmailsWithoutSummary({int limit = 20}) async {
    final db = await database;
    return await db.query(
      'emails',
      where: 'aiSummary IS NULL',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
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

  // ==========================================
  // CUSTOM EMAIL LABELS
  // ==========================================

  List<EmailLabel> getCustomLabels() {
    final jsonStr = _prefs?.getString('custom_email_labels');
    if (jsonStr == null) return [];
    try {
      final list = json.decode(jsonStr) as List<dynamic>;
      return list.map((j) => EmailLabel.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Sync version for use during DB migration
  List<EmailLabel> _loadCustomLabelsSync() {
    return getCustomLabels();
  }

  Future<void> saveCustomLabels(List<EmailLabel> labels) async {
    final jsonStr = json.encode(labels.map((l) => l.toJson()).toList());
    await _prefs?.setString('custom_email_labels', jsonStr);
  }

  Future<void> addCustomLabel(EmailLabel label) async {
    final labels = getCustomLabels();
    // Don't add if ID already exists
    if (labels.any((l) => l.id == label.id)) return;
    labels.add(label);
    await saveCustomLabels(labels);
  }

  Future<void> removeCustomLabel(String labelId) async {
    final labels = getCustomLabels();
    labels.removeWhere((l) => l.id == labelId);
    await saveCustomLabels(labels);
  }

  Future<void> updateCustomLabel(EmailLabel updated) async {
    final labels = getCustomLabels();
    final index = labels.indexWhere((l) => l.id == updated.id);
    if (index >= 0) {
      labels[index] = updated;
      await saveCustomLabels(labels);
    }
  }

  SharedPreferences get prefs => _prefs!;
}