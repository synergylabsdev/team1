class TagModel {
  final String id;
  final String name;

  TagModel({required this.id, required this.name});

  factory TagModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    if (rawId == null) {
      throw FormatException('Tag id is missing in JSON payload.');
    }
    return TagModel(id: rawId.toString(), name: json['name'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
