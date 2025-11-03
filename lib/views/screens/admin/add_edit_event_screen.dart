import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constant/app_theme.dart';import '../../../models/event_model.dart';
import '../../../providers/events_provider.dart';
import 'map_picker_screen.dart';

class AddEditEventScreen extends StatefulWidget {
  final Event? event;
  const AddEditEventScreen({super.key, this.event});
  bool get isEditing => event != null;
  @override
  State<AddEditEventScreen> createState() => _AddEditEventScreenState();
}

class _AddEditEventScreenState extends State<AddEditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _imageUrlController;
  late TextEditingController _maxParticipantsController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;

  String _selectedCategory = 'Development';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _descriptionController = TextEditingController(text: widget.event?.description ?? '');
    _locationController = TextEditingController(text: widget.event?.location ?? '');
    _imageUrlController = TextEditingController(text: widget.event?.imageUrl ?? '');
    _maxParticipantsController = TextEditingController(text: widget.event?.maxParticipants.toString() ?? '');
    _latitudeController = TextEditingController(text: widget.event?.latitude?.toString() ?? '');
    _longitudeController = TextEditingController(text: widget.event?.longitude?.toString() ?? '');

    if (widget.isEditing) {
      _selectedCategory = widget.event!.category;
      _selectedDate = DateTime.parse(widget.event!.eventDate);
      final timeParts = widget.event!.eventTime.split(':');
      _selectedTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
    }

    _dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(_selectedDate));
    _timeController = TextEditingController(text: '');
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      _timeController.text = _selectedTime.format(context);
      _isInit = false;
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _imageUrlController.dispose();
    _maxParticipantsController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2101),
      // --- THEME CHANGE FOR DATE PICKER ---
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.errorColor, // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorColor, // button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      // --- THEME CHANGE FOR TIME PICKER ---
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.errorColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = _selectedTime.format(context);
      });
    }
  }

  Future<void> _openMapPicker() async {
    final initialLat = double.tryParse(_latitudeController.text);
    final initialLng = double.tryParse(_longitudeController.text);
    LatLng initialPoint = (initialLat != null && initialLng != null)
        ? LatLng(initialLat, initialLng)
        : const LatLng(36.7753, 3.0602);

    final LatLng? pickedLocation = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => MapPickerScreen(initialLocation: initialPoint),
      ),
    );

    if (pickedLocation != null) {
      setState(() {
        _latitudeController.text = pickedLocation.latitude.toStringAsFixed(6);
        _longitudeController.text = pickedLocation.longitude.toStringAsFixed(6);
      });
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    final eventsProvider = Provider.of<EventsProvider>(context, listen: false);

    final double? latitude = _latitudeController.text.isEmpty ? null : double.tryParse(_latitudeController.text);
    final double? longitude = _longitudeController.text.isEmpty ? null : double.tryParse(_longitudeController.text);

    final eventData = Event(
      id: widget.event?.id,
      title: _titleController.text,
      description: _descriptionController.text,
      location: _locationController.text,
      imageUrl: _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
      category: _selectedCategory,
      eventDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
      eventTime: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
      maxParticipants: int.parse(_maxParticipantsController.text),
      latitude: latitude,
      longitude: longitude,
      currentParticipants: widget.event?.currentParticipants ?? 0,
      createdBy: 1,
    );

    bool success;
    if (widget.isEditing) {
      success = await eventsProvider.updateEvent(eventData);
    } else {
      success = await eventsProvider.addEvent(eventData);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Event saved successfully!' : 'Failed to save event.'),
          backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
        ),
      );
      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Event' : 'Add New Event'),
        // --- COLOR CHANGE ---
        backgroundColor: AppTheme.errorColor,
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _submitForm)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title'), validator: (v) => v!.isEmpty ? 'Please enter a title' : null),
                const SizedBox(height: 12),
                TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3, validator: (v) => v!.isEmpty ? 'Please enter a description' : null),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: ['Development', 'Data Science', 'Design', 'Marketing', 'Technology', 'AI'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location'), validator: (v) => v!.isEmpty ? 'Please enter a location' : null),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitudeController,
                        decoration: const InputDecoration(labelText: 'Latitude'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        validator: (value) {
                          if (value != null && value.isNotEmpty && double.tryParse(value) == null) return 'Invalid number';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _longitudeController,
                        decoration: const InputDecoration(labelText: 'Longitude'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        validator: (value) {
                          if (value != null && value.isNotEmpty && double.tryParse(value) == null) return 'Invalid number';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openMapPicker,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text("Select Location on Map"),
                    // --- THEME CHANGE FOR BUTTON ---
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: const BorderSide(color: AppTheme.errorColor),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(controller: _imageUrlController, decoration: const InputDecoration(labelText: 'Image URL')),
                const SizedBox(height: 12),
                TextFormField(controller: _maxParticipantsController, decoration: const InputDecoration(labelText: 'Max Participants'), keyboardType: TextInputType.number, validator: (v) => (v == null || v.isEmpty || int.tryParse(v) == null) ? 'Please enter a valid number' : null),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextFormField(controller: _dateController, decoration: const InputDecoration(labelText: 'Event Date', suffixIcon: Icon(Icons.calendar_today)), readOnly: true, onTap: () => _selectDate(context))),
                    const SizedBox(width: 16),
                    Expanded(child: TextFormField(controller: _timeController, decoration: const InputDecoration(labelText: 'Event Time', suffixIcon: Icon(Icons.access_time)), readOnly: true, onTap: () => _selectTime(context))),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _submitForm, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor, padding: const EdgeInsets.symmetric(vertical: 16)), child: Text(widget.isEditing ? 'Update Event' : 'Add Event'))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
