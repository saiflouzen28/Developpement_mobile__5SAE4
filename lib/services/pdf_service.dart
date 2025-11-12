import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:http/http.dart' as http;

class PDFService {
  static Future<String> extractTextFromPDF(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = PdfDocument(inputBytes: response.bodyBytes);
        final text = PdfTextExtractor(document).extractText();
        document.dispose();
        return text.isNotEmpty ? text : "Aucun texte détecté dans le PDF.";
      } else {
        return "Impossible de charger le fichier PDF (code ${response.statusCode}).";
      }
    } catch (e) {
      return "Erreur lors de la lecture du PDF : $e";
    }
  }
}
