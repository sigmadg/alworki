import 'package:alworki_auto/models/exchange_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ExchangeRequest req({
    ExchangeStatus status = ExchangeStatus.pendiente,
    int userId = 1,
    int? targetUserId = 2,
  }) =>
      ExchangeRequest(
        id: 10,
        title: 'Ayuda con mudanza',
        description: 'Ofrezco clases de inglés',
        status: status,
        createdAt: DateTime.utc(2026, 1, 1),
        userId: userId,
        targetUserId: targetUserId,
      );

  test('el destinatario puede aceptar y rechazar un pendiente', () {
    final r = req();
    expect(r.canAccept(2), isTrue);
    expect(r.canReject(2), isTrue);
    expect(r.canAccept(1), isFalse);
    expect(r.isIncomingFor(2), isTrue);
  });

  test('el autor no acepta su propia solicitud abierta', () {
    final r = req(targetUserId: null);
    expect(r.canAccept(1), isFalse);
    expect(r.canAccept(7), isTrue);
  });

  test('solo aceptada se puede completar', () {
    expect(req().canComplete(1), isFalse);
    expect(req(status: ExchangeStatus.aceptada).canComplete(1), isTrue);
    expect(req(status: ExchangeStatus.aceptada).canComplete(2), isTrue);
    expect(req(status: ExchangeStatus.aceptada).canComplete(9), isFalse);
  });

  test('serializa userId y targetUserId', () {
    final json = req().toJson();
    final copy = ExchangeRequest.fromJson(Map<String, dynamic>.from(json));
    expect(copy.userId, 1);
    expect(copy.targetUserId, 2);
    expect(copy.statusLabel, 'Pendiente');
  });
}
