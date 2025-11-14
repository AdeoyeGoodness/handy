import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/token_storage.dart';
import '../features/auth/domain/auth_controller.dart';
import '../features/auth/domain/auth_state.dart';
import '../features/bookings/data/booking_repository.dart';
import '../features/messages/data/message_repository.dart';
import '../features/services/data/service_repository.dart';
import '../shared/models/booking.dart';
import '../shared/models/message_models.dart';
import '../shared/models/service_category.dart';
import '../shared/models/service_listing.dart';
import '../shared/services/address_lookup_service.dart';
import 'config.dart';
import 'network/api_client.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

final appConfigProvider = Provider<AppConfig>((_) => const AppConfig());

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TokenStorage(prefs);
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final storage = ref.watch(tokenStorageProvider);
  return ApiClient(baseUrl: config.apiBaseUrl, tokenStorage: storage);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(tokenStorageProvider);
  return AuthRepository(apiClient: apiClient, tokenStorage: storage);
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repository: repo);
});

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ServiceRepository(client);
});

final serviceCategoriesProvider = FutureProvider<List<ServiceCategoryModel>>(
  (ref) => ref.watch(serviceRepositoryProvider).fetchCategories(),
);

final serviceListingsProvider = FutureProvider<List<ServiceListingModel>>(
  (ref) => ref.watch(serviceRepositoryProvider).fetchListings(),
);

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return BookingRepository(client);
});

final bookingsProvider = FutureProvider.family<List<BookingModel>, String>((ref, role) {
  return ref.watch(bookingRepositoryProvider).fetchBookings(role: role);
});

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return MessageRepository(client);
});

final messageThreadsProvider = FutureProvider<List<MessageThreadModel>>(
  (ref) => ref.watch(messageRepositoryProvider).fetchThreads(),
);

final messageListProvider = FutureProvider.family<List<MessageModel>, int>(
  (ref, threadId) => ref.watch(messageRepositoryProvider).fetchMessages(threadId),
);

final addressLookupServiceProvider = Provider<AddressLookupService>((ref) {
  final service = AddressLookupService();
  ref.onDispose(service.dispose);
  return service;
});

