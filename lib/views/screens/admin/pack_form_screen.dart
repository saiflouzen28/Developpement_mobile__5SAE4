import 'package:flutter/material.dart';
import '../../../models/pack.dart';
import '../../../models/course.dart';
import '../../../providers/pack_repository.dart';
import '../../../providers/course_repository.dart';

class PackFormScreen extends StatefulWidget {
  final Pack? pack;
  const PackFormScreen({super.key, this.pack});

  @override
  State<PackFormScreen> createState() => _PackFormScreenState();
}

class _PackFormScreenState extends State<PackFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _packRepo = PackRepository();
  final _courseRepo = CourseRepository();

  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final durationCtrl = TextEditingController();

  List<Course> allCourses = [];
  List<int> selectedCourseIds = [];
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    allCourses = await _courseRepo.getAllCourses();
    if (widget.pack != null) {
      titleCtrl.text = widget.pack!.title;
      descCtrl.text = widget.pack!.description ?? '';
      priceCtrl.text = widget.pack!.price.toString();
      durationCtrl.text = widget.pack!.durationDays.toString();
      selectedCourseIds = await _packRepo.getCourseIdsForPack(widget.pack!.id!);
    }
    setState(() {});
  }

  Future<void> _savePack() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSaving = true);

    final now = DateTime.now().millisecondsSinceEpoch;
    final pack = Pack(
      id: widget.pack?.id,
      title: titleCtrl.text,
      description: descCtrl.text,
      price: double.tryParse(priceCtrl.text) ?? 0,
      durationDays: int.tryParse(durationCtrl.text) ?? 365,
      createdAt: widget.pack?.createdAt ?? now,
      updatedAt: now,
    );

    if (widget.pack == null) {
      await _packRepo.insertPack(pack, courseIds: selectedCourseIds);
    } else {
      await _packRepo.updatePack(pack, courseIds: selectedCourseIds);
    }

    setState(() => isSaving = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          widget.pack == null ? "Créer un pack" : "Modifier le pack",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 4,
        backgroundColor: Colors.deepPurple,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: isSaving
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Détails du pack",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 20),

                // Champ titre
                _buildTextField(
                  controller: titleCtrl,
                  label: "Titre du pack",
                  icon: Icons.title,
                  validator: (v) => v == null || v.isEmpty ? "Titre requis" : null,
                ),

                // Champ description
                _buildTextField(
                  controller: descCtrl,
                  label: "Description",
                  icon: Icons.description,
                  maxLines: 2,
                ),

                // Champ prix
                _buildTextField(
                  controller: priceCtrl,
                  label: "Prix (TND)",
                  icon: Icons.monetization_on,
                  keyboardType: TextInputType.number,
                ),

                // Champ durée
                _buildTextField(
                  controller: durationCtrl,
                  label: "Durée d’accès (jours)",
                  icon: Icons.access_time,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 20),
                const Text(
                  "Cours inclus",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepPurple),
                ),
                const SizedBox(height: 8),

                allCourses.isEmpty
                    ? const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text("Aucun cours disponible."),
                )
                    : Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.deepPurple.shade100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: allCourses
                        .map((c) => CheckboxListTile(
                      value: selectedCourseIds.contains(c.id),
                      activeColor: Colors.deepPurple,
                      title: Text(
                        c.title,
                        style: const TextStyle(fontSize: 15),
                      ),
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            selectedCourseIds.add(c.id!);
                          } else {
                            selectedCourseIds.remove(c.id);
                          }
                        });
                      },
                    ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 30),

                // Bouton enregistrer
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _savePack,
                    icon: const Icon(Icons.save, size: 22),
                    label: const Text(
                      "Enregistrer",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: Colors.deepPurple,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.deepPurple),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.deepPurple.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
          ),
        ),
      ),
    );
  }
}
