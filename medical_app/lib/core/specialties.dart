import 'package:get/get.dart';

// French specialties list
const List<String> specialtyKeys = [
  'Dentiste',
  'Pneumologue',
  'Dermatologue',
  'Nutritionniste',
  'Cardiologue',
  'Psychologue',
  'Médecin généraliste',
  'Neurologue',
  'Orthopédiste',
  'Gynécologue',
  'Ophtalmologue',
  'Médecin esthétique',
];

// Get translated specialties list
List<String> getTranslatedSpecialties() {
  return specialtyKeys;
}

// Get specialties with images
List<Map<String, dynamic>> getSpecialtiesWithImages() {
  return [
    {'image': 'assets/images/dentiste.png', 'text': 'Dentiste'},
    {'image': 'assets/images/bebe.png', 'text': 'Pédiatre'},
    {'image': 'assets/images/generaliste.png', 'text': 'Généraliste'},
    {'image': 'assets/images/pnmeulogue.png', 'text': 'Pneumologue'},
    {'image': 'assets/images/dermatologue.png', 'text': 'Dermatologue'},
    {'image': 'assets/images/diet.png', 'text': 'Nutritionniste'},
    {'image': 'assets/images/cardio.png', 'text': 'Cardiologue'},
    {'image': 'assets/images/psy.png', 'text': 'Psychologue'},
    {'image': 'assets/images/neurologue.png', 'text': 'Neurologue'},
    {'image': 'assets/images/orthopediste.png', 'text': 'Orthopédiste'},
    {'image': 'assets/images/gyneco.png', 'text': 'Gynécologue'},
    {'image': 'assets/images/ophtalmo.png', 'text': 'Ophtalmologue'},
    {'image': 'assets/images/botox.png', 'text': 'Médecin esthétique'},
  ];
}
