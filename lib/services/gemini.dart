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
          TextPart("Opisi sliku"),
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
