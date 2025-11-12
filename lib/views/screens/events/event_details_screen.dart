import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/events_provider.dart';
import '../../../providers/wallet_provider.dart'; // Import Wallet Provider
import '../../../models/event_model.dart';
import '../../../core/constant/app_theme.dart';
import '../../../core/constant/app_route.dart';
import '../../../services/share_service.dart';

class EventDetailsScreen extends StatefulWidget {
  const EventDetailsScreen({super.key});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _isProcessing = false; // Use a single flag for processing
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRegistrationStatus();
    });
  }

  Future<void> _checkRegistrationStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
    if (!mounted) return;
    final event = ModalRoute.of(context)!.settings.arguments as Event;

    if (authProvider.user != null) {
      final registered = await eventsProvider.isUserRegisteredForEvent(
        authProvider.user!.id!,
        event.id!,
      );
      if (mounted) {
        setState(() {
          _isRegistered = registered;
        });
      }
    }
  }

  // <<< THIS IS THE NEW METHOD THAT HANDLES COIN PAYMENT >>>
  Future<void> _handlePurchaseAndJoinEvent() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    if (!mounted) return;
    final event = ModalRoute.of(context)!.settings.arguments as Event;
    final user = authProvider.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to join events'), backgroundColor: AppTheme.errorColor),
      );
      return;
    }

    // 1. Check coin balance
    if (walletProvider.coins < event.coinPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Not enough coins! You need ${event.coinPrice}.'), backgroundColor: AppTheme.errorColor),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // 2. Spend coins
    final paymentSuccess = walletProvider.spendCoins(event.coinPrice);

    if (paymentSuccess) {
      // 3. If payment succeeds, join event
      final joinSuccess = await eventsProvider.joinEvent(user, event);
      if (joinSuccess) {
        // Also refresh the user's event list for the schedule page
        await Provider.of<EventsProvider>(context, listen: false).getUserEvents(user.id!);
        if (mounted) {
          setState(() => _isRegistered = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Success! Joined for ${event.coinPrice} coins.'), backgroundColor: AppTheme.successColor),
          );
        }
      } else {
        // If joining fails for some reason, refund the coins
        walletProvider.addCoins(event.coinPrice);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to join. You may already be registered.'), backgroundColor: AppTheme.errorColor),
          );
        }
      }
    } else {
      // This case should not happen if the check above works, but as a fallback:
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment failed. Please try again.'), backgroundColor: AppTheme.errorColor),
      );
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleLeaveEvent() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
    if (!mounted) return;
    final event = ModalRoute.of(context)!.settings.arguments as Event;

    setState(() => _isProcessing = true);

    final success = await eventsProvider.leaveEvent(
      authProvider.user!.id!,
      event.id!,
    );

    if (success) {
      // Also refresh the user's event list for the schedule page
      await Provider.of<EventsProvider>(context, listen: false).getUserEvents(authProvider.user!.id!);
      if (mounted) {
        setState(() => _isRegistered = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully left the event'), backgroundColor: AppTheme.warningColor),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to leave event'), backgroundColor: AppTheme.errorColor),
        );
      }
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleShareEvent() async {
    if (!mounted) return;
    final event = ModalRoute.of(context)!.settings.arguments as Event;
    await ShareService.shareEvent(event);
  }

  @override
  Widget build(BuildContext context) {
    final event = ModalRoute.of(context)!.settings.arguments as Event;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      // The body of the screen is now wrapped in a WillPopScope
      // to handle the Android back button correctly with the bottom nav bar.
      body: WillPopScope(
        onWillPop: () async {
          // When the back button is pressed, navigate to the main events screen
          // instead of just popping the context.
          Navigator.pushReplacementNamed(context, AppRoute.events);
          // Return false to prevent the default pop behavior.
          return false;
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              // Overwrite the default back arrow to navigate correctly
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoute.events),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Hero(
                  tag: 'event-${event.id}',
                  child: event.imageUrl != null
                      ? CachedNetworkImage(
                    imageUrl: event.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      child: const Icon(Icons.event, size: 80, color: AppTheme.primaryColor),
                    ),
                  )
                      : Container(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    child: const Icon(Icons.event, size: 80, color: AppTheme.primaryColor),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              event.category,
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            event.title,
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Event Details',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            icon: Icons.calendar_today,
                            title: 'Date & Time',
                            subtitle: event.eventDateTime,
                          ),
                          const SizedBox(height: 16),
                          if (event.latitude != null && event.longitude != null)
                            _buildOpenStreetMapSection(event)
                          else
                            _buildDetailRow(
                              icon: Icons.location_on,
                              title: 'Location',
                              subtitle: event.location,
                            ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            icon: Icons.people,
                            title: 'Available Seats',
                            subtitle: '${event.availableSeats} of ${event.maxParticipants} remaining',
                          ),
                          const SizedBox(height: 16),
                          // <<< NEW WIDGET TO SHOW THE PRICE >>>
                          _buildDetailRow(
                            icon: Icons.monetization_on,
                            title: 'Price',
                            subtitle: '${event.coinPrice} coins',
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Registration Progress',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: event.progress,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    event.hasAvailableSeats ? AppTheme.successColor : AppTheme.errorColor,
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${event.currentParticipants} registered, ${event.availableSeats} spots left',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: event.hasAvailableSeats ? AppTheme.successColor : AppTheme.errorColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About This Event',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            event.description,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 300),
                      child: Column(
                        children: [
                          if (authProvider.user == null)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, AppRoute.signIn);
                                },
                                child: const Text('Login to Join Event'),
                              ),
                            )
                          else if (_isRegistered)
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _isProcessing ? null : _handleLeaveEvent,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.errorColor,
                                      side: const BorderSide(color: AppTheme.errorColor, width: 2),
                                    ),
                                    child: _isProcessing
                                        ? const SizedBox(
                                      height: 20, width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.errorColor)),
                                    )
                                        : const Text('Leave Event'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: null,
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                                    child: const Text('Already Joined ✓'),
                                  ),
                                ),
                              ],
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                // <<< USE THE NEW PURCHASE METHOD >>>
                                onPressed: event.isFull || _isProcessing ? null : _handlePurchaseAndJoinEvent,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: event.isFull ? AppTheme.errorColor : AppTheme.primaryColor,
                                ),
                                child: _isProcessing
                                    ? const SizedBox(
                                  height: 20, width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                )
                                // <<< UPDATE BUTTON TEXT TO SHOW PRICE >>>
                                    : Text(event.isFull ? 'Event Full' : 'Join for ${event.coinPrice} Coins'),
                              ),
                            ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _handleShareEvent,
                              icon: const Icon(Icons.share),
                              label: const Text('Share Event'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryColor,
                                side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // <<< ADD THE BOTTOM NAVIGATION BAR >>>
      bottomNavigationBar: BottomNavigationBar(
        // The current index is 0 because this screen is part of the "Events" flow.
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
            // If already on events flow, do nothing or go to main events screen
              Navigator.pushReplacementNamed(context, AppRoute.events);
              break;
            case 1:
              Navigator.pushReplacementNamed(context, AppRoute.schedule);
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

  Widget _buildOpenStreetMapSection(Event event) {
    // This method is unchanged
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text( 'Location', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(event.location, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(event.latitude!, event.longitude!),
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.filmpro',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(event.latitude!, event.longitude!),
                      width: 50,
                      height: 50,
                      child: const Icon(Icons.location_pin, size: 50, color: AppTheme.errorColor),
                    ),
                  ],
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution( 'OpenStreetMap contributors', onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright'))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool showArrow = false,
  }) {
    // This method is unchanged
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (showArrow) const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
