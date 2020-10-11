import 'package:http/http.dart' as http;

const String API_URL = "https://jsonplaceholder.typicode.com";

class API {
  static Future getDetections(int pageNumber) {
    // @TODO: replace API_URL and route by the correct one.
    return http.get(API_URL + "/photos?_page=$pageNumber");
  }
}
