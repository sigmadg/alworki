enum ProjectStatus { planificacion, enCurso, completado, pausado }

enum DeliveryStatus { solicitado, asignado, enTrabajo, entregado, confirmado }

class ProjectEvent {
  const ProjectEvent({
    required this.type,
    required this.title,
    required this.timestamp,
    this.actorId,
  });

  final String type;
  final String title;
  final String timestamp;
  final int? actorId;

  factory ProjectEvent.fromJson(Map<String, dynamic> json) => ProjectEvent(
        type: json['type'] as String? ?? '',
        title: json['title'] as String? ?? '',
        timestamp: json['timestamp'] as String? ?? '',
        actorId: (json['actorId'] as num?)?.toInt(),
      );
}

class ProjectDeliveryNote {
  const ProjectDeliveryNote({
    required this.message,
    required this.image,
    this.submittedAt,
    this.providerName = '',
    this.providerAvatar = 'users/user.jpg',
  });

  final String message;
  final String image;
  final String? submittedAt;
  final String providerName;
  final String providerAvatar;

  factory ProjectDeliveryNote.fromJson(Map<String, dynamic> json) => ProjectDeliveryNote(
        message: json['message'] as String? ?? '',
        image: json['image'] as String? ?? 'background4.png',
        submittedAt: json['submittedAt'] as String?,
        providerName: json['providerName'] as String? ?? '',
        providerAvatar: json['providerAvatar'] as String? ?? 'users/user.jpg',
      );
}

class ProjectItem {
  const ProjectItem({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.partnerName,
    this.ownerUserId,
    this.partnerUserId,
    this.followed = false,
    this.trackingNumber,
    this.deliveryStatus = DeliveryStatus.solicitado,
    this.requirements = const [],
    this.events = const [],
    this.delivery,
    this.category = '',
    this.isOwner = false,
    this.isPartner = false,
    this.canStart = false,
    this.canDeliver = false,
    this.canConfirm = false,
  });

  final int id;
  final String name;
  final String description;
  final ProjectStatus status;
  final String partnerName;
  final int? ownerUserId;
  final int? partnerUserId;
  final bool followed;
  final String? trackingNumber;
  final DeliveryStatus deliveryStatus;
  final List<String> requirements;
  final List<ProjectEvent> events;
  final ProjectDeliveryNote? delivery;
  final String category;
  final bool isOwner;
  final bool isPartner;
  final bool canStart;
  final bool canDeliver;
  final bool canConfirm;

  static const deliverySteps = ['Solicitado', 'En trabajo', 'Entregado', 'Confirmado'];

  int get deliveryStepIndex => switch (deliveryStatus) {
        DeliveryStatus.solicitado => 0,
        DeliveryStatus.asignado || DeliveryStatus.enTrabajo => 1,
        DeliveryStatus.entregado => 2,
        DeliveryStatus.confirmado => 3,
      };

  String get deliveryLabel => switch (deliveryStatus) {
        DeliveryStatus.solicitado => 'Solicitado',
        DeliveryStatus.asignado => 'Asignado',
        DeliveryStatus.enTrabajo => 'En trabajo',
        DeliveryStatus.entregado => 'Entregado',
        DeliveryStatus.confirmado => 'Confirmado',
      };

  ProjectItem copyWith({
    bool? followed,
    DeliveryStatus? deliveryStatus,
    ProjectStatus? status,
    List<ProjectEvent>? events,
    ProjectDeliveryNote? delivery,
    bool? canStart,
    bool? canDeliver,
    bool? canConfirm,
    String? trackingNumber,
  }) =>
      ProjectItem(
        id: id,
        name: name,
        description: description,
        status: status ?? this.status,
        partnerName: partnerName,
        ownerUserId: ownerUserId,
        partnerUserId: partnerUserId,
        followed: followed ?? this.followed,
        trackingNumber: trackingNumber ?? this.trackingNumber,
        deliveryStatus: deliveryStatus ?? this.deliveryStatus,
        requirements: requirements,
        events: events ?? this.events,
        delivery: delivery ?? this.delivery,
        category: category,
        isOwner: isOwner,
        isPartner: isPartner,
        canStart: canStart ?? this.canStart,
        canDeliver: canDeliver ?? this.canDeliver,
        canConfirm: canConfirm ?? this.canConfirm,
      );

  String get statusLabel => switch (status) {
        ProjectStatus.planificacion => 'Planificación',
        ProjectStatus.enCurso => 'En curso',
        ProjectStatus.completado => 'Completado',
        ProjectStatus.pausado => 'Pausado',
      };

  factory ProjectItem.fromJson(Map<String, dynamic> json) => ProjectItem(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        status: _parseStatus(json['status'] as String? ?? 'planificacion'),
        partnerName: json['partnerName'] as String? ?? '',
        ownerUserId: (json['ownerUserId'] as num?)?.toInt(),
        partnerUserId: (json['partnerUserId'] as num?)?.toInt(),
        followed: json['followed'] as bool? ?? false,
        trackingNumber: json['trackingNumber'] as String?,
        deliveryStatus: _parseDelivery(json['deliveryStatus'] as String? ?? json['status'] as String?),
        requirements: (json['requirements'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        events: (json['events'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ProjectEvent.fromJson)
            .toList(),
        delivery: json['delivery'] is Map<String, dynamic>
            ? ProjectDeliveryNote.fromJson(json['delivery'] as Map<String, dynamic>)
            : null,
        category: json['category'] as String? ?? '',
        isOwner: json['isOwner'] as bool? ?? false,
        isPartner: json['isPartner'] as bool? ?? false,
        canStart: json['canStart'] as bool? ?? false,
        canDeliver: json['canDeliver'] as bool? ?? false,
        canConfirm: json['canConfirm'] as bool? ?? false,
      );

  static ProjectStatus _parseStatus(String raw) {
    final s = raw.replaceAll('-', '_');
    return switch (s) {
      'planificacion' => ProjectStatus.planificacion,
      'en_curso' || 'enCurso' => ProjectStatus.enCurso,
      'completado' => ProjectStatus.completado,
      'pausado' => ProjectStatus.pausado,
      _ => ProjectStatus.planificacion,
    };
  }

  static DeliveryStatus _parseDelivery(String? raw) {
    final s = (raw ?? '').replaceAll('-', '_').toLowerCase();
    return switch (s) {
      'solicitado' || 'planificacion' => DeliveryStatus.solicitado,
      'asignado' => DeliveryStatus.asignado,
      'en_trabajo' || 'en_curso' || 'encurso' => DeliveryStatus.enTrabajo,
      'entregado' => DeliveryStatus.entregado,
      'confirmado' || 'completado' => DeliveryStatus.confirmado,
      _ => DeliveryStatus.solicitado,
    };
  }
}
