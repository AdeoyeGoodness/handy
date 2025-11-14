class ServiceCategoryModel {
  ServiceCategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.icon,
  });

  final int id;
  final String name;
  final String? description;
  final String? icon;

  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json) {
    return ServiceCategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
    );
  }
}

