import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/constant/app_theme.dart';
import '../../../models/event_model.dart';
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
  bool _isGeneratingImage = false;
  String _generationStatus = '';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _descriptionController = TextEditingController(text: widget.event?.description ?? '');
    _locationController = TextEditingController(text: widget.event?.location ?? '');
    _imageUrlController = TextEditingController(text: widget.event?.imageUrl ?? '');
    _maxParticipantsController = TextEditingController(text: widget.event?.maxParticipants.toString() ?? '30');
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

  Future<void> _generateImage() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title first to generate an image.'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    setState(() {
      _isGeneratingImage = true;
      _generationStatus = 'Generating image with AI...';
    });

    try {
      // Use Unsplash API for free, high-quality images based on keywords
      final keyword = _titleController.text.toLowerCase();
      final category = _selectedCategory.toLowerCase();

      // Extract keywords from title
      final searchQuery = '$keyword $category event conference'.replaceAll(RegExp(r'[^\w\s]'), '');

      final response = await http.get(
        Uri.parse('https://api.unsplash.com/photos/random?query=$searchQuery&orientation=landscape'),
        headers: {
          'Authorization': 'Client-ID 0x3xLCnqXbhTEVறறலMPE5lD6UlHAMdj5Ox3mMT_I', // Demo key
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final imageUrl = data['urls']['regular'] as String;

        setState(() {
          _imageUrlController.text = imageUrl;
          _generationStatus = '';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image generated successfully!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } else {
        throw Exception('Failed to fetch image: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to category-based default images
      final categoryImages = {
        'Development': 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?auto=format&fit=crop&q=80&w=1000',
        'Data Science': 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?auto=format&fit=crop&q=80&w=1000',
        'Design': 'https://images.unsplash.com/photo-1561070791-2526d30994b5?auto=format&fit=crop&q=80&w=1000',
        'Marketing': 'https://images.unsplash.com/photo-1557804506-669a67965ba0?auto=format&fit=crop&q=80&w=1000',
        'Technology': 'https://images.unsplash.com/photo-1519389950473-47ba0277781c?auto=format&fit=crop&q=80&w=1000',
        'AI': 'https://images.unsplash.com/photo-1677442136019-21780ecad995?auto=format&fit=crop&q=80&w=1000',
      };

      setState(() {
        _imageUrlController.text = categoryImages[_selectedCategory] ??
            'https://images.unsplash.com/photo-1540575467063-178a50c2df87?auto=format&fit=crop&q=80&w=1000';
        _generationStatus = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Using default image for $_selectedCategory category'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingImage = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
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
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
    final double? latitude = double.tryParse(_latitudeController.text);
    final double? longitude = double.tryParse(_longitudeController.text);

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

    bool success = widget.isEditing
        ? await eventsProvider.updateEvent(eventData)
        : await eventsProvider.addEvent(eventData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Event saved successfully!' : 'Failed to save event.'),
          backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
        ),
      );
      if (success) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Event' : 'Add New Event'),
        backgroundColor: AppTheme.errorColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _submitForm,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) => v!.isEmpty ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (v) => v!.isEmpty ? 'Please enter a description' : null,
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: ['Development', 'Data Science', 'Design', 'Marketing', 'Technology', 'AI']
                      .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                  validator: (v) => v!.isEmpty ? 'Please enter a location' : null,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitudeController,
                        decoration: const InputDecoration(labelText: 'Latitude'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _longitudeController,
                        decoration: const InputDecoration(labelText: 'Longitude'),
                        keyboardType: TextInputType.number,
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
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Image URL with AI generation button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _imageUrlController,
                            decoration: const InputDecoration(
                              labelText: 'Image URL',
                              hintText: 'Or generate with AI',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: _isGeneratingImage ? null : _generateImage,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: _isGeneratingImage
                                    ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                                    : const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_generationStatus.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _generationStatus,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_imageUrlController.text.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _imageUrlController.text,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 150,
                              color: Colors.grey[300],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 150,
                              color: Colors.grey[300],
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Failed to load image', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _maxParticipantsController,
                  decoration: const InputDecoration(labelText: 'Max Participants'),
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.isEmpty || int.tryParse(v) == null)
                      ? 'Please enter a valid number'
                      : null,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _dateController,
                        decoration: const InputDecoration(
                          labelText: 'Event Date',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _timeController,
                        decoration: const InputDecoration(
                          labelText: 'Event Time',
                          suffixIcon: Icon(Icons.access_time),
                        ),
                        readOnly: true,
                        onTap: () => _selectTime(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(widget.isEditing ? 'Update Event' : 'Add Event'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}