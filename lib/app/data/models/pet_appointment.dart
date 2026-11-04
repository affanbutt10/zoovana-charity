class PetAppointment {
  const PetAppointment({
    required this.id,
    required this.service,
    required this.provider,
    required this.petName,
    required this.date,
    required this.time,
    required this.price,
    required this.status,
  });

  final String id;
  final String service;
  final String provider;
  final String petName;
  final String date;
  final String time;
  final double price;
  final String status;

  factory PetAppointment.fromJson(Map<String, dynamic> json) => PetAppointment(
    id: json['id'] as String,
    service: json['service'] as String,
    provider: json['provider'] as String,
    petName: json['petName'] as String,
    date: json['date'] as String,
    time: json['time'] as String,
    price: (json['price'] as num).toDouble(),
    status: json['status'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'service': service,
    'provider': provider,
    'petName': petName,
    'date': date,
    'time': time,
    'price': price,
    'status': status,
  };
}
