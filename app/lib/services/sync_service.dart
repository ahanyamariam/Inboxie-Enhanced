import 'package:app/services/gmail_service.dart';
import 'package:app/services/storage_service.dart';
import 'package:app/services/intelligence_service.dart';
import 'package:app/services/ai_service.dart';
import 'package:app/models/user_settings_model.dart';
import 'package:app/models/usage_stats_model.dart';

class SyncService {
  final GmailService _gmail;
  final StorageService _storage = StorageService();
  final AIService? _ai;

  SyncService({required String accessToken, AIService? aiService})
      : _gmail = GmailService(accessToken: accessToken),
        _ai = aiService;

  // TIER 1: Quick Sync (first load)
  Future<int> quickSync() async {
    print('TIER 1: Quick Sync...');
    return await _syncEmails(maxResults: 20);
  }

  // TIER 2: Background Sync
  Future<int> backgroundSync() async {
    print('TIER 2: Background Sync...');
    return await _syncEmails(maxResults: 50);
  }

  // TIER 3: Refresh (pull down)
  Future<int> refreshSync() async {
    print('TIER 3: Refresh Sync...');
    return await _syncEmails(maxResults: 10);
  }

  // TIER 4: Deep Sync (load more)
  Future<int> deepSync() async {
    print('TIER 4: Deep Sync...');
    return await _syncEmails(maxResults: 100);
  }

  // CORE ENGINE
  Future<int> _syncEmails({required int maxResults}) async {
    try {
      // 1. Fetch from Gmail
      final messageList = await _gmail.fetchMessages(maxResults: maxResults);
      print('Found ${messageList.length} messages from Gmail');

      if (messageList.isEmpty) return 0;

      // 2. Load VIP senders, muted senders, priority sensitivity, and custom labels
      final vipSenders = _storage.getVipSenders();
      final mutedSenders = _storage.getMutedSenders();
      final settings = _storage.loadSettings();
      final prioritySensitivity = settings.prioritySensitivity;
      final smartDetectionEnabled = settings.smartDetectionEnabled;
      final customLabels = _storage.getCustomLabels();

      // 3. Process each message
      List<Map<String, dynamic>> processedEmails = [];
      int processed = 0;
      int skipped = 0;

      for (var msg in messageList) {
        final messageId = msg['id'] as String;
        final threadId = msg['threadId'] as String? ?? '';

        try {
          // 4. Fetch metadata from Gmail (needed for read status and content)
          final metadata = await _gmail.fetchMessageMetadata(messageId);

          // 5. Parse labelIds and read state
          final labelIds = (metadata['labelIds'] as List<dynamic>?) ?? [];
          final isRead = !labelIds.contains('UNREAD');

          // 3. Update existing email if it's already in DB
          final exists = await _storage.emailExists(messageId);
          if (exists) {
            await _storage.updateReadStatus(messageId, isRead);
            skipped++;
            continue;
          }

          // 6. Parse headers
          String subject = '';
          String from = '';
          String senderEmail = '';
          final headers = metadata['payload']?['headers'] as List<dynamic>? ?? [];

          for (var header in headers) {
            if (header['name'] == 'Subject') subject = header['value'] ?? '';
            if (header['name'] == 'From') from = header['value'] ?? '';
          }

          String senderName = from;
          if (from.contains('<')) {
            senderName = from.split('<')[0].trim();
            senderEmail = from.split('<')[1].replaceAll('>', '').trim();
          } else {
            senderEmail = from;
          }

          final snippet = metadata['snippet'] ?? '';
          final internalDate = int.parse(metadata['internalDate'] ?? '0');

          // 7. Run Priority Scoring Engine with label classification
          final analysis = IntelligenceService.analyze(
            subject: subject,
            snippet: snippet,
            from: from,
            vipSenders: vipSenders,
            mutedSenders: mutedSenders,
            prioritySensitivity: prioritySensitivity,
            emailTimestamp: internalDate,
            customLabels: customLabels,
          );

          // 8. Add to batch
          processedEmails.add({
            'id': messageId,
            'thread_id': threadId,
            'senderName': senderName.isEmpty ? 'Unknown' : senderName,
            'senderEmail': senderEmail,
            'subject': subject.isEmpty ? '(No Subject)' : subject,
            'snippet': snippet,
            'timestamp': internalDate,
            'bucket': analysis['bucket'],
            'label': analysis['label'],
            'priorityScore': analysis['priorityScore'],
            'priorityLabel': analysis['priorityLabel'],
            'isActionable': analysis['isActionable'] ? 1 : 0,
            'isRead': isRead ? 1 : 0,
            'status': 'open',
            'syncedAt': DateTime.now().millisecondsSinceEpoch,
            'signals': (analysis['signals'] as List<String>).join('||'),
          });

          processed++;
          print('✅ $subject → ${analysis['label']} / ${analysis['priorityLabel'].toString().toUpperCase()} (${analysis['priorityScore']})');
        } catch (e) {
          print('❌ Error: $messageId - $e');
          continue;
        }
      }

      // 8. Batch save
      if (processedEmails.isNotEmpty) {
        await _storage.saveEmails(processedEmails);
      }

      // 9. Generate AI summaries (non-blocking, after save) — only if smart detection is ON
      final ai = _ai;
      if (ai != null && ai.isConfigured && smartDetectionEnabled && processedEmails.isNotEmpty) {
        _generateAiSummaries(ai, processedEmails);
      } else if (!smartDetectionEnabled) {
        print('🤖 Smart Detection disabled — skipping AI summaries');
      }

      // 10. Update usage stats
      if (processed > 0) {
        _updateUsageStats(processedEmails);
      }

      final total = await _storage.getEmailCount();
      print('═══════════════════════════════════');
      print('New: $processed | Skipped: $skipped | Total in DB: $total');
      print('═══════════════════════════════════');

      return processed;
    } catch (e) {
      print('Sync Error: $e');
      rethrow;
    }
  }

  /// Update usage stats after a successful sync.
  void _updateUsageStats(List<Map<String, dynamic>> emails) {
    try {
      final stats = _storage.getUsageStats();

      int needsAction = 0;
      int newsletters = 0;
      int deadlines = 0;

      for (var email in emails) {
        final bucket = email['bucket'] as String? ?? '';
        final signals = email['signals'] as String? ?? '';

        if (bucket == 'needs_reply') needsAction++;
        if (bucket == 'promotions' || signals.contains('Promotional')) newsletters++;
        if (bucket == 'events' || signals.contains('Calendar')) deadlines++;
      }

      final updated = stats.copyWith(
        totalEmailsProcessed: stats.totalEmailsProcessed + emails.length,
        needsActionSurfaced: stats.needsActionSurfaced + needsAction,
        newslettersFiltered: stats.newslettersFiltered + newsletters,
        deadlinesDetected: stats.deadlinesDetected + deadlines,
        minutesSaved: stats.minutesSaved + emails.length, // ~1 min per email
        firstUsed: stats.firstUsed ?? DateTime.now(),
        lastSync: DateTime.now(),
      );

      _storage.saveUsageStats(updated);
      print('📊 Usage stats updated: +${emails.length} processed, +$needsAction actions, +$newsletters newsletters');
    } catch (e) {
      print('📊 Usage stats update failed: $e');
    }
  }

  /// Generate AI summaries in the background after sync completes.
  Future<void> _generateAiSummaries(AIService ai, List<Map<String, dynamic>> emails) async {
    if (!ai.isConfigured) return;

    print('🤖 Generating AI summaries for ${emails.length} emails...');
    int success = 0;

    for (var email in emails) {
      try {
        final summary = await ai.generateSummary(
          subject: email['subject'] ?? '',
          snippet: email['snippet'] ?? '',
        );
        if (summary != null) {
          await _storage.updateAiData(email['id'], aiSummary: summary);
          success++;
          print('✨ AI Summary: ${email['subject']} → $summary');
        }
      } catch (e) {
        print('🤖 AI Error for ${email['id']}: $e');
      }
    }

    print('🤖 AI summaries generated: $success/${emails.length}');
  }
}
