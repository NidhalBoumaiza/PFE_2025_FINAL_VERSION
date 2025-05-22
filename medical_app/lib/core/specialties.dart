import 'package:get/get.dart';

// Translation keys for specialties
const List<String> specialtyKeys = [
  'dentist',
  'pulmonologist',
  'dermatologist',
  'nutritionist',
  'cardiologist',
  'psychologist',
  'general_practitioner',
  'neurologist',
  'orthopedic',
  'gynecologist',
  'ophthalmologist',
  'aesthetic_doctor',
];

// Get translated specialties list
List<String> getTranslatedSpecialties() {
  return specialtyKeys.map((key) => key.tr).toList();
}

// Get specialties with images
List<Map<String, dynamic>> getSpecialtiesWithImages() {
  return [
    {'image': 'assets/images/dentiste.png', 'text': 'dentist'.tr},
    {'image': 'assets/images/bebe.png', 'text': 'pediatrician'.tr},
    {'image': 'assets/images/generaliste.png', 'text': 'generalist'.tr},
    {'image': 'assets/images/pnmeulogue.png', 'text': 'pulmonologist'.tr},
    {'image': 'assets/images/dermatologue.png', 'text': 'dermatologist'.tr},
    {'image': 'assets/images/diet.png', 'text': 'nutritionist'.tr},
    {'image': 'assets/images/cardio.png', 'text': 'cardiologist'.tr},
    {'image': 'assets/images/psy.png', 'text': 'psychologist'.tr},
    {'image': 'assets/images/neurologue.png', 'text': 'neurologist'.tr},
    {'image': 'assets/images/orthopediste.png', 'text': 'orthopedic'.tr},
    {'image': 'assets/images/gyneco.png', 'text': 'gynecologist'.tr},
    {'image': 'assets/images/ophtalmo.png', 'text': 'ophthalmologist'.tr},
    {'image': 'assets/images/botox.png', 'text': 'aesthetic_doctor'.tr},
  ];
}
