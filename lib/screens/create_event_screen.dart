import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date/time formatting
import '../screens/venue_results_screen.dart'; // Screen to navigate to

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>(); // For input validation

  // --- Controllers ---
  final _eventNameController = TextEditingController();
  final _guestCountController = TextEditingController(text: '50'); // Start with a default
  final _notesController = TextEditingController(); // Optional notes field

  // --- State Variables ---
  String? _selectedEventType; // Use dropdown
  DateTime? _selectedDate; // Store full DateTime
  TimeOfDay? _selectedTime; // Store TimeOfDay
  double _budget = 50000; // Default budget
  bool _isLoading = false; // For submit button loading state

  // Add more service toggles if needed
  bool _needsCatering = false;
  bool _needsPhotography = false;
  bool _needsMusic = false;
  bool _needsDecor = false;

  // --- Services List for Checkboxes/Chips (Expand this) ---
  final List<String> _allServices = ['Catering', 'Photography', 'Music/DJ', 'Decoration', 'Venue Finding', 'Invitations'];
  final Set<String> _selectedServices = {}; // Track selected services


  // --- Firestore / Auth Instances ---
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Event Type Options ---
  final List<String> _eventTypes = [ // Make this more comprehensive
    'Wedding', 'Reception', 'Engagement', 'Sangeet', 'Mehndi', 'Haldi',
    'Birthday Party', 'Anniversary', 'Baby Shower', 'Naming Ceremony',
    'House Warming', 'Corporate Event', 'Conference', 'Seminar', 'Product Launch',
    'Get-Together', 'Festival Celebration', 'Other'
  ];

  @override
  void dispose() {
    _eventNameController.dispose();
    _guestCountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // --- Date Picker Logic ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 7)), // Default to a week from now
      firstDate: DateTime.now(), // Cannot select past dates
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)), // Allow up to 3 years ahead
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
      // Optionally auto-open time picker after date selection
      if (_selectedTime == null && context.mounted) {
        _selectTime(context);
      }
    }
  }

  // --- Time Picker Logic ---
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  // --- Helper to combine Date and Time ---
  DateTime? _getCombinedDateTime() {
    if (_selectedDate == null) return null;
    // Use midnight if time not selected, or combine date and time
    final time = _selectedTime ?? const TimeOfDay(hour: 0, minute: 0);
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      time.hour,
      time.minute,
    );
  }

  // --- Format Date/Time for Display ---
  String _getFormattedDateTime() {
    final dateTime = _getCombinedDateTime();
    if (dateTime == null) return 'Select Date & Time';
    // Example Format: Sat, 18 May 2024 • 7:30 PM
    return DateFormat('EEE, d MMM yyyy • h:mm a').format(dateTime);
  }


  // --- Submit Logic: Save to Firestore & Navigate ---
  Future<void> _submitForm() async {
    // Validate form inputs
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Please fix the errors in the form.');
      return;
    }
    // Ensure date/time is selected
    if (_selectedDate == null || _selectedTime == null) {
      _showErrorSnackBar('Please select both a date and a time for the event.');
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      _showErrorSnackBar('You must be logged in to create an event.');
      return;
    }

    _dismissKeyboard();
    setState(() { _isLoading = true; });

    final combinedDateTime = _getCombinedDateTime()!; // We validated date/time above
    final guestCount = int.tryParse(_guestCountController.text.trim()) ?? 0;

    // Prepare data for Firestore
    final eventData = {
      'userId': user.uid, // Link event to user
      'name': _eventNameController.text.trim(),
      'type': _selectedEventType, // From dropdown
      'date': Timestamp.fromDate(combinedDateTime), // Store as Firestore Timestamp
      'guestCount': guestCount,
      'budget': _budget.toInt(), // Use the slider value
      'status': 'planning', // Initial status
      'createdAt': FieldValue.serverTimestamp(), // Record creation time
      'notes': _notesController.text.trim(), // Optional notes
      // Store selected services as a list
      'servicesNeeded': _selectedServices.toList(),
      // Optionally store basic user info for easier querying/display (denormalization)
      // 'userName': user.displayName ?? user.email,
      // 'userEmail': user.email,
    };

    try {
      // Add the event document to the 'events' collection
      DocumentReference eventRef = await _firestore.collection('events').add(eventData);
      String newEventId = eventRef.id; // Get the ID of the newly created event

      debugPrint("Event created successfully with ID: $newEventId");

      // Prepare details to pass to the next screen
      final eventDetailsForNextScreen = {
        'id': newEventId, // <-- PASS THE NEW EVENT ID
        'name': eventData['name'],
        'type': eventData['type'],
        'date': combinedDateTime, // Pass DateTime object for easier use
        'guestCount': eventData['guestCount'],
        'budget': eventData['budget'],
        // Pass needed services derived from _selectedServices
        'needCatering': _selectedServices.contains('Catering'),
        'needDecoration': _selectedServices.contains('Decoration'),
        'needPhotography': _selectedServices.contains('Photography'),
        'needMusic': _selectedServices.contains('Music/DJ'),
        // Add other needed services flags...
      };

      // Navigate to results screen on success, passing the created event's ID and details
      if (mounted) {
        Navigator.pushReplacement( // Use replacement so user doesn't go back to create form
          context,
          MaterialPageRoute(
            builder: (_) => VenueResultsScreen(eventDetails: eventDetailsForNextScreen),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error saving event: $e");
      _showErrorSnackBar('Failed to create event: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }


  // --- Helper to show SnackBar ---
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.redAccent[700],
      behavior: SnackBarBehavior.floating,
    ));
  }

  // --- Helper to dismiss keyboard ---
  void _dismissKeyboard() {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  // --- ================== Main Build Method ================== ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Plan New Event"),
        centerTitle: true,
        elevation: 1,
      ),
      body: GestureDetector(
        onTap: _dismissKeyboard,
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Event Details Section ---
                Text('Event Details', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Event Name
                TextFormField(
                  controller: _eventNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Event Name*', border: OutlineInputBorder(), prefixIcon: Icon(Icons.event)),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter event name' : null,
                ),
                const SizedBox(height: 16),

                // Event Type Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedEventType,
                  hint: const Text('Select Event Type*'),
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.category_outlined)),
                  items: _eventTypes.map((String type) {
                    return DropdownMenuItem<String>(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() { _selectedEventType = newValue; });
                  },
                  validator: (value) => (value == null) ? 'Please select an event type' : null,
                ),
                const SizedBox(height: 16),

                // Date & Time Picker Input
                TextFormField(
                  // Use a dummy controller or key to display formatted date/time
                  key: ValueKey(_getFormattedDateTime()), // Rebuilds when value changes
                  initialValue: _getFormattedDateTime(),
                  readOnly: true,
                  decoration: InputDecoration(
                      labelText: 'Date & Time*',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      suffixIcon: IconButton( // Allow picking time separately too
                        icon: const Icon(Icons.access_time_outlined),
                        tooltip: "Select Time",
                        onPressed: () => _selectTime(context),
                      )
                  ),
                  onTap: () => _selectDate(context), // Tap anywhere to open date picker first
                  validator: (value) => (_selectedDate == null || _selectedTime == null) ? 'Please pick a date and time' : null,
                ),
                const SizedBox(height: 24),


                // --- Logistics Section ---
                Text('Logistics', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Guest Count
                TextFormField(
                  controller: _guestCountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Estimated Guest Count*', border: OutlineInputBorder(), prefixIcon: Icon(Icons.people_outline)),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter guest count';
                    final count = int.tryParse(value);
                    if (count == null || count <= 0) return 'Must be a positive number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Budget Slider
                Text('Estimated Budget (₹)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('₹ 50k', style: theme.textTheme.bodySmall),
                    Expanded(
                      child: Slider(
                        value: _budget,
                        min: 50000,  // Min budget INR 50k
                        max: 100000, // Max budget INR 1 Lakh
                        divisions: 190, // Creates steps
                        label: '₹${(_budget / 1000).toStringAsFixed(_budget < 100000 ? 1 : 0)}k', // Show in thousands
                        onChanged: (value) { setState(() { _budget = value; }); },
                      ),
                    ),
                    Text('₹ 1L', style: theme.textTheme.bodySmall),
                  ],
                ),
                Center(child: Text('Approx. ₹${NumberFormat.decimalPattern('en_IN').format(_budget.toInt())}', style: theme.textTheme.titleMedium)),
                const SizedBox(height: 24),

                // --- Services Needed Section ---
                Text('Services Required', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap( // Layout chips nicely
                  spacing: 8.0, // Horizontal space between chips
                  runSpacing: 4.0, // Vertical space between lines of chips
                  children: _allServices.map((service) {
                    bool isSelected = _selectedServices.contains(service);
                    return FilterChip(
                      label: Text(service),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) { _selectedServices.add(service); }
                          else { _selectedServices.remove(service); }
                        });
                      },
                      selectedColor: colorScheme.primaryContainer.withOpacity(0.7),
                      checkmarkColor: colorScheme.onPrimaryContainer,
                      pressElevation: 1,
                      elevation: isSelected ? 0 : 1, // Flat when selected
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // --- Optional Notes ---
                Text('Additional Notes (Optional)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    hintText: 'Any specific requests or details...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 32),


                // --- Submit Button ---
                Center(
                  child: SizedBox(
                    width: double.infinity, // Stretch button
                    height: 50, // Standard button height
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_forward),
                      label: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text("Find Venues & Services"),
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }
}