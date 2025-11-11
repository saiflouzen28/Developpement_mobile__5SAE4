import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import '../../../models/pack.dart';
import '../../../providers/pack_repository.dart';
import '../../../providers/payment_repository.dart';
import '../../../services/stripe_adel.dart';
import 'my_packs_screen.dart';

class PackStoreScreen extends StatefulWidget {
  const PackStoreScreen({super.key});

  @override
  State<PackStoreScreen> createState() => _PackStoreScreenState();
}

class _PackStoreScreenState extends State<PackStoreScreen> {
  final PackRepository _packRepo = PackRepository();
  final PaymentRepository _payRepo = PaymentRepository();

  List<Pack> packs = [];
  List<Pack> filteredPacks = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // 🔹 Palette de couleurs pour les packs
  final List<List<Color>> packGradients = [
    [Colors.deepPurple.shade400, Colors.deepPurple.shade200],
    [Colors.orange.shade400, Colors.orange.shade200],
    [Colors.green.shade400, Colors.green.shade200],
    [Colors.blue.shade400, Colors.blue.shade200],
    [Colors.red.shade400, Colors.red.shade200],
    [Colors.teal.shade400, Colors.teal.shade200],
  ];

  @override
  void initState() {
    super.initState();
    _loadPacks();
  }

  Future<void> _loadPacks() async {
    setState(() => isLoading = true);
    final data = await _packRepo.getAllPacks();
    setState(() {
      packs = data;
      filteredPacks = data;
      isLoading = false;
    });
  }

  void _filterPacks(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      filteredPacks = packs.where((pack) {
        return pack.title.toLowerCase().contains(lowerQuery) ||
            pack.courses.any((c) => c.title.toLowerCase().contains(lowerQuery));
      }).toList();
    });
  }

  Future<void> _onBuy(Pack pack) async {
    final confirmed = await _showConfirmDialog(pack);
    if (!confirmed) return;

    final success = await StripeAdelService.openPaymentSheet(
      context: context,
      amount: pack.price,
    );

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Paiement échoué ou annulé')),
      );
      return;
    }

    await _payRepo.recordPaymentAndGrant(1, pack);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Pack "${pack.title}" acheté avec succès !')),
    );

    await _loadPacks();
  }

  Future<bool> _showConfirmDialog(Pack pack) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('💳 Confirmer le paiement'),
        content: Text(
            'Souhaitez-vous payer ${pack.price.toStringAsFixed(2)} TND pour "${pack.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: () => Navigator.pop(context, true),
            label: const Text('Payer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Boutique des packs',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyPacksScreen()),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
          child: CircularProgressIndicator(color: Colors.deepPurple))
          : Column(
        children: [
          // 🔹 Barre de recherche stylée
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _searchController,
              onChanged: _filterPacks,
              decoration: InputDecoration(
                hintText: 'Rechercher un pack ou un cours...',
                prefixIcon:
                const Icon(Icons.search, color: Colors.deepPurple),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear,
                      color: Colors.deepPurple),
                  onPressed: () {
                    _searchController.clear();
                    _filterPacks('');
                  },
                )
                    : null,
              ),
            ),
          ),

          // 🔹 Liste filtrée des packs
          Expanded(
            child: filteredPacks.isEmpty
                ? const Center(
              child: Text(
                'Aucun résultat trouvé',
                style:
                TextStyle(fontSize: 16, color: Colors.black54),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredPacks.length,
              itemBuilder: (context, i) {
                final pack = filteredPacks[i];
                final coursesText = pack.courses.isNotEmpty
                    ? pack.courses
                    .map((c) => '• ${c.title}')
                    .join('\n')
                    : 'Aucun cours';

                // 🔹 Choix du gradient en fonction de l'index
                final gradient =
                packGradients[i % packGradients.length];

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: gradient[0].withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                pack.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${pack.price.toStringAsFixed(2)} TND',
                                style: const TextStyle(
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${pack.durationDays} jours d’accès',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          coursesText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _onBuy(pack),
                            icon: const Icon(
                                Icons.shopping_cart_outlined,
                                color: Colors.white),
                            label: const Text(
                              'Acheter maintenant',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              Colors.white.withOpacity(0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                            ),
                          ),
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
