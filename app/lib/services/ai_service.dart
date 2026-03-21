import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AIService {
  static const String _keyApiKey = 'ai_api_key';
  static const String _keyBaseUrl = 'ai_base_url';
  static const String _keyModel = 'ai_model';

  static const String defaultBaseUrl = 'https://api.groq.com/openai/v1';
  static const String defaultModel = 'llama-3.3-70b-versatile';

  final SharedPreferences _prefs;

  AIService({required SharedPreferences prefs}) : _prefs = prefs;

  // ==========================================
  // CONFIGURATION
  // ==========================================

  String get apiKey => _prefs.getString(_keyApiKey) ?? '';
  String get baseUrl => _prefs.getString(_keyBaseUrl) ?? defaultBaseUrl;
  String get model => _prefs.getString(_keyModel) ?? defaultModel;

  bool get isConfigured => apiKey.isNotEmpty;

  Future<void> setApiKey(String key) async {
    await _prefs.setString(_keyApiKey, key);
  }

  Future<void> setBaseUrl(String url) async {
    await _prefs.setString(_keyBaseUrl, url);
  }

  Future<void> setModel(String modelName) async {
    await _prefs.setString(_keyModel, modelName);
  }

  // ==========================================
  // AI SUMMARY
  // ==========================================

  /// Generates a concise 1-line summary of an email.
  /// Returns null if AI is not configured or fails.
  Future<String?> generateSummary({
    required String subject,
    required String snippet,
  }) async {
    if (!isConfigured) return null;

    final prompt = '''Summarize this email in ONE short sentence (max 15 words). Be direct and informative. No quotes or prefixes.

Subject: $subject
Content: $snippet''';

    return await _chatCompletion(prompt);
  }

  // ==========================================
  // AI REPLY SUGGESTIONS
  // ==========================================

  /// Generates 3 short reply suggestions for an email.
  /// Returns empty list if AI is not configured or fails.
  Future<List<String>> generateReplySuggestions({
    required String subject,
    required String content,
  }) async {
    if (!isConfigured) return [];

    final prompt = '''Generate exactly 3 short email reply suggestions for this email. Each reply should be 1-2 sentences, professional, and ready to send.

Return ONLY a JSON array of 3 strings, no other text. Example: ["Reply 1", "Reply 2", "Reply 3"]

Subject: $subject
Content: $content''';

    final response = await _chatCompletion(prompt);
    if (response == null) return [];

    try {
      // Parse the JSON array from the response
      String jsonStr = response.trim();
      
      // Extract JSON array if wrapped in other text
      final startIdx = jsonStr.indexOf('[');
      final endIdx = jsonStr.lastIndexOf(']');
      if (startIdx != -1 && endIdx != -1) {
        jsonStr = jsonStr.substring(startIdx, endIdx + 1);
      }

      final parsed = json.decode(jsonStr) as List<dynamic>;
      return parsed.map((e) => e.toString()).take(3).toList();
    } catch (e) {
      print('AI: Failed to parse reply suggestions: $e');
      return [];
    }
  }

  // ==========================================
  // CORE API CALL
  // ==========================================

  Future<String?> _chatCompletion(String userMessage) async {
    try {
      final url = Uri.parse('$baseUrl/chat/completions');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': model,
          'messages': [
            {
              'role': 'user',
              'content': userMessage,
            }
          ],
          'temperature': 0.7,
          'max_tokens': 256,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices']?[0]?['message']?['content'] as String?;
        return content?.trim();
      } else {
        print('AI API Error ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('AI Service Error: $e');
      return null;
    }
  }
}
