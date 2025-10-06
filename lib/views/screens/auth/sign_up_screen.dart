import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import '../../../DB/database_helper.dart';
import '../../../core/constant/app_color.dart';
import '../../../core/constant/app_string.dart';
import '../../../core/constant/app_style.dart';
import '../../../core/constant/app_route.dart';
import '../../widgets/forms/common_input_decoration.dart';
import '../../widgets/buttons/primary_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _numtelController = TextEditingController();


  void _register() async {
    if (!_formKey.currentState!.validate()) {
      print("Formulaire invalide");
      return;
    }

    final plain = _passwordController.text.trim();
    final hashedPassword = BCrypt.hashpw(plain, BCrypt.gensalt());
    print("Hashed password: $hashedPassword"); // debug, vérifie le hash dans la console

    try {
      final id = await DatabaseHelper.instance.registerUser(
        _nomController.text.trim(),
        _prenomController.text.trim(),
        _emailController.text.trim(),
        hashedPassword,                    // ← IMPORTANT : on envoie le hash
        _numtelController.text.trim(),
      );

      print("Insertion réussie, id = $id");

      final db = await DatabaseHelper.instance.database;
      final users = await db.query('users');
      print("Tous les utilisateurs dans SQLite : $users"); // vérifie ici aussi

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Compte créé avec succès ✅")),
      );

      Navigator.pushReplacementNamed(context, AppRoute.home);
    } catch (e) {
      print("Erreur lors du signup: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur: cet email existe déjà ❌")),
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppString.signUp, style: AppStyle.title),
                const SizedBox(height: 4),
                const Text(AppString.findMeal, style: AppStyle.subtitle),
                const SizedBox(height: 32),

                // Nom
                const Text('Nom', style: AppStyle.label),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nomController,
                  decoration: commonInputDecoration('Saisissez votre nom'),
                  validator: (value) => value!.isEmpty ? 'Champ obligatoire' : null,
                ),
                const SizedBox(height: 16),

                // Prénom
                const Text('Prénom', style: AppStyle.label),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _prenomController,
                  decoration: commonInputDecoration('Saisissez votre prénom'),
                  validator: (value) => value!.isEmpty ? 'Champ obligatoire' : null,
                ),
                const SizedBox(height: 16),

                // Email
                const Text(AppString.email, style: AppStyle.label),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  decoration: commonInputDecoration('Saisissez votre adresse e-mail'),
                  validator: (value) =>
                  value!.isEmpty || !value.contains('@') ? 'Email invalide' : null,
                ),
                const SizedBox(height: 16),

                // Password
                const Text(AppString.password, style: AppStyle.label),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword, // utilise l'état global du widget
                  decoration: commonInputDecoration('Saisissez votre mot de passe').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword; // toggle visibilité
                        });
                      },
                    ),
                  ),
                  validator: (value) => value!.length < 6
                      ? 'Le mot de passe doit contenir au moins 6 caractères'
                      : null,
                ),

                const SizedBox(height: 16),

                // NumTel
                const Text('Numéro de téléphone', style: AppStyle.label),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _numtelController,
                  keyboardType: TextInputType.phone,
                  decoration: commonInputDecoration('Saisissez votre numéro de téléphone'),
                  validator: (value) => value!.isEmpty ? 'Champ obligatoire' : null,
                ),
                const SizedBox(height: 30),

                PrimaryButton(
                  text: AppString.continueBtn,
                  onPressed: _register,
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
      ),
    );
  }
}
