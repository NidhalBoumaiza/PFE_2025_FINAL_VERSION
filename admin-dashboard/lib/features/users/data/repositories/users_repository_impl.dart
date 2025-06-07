import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/patient_entity.dart';
import '../../domain/entities/doctor_entity.dart';
import '../../domain/repositories/users_repository.dart';
import '../datasources/users_remote_data_source.dart';
import '../models/patient_model.dart';
import '../models/doctor_model.dart';

class UsersRepositoryImpl implements UsersRepository {
  final UsersRemoteDataSource remoteDataSource;

  UsersRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<PatientEntity>>> getAllPatients() async {
    try {
      final patients = await remoteDataSource.getPatients();
      return Right(patients);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to fetch patients: $e'));
    }
  }

  @override
  Future<Either<Failure, List<DoctorEntity>>> getAllDoctors() async {
    try {
      final doctors = await remoteDataSource.getDoctors();
      return Right(doctors);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to fetch doctors: $e'));
    }
  }

  @override
  Stream<Either<Failure, List<PatientEntity>>> getPatientsStream() {
    try {
      return remoteDataSource.getPatientsStream().map(
        (patients) => Right(patients),
      );
    } catch (e) {
      return Stream.value(
        Left(ServerFailure(message: 'Failed to get patients stream: $e')),
      );
    }
  }

  @override
  Stream<Either<Failure, List<DoctorEntity>>> getDoctorsStream() {
    try {
      return remoteDataSource.getDoctorsStream().map(
        (doctors) => Right(doctors),
      );
    } catch (e) {
      return Stream.value(
        Left(ServerFailure(message: 'Failed to get doctors stream: $e')),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> refreshAllUsers() async {
    try {
      await remoteDataSource.refreshData();
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to refresh users: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> createPatient(
    PatientEntity patient,
    String password,
  ) async {
    try {
      final patientModel = PatientModel(
        id: patient.id,
        fullName: patient.fullName,
        email: patient.email,
        gender: patient.gender,
        phoneNumber: patient.phoneNumber,
        dateOfBirth: patient.dateOfBirth,
        age: patient.age,
        address: patient.address,
        accountStatus: patient.accountStatus,
        antecedent: patient.antecedent,
        bloodType: patient.bloodType,
        height: patient.height,
        weight: patient.weight,
        allergies: patient.allergies,
        chronicDiseases: patient.chronicDiseases,
        emergencyContactName: patient.emergencyContactName,
        emergencyContactPhone: patient.emergencyContactPhone,
        createdAt: patient.createdAt,
        lastLogin: patient.lastLogin,
      );

      await remoteDataSource.createPatient(patientModel, password);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to create patient: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> createDoctor(
    DoctorEntity doctor,
    String password,
  ) async {
    try {
      final doctorModel = DoctorModel(
        id: doctor.id,
        fullName: doctor.fullName,
        email: doctor.email,
        gender: doctor.gender,
        phoneNumber: doctor.phoneNumber,
        dateOfBirth: doctor.dateOfBirth,
        age: doctor.age,
        address: doctor.address,
        accountStatus: doctor.accountStatus,
        speciality: doctor.speciality,
        numLicence: doctor.numLicence,
        appointmentDuration: doctor.appointmentDuration,
        experienceYears: doctor.experienceYears,
        educationSummary: doctor.educationSummary,
        consultationFee: doctor.consultationFee,
        createdAt: doctor.createdAt,
        lastLogin: doctor.lastLogin,
      );

      await remoteDataSource.createDoctor(doctorModel, password);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to create doctor: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updatePatient(PatientEntity patient) async {
    try {
      final patientModel = PatientModel(
        id: patient.id,
        fullName: patient.fullName,
        email: patient.email,
        gender: patient.gender,
        phoneNumber: patient.phoneNumber,
        dateOfBirth: patient.dateOfBirth,
        age: patient.age,
        address: patient.address,
        accountStatus: patient.accountStatus,
        antecedent: patient.antecedent,
        bloodType: patient.bloodType,
        height: patient.height,
        weight: patient.weight,
        allergies: patient.allergies,
        chronicDiseases: patient.chronicDiseases,
        emergencyContactName: patient.emergencyContactName,
        emergencyContactPhone: patient.emergencyContactPhone,
        createdAt: patient.createdAt,
        lastLogin: patient.lastLogin,
      );

      await remoteDataSource.updatePatient(patientModel);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to update patient: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateDoctor(DoctorEntity doctor) async {
    try {
      final doctorModel = DoctorModel(
        id: doctor.id,
        fullName: doctor.fullName,
        email: doctor.email,
        gender: doctor.gender,
        phoneNumber: doctor.phoneNumber,
        dateOfBirth: doctor.dateOfBirth,
        age: doctor.age,
        address: doctor.address,
        accountStatus: doctor.accountStatus,
        speciality: doctor.speciality,
        numLicence: doctor.numLicence,
        appointmentDuration: doctor.appointmentDuration,
        experienceYears: doctor.experienceYears,
        educationSummary: doctor.educationSummary,
        consultationFee: doctor.consultationFee,
        createdAt: doctor.createdAt,
        lastLogin: doctor.lastLogin,
      );

      await remoteDataSource.updateDoctor(doctorModel);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to update doctor: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteUser(
    String userId,
    String userType,
  ) async {
    try {
      await remoteDataSource.deleteUser(userId, userType);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to delete user: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> getUserStatistics() async {
    try {
      final statistics = await remoteDataSource.getUserStatistics();
      return Right(statistics);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get user statistics: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getUserAppointmentCount(
    String userId,
    String userType,
  ) async {
    try {
      final count = await remoteDataSource.getUserAppointmentCount(
        userId,
        userType,
      );
      return Right(count);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Failed to get appointment count: $e'),
      );
    }
  }
}
