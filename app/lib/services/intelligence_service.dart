import 'package:app/models/email_label_model.dart';
import 'package:app/models/user_settings_model.dart';

class IntelligenceService {
  static Map<String, dynamic> analyze({
    required String subject,
    required String snippet,
    required String from,
    List<String> vipSenders = const [],
    List<String> mutedSenders = const [],
    PrioritySensitivity prioritySensitivity = PrioritySensitivity.normal,
    int? emailTimestamp,
    List<EmailLabel> customLabels = const [],
  }) {
    final subjectLower = subject.toLowerCase();
    final snippetLower = snippet.toLowerCase();
    final fromLower = from.toLowerCase();

    // Extract sender email
    String senderEmail = fromLower;
    if (fromLower.contains('<')) {
      senderEmail = fromLower.split('<').last.replaceAll('>', '').trim();
    }

    final classifiedLabel = DefaultLabels.classify(subject, snippet, customLabels: customLabels);
    final labelIdFromClassifier = classifiedLabel.id;
    final isCustom = customLabels.any((l) => l.id == labelIdFromClassifier);

    // ---------------------------------------------------------
    // 1️⃣ PHASE 1: SIGNAL DETECTION
    // ---------------------------------------------------------
    final signals = <String>{};

    // Detect automated/no-reply senders (can never need a reply)
    final _noReplyPatterns = ['noreply', 'no-reply', 'no_reply', 'donotreply', 'do-not-reply', 'notifications@', 'notify@', 'mailer@', 'updates@', 'news@', 'info@', 'support@', 'hello@', 'team@', 'digest@', 'alert@'];
    final _knownNotificationDomains = ['pinterest', 'linkedin', 'facebook', 'twitter', 'instagram', 'youtube', 'tiktok', 'reddit', 'quora', 'medium', 'substack', 'mailchimp', 'sendgrid', 'amazonses', 'shopify', 'stripe', 'uber', 'swiggy', 'zomato', 'flipkart', 'amazon', 'myntra', 'github', 'gitlab', 'figma', 'notion', 'slack', 'discord', 'canva'];
    bool isAutomatedSender = _noReplyPatterns.any((p) => senderEmail.contains(p)) || _knownNotificationDomains.any((d) => senderEmail.contains(d));
    
    // Marketing first to catch promotional "purchase" or "confirm"
    bool isMarketing = isAutomatedSender || labelIdFromClassifier == 'marketing' || labelIdFromClassifier == 'newsletter' || snippetLower.contains('unsubscribe') || snippetLower.contains('view in browser') || snippetLower.contains('opt out') ||  _hasKeywords(subjectLower, snippetLower, ['sale', 'offer', 'discount', 'promo', 'off your next']);

    bool isSecurity = !_hasKeywords(subjectLower, snippetLower, ['marketing', 'promo']) && (labelIdFromClassifier == 'security' || _hasKeywords(subjectLower, snippetLower, ['otp', 'verification code', 'password reset', 'security alert', '2fa']));
    
    bool isFinancial = (labelIdFromClassifier == 'finance' || _hasKeywords(subjectLower, snippetLower, ['receipt', 'payment', 'invoice', 'transaction', 'billing', 'order confirmation'])) && !isMarketing;
    
    bool isCalendar = labelIdFromClassifier == 'calendar' || _hasKeywords(subjectLower, snippetLower, ['meeting', 'invite', 'calendar', 'zoom', 'google meet']);
    
    bool isActionPhrases = _hasKeywords(subjectLower, snippetLower, ['please', 'could you', 'can you', 'let me know', 'confirm', 'review', 'action required']) && !isFinancial && !isAutomatedSender;
    bool hasQuestionInSubject = subject.contains('?') && !isAutomatedSender;
    bool isReplyNeeded = (isActionPhrases || hasQuestionInSubject || labelIdFromClassifier == 'work') && !isFinancial && !isMarketing && !isAutomatedSender;

    bool isShipping = _hasKeywords(subjectLower, snippetLower, ['shipped', 'shipping', 'delivery', 'tracking', 'package', 'out for delivery', 'in transit', 'shipment', 'dispatched', 'courier']) && !isMarketing;
    bool isTravel = _hasKeywords(subjectLower, snippetLower, ['flight', 'boarding pass', 'check-in', 'itinerary', 'hotel reservation', 'booking confirmation', 'travel', 'airline']) && !isMarketing;

    bool isVIP = vipSenders.any((vip) => senderEmail.contains(vip.toLowerCase()));
    bool isMuted = mutedSenders.any((m) => senderEmail.contains(m.toLowerCase()));
    
    if (isSecurity) signals.add('Security alert');
    if (isFinancial) signals.add('Finance/Transaction');
    if (isCalendar) signals.add('Calendar/Meeting');
    if (isShipping) signals.add('Shipping/Delivery');
    if (isTravel) signals.add('Travel/Flight');
    if (isReplyNeeded) signals.add('Action required');
    if (isVIP) signals.add('VIP Sender');
    if (isMuted) signals.add('Muted Sender');
    if (isMarketing) signals.add('Promotional');
    if (isCustom) signals.add('Custom Rule: ${classifiedLabel.name}');

    // ---------------------------------------------------------
    // 2️⃣ PHASE 2: BUCKET ASSIGNMENT
    // ---------------------------------------------------------
    String bucket;
    if (isMuted) {
      bucket = 'promotions';
    } else if (isSecurity || isVIP) {
      bucket = 'important';
    } else if (isShipping) {
      bucket = 'shipping';
    } else if (isTravel) {
      bucket = 'travel';
    } else if (isFinancial) {
      bucket = 'transactions';
    } else if (isReplyNeeded) {
      bucket = 'needs_reply';
    } else if (isCalendar) {
      bucket = 'events';
    } else if (isMarketing) {
      bucket = 'promotions';
    } else {
      bucket = (classifiedLabel.bucketId == 'inbox' || classifiedLabel.bucketId == 'updates') ? 'updates' : classifiedLabel.bucketId;
    }

    // ---------------------------------------------------------
    // 3️⃣ PHASE 3: PRIORITY CALCULATION
    // ---------------------------------------------------------
    int score = 0;
    if (isSecurity) score += 90;
    else if (isVIP) score += 40;
    else if (isFinancial) score += 40; // Increased to match 'important' expectation
    else if (isCalendar) score += 25;
    else if (isReplyNeeded) score += 25;
    
    if (isCustom) score += 30;
    if (isMarketing) score -= 40;

    if (emailTimestamp != null && emailTimestamp > 0) {
      final emailAge = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(emailTimestamp));
      if (emailAge.inDays >= 7) score += 10;
    }

    // Apply priority sensitivity scaling
    if (isMuted) {
      score = 0;
    } else {
      switch (prioritySensitivity) {
        case PrioritySensitivity.low:
          score = (score * 0.6).round();
          break;
        case PrioritySensitivity.high:
          score = (score * 1.4).round();
          break;
        case PrioritySensitivity.normal:
          break;
      }
    }

    score = score.clamp(0, 100);
    String priorityLabel;
    if (isMuted) {
      priorityLabel = 'low';
    } else if (score >= 70) priorityLabel = 'urgent';
    else if (score >= 40) priorityLabel = 'important';
    else if (score >= 20) priorityLabel = 'normal';
    else priorityLabel = 'low';

    // ---------------------------------------------------------
    // 4️⃣ PHASE 4: LABEL ASSIGNMENT
    // ---------------------------------------------------------
    String labelId = labelIdFromClassifier;
    
    if (isSecurity) labelId = 'security';
    else if (isFinancial) labelId = 'finance';
    else if (isCalendar) labelId = 'calendar';
    else if (isReplyNeeded) labelId = 'work';
    else if (isMarketing) labelId = 'marketing';
    else if (labelId == 'personal' && !isVIP && !isCustom) {
      final personalSalutations = ['hi', 'hello', 'hey', 'dear', 'thanks', 'regards', 'best'];
      bool looksPersonal = personalSalutations.any((s) => snippetLower.startsWith(s) || subjectLower.startsWith(s));
      if (!looksPersonal) labelId = 'general';
    }

    if (signals.isEmpty) signals.add('Generic');

    return {
      'bucket': bucket,
      'label': labelId,
      'priorityScore': score,
      'isActionable': !isMuted && (isReplyNeeded || isCalendar || isSecurity || isFinancial || isShipping || isTravel),
      'priorityLabel': priorityLabel,
      'signals': signals.toList(),
    };
  }

  static bool _hasKeywords(String subject, String snippet, List<String> keywords) {
    return keywords.any((w) => subject.contains(w) || snippet.contains(w));
  }
}