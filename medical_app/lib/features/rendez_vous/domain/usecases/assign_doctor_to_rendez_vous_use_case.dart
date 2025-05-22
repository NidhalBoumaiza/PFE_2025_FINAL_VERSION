import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/rendez_vous/domain/repositories/rendez_vous_repository.dart';

class AssignDoctorToRendezVousUseCase {
  final RendezVousRepository rendezVousRepository;

  AssignDoctorToRendezVousUseCase(this.rendezVousRepository);

  Future<Either<Failure, Unit>> call(
      String rendezVousId,
      String doctorId,
      String doctorName,
      ) async {
    return await rendezVousRepository.assignDoctorToRendezVous(
      rendezVousId,
      doctorId,
      doctorName,
    );
  }
}