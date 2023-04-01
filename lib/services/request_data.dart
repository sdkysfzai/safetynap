import 'dart:convert';
import 'package:http/http.dart' as http;

class RequestData {
  static Future<dynamic> get(String url) async {
    http.Response response = await http.get(Uri.parse(url));
    try {
      if (response.statusCode == 200) {
        String responseData = response.body;
        var decodeResponseData = jsonDecode(responseData);
        return decodeResponseData;
      } else {
        return "Error";
      }
    } catch (e) {
      return "Error";
    }
  }
}
