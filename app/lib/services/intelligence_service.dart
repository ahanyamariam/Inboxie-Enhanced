class IntelligenceService {
  static Map<String, dynamic> analyze({
    required String subject,
    required String snippet,
    required String from,
    List<String> vipSenders = const [],
    int? emailTimestamp,
  }) {
    String bucket = 'inbox';
    int score = 0;
    bool isActionable = false;
    List<String> signals = [];

    final subjectLower = subject.toLowerCase();
    final snippetLower = snippet.toLowerCase();
    final fromLower = from.toLowerCase();

    // Extract sender email
    String senderEmail = fromLower;
    if (fromLower.contains('<')) {
      senderEmail = fromLower.split('<').last.replaceAll('>', '').trim();
    }

    final senderDomain =
        senderEmail.contains('@') ? senderEmail.split('@').last : senderEmail;

    // ============================================================
    // 1️⃣ CRITICAL / SECURITY EMAIL SHIELD (NEVER ALLOW SPAM FILTER)
    // ============================================================

    final criticalWords = [
      'otp',
      'one time password',
      'verification code',
      'password reset',
      'reset your password',
      'login attempt',
      'new device login',
      'security alert',
      'suspicious activity',
      'account locked',
      'two-factor',
      '2fa',
      'authentication code'
    ];

    bool isCritical = criticalWords.any(
      (w) => subjectLower.contains(w) || snippetLower.contains(w),
    );

    if (isCritical) {
      return {
        'bucket': 'important',
        'priorityScore': 90,
        'isActionable': true,
        'priorityLabel': 'urgent',
        'signals': ['Security / verification email'],
      };
    }

    // ============================================================
    // 2️⃣ FINANCIAL / TRANSACTIONAL PROTECTION
    // ============================================================

    final financialWords = [
      'invoice',
      'receipt',
      'payment',
      'debited',
      'credited',
      'transaction',
      'order confirmation',
      'purchase',
      'subscription renewal',
      'billing',
      'statement'
    ];

    bool isFinancial = financialWords.any(
      (w) => subjectLower.contains(w) || snippetLower.contains(w),
    );

    if (isFinancial) {
      return {
        'bucket': 'transactional',
        'priorityScore': 70,
        'isActionable': true,
        'priorityLabel': 'important',
        'signals': ['Financial / receipt email'],
      };
    }

    // ============================================================
    // 3️⃣ VIP SENDERS
    // ============================================================

    if (vipSenders.any((vip) => senderEmail.contains(vip.toLowerCase()))) {
      score += 40;
      bucket = 'needs_reply';
      isActionable = true;
      signals.add('From VIP sender');
    }

    // ============================================================
    // 4️⃣ ACTION / REPLY DETECTION
    // ============================================================

    final urgentWords = [
      'urgent',
      'asap',
      'immediately',
      'critical',
      'action required',
      'important'
    ];

    for (var word in urgentWords) {
      if (subjectLower.contains(word) || snippetLower.contains(word)) {
        score += 30;
        bucket = 'needs_reply';
        isActionable = true;
        signals.add('Urgency detected');
        break;
      }
    }

    final actionPhrases = [
      'please',
      'could you',
      'can you',
      'let me know',
      'confirm',
      'review',
      'approve',
      'send me',
      'your feedback',
      'take a look'
    ];

    for (var phrase in actionPhrases) {
      if (snippetLower.contains(phrase)) {
        score += 20;
        bucket = 'needs_reply';
        isActionable = true;
        signals.add('Action requested');
        break;
      }
    }

    if (subject.contains('?') || snippet.contains('?')) {
      score += 15;
      bucket = 'needs_reply';
      isActionable = true;
      signals.add('Contains a question');
    }

    // ============================================================
    // 5️⃣ CALENDAR / MEETINGS
    // ============================================================

    final calendarWords = [
      'meeting',
      'invite',
      'calendar',
      'schedule',
      'appointment',
      'rsvp',
      'zoom',
      'google meet',
      'teams call'
    ];

    for (var word in calendarWords) {
      if (subjectLower.contains(word) || snippetLower.contains(word)) {
        bucket = 'calendar';
        score += 20;
        isActionable = true;
        signals.add('Calendar event');
        break;
      }
    }

    // ============================================================
    // 6️⃣ MARKETING / PROMOTIONAL DETECTION (BEHAVIOR-BASED)
    // ============================================================

    int marketingScore = 0;

    // unsubscribe indicators
    if (snippetLower.contains('unsubscribe')) marketingScore += 3;
    if (snippetLower.contains('manage preferences')) marketingScore += 2;
    if (snippetLower.contains('opt out')) marketingScore += 2;

    // no-reply senders
    bool isNoReplySender = [
      'noreply',
      'no-reply',
      'donotreply',
      'do-not-reply'
    ].any((p) => senderEmail.contains(p));

    if (isNoReplySender) marketingScore += 2;

    // promo language
    final promoWords = [
      'sale',
      'offer',
      'discount',
      '% off',
      'limited time',
      'deal',
      'shop now',
      'buy now',
      'exclusive',
      'free shipping',
      'act fast',
      'clearance'
    ];

    for (var w in promoWords) {
      if (subjectLower.contains(w) || snippetLower.contains(w)) {
        marketingScore += 2;
      }
    }

    // marketing classification
    if (marketingScore >= 6 && !isActionable) {
      bucket = 'marketing';
      score = 5;
      isActionable = false;
      signals = ['Promotional email detected'];
    }

    // ============================================================
    // 7️⃣ TIME SIGNAL
    // ============================================================

    if (emailTimestamp != null && emailTimestamp > 0) {
      final emailAge = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(emailTimestamp),
      );

      if (emailAge.inDays >= 7) {
        score += 10;
        signals.add('Old unanswered email');
      }
    }

    // ============================================================
    // PRIORITY LABEL
    // ============================================================

    if (score > 100) score = 100;

    String priorityLabel;
    if (score >= 50) {
      priorityLabel = 'urgent';
    } else if (score >= 25) {
      priorityLabel = 'important';
    } else if (score >= 10) {
      priorityLabel = 'normal';
    } else {
      priorityLabel = 'low';
    }

    if (signals.isEmpty) {
      signals.add('No strong signals');
    }

    return {
      'bucket': bucket,
      'priorityScore': score,
      'isActionable': isActionable,
      'priorityLabel': priorityLabel,
      'signals': signals,
    };
  }
}