import 'package:intl/intl.dart';

class BookingModel {
  BookingModel({
    required this.id,
    required this.listingId,
    required this.requesterId,
    required this.providerId,
    required this.status,
    required this.scheduledAt,
    required this.durationHours,
    required this.location,
    required this.totalPrice,
    this.paymentStatus,
    this.notes,
  });

  final int id;
  final int listingId;
  final int requesterId;
  final int providerId;
  final String status;
  final DateTime scheduledAt;
  final double durationHours;
  final String location;
  final double totalPrice;
  final String? paymentStatus;
  final String? notes;

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as int,
      listingId: json['listing_id'] as int,
      requesterId: json['requester_id'] as int,
      providerId: json['provider_id'] as int,
      status: json['status'] as String,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      durationHours: (json['duration_hours'] as num).toDouble(),
      location: json['location'] as String,
      totalPrice: (json['total_price'] as num).toDouble(),
      paymentStatus: json['payment_status'] as String?,
      notes: json['notes'] as String?,
    );
  }

  String get formattedDate => DateFormat.yMMMd().add_jm().format(scheduledAt);
}

