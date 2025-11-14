import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../shared/models/service_category.dart';
import '../../../shared/models/service_listing.dart';

class ServiceRepository {
  ServiceRepository(this._client);

  final ApiClient _client;

  Future<List<ServiceCategoryModel>> fetchCategories() async {
    final response = await _client.get('/services/categories');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => ServiceCategoryModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ServiceListingModel>> fetchListings() async {
    final response = await _client.get('/services/listings');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => ServiceListingModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ServiceListingModel> createListing(Map<String, dynamic> payload) async {
    final response = await _client.post('/services/listings', body: payload);
    return ServiceListingModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}

