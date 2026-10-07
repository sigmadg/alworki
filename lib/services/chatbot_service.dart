import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ChatMessage {
  ChatMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
    this.confidence,
  });

  final String sender; // 'user' | 'bot'
  final String text;
  final DateTime timestamp;
  final bool? confidence;
}

class ChatbotService {
  /// URL opcional del backend Python (`enhanced_chatbot_simple.py`, puerto 5003).
  static const String _apiUrl = String.fromEnvironment(
    'CHATBOT_URL',
    defaultValue: 'http://10.0.2.2:5003',
  );

  Future<String?> _tryRemote(String message) async {
    if (kIsWeb) return null;
    try {
      final res = await http
          .post(
            Uri.parse('$_apiUrl/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': message, 'user_id': 'flutter_user'}),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode >= 400) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['response'] as String?;
    } catch (_) {
      return null;
    }
  }

  String _localReply(String message) {
    final m = message.toLowerCase();
    if (m.contains('hola') || m.contains('buenas')) {
      return '¡Hola! Soy el asistente de Alworki. Puedo explicarte cómo funcionan los intercambios de favores, el feed y las solicitudes de coincidencia.';
    }
    if (m.contains('intercambio') || m.contains('favor') || m.contains('coincidencia')) {
      return 'En Alworki publicas un favor (ej. clases de inglés) y propones a cambio otro (ej. pasear mascotas). '
          'Usa el menú ⋮ en una publicación → «Solicitud de coincidencia», o crea una en la pestaña Intercambio.';
    }
    if (m.contains('inglés') || m.contains('ingles') || m.contains('mascota') || m.contains('perro')) {
      return 'Ejemplo típico: ofreces 2 horas de inglés a la semana y recibes paseos de mascota los martes. '
          'Define el valor en «favores» en tu publicación y tarjeta de servicio.';
    }
    if (m.contains('registro') || m.contains('cuenta') || m.contains('login')) {
      return 'Puedes registrarte en la app (datos solo en tu dispositivo) o continuar como invitado para explorar el feed.';
    }
    if (m.contains('carpinter') || m.contains('cercan') || m.contains('requisito')) {
      return 'En Búsqueda escribe el oficio (ej. carpintero), agrega requisitos (muebles, madera, herramientas) '
          'y deja «Más cercano primero». Sale el profesional más cerca que cumpla lo que pediste.';
    }
    if (m.contains('buscar') || m.contains('búsqueda') || m.contains('servicio')) {
      return 'Ve a Búsqueda, escribe el oficio y los requisitos. Activa «Más cercano primero» para ver al carpintero o plomero más cerca que sí los cumpla.';
    }
    if (m.contains('entrega') || m.contains('seguimiento') || m.contains('tracking')) {
      return 'En Proyectos toca un trabajo para ver su guía: solicitado → en trabajo → entregado → confirmado. '
          'El profesional registra la entrega y tú la confirmas.';
    }
    if (m.contains('proyecto')) {
      return 'Puedes crear un proyecto desde el botón + o en Proyectos, publicarlo en el feed y seguir la entrega. '
          'Si nace de un intercambio aceptado, se crea solo con número de seguimiento.';
    }
    if (m.contains('historia') || m.contains('stories')) {
      return 'Arriba del inicio está la fila de historias. Toca «Tu historia» para publicar una. Toca un círculo para verla.';
    }
    if (m.contains('seguir') || m.contains('follow')) {
      return 'En cada publicación toca Seguir para esa persona. En un proyecto, «Seguir proyecto» lo deja en tu tablero.';
    }
    if (m.contains('identidad') || m.contains('ine') || m.contains('verificar')) {
      return 'Regístrate y luego ve a Verificar identidad: INE + selfie. '
          'PENDIENTE: API oficial del INE/CNBV y WhatsApp OTP. Mientras tanto la verificación es interna de Alworki.';
    }
    return 'Puedo ayudarte con intercambios, el feed, historias, proyectos, seguir personas y verificar identidad. '
        '¿Qué favor te gustaría ofrecer o recibir?';
  }

  Future<({String text, bool confidence})> sendMessage(String message) async {
    final remote = await _tryRemote(message);
    if (remote != null && remote.isNotEmpty) {
      return (text: remote, confidence: true);
    }
    return (text: _localReply(message), confidence: false);
  }
}
