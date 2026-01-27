import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Za jsonDecode

Future<String?> uploadToCloudinary(File imageFile) async {
  // 1. POSTAVI SVOJE PODATKE
  String cloudName = "dtv41eozz"; 
  String uploadPreset = "flutter_preset"; 

  // 2. Definisanje endpoint-a
  // URL format je uvek: https://api.cloudinary.com/v1_1/<cloud_name>/image/upload
  var uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

  // 3. Kreiranje Multipart Request-a
  var request = http.MultipartRequest("POST", uri);

  // 4. Dodavanje fajla
  // 'file' je obavezan ključ koji Cloudinary očekuje
  var multipartFile = await http.MultipartFile.fromPath(
    'file', 
    imageFile.path
  );
  request.files.add(multipartFile);

  // 5. Dodavanje upload_preset-a
  // 'upload_preset' je obavezan ključ za unsigned upload
  request.fields['upload_preset'] = uploadPreset;

  // Možeš dodati i folder ako želiš (opciono, ako nije definisano u presetu)
  // request.fields['folder'] = 'korisnicke_slike';

  try {
    // 6. Slanje zahteva
    var response = await request.send();

    // 7. Čitanje odgovora
    if (response.statusCode == 200) {
      var responseData = await http.Response.fromStream(response);
      var jsonResponse = jsonDecode(responseData.body);
      
      // Vraćamo secure_url (HTTPS link do slike)
      String imageUrl = jsonResponse['secure_url'];
      print("Upload uspešan! URL: $imageUrl");
      return imageUrl;
    } else {
      print("Greška pri uploadu: ${response.statusCode}");
      return null;
    }
  } catch (e) {
    print("Došlo je do greške: $e");
    return null;
  }
}