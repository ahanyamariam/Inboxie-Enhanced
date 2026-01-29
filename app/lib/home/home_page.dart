import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  final String accessToken;
  final String userEmail;

  const HomeScreen({
    Key? key,
    required this.accessToken,
    required this.userEmail,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, String>> _emails = [];

  @override
  void initState() {
    super.initState();
    _fetchEmails();
  }

  Future<void> _fetchEmails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch message list (limited to 10 for simplicity)
      final messagesResponse = await http.get(
        Uri.parse('https://gmail.googleapis.com/gmail/v1/users/me/messages?maxResults=10'),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
        },
      );

      if (messagesResponse.statusCode != 200) {
        throw Exception('Failed to fetch messages');
      }

      final messagesData = json.decode(messagesResponse.body);
      final messages = messagesData['messages'] ?? [];

      List<Map<String, String>> emailList = [];

      // Fetch details for each message
      for (var message in messages) {
        final messageId = message['id'];
        final messageDetailResponse = await http.get(
          Uri.parse('https://gmail.googleapis.com/gmail/v1/users/me/messages/$messageId?format=metadata&metadataHeaders=Subject&metadataHeaders=From'),
          headers: {
            'Authorization': 'Bearer ${widget.accessToken}',
          },
        );

        if (messageDetailResponse.statusCode == 200) {
          final detailData = json.decode(messageDetailResponse.body);
          final headers = detailData['payload']['headers'] as List<dynamic>;

          String subject = '';
          String from = '';

          for (var header in headers) {
            if (header['name'] == 'Subject') subject = header['value'];
            if (header['name'] == 'From') from = header['value'];
          }

          emailList.add({'subject': subject, 'from': from});
        }
      }

      setState(() {
        _emails = emailList;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inbox - ${widget.userEmail}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : _emails.isEmpty
                  ? const Center(child: Text('No emails found'))
                  : ListView.builder(
                      itemCount: _emails.length,
                      itemBuilder: (context, index) {
                        final email = _emails[index];
                        return ListTile(
                          title: Text(email['subject'] ?? '(No Subject)'),
                          subtitle: Text(email['from'] ?? ''),
                          leading: const Icon(Icons.email),
                        );
                      },
                    ),
    );
  }
}
