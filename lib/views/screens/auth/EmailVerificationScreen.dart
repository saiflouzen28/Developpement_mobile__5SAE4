import 'package:flutter/material.dart';
import '../../../DB/database_helper.dart';
import '../../../core/constant/app_color.dart';
import '../../../core/constant/app_route.dart';
import '../../../core/constant/app_string.dart';
import 'ResetPasswordScreen.dart';
// page pour réinitialiser le mot de passe

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final TextEditingController _emailController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  String _message = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _verifyEmail() async {
    final user = await _dbHelper.getUserByEmail(_emailController.text.trim());
    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ResetPasswordScreen(email: _emailController.text.trim()),
        ),
      );
    } else {
      setState(() => _message = "Cet email n'existe pas !");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // 🔹 Icon retour
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, AppRoute.signIn);
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  AppString.phoneVerification,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Veuillez entrer votre email pour réinitialiser votre mot de passe",
                  style: TextStyle(fontSize: 14, color: AppColor.grey),
                ),
                const SizedBox(height: 32),

                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                if (_message.isNotEmpty)
                  Text(
                    _message,
                    style: const TextStyle(color: Colors.red),
                  ),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _verifyEmail,
                    child: const Text('Next'),
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