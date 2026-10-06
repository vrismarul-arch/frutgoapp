class CategoryModel {
  final String id;
  final String label;
  final String image;
  final bool isAll;

  const CategoryModel({
    required this.id,
    required this.label,
    required this.image,
    this.isAll = false,
  });
}