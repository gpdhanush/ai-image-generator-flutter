import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String apiEndpoint =
      'https://api.bytez.com/models/v2/dreamlike-art/dreamlike-photoreal-2.0';
  static const String apiKey = '95bf3d787db6c1c95f9a7afea4f2fdc2';

  static Future<http.Response> postText({required String text}) async {
    final Uri uri = Uri.parse(apiEndpoint);
    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Key $apiKey',
    };
    final String body = jsonEncode(<String, String>{'text': text});
    return http.post(uri, headers: headers, body: body);
  }
}
