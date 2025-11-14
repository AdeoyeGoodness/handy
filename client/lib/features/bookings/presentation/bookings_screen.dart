import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/widgets/async_value_widget.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final role = _tabIndex == 0 ? 'requester' : 'provider';
    final bookingsAsync = ref.watch(bookingsProvider(role));

    return Column(
      children: [
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('My Requests')),
            ButtonSegment(value: 1, label: Text('Jobs Offered')),
          ],
          selected: {_tabIndex},
          onSelectionChanged: (value) => setState(() => _tabIndex = value.first),
        ),
        Expanded(
          child: AsyncValueWidget<List<BookingModel>>(
            value: bookingsAsync,
            data: (bookings) {
              if (bookings.isEmpty) {
                return const Center(child: Text('No bookings yet.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  return ListTile(
                    leading: const Icon(Icons.home_repair_service),
                    title: Text('Booking #${booking.id}'),
                    subtitle: Text('${booking.status} • ${booking.formattedDate}'),
                    trailing: Text('\$${booking.totalPrice.toStringAsFixed(2)}'),
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: bookings.length,
              );
            },
          ),
        ),
      ],
    );
  }
}

