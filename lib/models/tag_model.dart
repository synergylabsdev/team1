class TagModel {
  final String id;
  final String name;

  TagModel({required this.id, required this.name});

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(id: json['id'].toString(), name: json['name'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
