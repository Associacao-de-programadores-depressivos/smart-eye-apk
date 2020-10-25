import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class Detection {
  final String id;
  final String rawImg;
  final String boundaryImage;
  final DateTime detectionTime;

  Detection(
    this.id,
    this.rawImg,
    this.boundaryImage,
    this.detectionTime,
  );

  factory Detection.fromDynamic(var data) {
    return Detection(
      data["id"],
      data["raw_image_url"],
      data["boundary_box_image_url"],
      DateTime.parse(data["created_date"]),
    );
  }

  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      json["id"],
      json["raw_image_url"],
      json["boundary_box_image_url"],
      DateTime.parse(json["created_date"]),
    );
  }

  String detectionText() {
    initializeDateFormatting();
    String day = DateFormat('dd/MM/yyyy').format(this.detectionTime);
    String hour = DateFormat('kk:mm:ss').format(this.detectionTime);
    return "Pessoa detectada em $day às $hour";
  }

  static List<Detection> parseList(List<dynamic> list) {
    return list.map((i) => Detection.fromJson(i)).toList();
  }
}
