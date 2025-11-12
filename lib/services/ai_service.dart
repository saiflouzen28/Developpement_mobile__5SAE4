import 'dart:math';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:http/http.dart' as http;

/// 🔹 Service local de résumé automatique simulant un effet "IA"
class AIService {
  static const Set<String> _stopwords = {
    'le', 'la', 'les', 'de', 'des', 'du', 'un', 'une', 'et', 'en', 'a', 'à',
    'au', 'aux', 'dans', 'ce', 'cet', 'cette', 'ces', 'pour', 'par', 'avec',
    'sur', 'se', 'sa', 'son', 'ses', 'est', 'sont', 'ou', 'où', 'que', 'qui',
    'ne', 'pas', 'plus', 'moins', 'il', 'elle', 'on', 'nous', 'vous', 'ils',
    'elles', 'leur', 'leurs', 'comme', 'dont', 'cela', 'ça', 'c\'est', 'été',
    'être', 'faire', 'fait', 'afin', 'toute', 'tous', 'tout', 'ainsi'
  };

  /// 🧠 1️⃣ Résumé intelligent (version courte et naturelle)
  static Future<String> summarizeText(String text) async {
    if (text.trim().isEmpty) return "Aucun contenu à résumer.";

    // Découper en phrases
    List<String> sentences = text.split(RegExp(r'(?<=[.!?])\s+'));
    if (sentences.length <= 2) return text.trim();

    // Compter la fréquence des mots significatifs
    Map<String, int> freq = {};
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zàâçéèêëîïôûùüÿñæœ\s]'), ' ')
        .split(' ')
        .where((w) => w.isNotEmpty && !_stopwords.contains(w));

    for (var w in words) {
      freq[w] = (freq[w] ?? 0) + 1;
    }

    // Score de chaque phrase
    Map<String, double> sentenceScores = {};
    for (var s in sentences) {
      double score = 0;
      final sWords = s
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-zàâçéèêëîïôûùüÿñæœ\s]'), ' ')
          .split(' ');
      for (var w in sWords) {
        if (freq.containsKey(w)) score += freq[w]! / (sWords.length + 1);
      }
      sentenceScores[s] = score;
    }

    // Garder 2-3 phrases les plus significatives
    final int keep = min(3, sentences.length);
    final best = (sentenceScores.keys.toList()
      ..sort((a, b) => sentenceScores[b]!.compareTo(sentenceScores[a]!)))
        .take(keep)
        .toList();

    // Nettoyage et fusion courte
    String summary = best.join(" ");
    summary = summary.replaceAll(RegExp(r'\s+'), ' ').trim();

    // 🔹 Rendre le style plus "IA"
    return "💡 Résumé automatique :\n\n${_beautifySummary(summary)}";
  }

  /// 🌟 Ajuster la forme du résumé pour un style plus fluide et humain
  static String _beautifySummary(String text) {
    // Tronquer si trop long
    if (text.length > 250) {
      text = text.substring(0, 250);
      final lastDot = text.lastIndexOf('.');
      if (lastDot > 0) text = text.substring(0, lastDot + 1);
    }

    // Ajouter une tonalité plus naturelle
    if (!text.endsWith('.')) text += '.';
    return text.replaceFirstMapped(RegExp(r'^.'), (m) => m.group(0)!.toUpperCase());
  }

  /// 📘 2️⃣ Extraction du texte d’un PDF à partir d’une URL
  static Future<String> _extractPdfTextFromUrl(String url) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) {
        return "Erreur : impossible de télécharger le PDF (${res.statusCode}).";
      }

      final PdfDocument pdf = PdfDocument(inputBytes: res.bodyBytes);
      final text = PdfTextExtractor(pdf).extractText();
      pdf.dispose();

      return text.trim().isEmpty ? "PDF vide ou illisible." : text.trim();
    } catch (e) {
      return "Erreur lors de la lecture du PDF : $e";
    }
  }

  /// 📄 3️⃣ Résumé automatique du contenu d’un PDF
  static Future<String> summarizePDF(String pdfUrl) async {
    final text = await _extractPdfTextFromUrl(pdfUrl);
    if (text.startsWith("Erreur")) return text;
    return await summarizeText(text);
  }

  /// 🔍 4️⃣ Extraction simple (utilisée pour la traduction IA)
  static Future<String> extractTextFromPDF(String pdfUrl) async {
    return await _extractPdfTextFromUrl(pdfUrl);
  }
}
