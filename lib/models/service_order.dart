class OrderLineItem {
  const OrderLineItem({required this.label, required this.amount});

  final String label;
  final int amount;

  factory OrderLineItem.fromJson(Map<String, dynamic> json) => OrderLineItem(
        label: json['label'] as String? ?? '',
        amount: (json['amount'] as num?)?.toInt() ?? 0,
      );
}

class OrderRequirement {
  const OrderRequirement({required this.question, required this.answer});

  final String question;
  final String answer;

  factory OrderRequirement.fromJson(Map<String, dynamic> json) => OrderRequirement(
        question: json['question'] as String? ?? '',
        answer: json['answer'] as String? ?? '',
      );
}

class OrderActivity {
  const OrderActivity({
    required this.type,
    required this.title,
    required this.timestamp,
    this.icon = 'green',
    this.avatar,
    this.rating,
    this.text,
    this.linkLabel,
    this.linkTab,
  });

  final String type;
  final String title;
  final String timestamp;
  final String icon;
  final String? avatar;
  final double? rating;
  final String? text;
  final String? linkLabel;
  final String? linkTab;

  factory OrderActivity.fromJson(Map<String, dynamic> json) => OrderActivity(
        type: json['type'] as String? ?? '',
        title: json['title'] as String? ?? '',
        timestamp: json['timestamp'] as String? ?? '',
        icon: json['icon'] as String? ?? 'green',
        avatar: json['avatar'] as String?,
        rating: (json['rating'] as num?)?.toDouble(),
        text: json['text'] as String?,
        linkLabel: json['linkLabel'] as String?,
        linkTab: json['linkTab'] as String?,
      );
}

class OrderDelivery {
  const OrderDelivery({
    required this.number,
    required this.message,
    required this.image,
    required this.providerName,
    required this.providerAvatar,
  });

  final int number;
  final String message;
  final String image;
  final String providerName;
  final String providerAvatar;

  factory OrderDelivery.fromJson(Map<String, dynamic> json) => OrderDelivery(
        number: (json['number'] as num?)?.toInt() ?? 1,
        message: json['message'] as String? ?? '',
        image: json['image'] as String? ?? 'background4.png',
        providerName: json['providerName'] as String? ?? '',
        providerAvatar: json['providerAvatar'] as String? ?? 'users/user.jpg',
      );
}

class OrderReview {
  const OrderReview({required this.rating, required this.text});

  final double rating;
  final String text;

  factory OrderReview.fromJson(Map<String, dynamic> json) => OrderReview(
        rating: (json['rating'] as num?)?.toDouble() ?? 5,
        text: json['text'] as String? ?? '',
      );
}

class ServiceOrder {
  const ServiceOrder({
    required this.id,
    required this.trackingNumber,
    required this.title,
    required this.providerId,
    required this.providerName,
    required this.providerAvatar,
    required this.services,
    required this.materials,
    required this.lineItems,
    required this.requirements,
    required this.activities,
    required this.totalAl,
    required this.shippingCost,
    required this.date,
    required this.timeSlot,
    required this.status,
    this.delivery,
    this.deliveryDate,
    this.orderStartDate,
    this.clientReview,
    this.providerReview,
    this.isProvider = false,
    this.isClient = false,
  });

  final int id;
  final String trackingNumber;
  final String title;
  final int providerId;
  final String providerName;
  final String providerAvatar;
  final List<String> services;
  final List<String> materials;
  final List<OrderLineItem> lineItems;
  final List<OrderRequirement> requirements;
  final List<OrderActivity> activities;
  final OrderDelivery? delivery;
  final int totalAl;
  final int shippingCost;
  final String date;
  final String? deliveryDate;
  final String? orderStartDate;
  final String timeSlot;
  final String status;
  final OrderReview? clientReview;
  final OrderReview? providerReview;
  final bool isProvider;
  final bool isClient;

  bool get needsDelivery => isProvider && delivery == null;

  factory ServiceOrder.fromJson(Map<String, dynamic> json) => ServiceOrder(
        id: (json['id'] as num?)?.toInt() ?? 0,
        trackingNumber: json['trackingNumber'] as String? ?? '',
        title: json['title'] as String? ?? '',
        providerId: (json['providerId'] as num?)?.toInt() ?? 0,
        providerName: json['providerName'] as String? ?? '',
        providerAvatar: json['providerAvatar'] as String? ?? 'users/user.jpg',
        services: (json['services'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        materials: (json['materials'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        lineItems: (json['lineItems'] as List<dynamic>?)
                ?.map((e) => OrderLineItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        requirements: (json['requirements'] as List<dynamic>?)
                ?.map((e) => OrderRequirement.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        activities: (json['activities'] as List<dynamic>?)
                ?.map((e) => OrderActivity.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        delivery: json['delivery'] != null
            ? OrderDelivery.fromJson(json['delivery'] as Map<String, dynamic>)
            : null,
        totalAl: (json['totalAl'] as num?)?.toInt() ?? 0,
        shippingCost: (json['shippingCost'] as num?)?.toInt() ?? 0,
        date: json['date'] as String? ?? '',
        deliveryDate: json['deliveryDate'] as String?,
        orderStartDate: json['orderStartDate'] as String?,
        timeSlot: json['timeSlot'] as String? ?? '',
        status: json['status'] as String? ?? 'pendiente',
        clientReview: json['clientReview'] != null
            ? OrderReview.fromJson(json['clientReview'] as Map<String, dynamic>)
            : null,
        providerReview: json['providerReview'] != null
            ? OrderReview.fromJson(json['providerReview'] as Map<String, dynamic>)
            : null,
        isProvider: json['isProvider'] as bool? ?? false,
        isClient: json['isClient'] as bool? ?? false,
      );
}
