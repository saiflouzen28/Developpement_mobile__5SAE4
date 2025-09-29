import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../../core/constant/app_color.dart';
import '../../../core/constant/app_string.dart';
import '../../../core/constant/app_route.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  String phone = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BackButton(color: Colors.black),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const SizedBox(
                      width: 40, height: 40, child: Icon(Icons.close, size: 24, color: Colors.black),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              const Text(
                AppString.forgotTitle,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColor.black),
              ),
              const SizedBox(height: 10),

              const Text(
                AppString.forgotSubtitle,
                style: TextStyle(fontSize: 14, color: AppColor.grey),
              ),
              const SizedBox(height: 36),

              Container(
                width: double.infinity,
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IntlPhoneField(
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: AppString.phoneHint,
                  ),
                  initialCountryCode: 'TN', // Tunisie par défaut
                  onChanged: (phoneNumber) => phone = phoneNumber.completeNumber,
                ),
              ),

              const Spacer(),

              Center(
                child: SizedBox(
                  width: 160,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoute.phoneVerification,
                        arguments: phone,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(60)),
                    ),
                    child: const Text(AppString.next, style: TextStyle(color: Colors.white, fontSize: 16)),
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
