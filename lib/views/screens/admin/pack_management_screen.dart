import 'package:flutter/material.dart';
import '../../../models/pack.dart';
import '../../../models/course.dart';
import '../../../providers/pack_repository.dart';
import 'pack_form_screen.dart';

class PackManagementScreen extends StatefulWidget {
  const PackManagementScreen({super.key});

  @override
  State<PackManagementScreen> createState() => _PackManagementScreenState();
}

class _PackManagementScreenState extends State<PackManagementScreen> {
  final PackRepository _repo = PackRepository();
  List<Pack> _allPacks = [];
  List<Pack> _filteredPacks = [];
  bool isLoading = true;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadPacks();
  }

  Future<void> _loadPacks() async {
    setState(() => isLoading = true);
    final data = await _repo.getAllPacks();
    setState(() {
      _allPacks = data;
      _filteredPacks = data;
      isLoading = false;
    });
  }

  void _filterPacks(String query) {
    final filtered = _allPacks
        .where((pack) =>
        pack.title.toLowerCase().contains(query.toLowerCase().trim()))
        .toList();
    setState(() {
      _searchText = query;
      _filteredPacks = filtered;
    });
  }

  Future<void> _deletePack(int id) async {
    await _repo.deletePack(id);
    _loadPacks();
  }

  void _openPackForm({Pack? pack}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PackFormScreen(pack: pack)),
    );
    _loadPacks(); // rafraîchir après retour
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      floatingActionButton: FloatingActionButton(
        onPressed: () => _openPackForm(),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, size: 30),
      ),
      body: isLoading
          ? const Center(
          child: CircularProgressIndicator(color: Colors.deepPurple))
          : Column(
        children: [
          // 🔹 Barre de recherche
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: _filterPacks,
              decoration: InputDecoration(
                hintText: 'Rechercher un pack...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // 🔹 Liste des packs filtrés
          Expanded(
            child: _filteredPacks.isEmpty
                ? const Center(
              child: Text(
                "Aucun pack trouvé",
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              itemCount: _filteredPacks.length,
              itemBuilder: (context, i) {
                final pack = _filteredPacks[i];

                final coursesText = (pack.courses?.isNotEmpty ?? false)
                    ? pack.courses!
                    .map((Course c) => "• ${c.title}")
                    .join("\n")
                    : "Aucun cours associé";

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.shade400,
                        Colors.deepPurple.shade200
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    title: Text(
                      pack.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        "Prix : ${pack.price.toStringAsFixed(2)} TND | "
                            "Durée : ${pack.durationDays} jours\n$coursesText",
                        style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Colors.white70),
                      ),
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit,
                              color: Colors.white),
                          onPressed: () => _openPackForm(pack: pack),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.redAccent),
                          onPressed: () {
                            if (pack.id != null) _deletePack(pack.id!);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
