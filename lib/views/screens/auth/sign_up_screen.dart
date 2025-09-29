import 'package:flutter/material.dart';
import '../../../core/constant/app_color.dart';
import '../../../core/constant/app_string.dart';
import '../../../core/constant/app_style.dart';
import '../../../core/constant/app_route.dart';
import '../../widgets/forms/common_input_decoration.dart';
import '../../widgets/buttons/primary_button.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

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
              const Text(AppString.signUp, style: AppStyle.title),
              const SizedBox(height: 4),
              const Text(AppString.findMeal, style: AppStyle.subtitle),
              const SizedBox(height: 32),

              const Text(AppString.fullName, style: AppStyle.label),
              const SizedBox(height: 6),
              TextFormField(decoration: commonInputDecoration('Saisissez votre nom complet')),
              const SizedBox(height: 16),

              const Text(AppString.email, style: AppStyle.label),
              const SizedBox(height: 6),
              TextFormField(decoration: commonInputDecoration('Saisissez votre adresse e-mail')),
              const SizedBox(height: 16),

              const Text(AppString.password, style: AppStyle.label),
              const SizedBox(height: 6),
              TextFormField(
                obscureText: true,
                decoration: commonInputDecoration('Saisissez votre mot de passe'),
              ),
              const SizedBox(height: 30),

              PrimaryButton(
                text: AppString.continueBtn,
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoute.home),
              ),
              const SizedBox(height: 20),

              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, AppRoute.signIn),
                  child: const Text.rich(
                    TextSpan(
                      text: AppString.alreadyHaveAccount,
                      style: TextStyle(color: Colors.black54),
                      children: [
                        TextSpan(
                          text: AppString.logIn,
                          style: TextStyle(color: AppColor.black, fontWeight: FontWeight.bold),
                        )
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
