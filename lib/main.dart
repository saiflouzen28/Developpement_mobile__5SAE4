import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart'; // ← pour getDatabasesPath et deleteDatabase
import 'package:path/path.dart'; // ← pour join()

import 'database/database_helper.dart';
import 'providers/auth_provider.dart';
import 'providers/events_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/quizzes_provider.dart';
import 'providers/questionsprovider.dart';
import 'providers/posts_provider.dart';
import 'providers/comment_provider.dart';
import 'providers/notifications_provider.dart';
import 'core/constant/app_theme.dart';
import 'core/constant/app_route.dart';
import 'views/screens/auth/sign_in_screen.dart';
import 'views/screens/auth/sign_up_screen.dart';
import 'views/screens/home/home_screen.dart';
import 'views/screens/events/events_screen.dart';
import 'views/screens/events/event_details_screen.dart';
import 'views/screens/schedule/schedule_screen.dart';
import 'views/screens/profile/profile_screen.dart';
import 'views/screens/postulation/posts_list_screen.dart';
import 'views/screens/postulation/create_post_screen.dart';
import 'views/screens/notifications/notifications_screen.dart';
import 'views/screens/quizze/quizze_screen.dart';
import 'views/screens/packs/pack_store_screen.dart';
import 'views/screens/packs/stripe_test_page.dart';
import 'services/stripe_service.dart';
import 'services/stripe_adel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Stripe
  Stripe.publishableKey =
  'pk_test_51SQ87HHhwklufEWKb3ROAt3YttLpn2Wm7OxbsD3C45wkhBTMGEc9FoiLCzJClSIif9eZPuFpWJYQ3yuMkoBElRLz00TUgCYGL4';
  StripeAdelService.init();

  // --- SUPPRIME ET RECONSTRUIT LA BASE DE DONNÉES ---
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'elearning.db');
  await deleteDatabase(path); // ← supprime l'ancienne base (pour dev)

  // Initialise la base de données (recréation des tables)
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
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => QuizzesProvider()),
        ChangeNotifierProvider(create: (_) => QuestionsProvider()),
        ChangeNotifierProvider(create: (_) => PostsProvider()),
        ChangeNotifierProvider(create: (_) => CommentsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
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
          AppRoute.postsList: (_) => const PostsListScreen(),
          AppRoute.createPost: (_) => const CreatePostScreen(),
          AppRoute.eventDetails: (_) => const EventDetailsScreen(),
          AppRoute.schedule: (_) => const ScheduleScreen(),
          AppRoute.profile: (_) => const ProfileScreen(),
          AppRoute.quizze: (_) => const QuizzesScreen(),
          AppRoute.notifications: (_) => const NotificationsScreen(),
          AppRoute.PackStoreScreen: (_) => const PackStoreScreen(),
        },
      ),
    );
  }
}
