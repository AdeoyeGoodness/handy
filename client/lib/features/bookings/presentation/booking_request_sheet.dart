import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../shared/models/service_listing.dart';

class BookingRequestSheet extends ConsumerStatefulWidget {
  const BookingRequestSheet({super.key, required this.listing});

  final ServiceListingModel listing;

  @override
  ConsumerState<BookingRequestSheet> createState() => _BookingRequestSheetState();
}

class _BookingRequestSheetState extends ConsumerState<BookingRequestSheet> {
  DateTime? _scheduledAt;
  final _locationController = TextEditingController();
  final _durationController = TextEditingController(text: '1.0');
  final _notesController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _locationController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickSchedule() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null) return;
    setState(() {
      _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (_scheduledAt == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please choose a schedule')));
      return;
    }
    if (_locationController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please provide a location')));
      return;
    }
    setState(() => _submitting = true);
    final duration = double.tryParse(_durationController.text) ?? 1.0;
    final payload = {
      'listing_id': widget.listing.id,
      'provider_id': widget.listing.providerId,
      'scheduled_at': _scheduledAt!.toIso8601String(),
      'duration_hours': duration,
      'location': _locationController.text,
      'notes': _notesController.text,
      'total_price': widget.listing.basePrice * duration,
    };
    try {
      await ref.read(bookingRepositoryProvider).createBooking(payload);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking request sent')),
      );
      ref.invalidate(bookingsProvider('requester'));
      ref.invalidate(bookingsProvider('provider'));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create booking: $error')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Request ${widget.listing.title}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text(_scheduledAt == null
                  ? 'Choose date & time'
                  : 'Scheduled: ${_scheduledAt!.toLocal()}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickSchedule,
            ),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Service location'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _durationController,
              decoration: const InputDecoration(labelText: 'Duration (hours)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Additional notes'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send booking request'),
            ),
          ],
        ),
      ),
    );
  }
}

