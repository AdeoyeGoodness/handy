class ServiceListingModel {
  ServiceListingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.basePrice,
    required this.pricingUnit,
    required this.providerId,
    required this.categoryId,
    this.coverImageUrl,
    this.coverageArea,
  });

  final int id;
  final String title;
  final String description;
  final double basePrice;
  final String pricingUnit;
  final int providerId;
  final int categoryId;
  final String? coverImageUrl;
  final String? coverageArea;

  factory ServiceListingModel.fromJson(Map<String, dynamic> json) {
    return ServiceListingModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      basePrice: (json['base_price'] as num).toDouble(),
      pricingUnit: json['pricing_unit'] as String,
      providerId: json['provider_id'] as int,
      categoryId: json['category_id'] as int,
      coverImageUrl: json['cover_image_url'] as String?,
      coverageArea: json['coverage_area'] as String?,
    );
  }
}

