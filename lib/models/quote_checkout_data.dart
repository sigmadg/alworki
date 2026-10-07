/// Datos del flujo de cotización → checkout con monedas.
class QuoteCheckoutData {
  const QuoteCheckoutData({
    required this.providerId,
    required this.providerName,
    required this.services,
    required this.materials,
    required this.date,
    required this.timeSlot,
  });

  final int providerId;
  final String providerName;
  final List<String> services;
  final List<String> materials;
  final String date;
  final String timeSlot;

  Map<String, dynamic> toJson() => {
        'providerId': providerId,
        'providerName': providerName,
        'services': services,
        'materials': materials,
        'date': date,
        'timeSlot': timeSlot,
      };

  factory QuoteCheckoutData.fromJson(Map<String, dynamic> json) => QuoteCheckoutData(
        providerId: (json['providerId'] as num).toInt(),
        providerName: json['providerName'] as String? ?? '',
        services: (json['services'] as List<dynamic>).map((e) => e.toString()).toList(),
        materials: (json['materials'] as List<dynamic>).map((e) => e.toString()).toList(),
        date: json['date'] as String,
        timeSlot: json['timeSlot'] as String,
      );
}

enum CoinPaymentType { red, blue }
