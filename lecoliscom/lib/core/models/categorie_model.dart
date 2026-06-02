class CategorieModel {
  final String id;
  final String nom;

  const CategorieModel({
    required this.id,
    required this.nom,
  });

  factory CategorieModel.fromJson(Map<String, dynamic> json) {
    return CategorieModel(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
    );
  }
}
