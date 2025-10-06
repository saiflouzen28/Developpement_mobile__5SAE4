import 'package:flutter/material.dart';
import 'package:bcrypt/bcrypt.dart';

import '../../../DB/database_helper.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  String _message = '';
  bool _obscurePassword = true; // 🔹 controle visibilité mot de passe

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final plain = _passwordController.text.trim();
    if (plain.isEmpty) {
      setState(() => _message = "Veuillez entrer un nouveau mot de passe");
      return;
    }

    final hashedPassword = BCrypt.hashpw(plain, BCrypt.gensalt());
    await _dbHelper.updatePassword(widget.email, hashedPassword);

    setState(() => _message = "Mot de passe réinitialisé avec succès !");

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.popUntil(context, (route) => route.isFirst);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réinitialiser le mot de passe')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Email : ${widget.email}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword, // 🔹 contrôle de visibilité
              decoration: InputDecoration(
                labelText: 'Nouveau mot de passe',
                border: const OutlineInputBorder(),

                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),

            ),
            const SizedBox(height: 16),
            if (_message.isNotEmpty)
              Text(
                _message,
                style: const TextStyle(color: Colors.green),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _resetPassword,
                child: const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
