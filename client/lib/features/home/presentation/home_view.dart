import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../shared/models/service_category.dart';
import '../../../shared/models/service_listing.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../bookings/presentation/booking_request_sheet.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(serviceCategoriesProvider);
    final listingsAsync = ref.watch(serviceListingsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(serviceCategoriesProvider);
        ref.invalidate(serviceListingsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Find the right helper',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          AsyncValueWidget<List<ServiceCategoryModel>>(
            value: categoriesAsync,
            data: (categories) {
              if (categories.isEmpty) {
                return const Text('No categories available yet.');
              }
              return SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _CategoryCard(category: category);
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemCount: categories.length,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Popular services',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          AsyncValueWidget<List<ServiceListingModel>>(
            value: listingsAsync,
            data: (listings) {
              if (listings.isEmpty) {
                return const Text('No listings found. Check back later!');
              }
              return Column(
                children: listings
                    .map((listing) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ServiceCard(listing: listing),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final ServiceCategoryModel category;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.category, color: Colors.white.withOpacity(0.9)),
          const Spacer(),
          Text(
            category.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            category.description ?? 'Browse professionals',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends ConsumerWidget {
  const _ServiceCard({required this.listing});

  final ServiceListingModel listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(listing.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(listing.description, maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(label: Text('${listing.basePrice.toStringAsFixed(0)} / ${listing.pricingUnit}')),
                const SizedBox(width: 8),
                if (listing.coverageArea != null)
                  Chip(
                    avatar: const Icon(Icons.location_on, size: 16),
                    label: Text(listing.coverageArea!),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                icon: const Icon(Icons.handshake),
                label: const Text('Request Service'),
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => BookingRequestSheet(listing: listing),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

