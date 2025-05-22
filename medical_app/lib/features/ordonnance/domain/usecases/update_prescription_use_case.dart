import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/ordonnance/domain/entities/prescription_entity.dart';
import 'package:medical_app/features/ordonnance/domain/repositories/prescription_repository.dart';

class UpdatePrescriptionUseCase {
  final PrescriptionRepository repository;

  UpdatePrescriptionUseCase(this.repository);

  Future<Either<Failure, Unit>> call({required PrescriptionEntity prescription}) async {
    return await repository.updatePrescription(prescription);
  }
} 