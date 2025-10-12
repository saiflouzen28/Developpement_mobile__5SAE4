import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'database/database_helper.dart';
import 'providers/auth_provider.dart';
import 'providers/events_provider.dart';
import 'core/constant/app_theme.dart';
import 'core/constant/app_route.dart';
import 'views/screens/auth/sign_in_screen.dart';
import 'views/screens/auth/sign_up_screen.dart';
import 'views/screens/events/events_screen.dart';
import 'views/screens/events/event_details_screen.dart';
import 'views/screens/schedule/schedule_screen.dart';
import 'views/screens/profile/profile_screen.dart';
import 'views/screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EventsProvider()),
      ],
      child: MaterialApp(
        title: 'E-Learning Events',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        initialRoute: AppRoute.signIn,
        routes: {
          AppRoute.signIn: (_) => const SignInScreen(),
          AppRoute.signUp: (_) => const SignUpScreen(),
          AppRoute.home: (_) => const HomeScreen(),
          AppRoute.events: (_) => const EventsScreen(),
          AppRoute.eventDetails: (_) => const EventDetailsScreen(),
          AppRoute.schedule: (_) => const ScheduleScreen(),
          AppRoute.profile: (_) => const ProfileScreen(),
        },
      ),
    );
  }
}