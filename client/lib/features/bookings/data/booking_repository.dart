import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../shared/models/booking.dart';

class BookingRepository {
  BookingRepository(this._client);

  final ApiClient _client;

  Future<BookingModel> createBooking(Map<String, dynamic> payload) async {
    final response = await _client.post('/bookings/', body: payload);
    return BookingModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<BookingModel>> fetchBookings({
    String role = 'requester',
    String? status,
  }) async {
    final query = <String, String>{'role': role};
    if (status != null) query['status_filter'] = status;
    final response = await _client.get('/bookings/', queryParameters: query);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => BookingModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<BookingModel> updateStatus(int bookingId, String status) async {
    final response = await _client.patch(
      '/bookings/$bookingId/status',
      body: {'new_status': status},
    );
    return BookingModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}

