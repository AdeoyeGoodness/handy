import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../shared/models/message_models.dart';

class MessageRepository {
  MessageRepository(this._client);

  final ApiClient _client;

  Future<List<MessageThreadModel>> fetchThreads() async {
    final response = await _client.get('/messages/threads');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => MessageThreadModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<MessageModel>> fetchMessages(int threadId) async {
    final response = await _client.get('/messages/threads/$threadId/messages');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => MessageModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<MessageThreadModel> createThread(int receiverId) async {
    final response = await _client.post(
      '/messages/threads',
      body: {'receiver_id': receiverId},
    );
    return MessageThreadModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<MessageModel> sendMessage(int threadId, String content) async {
    final response = await _client.post(
      '/messages/threads/$threadId/messages',
      body: {'content': content},
    );
    return MessageModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}

