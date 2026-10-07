enum ExchangeStatus { pendiente, aceptada, rechazada, completada }

class ExchangeRequest {
  const ExchangeRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    this.postId,
    this.cardId,
    this.offerTitle,
    this.userId,
    this.targetUserId,
  });

  final int id;
  final String title;
  final String description;
  final ExchangeStatus status;
  final DateTime createdAt;
  final int? postId;
  final int? cardId;
  final String? offerTitle;
  final int? userId;
  final int? targetUserId;

  bool isIncomingFor(int? actorId) =>
      actorId != null && targetUserId != null && targetUserId == actorId && userId != actorId;

  bool canAccept(int? actorId) =>
      status == ExchangeStatus.pendiente &&
      actorId != null &&
      actorId != userId &&
      (targetUserId == null || targetUserId == actorId);

  bool canReject(int? actorId) =>
      status == ExchangeStatus.pendiente &&
      actorId != null &&
      (actorId == userId || actorId == targetUserId || targetUserId == null);

  bool canComplete(int? actorId) =>
      status == ExchangeStatus.aceptada &&
      actorId != null &&
      (actorId == userId || actorId == targetUserId);

  String get statusLabel => switch (status) {
        ExchangeStatus.pendiente => 'Pendiente',
        ExchangeStatus.aceptada => 'Aceptada',
        ExchangeStatus.rechazada => 'Rechazada',
        ExchangeStatus.completada => 'Completada',
      };

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'postId': postId,
        'cardId': cardId,
        'offerTitle': offerTitle,
        'userId': userId,
        'targetUserId': targetUserId,
      };

  factory ExchangeRequest.fromJson(Map<String, dynamic> json) => ExchangeRequest(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String,
        description: json['description'] as String,
        status: ExchangeStatus.values.byName(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        postId: (json['postId'] as num?)?.toInt(),
        cardId: (json['cardId'] as num?)?.toInt(),
        offerTitle: json['offerTitle'] as String?,
        userId: (json['userId'] as num?)?.toInt(),
        targetUserId: (json['targetUserId'] as num?)?.toInt(),
      );
}
