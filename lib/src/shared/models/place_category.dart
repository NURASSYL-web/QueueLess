enum PlaceCategory {
  cafeterias('cafeterias', 'Cafeterias'),
  coffee('coffee', 'Coffee'),
  banks('banks', 'Banks'),
  clinics('clinics', 'Clinics');

  const PlaceCategory(this.value, this.label);

  final String value;
  final String label;

  static PlaceCategory fromValue(String value) {
    return PlaceCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => PlaceCategory.cafeterias,
    );
  }
}
