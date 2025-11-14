import 'dart:convert';

import 'package:http/http.dart' as http;

class AddressSuggestion {
  AddressSuggestion({
    required this.displayName,
    required this.addressLine,
    required this.houseNumber,
    required this.road,
    required this.latitude,
    required this.longitude,
    this.city,
    this.state,
    this.postalCode,
  });

  final String displayName;
  final String addressLine;
  final String houseNumber;
  final String road;
  final double latitude;
  final double longitude;
  final String? city;
  final String? state;
  final String? postalCode;

  factory AddressSuggestion.fromJson(Map<String, dynamic> json) {
    final address = (json['address'] as Map<String, dynamic>?) ?? {};

    final houseNumber = (address['house_number'] ?? '') as String;
    final road = (address['road'] ?? address['street'] ?? '') as String;
    final suburb = (address['suburb'] ?? address['neighbourhood'] ?? '') as String;

    final streetParts = [
      if (houseNumber.isNotEmpty) houseNumber,
      if (road.isNotEmpty) road,
      if (suburb.isNotEmpty) suburb,
    ].where((value) => value.isNotEmpty).toList();

    final city = (address['city'] ??
            address['town'] ??
            address['village'] ??
            address['municipality'] ??
            address['county']) as String?;

    final state = (address['state'] ?? address['region']) as String?;

    final formattedStreet =
        streetParts.isNotEmpty ? streetParts.join(' ') : (city ?? json['display_name'] as String);

    return AddressSuggestion(
      displayName: json['display_name'] as String,
      addressLine: formattedStreet,
      houseNumber: houseNumber,
      road: road,
      latitude: double.tryParse(json['lat'] as String? ?? '') ?? 0,
      longitude: double.tryParse(json['lon'] as String? ?? '') ?? 0,
      city: city,
      state: state,
      postalCode: (address['postcode'] ?? '') as String?,
    );
  }
}

class AddressLookupService {
  AddressLookupService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<AddressSuggestion>> search(String query) async {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'q': query,
        'format': 'json',
        'addressdetails': '1',
        'limit': '5',
        'countrycodes': 'ng',
      },
    );

    final response = await _client.get(
      uri,
      headers: {
        'User-Agent': 'GuardianTracker/1.0 (finalyearproject@example.com)',
      },
    );

    if (response.statusCode != 200) {
      return [];
    }

    final raw = jsonDecode(response.body) as List<dynamic>;
    return raw
        .map((entry) => AddressSuggestion.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  void dispose() {
    _client.close();
  }
}

