class Allergy {
  final int id;
  final String name;

  Allergy({required this.id, required this.name});

  factory Allergy.fromJson(Map<String, dynamic> json) {
    return Allergy(id: json['id'] as int, name: json['name'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
