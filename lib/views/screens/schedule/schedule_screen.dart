import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart'; // Add this import for date formatting

import '../../../providers/auth_provider.dart';
import '../../../providers/events_provider.dart';
import '../../../models/event_model.dart';
import '../../../core/constant/app_route.dart';
import '../../../core/constant/app_theme.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late Future<List<Event>> _loadUserEventsFuture;

  // NEW: State variables for the new UI
  Map<String, List<Event>> _groupedEvents = {};
  List<String> _uniqueDates = [];
  String? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadUserEventsFuture = _loadUserEvents();
  }

  Future<List<Event>> _loadUserEvents() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final eventsProvider = Provider.of<EventsProvider>(context, listen: false);

    if (authProvider.user != null) {
      // Fetch events and then group them
      return eventsProvider.getUserEvents(authProvider.user!.id!).then((events) {
        // This is a new method to process the data for our UI
        _groupAndSetEvents(events);
        return events;
      });
    }
    return Future.value([]);
  }

  // NEW: Helper method to group events by date
  void _groupAndSetEvents(List<Event> events) {
    // Prevent calling setState on a disposed widget
    if (!mounted) return;

    final grouped = <String, List<Event>>{};
    for (final event in events) {
      final dateKey = event.eventDate; // Using 'YYYY-MM-DD' as the key
      if (grouped[dateKey] == null) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(event);
    }

    setState(() {
      _groupedEvents = grouped;
      _uniqueDates = grouped.keys.toList()..sort(); // Sort dates chronologically
      // If there are dates, select the first one by default
      if (_uniqueDates.isNotEmpty) {
        _selectedDate = _uniqueDates.first;
      } else {
        _selectedDate = null;
      }
    });
  }

  Future<void> _refreshEvents() async {
    setState(() {
      _loadUserEventsFuture = _loadUserEvents();
    });
  }

  // NEW: Helper to format date for display in the chip
  String _formatDateForDisplay(String date) {
    try {
      final dateTime = DateTime.parse(date);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = DateTime(now.year, now.month, now.day + 1);

      if (dateTime == today) {
        return 'Today';
      } else if (dateTime == tomorrow) {
        return 'Tomorrow';
      } else {
        // Format as "Sat, Oct 25"
        return DateFormat('EEE, MMM d').format(dateTime);
      }
    } catch (e) {
      return date; // Fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedule'),
      ),
      body: SafeArea(
        child: authProvider.user == null
            ? _buildLoginPrompt()
            : RefreshIndicator(
          onRefresh: _refreshEvents,
          child: FutureBuilder<List<Event>>(
            future: _loadUserEventsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
              }
              if (snapshot.hasError) {
                return _buildErrorWidget(snapshot.error.toString());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyWidget();
              }

              // *** NEW UI STRUCTURE ***
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Horizontal Date Selector
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
                      itemCount: _uniqueDates.length,
                      itemBuilder: (context, index) {
                        final date = _uniqueDates[index];
                        final isSelected = date == _selectedDate;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ChoiceChip(
                            label: Text(_formatDateForDisplay(date)),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedDate = date;
                                });
                              }
                            },
                            selectedColor: AppTheme.primaryColor,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : null,
                              fontWeight: FontWeight.w600,
                            ),
                            backgroundColor: Theme.of(context).cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                              side: BorderSide(
                                color: isSelected ? AppTheme.primaryColor : Theme.of(context).dividerColor,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // List of Events for the Selected Date
                  Expanded(
                    child: _buildEventsListForSelectedDate(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, AppRoute.events);
              break;
            case 2:
              Navigator.pushReplacementNamed(context, AppRoute.profile);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // NEW: Widget builder for the filtered list
  Widget _buildEventsListForSelectedDate() {
    // Get events for the selected date, or an empty list if no date is selected
    final eventsForDate = _selectedDate != null ? _groupedEvents[_selectedDate!] ?? [] : [];

    if (eventsForDate.isEmpty) {
      // This state can happen if there's a logic error, but it's good to handle
      return const Center(
        child: Text("No events found for this day.", style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: eventsForDate.length,
      itemBuilder: (context, index) {
        final event = eventsForDate[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ScheduledEventCard(
            event: event,
            onTap: () {
              Navigator.pushNamed(context, AppRoute.eventDetails, arguments: event);
            },
          ),
        );
      },
    );
  }

  // No changes needed for the widgets below
  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Please login to view your schedule', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoute.signIn),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Failed to load schedule: $error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _refreshEvents,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_note, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No events scheduled yet', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Join events to see them in your schedule', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, AppRoute.events),
            child: const Text('Browse Events'),
          ),
        ],
      ),
    );
  }
}

// ScheduledEventCard is UNCHANGED from your working version
class ScheduledEventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const ScheduledEventCard({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: GestureDetector(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                  child: SizedBox(
                    width: 120,
                    child: event.imageUrl != null
                        ? CachedNetworkImage(
                      imageUrl: event.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(color: Colors.white),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        child: const Icon(Icons.event, size: 40, color: AppTheme.primaryColor),
                      ),
                    )
                        : Container(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      child: const Icon(Icons.event, size: 40, color: AppTheme.primaryColor),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: [
                            _buildChip('Joined', AppTheme.successColor),
                            _buildChip(event.category, AppTheme.primaryColor),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(event.formattedDate, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(event.formattedTime, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            minimumSize: const Size(double.infinity, 36),
                          ),
                          child: const Text('View Details'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
