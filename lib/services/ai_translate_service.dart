import 'dart:convert';
import 'package:http/http.dart' as http;

/// 🌍 Traduction via MyMemory API – simple, fiable et gratuite
class AITranslateService {
  static const _baseUrl = "https://api.mymemory.translated.net/get";

  /// Traduire un texte (auto-détection fr ↔ ar)
  static Future<String> translate({
    required String text,
    required String targetLang,
  }) async {
    if (text.trim().isEmpty) return "⚠️ Aucun texte à traduire.";

    try {
      // Détection automatique : si le texte contient de l’arabe
      String sourceLang = text.contains(RegExp(r'[\u0600-\u06FF]')) ? "ar" : "fr";

      final uri = Uri.parse(
          "$_baseUrl?q=${Uri.encodeComponent(text)}&langpair=$sourceLang|$targetLang");

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["responseData"]["translatedText"] ??
            "⚠️ Traduction non disponible.";
      } else {
        return "⚠️ Erreur (${response.statusCode}) : ${response.body}";
      }
    } catch (e) {
      return "❌ Erreur lors de la traduction : $e";
    }
  }

  /// 🌐 Version sécurisée (mode hors ligne)
  static Future<String> safeTranslate(String text, String targetLang) async {
    try {
      final result = await translate(text: text, targetLang: targetLang);
      if (result.startsWith("⚠️") || result.startsWith("❌")) {
        return "Traduction non disponible (mode hors ligne).";
      }
      return result;
    } catch (_) {
      return "Traduction non disponible (connexion perdue).";
    }
  }
}
