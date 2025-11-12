import 'dart:math';

class LocalAICourseGenerator {
  static final _random = Random();

  /// 🔹 Génère un plan intelligent selon le thème détecté
  static Future<List<Map<String, String>>> generateCoursePlan(
      String title) async {
    if (title.trim().isEmpty) {
      return [
        {
          "title": "Erreur",
          "description":
          "Veuillez saisir un titre de cours avant de générer le plan."
        }
      ];
    }

    final theme = detectTheme(title.toLowerCase());

    final intro = {
      "title": "Introduction à $theme",
      "description":
      "Découvrez les objectifs, le contexte et les opportunités qu’offre le domaine de $theme."
    };

    final modules = [
      {
        "title": "Fondamentaux de $theme",
        "description":
        "Comprendre les bases et les notions clés pour débuter efficacement en $theme."
      },
      {
        "title": "Applications pratiques",
        "description":
        "Mise en œuvre des concepts à travers des projets et cas concrets dans $theme."
      },
      {
        "title": "Outils et méthodologies",
        "description":
        "Présentation des outils modernes, frameworks et bonnes pratiques liés à $theme."
      },
      {
        "title": "Projet final et évaluation",
        "description":
        "Conception d’un mini-projet complet pour valider vos compétences acquises en $theme."
      },
    ];

    final conclusion = {
      "title": "Conclusion et perspectives",
      "description":
      "Révision des acquis, ouverture vers des sujets avancés et conseils pour progresser dans $theme."
    };

    return [intro, ...modules, conclusion];
  }

  /// 🧭 Détecte le thème à partir du titre
  static String detectTheme(String title) {
    final keywords = {
      "flutter": ["flutter", "dart", "mobile"],
      "python": ["python", "programmation"],
      "marketing": ["marketing", "digital", "réseaux"],
      "design": ["design", "ux", "ui", "graphique"],
      "ia": ["intelligence", "ai", "machine", "deep"],
      "robotique": ["robot", "arduino", "capteur"],
    };

    for (final entry in keywords.entries) {
      if (entry.value.any((word) => title.contains(word))) {
        return entry.key[0].toUpperCase() + entry.key.substring(1);
      }
    }

    final words = title.split(" ");
    return words.isNotEmpty ? words.last.capitalize() : "Cours";
  }
}

extension StringCap on String {
  String capitalize() =>
      isEmpty ? this : this[0].toUpperCase() + substring(1);
}
