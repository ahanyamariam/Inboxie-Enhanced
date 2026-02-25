import 'package:app/services/gmail_service.dart';
import 'package:app/services/storage_service.dart';
import 'package:app/services/intelligence_service.dart';

class SyncService {
  final GmailService _gmail;
  final StorageService _storage = StorageService();

  SyncService({required String accessToken})
      : _gmail = GmailService(accessToken: accessToken);

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

      // 2. Load VIP senders and custom labels for classification
      final vipSenders = _storage.getVipSenders();
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
            emailTimestamp: internalDate,
            customLabels: customLabels,
          );

          // 8. Add to batch
          processedEmails.add({
            'id': messageId,
            'threadId': threadId,
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
}