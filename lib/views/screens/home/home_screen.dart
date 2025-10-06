import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constant/app_route.dart'; // assure-toi que AppRoute.signIn existe

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
       /* actions: [
          // Bouton pour aller à la page login
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Naviguer vers la page login
              Navigator.pushReplacementNamed(context, AppRoute.signIn);
            },
          ),
        ],*/

        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); // supprime toutes les données
              Navigator.pushReplacementNamed(context, AppRoute.signIn);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Bienvenue 👋',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'welcome to my app',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),

          // Deux actions génériques
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Action principale'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Action secondaire'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(),

          const SizedBox(height: 12),
          const Text(
            'Sections',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),

          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.folder)),
              title: const Text('Section 1'),
              subtitle: const Text('Description courte…'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.star)),
              title: const Text('Section 2'),
              subtitle: const Text('Description courte…'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.settings)),
              title: const Text('Paramètres'),
              subtitle: const Text('Configurer votre application'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
