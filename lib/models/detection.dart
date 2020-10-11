class Detection {
  // @TODO: Adapt this class when we have the real Detection data
  final String title;
  final String imgUrl;
  // final DateTime detectionTime;

  Detection(
    this.title,
    this.imgUrl,
  );

  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(json["title"], json["thumbnailUrl"]);
  }

  static List<Detection> parseList(List<dynamic> list) {
    return list.map((i) => Detection.fromJson(i)).toList();
  }
}
