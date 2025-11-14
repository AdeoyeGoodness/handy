import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../shared/services/address_lookup_service.dart';
import '../domain/auth_state.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  static const int _totalSteps = 4;

  int _currentStep = 1;

  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _addressLineController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _notesController = TextEditingController();
  Timer? _addressDebounce;
  List<AddressSuggestion> _addressSuggestions = [];
  bool _isSearchingAddress = false;
  String _lastAddressQuery = '';
  
  // Step 3: Role and Availability
  String _selectedRole = 'SERVICE_SEEKER'; // Default to seeker
  final Set<String> _availableDays = {};
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressLineController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _notesController.dispose();
    _addressDebounce?.cancel();
    super.dispose();
  }

  GlobalKey<FormState> get _activeFormKey {
    if (_currentStep == 1) return _step1Key;
    if (_currentStep == 2) return _step2Key;
    if (_currentStep == 3) return _step3Key;
    return _step1Key; // Step 4 doesn't need validation
  }

  Future<void> _handleNext() async {
    if (_currentStep < 3) {
      final form = _activeFormKey.currentState;
      if (form == null || !form.validate()) return;
    }

    if (_currentStep == 1) {
      setState(() => _currentStep = 2);
      return;
    }

    if (_currentStep == 2) {
      setState(() => _currentStep = 3);
      return;
    }

    if (_currentStep == 3) {
      // Validate availability if service provider
      if (_selectedRole == 'SERVICE_PROVIDER') {
        if (_availableDays.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select at least one available day')),
          );
          return;
        }
        if (_startTime == null || _endTime == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please set your working hours')),
          );
          return;
        }
      }
      setState(() => _currentStep = 4);
      return;
    }

    if (_currentStep == 4) {
      // Final submission
      await _submitRegistration();
    }
  }

  Future<void> _submitRegistration() async {
    final authController = ref.read(authControllerProvider.notifier);

    // Build address data
    final addressData = <String, dynamic>{
      'street': _addressLineController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      if (_postalCodeController.text.trim().isNotEmpty)
        'postal_code': _postalCodeController.text.trim(),
      if (_notesController.text.trim().isNotEmpty)
        'notes': _notesController.text.trim(),
    };

    // Build availability data (for service providers only)
    List<Map<String, dynamic>>? availabilityData;
    if (_selectedRole == 'SERVICE_PROVIDER' &&
        _availableDays.isNotEmpty &&
        _startTime != null &&
        _endTime != null) {
      availabilityData = _availableDays.map((day) {
        // Format time as "HH:MM"
        final startTimeStr =
            '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}';
        final endTimeStr =
            '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}';

        return {
          'day_of_week': day,
          'start_time': startTimeStr,
          'end_time': endTimeStr,
          'is_available': true,
        };
      }).toList();
    }

    final success = await authController.register(
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      role: _selectedRole,
      address: addressData,
      availability: availabilityData,
    );

    if (!mounted) return;

    if (success) {
      context.go('/home');
    } else {
      final currentState = ref.read(authControllerProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentState.status == AuthStatus.error
                ? 'Registration failed. Please try again.'
                : 'An error occurred',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _onAddressChanged(String value, WidgetRef ref) {
    _addressDebounce?.cancel();
    final query = value.trim();

    if (query.length < 3) {
      setState(() {
        _addressSuggestions = [];
        _isSearchingAddress = false;
        _lastAddressQuery = '';
      });
      return;
    }

    _lastAddressQuery = query;
    _addressDebounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() {
        _isSearchingAddress = true;
      });
      final results = await ref.read(addressLookupServiceProvider).search(query);
      if (!mounted) return;
      setState(() {
        _addressSuggestions = results;
        _isSearchingAddress = false;
      });
    });
  }

  void _selectAddress(AddressSuggestion suggestion) {
    final numberedStreet = [
      if (suggestion.houseNumber.isNotEmpty) suggestion.houseNumber,
      if (suggestion.road.isNotEmpty) suggestion.road else suggestion.addressLine,
    ].where((value) => value.isNotEmpty).join(' ');

    setState(() {
      _addressLineController.text =
          numberedStreet.isNotEmpty ? numberedStreet : suggestion.displayName;
      _cityController.text = suggestion.city ?? '';
      _stateController.text = suggestion.state ?? '';
      _postalCodeController.text = suggestion.postalCode ?? '';
      _addressSuggestions = [];
      _isSearchingAddress = false;
    });
  }

  List<Widget> _buildStepOneFields(BuildContext context) {
    return [
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'First Name',
                helperText: 'Customers will see this name',
              ),
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                helperText: 'Use your legal last name',
              ),
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _phoneController,
        decoration: const InputDecoration(
          labelText: 'Phone number',
          helperText: 'We’ll send verification here',
        ),
        keyboardType: TextInputType.phone,
        maxLength: 11,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(11),
        ],
        validator: (value) =>
            value == null || value.length != 11 ? 'Enter 11-digit phone number' : null,
      ),
      const SizedBox(height: 24),
      TextFormField(
        controller: _passwordController,
        decoration: const InputDecoration(
          labelText: 'Password',
          helperText: 'At least 8 characters with capitals, numbers & symbols',
        ),
        obscureText: true,
        validator: (value) {
          if (value == null || value.length < 8) {
            return 'Password must be at least 8 characters';
          }
          final hasUpper = value.contains(RegExp(r'[A-Z]'));
          final hasNumber = value.contains(RegExp(r'[0-9]'));
          final hasSymbol = value.contains(RegExp(r'[^A-Za-z0-9]'));
          if (!hasUpper || !hasNumber || !hasSymbol) {
            return 'Include upper-case letter, number, and symbol';
          }
          return null;
        },
      ),
    ];
  }

  List<Widget> _buildStepTwoFields(BuildContext context, WidgetRef ref) {
    return [
      Text(
        'Type your Nigerian street address the way you’d write it on an envelope.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
      ),
      const SizedBox(height: 20),
      TextFormField(
        controller: _addressLineController,
        decoration: const InputDecoration(
          labelText: 'Home address',
          helperText: 'Street number + street name (e.g. 12 Adeola Odeku St)',
        ),
        onChanged: (value) => _onAddressChanged(value, ref),
        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
      if (_isSearchingAddress)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: LinearProgressIndicator(minHeight: 3),
        ),
      if (!_isSearchingAddress &&
          _addressSuggestions.isEmpty &&
          _lastAddressQuery.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'No matches found. Try a nearby landmark.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.error),
          ),
        ),
      if (_addressSuggestions.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _addressSuggestions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final suggestion = _addressSuggestions[index];
              final subtitleParts = [
                if (suggestion.city?.isNotEmpty ?? false) suggestion.city!,
                if (suggestion.state?.isNotEmpty ?? false) suggestion.state!,
                if (suggestion.postalCode?.isNotEmpty ?? false) suggestion.postalCode!,
              ];
              return ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(
                  suggestion.addressLine,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: subtitleParts.isNotEmpty ? Text(subtitleParts.join(', ')) : null,
                onTap: () => _selectAddress(suggestion),
              );
            },
          ),
        ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City / Local Government',
              ),
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _stateController,
              decoration: const InputDecoration(
                labelText: 'State',
              ),
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _postalCodeController,
        decoration: const InputDecoration(
          labelText: 'Postal code',
        ),
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _notesController,
        decoration: const InputDecoration(
          labelText: 'Delivery notes or directions (optional)',
          helperText: 'Landmarks or instructions to help citizens find you',
        ),
        maxLines: 4,
      ),
    ];
  }

  List<Widget> _buildStepThreeFields(BuildContext context) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    return [
      Text(
        'Are you looking for services or offering them?',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      const SizedBox(height: 16),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(
            value: 'SERVICE_SEEKER',
            label: Text('Looking for services'),
            icon: Icon(Icons.search),
          ),
          ButtonSegment(
            value: 'SERVICE_PROVIDER',
            label: Text('Offering services'),
            icon: Icon(Icons.handyman),
          ),
        ],
        selected: {_selectedRole},
        onSelectionChanged: (Set<String> selection) {
          setState(() {
            _selectedRole = selection.first;
            if (_selectedRole == 'SERVICE_SEEKER') {
              _availableDays.clear();
              _startTime = null;
              _endTime = null;
            }
          });
        },
      ),
      if (_selectedRole == 'SERVICE_PROVIDER') ...[
        const SizedBox(height: 32),
        Text(
          'When are you available?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the days you can work',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: days.map((day) {
            final isSelected = _availableDays.contains(day);
            return FilterChip(
              label: Text(day),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _availableDays.add(day);
                  } else {
                    _availableDays.remove(day);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text(
          'Working hours',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
                  );
                  if (time != null) {
                    setState(() => _startTime = time);
                  }
                },
                icon: const Icon(Icons.access_time),
                label: Text(
                  _startTime == null
                      ? 'Start time'
                      : _startTime!.format(context),
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Text('to', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _endTime ?? const TimeOfDay(hour: 17, minute: 0),
                  );
                  if (time != null) {
                    setState(() => _endTime = time);
                  }
                },
                icon: const Icon(Icons.access_time),
                label: Text(
                  _endTime == null
                      ? 'End time'
                      : _endTime!.format(context),
                ),
              ),
            ),
          ],
        ),
      ],
    ];
  }

  List<Widget> _buildStepFourFields(BuildContext context) {
    return [
      Text(
        'Review your information',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      const SizedBox(height: 24),
      _buildReviewSection(
        context,
        'Personal Information',
        [
          _buildReviewItem('Name', '${_firstNameController.text} ${_lastNameController.text}'),
          _buildReviewItem('Phone', _phoneController.text),
          _buildReviewItem('Role', _selectedRole == 'SERVICE_PROVIDER' ? 'Service Provider' : 'Service Seeker'),
        ],
      ),
      const SizedBox(height: 16),
      _buildReviewSection(
        context,
        'Address',
        [
          _buildReviewItem('Street', _addressLineController.text),
          _buildReviewItem('City/LGA', _cityController.text),
          _buildReviewItem('State', _stateController.text),
          if (_postalCodeController.text.isNotEmpty)
            _buildReviewItem('Postal Code', _postalCodeController.text),
          if (_notesController.text.isNotEmpty)
            _buildReviewItem('Notes', _notesController.text),
        ],
      ),
      if (_selectedRole == 'SERVICE_PROVIDER') ...[
        const SizedBox(height: 16),
        _buildReviewSection(
          context,
          'Availability',
          [
            _buildReviewItem(
              'Days',
              _availableDays.isEmpty
                  ? 'None selected'
                  : (_availableDays.toList()..sort()).join(', '),
            ),
            if (_startTime != null && _endTime != null)
              _buildReviewItem(
                'Hours',
                '${_startTime!.format(context)} - ${_endTime!.format(context)}',
              ),
          ],
        ),
      ],
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'You can update this information later in your profile settings.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildReviewSection(BuildContext context, String title, List<Widget> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.status == AuthStatus.authenticating;

    final colorScheme = Theme.of(context).colorScheme;

    const headerTitles = [
      'Let’s get to know you',
      'Confirm your home address',
      'Set your availability',
      'Review & launch',
    ];
    const headerSubtitles = [
      'We’ll use this information to create your account and help neighbours reach you.',
      'We deliver Nigeria-specific matches—confirm where citizens can find you.',
      'Let citizens know when you’re available to take on work.',
      'Double-check your details before going live.',
    ];
    const sectionTitles = [
      'Basic info',
      'Home address',
      'Availability',
      'Review',
    ];
    const stepChipTexts = [
      '2–3 mins to complete',
      '1 min',
      '< 1 min',
      'Almost done',
    ];

    final headerTitle = headerTitles[_currentStep - 1];
    final headerSubtitle = headerSubtitles[_currentStep - 1];
    final sectionTitle = sectionTitles[_currentStep - 1];
    final chipText = stepChipTexts[_currentStep - 1];

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.emoji_emotions_rounded,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            headerTitle,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            headerSubtitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withValues(alpha: 0.75),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    sectionTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      chipText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: _currentStep / _totalSteps,
                  minHeight: 6,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                      child: Form(
                        key: _activeFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: const BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: colorScheme.surface,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '$_currentStep',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                      TextSpan(
                                        text: ' of ',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(fontWeight: FontWeight.w500),
                                      ),
                                      TextSpan(
                                        text: '$_totalSteps',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            if (_currentStep == 1)
                              ..._buildStepOneFields(context)
                            else if (_currentStep == 2)
                              ..._buildStepTwoFields(context, ref)
                            else if (_currentStep == 3)
                              ..._buildStepThreeFields(context)
                            else if (_currentStep == 4)
                              ..._buildStepFourFields(context),
                            const SizedBox(height: 28),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.black87,
                                      side: const BorderSide(color: Colors.black87),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 12,
                                      ),
                                    ),
                                    onPressed: _currentStep == 1
                                        ? () => context.pop()
                                        : isLoading
                                            ? null
                                            : () => setState(() => _currentStep--),
                                    icon: const Icon(Icons.arrow_back),
                                    label: const Text('Back'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black87,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 12,
                                      ),
                                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: isLoading ? null : _handleNext,
                                    icon: _currentStep == 4
                                        ? const Icon(Icons.check)
                                        : const Icon(Icons.arrow_forward),
                                    label: isLoading
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : Text(_currentStep == 4 ? 'Create Account' : 'Next'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            if (_currentStep == 1)
                              TextButton(
                                onPressed: () => context.pop(),
                                child: Text(
                                  'Already have an account? Sign in',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

