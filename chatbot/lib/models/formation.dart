class Formation {
  final String id;
  final String nomFormation;
  final String nomEtablissement;
  final String placesDisponibles;

  Formation({
    required this.id,
    required this.nomFormation,
    required this.nomEtablissement,
    required this.placesDisponibles,
  });

  factory Formation.fromJson(Map<String, dynamic> json) {
    return Formation(
      id: json['id'] ?? '',
      nomFormation: json['nom_formation'] ?? '',
      nomEtablissement: json['nom_etablissement'] ?? '',
      placesDisponibles: json['places_disponibles']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom_formation': nomFormation,
        'nom_etablissement': nomEtablissement,
        'places_disponibles': placesDisponibles,
      };
}
