import 'package:flutter/material.dart';
import '../../../core/constant/app_color.dart';
import '../../../core/constant/app_string.dart';
import '../../../core/constant/app_style.dart';
import '../../../core/constant/app_route.dart';
import '../../widgets/forms/common_input_decoration.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/buttons/social_button.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final String staticEmail = 'user@example.com';
  final String staticPassword = '123456';

  void _handleLogin() {
    final enteredEmail = _emailController.text.trim();
    final enteredPassword = _passwordController.text;

    if (enteredEmail == staticEmail && enteredPassword == staticPassword) {
      Navigator.pushReplacementNamed(context, AppRoute.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adresse e-mail ou mot de passe invalide'),
          backgroundColor: AppColor.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(AppString.signIn, style: AppStyle.title),
              const SizedBox(height: 4),
              const Text(AppString.findMeal, style: AppStyle.subtitle),
              const SizedBox(height: 32),

              const Text(AppString.email, style: AppStyle.label),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: commonInputDecoration('Saisissez votre adresse e-mail'),
              ),
              const SizedBox(height: 16),

              const Text(AppString.password, style: AppStyle.label),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: commonInputDecoration('Saisissez votre mot de passe'),
              ),
              const SizedBox(height: 24),

              PrimaryButton(text: AppString.signIn, onPressed: _handleLogin),
              const SizedBox(height: 12),

              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoute.forgotPassword),
                  child: const Text(
                    AppString.forgotPassword,
                    style: TextStyle(color: AppColor.red),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Center(child: Text(AppString.orContinue, style: AppStyle.subtitle)),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SocialButton(icon: Icons.person, label: 'Google'),
                  SizedBox(width: 12),
                  SocialButton(icon: Icons.facebook, label: 'Facebook'),
                ],
              ),
              const SizedBox(height: 24),

              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, AppRoute.signUp),
                  child: const Text.rich(
                    TextSpan(
                      text: AppString.createAccount,
                      style: TextStyle(color: Colors.black54),
                      children: [
                        TextSpan(
                          text: AppString.signUp,
                          style: TextStyle(color: AppColor.black, fontWeight: FontWeight.bold),
                        ),
                      ],
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
