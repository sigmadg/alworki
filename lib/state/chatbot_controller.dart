import 'package:flutter/foundation.dart';

import '../services/chatbot_service.dart';

class ChatbotController extends ChangeNotifier {
  ChatbotController(this._service);

  final ChatbotService _service;

  final List<ChatMessage> messages = [];
  bool isTyping = false;
  bool initialized = false;

  static const _welcome =
      '¡Hola! Soy tu asistente de Alworki. Puedo ayudarte con intercambios de favores, '
      'el feed, las tarjetas de servicios y las solicitudes. ¿En qué puedo ayudarte?';

  Future<void> initialize() async {
    if (initialized) return;
    initialized = true;
    messages.add(ChatMessage(sender: 'bot', text: _welcome, timestamp: DateTime.now(), confidence: true));
    notifyListeners();
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    messages.add(ChatMessage(sender: 'user', text: trimmed, timestamp: DateTime.now()));
    isTyping = true;
    notifyListeners();

    final reply = await _service.sendMessage(trimmed);
    isTyping = false;
    messages.add(
      ChatMessage(
        sender: 'bot',
        text: reply.text,
        timestamp: DateTime.now(),
        confidence: reply.confidence,
      ),
    );
    notifyListeners();
  }

  void clear() {
    messages.clear();
    initialized = false;
    notifyListeners();
    initialize();
  }
}
