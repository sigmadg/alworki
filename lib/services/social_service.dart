import 'package:flutter/foundation.dart';

import 'api_client.dart';

class ChatPreview {
  const ChatPreview({
    required this.id,
    required this.name,
    required this.avatarKey,
    required this.lastMessage,
    required this.time,
    this.profession = '',
    this.peerId,
    this.unread = 0,
  });

  final int id;
  final String name;
  final String avatarKey;
  final String profession;
  final int? peerId;
  final String lastMessage;
  final String time;
  final int unread;

  factory ChatPreview.fromJson(Map<String, dynamic> json) => ChatPreview(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        avatarKey: json['avatarKey'] as String? ?? 'users/user.jpg',
        profession: json['profession'] as String? ?? '',
        peerId: (json['peerId'] as num?)?.toInt(),
        lastMessage: json['lastMessage'] as String? ?? '',
        time: json['time'] as String? ?? '',
        unread: (json['unread'] as num?)?.toInt() ?? 0,
      );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.type,
    required this.body,
    this.meta,
  });

  final int id;
  final String sender;
  final String type;
  final String body;
  final Map<String, dynamic>? meta;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: (json['id'] as num).toInt(),
        sender: json['sender'] as String? ?? 'text',
        type: json['type'] as String? ?? 'text',
        body: json['body'] as String? ?? '',
        meta: json['meta'] as Map<String, dynamic>?,
      );
}

class ContactItem {
  const ContactItem({
    required this.id,
    required this.name,
    required this.avatarKey,
    this.profession = '',
    this.peerId,
    this.threadId,
    this.lastMessage = '',
    this.time = '',
    this.source = 'chat',
  });

  final int id;
  final String name;
  final String avatarKey;
  final String profession;
  final int? peerId;
  final int? threadId;
  final String lastMessage;
  final String time;
  final String source;

  factory ContactItem.fromJson(Map<String, dynamic> json) => ContactItem(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        avatarKey: json['avatarKey'] as String? ?? 'users/user.jpg',
        profession: json['profession'] as String? ?? '',
        peerId: (json['peerId'] as num?)?.toInt(),
        threadId: (json['threadId'] as num?)?.toInt(),
        lastMessage: json['lastMessage'] as String? ?? '',
        time: json['time'] as String? ?? '',
        source: json['source'] as String? ?? 'chat',
      );
}

class ContactRequest {
  const ContactRequest({
    required this.id,
    required this.name,
    required this.avatarKey,
    required this.subtitle,
    required this.status,
  });

  final int id;
  final String name;
  final String avatarKey;
  final String subtitle;
  final String status;

  factory ContactRequest.fromJson(Map<String, dynamic> json) => ContactRequest(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        avatarKey: json['avatarKey'] as String? ?? 'users/user.jpg',
        subtitle: json['subtitle'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
      );
}

class BlockedContact {
  const BlockedContact({
    required this.id,
    required this.name,
    required this.avatarKey,
    this.peerId,
  });

  final int id;
  final String name;
  final String avatarKey;
  final int? peerId;

  factory BlockedContact.fromJson(Map<String, dynamic> json) => BlockedContact(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        avatarKey: json['avatarKey'] as String? ?? 'users/user.jpg',
        peerId: (json['peerId'] as num?)?.toInt(),
      );
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.userName,
    required this.avatarKey,
    required this.message,
    required this.timeAgo,
    this.isRecent = true,
  });

  final int id;
  final String userName;
  final String avatarKey;
  final String message;
  final String timeAgo;
  final bool isRecent;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: (json['id'] as num).toInt(),
        userName: json['userName'] as String? ?? '',
        avatarKey: json['avatarKey'] as String? ?? 'users/user.jpg',
        message: json['message'] as String? ?? '',
        timeAgo: json['timeAgo'] as String? ?? '',
        isRecent: json['isRecent'] as bool? ?? true,
      );
}

class SocialService extends ChangeNotifier {
  SocialService(this._api, this._tokenProvider);

  final ApiClient _api;
  final String? Function() _tokenProvider;

  List<ChatPreview> _chats = [];
  List<ContactItem> _contacts = [];
  List<AppNotification> _notifications = [];
  List<ContactRequest> _contactRequests = [];
  List<BlockedContact> _blocked = [];
  int _unreadMessages = 0;
  bool isLoading = false;
  String? error;

  List<ChatPreview> get chats => List.unmodifiable(_chats);
  List<ContactItem> get contacts => List.unmodifiable(_contacts);
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  List<ContactRequest> get contactRequests => List.unmodifiable(_contactRequests);
  List<BlockedContact> get blockedContacts => List.unmodifiable(_blocked);
  int get unreadMessages => _unreadMessages;

  Future<void> loadMessages() async {
    final token = _tokenProvider();
    if (token == null || token.isEmpty) return;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await _api.get('/api/messages', token: token) as List<dynamic>;
      _chats = data.map((e) => ChatPreview.fromJson(e as Map<String, dynamic>)).toList();
      final countData = await _api.get('/api/messages/unread-count', token: token) as Map<String, dynamic>;
      _unreadMessages = (countData['count'] as num?)?.toInt() ?? 0;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<({ChatPreview thread, List<ChatMessage> messages})?> loadThread(int threadId) async {
    final token = _tokenProvider();
    if (token == null) return null;
    try {
      final data = await _api.get('/api/messages/$threadId', token: token) as Map<String, dynamic>;
      final thread = ChatPreview.fromJson(data['thread'] as Map<String, dynamic>);
      final messages = (data['messages'] as List<dynamic>)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      return (thread: thread, messages: messages);
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<ChatMessage?> sendMessage(int threadId, String body) async {
    final token = _tokenProvider();
    if (token == null) return null;
    try {
      final data = await _api.post(
        '/api/messages/$threadId',
        token: token,
        body: {'body': body},
      ) as Map<String, dynamic>;
      return ChatMessage.fromJson(data);
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<ChatMessage?> sendQuoteMessage(int threadId, String amount) async {
    final token = _tokenProvider();
    if (token == null) return null;
    try {
      final parsed = int.tryParse(amount.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
      final data = await _api.post(
        '/api/messages/$threadId',
        token: token,
        body: {
          'body': amount,
          'type': 'quote',
          'meta': {'currency': 'MX', 'amount': parsed},
        },
      ) as Map<String, dynamic>;
      return ChatMessage.fromJson(data);
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  int? threadIdForPeer(int peerId) {
    for (final c in _chats) {
      if (c.peerId == peerId) return c.id;
    }
    for (final c in _contacts) {
      if (c.peerId == peerId && c.threadId != null) return c.threadId;
    }
    return null;
  }

  Future<int?> openThreadWithPeer({
    required int peerId,
    required String name,
    String avatarKey = 'users/user.jpg',
    String profession = '',
  }) async {
    final token = _tokenProvider();
    if (token == null) return null;
    final existing = threadIdForPeer(peerId);
    if (existing != null) return existing;
    try {
      final data = await _api.post(
        '/api/messages/with/$peerId',
        token: token,
        body: {'name': name, 'avatar': avatarKey, 'profession': profession},
      ) as Map<String, dynamic>;
      final thread = ChatPreview.fromJson(data);
      _chats = [thread, ..._chats.where((c) => c.id != thread.id)];
      notifyListeners();
      return thread.id;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  bool isPeerContact(int peerId) => _contacts.any((c) => c.peerId == peerId);

  Future<bool> sendContactRequest({required int peerId, String subtitle = ''}) async {
    final token = _tokenProvider();
    if (token == null) return false;
    try {
      await _api.post(
        '/api/contacts/requests',
        token: token,
        body: {'peer_id': peerId, 'subtitle': subtitle},
      );
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadContacts() async {
    final token = _tokenProvider();
    if (token == null) return;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await _api.get('/api/contacts', token: token) as List<dynamic>;
      _contacts = data.map((e) => ContactItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadContactRequests() async {
    final token = _tokenProvider();
    if (token == null) return;
    try {
      final data = await _api.get('/api/contacts/requests', token: token) as List<dynamic>;
      _contactRequests = data.map((e) => ContactRequest.fromJson(e as Map<String, dynamic>)).toList();
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> acceptContactRequest(int id) async {
    final token = _tokenProvider();
    if (token == null) return false;
    try {
      await _api.post('/api/contacts/requests/$id/accept', token: token);
      _contactRequests.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rejectContactRequest(int id) async {
    final token = _tokenProvider();
    if (token == null) return false;
    try {
      await _api.post('/api/contacts/requests/$id/reject', token: token);
      _contactRequests.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadBlockedContacts() async {
    final token = _tokenProvider();
    if (token == null) return;
    try {
      final data = await _api.get('/api/contacts/blocked', token: token) as List<dynamic>;
      _blocked = data.map((e) => BlockedContact.fromJson(e as Map<String, dynamic>)).toList();
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> unblockContact(int id) async {
    final token = _tokenProvider();
    if (token == null) return false;
    try {
      await _api.delete('/api/contacts/blocked/$id', token: token);
      _blocked.removeWhere((b) => b.id == id);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadNotifications() async {
    final token = _tokenProvider();
    if (token == null || token.isEmpty) return;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await _api.get('/api/notifications', token: token) as List<dynamic>;
      _notifications = data.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeNotification(int id) async {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
    final token = _tokenProvider();
    if (token == null) return;
    try {
      await _api.delete('/api/notifications/$id', token: token);
    } catch (_) {}
  }
}
