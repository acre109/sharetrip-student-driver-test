import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/driver_chat_page.dart';
import '../../../core/services/sharetrip_local_store.dart';

/// Student messaging opens the same persisted conversation used by the driver inbox.
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  static const conversationId = 'driver_jd';
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final messages = await ShareTripLocalStore.getMessages(conversationId);
    if (mounted) setState(() => _messages = messages);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 25, 20, 22),
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Messages', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text('Chat with your driver', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: Colors.white,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: const CircleAvatar(child: Icon(Icons.drive_eta)),
                    title: const Text('Your driver', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(_messages.isEmpty ? 'Start a conversation' : '${_messages.last['text'] ?? 'Conversation'}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverChatPage(
                        conversationId: conversationId,
                        title: 'Chat with Driver',
                        senderRole: 'Student',
                      )));
                      await _load();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
