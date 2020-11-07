import 'package:http/http.dart' as http;

const String API_URL = "https://smarteye.notfab.net";

class API {
  static Future getDetections(int pageNumber) {
    return http.get(API_URL + "/esp32cam/detections?page=$pageNumber");
  }

  static Future registerFirebaseToken(dynamic body) {
    return http.post(API_URL + "/mobile/register_firebase_token", body: body);
  }
}
