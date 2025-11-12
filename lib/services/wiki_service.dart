// lib/services/wiki_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class WikiSummary {
  final String title;
  final String extract;
  final String? thumbnailUrl;
  final String pageUrl;

  WikiSummary({
    required this.title,
    required this.extract,
    required this.pageUrl,
    this.thumbnailUrl,
  });
}

class WikiService {
  /// Récupère le résumé d’une page via l’API REST de Wikipédia.
  /// [term] : mot/terme à chercher (ex: "Flutter (logiciel)")
  /// [lang] : 'fr' par défaut (peut être 'en', etc.)
  static Future<WikiSummary?> fetchSummary(String term, {String lang = 'fr'}) async {
    // Encode le titre pour l’URL
    final encoded = Uri.encodeComponent(term.trim());
    final url = Uri.parse('https://$lang.wikipedia.org/api/rest_v1/page/summary/$encoded');

    final res = await http.get(url, headers: {
      'Accept': 'application/json',
      'User-Agent': 'elearning-events-app/1.0 (flutter)'
    });

    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;

      // Certaines réponses peuvent ne pas avoir d’extrait utile
      final title = (data['title'] ?? '').toString();
      final extract = (data['extract'] ?? '').toString();
      if (title.isEmpty || extract.isEmpty) return null;

      String? thumb;
      if (data['thumbnail'] is Map && data['thumbnail']['source'] != null) {
        thumb = data['thumbnail']['source'] as String;
      }

      // L’API renvoie aussi 'content_urls' → 'desktop' → 'page'
      String pageUrl = 'https://$lang.wikipedia.org/wiki/$encoded';
      if (data['content_urls'] is Map &&
          data['content_urls']['desktop'] is Map &&
          data['content_urls']['desktop']['page'] is String) {
        pageUrl = data['content_urls']['desktop']['page'] as String;
      }

      return WikiSummary(
        title: title,
        extract: extract,
        pageUrl: pageUrl,
        thumbnailUrl: thumb,
      );
    }

    // 404 / non trouvé → renvoie null
    return null;
  }
}
