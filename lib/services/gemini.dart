import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  
  final String _apiKey = "AIzaSyCIYoeeT-iN9ev2LnyAATjs8pkuLqev_94"; 
  late final GenerativeModel _model;

  GeminiService() {
    
    _model = GenerativeModel(model: 'gemini-2.5-flash-lite', apiKey: _apiKey);
  }



  Future<String?> analizirajSliku(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final content = [
        Content.multi([
          TextPart("Odmah proveri sliku. Ako na slici nema komunalnog, ekološkog, socijalnog ili sličnog problema koji bi se prijavio komunalnoj inspekciji,gradskim vlastima, ekološkoj inspekciji, zelenoj liniji ili komunalnoj policiji napiši SAMO i ISKLJUČIVO: 'ODBIJENO'. Ako postoji takav problem napiši kratak opis problema na srpskom jeziku maksimalno 3 rečenice. Ne piši ništa drugo, ne objašnjavaj, ne dodaj uvod, ne piši „mislim da“, „verovatno“, „nema problema“ niti bilo kakav dodatni tekst osim ODBIJENO ili opisa."),
          DataPart('image/jpeg', bytes),
        ])
      ];

      final response = await _model.generateContent(content);
      
      if (response.text == null || response.text!.contains("ODBIJENO")) {
        return null;
      }
      return response.text!.trim();
    } catch (e) {
      print("Greška: $e");
      return null;
    }
  }

}
