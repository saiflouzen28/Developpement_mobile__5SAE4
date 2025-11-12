import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constant/app_theme.dart';
import '../../../models/event_model.dart';
import '../../../providers/events_provider.dart';
import 'add_edit_event_screen.dart';

class ManageEventsScreen extends StatefulWidget {
  const ManageEventsScreen({super.key});

  @override
  State<ManageEventsScreen> createState() => _ManageEventsScreenState();
}

class _ManageEventsScreenState extends State<ManageEventsScreen> {
  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to safely call the provider after the build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use listen: false in initState
      final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
      if (eventsProvider.events.isEmpty) {
        eventsProvider.loadEvents();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use a Consumer to rebuild the UI when the events list changes
    return Consumer<EventsProvider>(
      builder: (context, eventsProvider, child) {
        // This Scaffold should NOT have an AppBar, as the parent provides it.
        return Scaffold(
          body: eventsProvider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.errorColor)) // Admin color
              : RefreshIndicator(
            onRefresh: () => eventsProvider.loadEvents(),
            color: AppTheme.errorColor, // Admin color
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: eventsProvider.events.length,
              itemBuilder: (context, index) {
                final event = eventsProvider.events[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  elevation: 3,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.errorColor.withOpacity(0.1),
                      child: const Icon(Icons.event, color: AppTheme.errorColor),
                    ),
                    title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${event.location} on ${event.formattedDate}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppTheme.primaryColor), // Using theme color
                          onPressed: () {
                            // Navigate to the edit screen, pushing it over the main admin UI
                            Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(
                                builder: (ctx) => AddEditEventScreen(event: event),
                              ),
                            ).then((_) {
                              // Refresh events when returning from the edit screen
                              Provider.of<EventsProvider>(context, listen: false).loadEvents();
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                          onPressed: () {
                            _confirmDelete(context, eventsProvider, event);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // Navigate to the add screen
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (ctx) => const AddEditEventScreen(),
                ),
              ).then((_) {
                // Refresh events when returning from the add screen
                Provider.of<EventsProvider>(context, listen: false).loadEvents();
              });
            },
            backgroundColor: AppTheme.errorColor,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, EventsProvider provider, Event event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete the event "${event.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            onPressed: () async {
              Navigator.of(ctx).pop(); // Close the dialog
              await provider.deleteEvent(event.id!);
              // The Consumer will automatically rebuild the list, no need for manual refresh here
            },
          ),
        ],
      ),
    );
  }
}
