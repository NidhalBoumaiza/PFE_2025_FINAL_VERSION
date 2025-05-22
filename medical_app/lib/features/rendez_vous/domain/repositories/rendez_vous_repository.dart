import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/authentication/domain/entities/medecin_entity.dart';
import 'package:medical_app/features/rendez_vous/domain/entities/rendez_vous_entity.dart';

abstract class RendezVousRepository {
  Future<Either<Failure, List<RendezVousEntity>>> getRendezVous({
    String? patientId,
    String? doctorId,
  });

  Future<Either<Failure, Unit>> updateRendezVousStatus(
      String rendezVousId,
      String status,
      String patientId,
      String doctorId,
      String patientName,
      String doctorName,
      );

  Future<Either<Failure, Unit>> createRendezVous(RendezVousEntity rendezVous);

  Future<Either<Failure, List<MedecinEntity>>> getDoctorsBySpecialty(
      String specialty,
      DateTime startTime,
      );

  Future<Either<Failure, Unit>> assignDoctorToRendezVous(
      String rendezVousId,
      String doctorId,
      String doctorName,
      );
}