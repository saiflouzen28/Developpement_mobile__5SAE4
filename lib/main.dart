import 'package:flutter/material.dart';

import 'core/constant/app_theme.dart';
import 'core/constant/app_route.dart';
import 'views/screens/auth/sign_in_screen.dart';
import 'views/screens/auth/sign_up_screen.dart';
import 'views/screens/auth/EmailVerificationScreen.dart';
import 'views/screens/home/home_screen.dart';



void main() {

  runApp(const MyApp());

}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth Starter',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoute.signIn,
      routes: {
        AppRoute.signIn: (_) => const SignInScreen(),
        AppRoute.signUp: (_) => const SignUpScreen(),
        AppRoute.home: (_) => const HomeScreen(),
        AppRoute.EmailVerificationScreen: (_) => const EmailVerificationScreen(),




        // PhoneVerification prend un argument => on utilise onGenerateRoute
      },

    );
  }
}
