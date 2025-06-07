import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/patient_entity.dart';
import '../../domain/entities/doctor_entity.dart';
import '../../domain/usecases/get_all_patients_usecase.dart';
import '../../domain/usecases/get_all_doctors_usecase.dart';
import '../../domain/usecases/create_patient_usecase.dart';
import '../../domain/usecases/create_doctor_usecase.dart';
import '../../domain/usecases/update_patient_usecase.dart';
import '../../domain/usecases/update_doctor_usecase.dart';
import '../../domain/usecases/delete_user_usecase.dart';
import '../../domain/usecases/get_user_statistics.dart';
import '../../data/datasources/users_remote_data_source.dart';
import 'users_event.dart';
import 'users_state.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final GetAllPatientsUseCase getAllPatientsUseCase;
  final GetAllDoctorsUseCase getAllDoctorsUseCase;
  final CreatePatientUseCase createPatientUseCase;
  final CreateDoctorUseCase createDoctorUseCase;
  final UpdatePatientUseCase updatePatientUseCase;
  final UpdateDoctorUseCase updateDoctorUseCase;
  final DeleteUserUseCase deleteUserUseCase;
  final GetUserStatistics getUserStatistics;
  final UsersRemoteDataSource remoteDataSource;

  // Stream subscriptions for real-time updates
  StreamSubscription<List<PatientEntity>>? _patientsSubscription;
  StreamSubscription<List<DoctorEntity>>? _doctorsSubscription;

  // Current data cache
  List<PatientEntity> _currentPatients = [];
  List<DoctorEntity> _currentDoctors = [];

  // Public getters for current data
  List<PatientEntity> get currentPatients => _currentPatients;
  List<DoctorEntity> get currentDoctors => _currentDoctors;

  UsersBloc({
    required this.getAllPatientsUseCase,
    required this.getAllDoctorsUseCase,
    required this.createPatientUseCase,
    required this.createDoctorUseCase,
    required this.updatePatientUseCase,
    required this.updateDoctorUseCase,
    required this.deleteUserUseCase,
    required this.getUserStatistics,
    required this.remoteDataSource,
  }) : super(UsersInitial()) {
    print('🏗️ UsersBloc: Constructor called - initializing event handlers');
    on<LoadPatients>(_onLoadPatients);
    on<LoadDoctors>(_onLoadDoctors);
    on<LoadAllUsers>(_onLoadAllUsers);
    on<LoadUserStatistics>(_onLoadUserStatistics);
    on<StartListeningToUsers>(_onStartListeningToUsers);
    on<StopListeningToUsers>(_onStopListeningToUsers);
    on<RefreshAllUsers>(_onRefreshAllUsers);
    on<PatientsUpdated>(_onPatientsUpdated);
    on<DoctorsUpdated>(_onDoctorsUpdated);

    // CRUD event handlers
    on<CreatePatientEvent>(_onCreatePatient);
    on<CreateDoctorEvent>(_onCreateDoctor);
    on<UpdatePatientEvent>(_onUpdatePatient);
    on<UpdateDoctorEvent>(_onUpdateDoctor);
    on<DeleteUserEvent>(_onDeleteUser);

    print('✅ UsersBloc: Constructor completed - all event handlers registered');
  }

  @override
  Future<void> close() {
    print('🔄 UsersBloc: close() called - cleaning up subscriptions');
    _patientsSubscription?.cancel();
    _doctorsSubscription?.cancel();
    print('✅ UsersBloc: close() completed');
    return super.close();
  }

  Future<void> _onLoadPatients(
    LoadPatients event,
    Emitter<UsersState> emit,
  ) async {
    print('📋 UsersBloc: LoadPatients event received');
    print('⏳ UsersBloc: Emitting PatientsLoading state');
    emit(PatientsLoading());

    print('🔍 UsersBloc: Calling getAllPatientsUseCase...');
    final result = await getAllPatientsUseCase();

    result.fold(
      (failure) {
        print(
          '❌ UsersBloc: Failed to load patients - Type: ${failure.runtimeType}',
        );
        print('❌ UsersBloc: Failure details: ${_getFailureMessage(failure)}');
        emit(UsersError(_getFailureMessage(failure)));
      },
      (patients) {
        print('✅ UsersBloc: Successfully loaded ${patients.length} patients');
        print('👥 UsersBloc: Patient details:');
        for (int i = 0; i < patients.length; i++) {
          final patient = patients[i];
          print(
            '   Patient $i: ${patient.fullName} - Email: ${patient.email}, Active: ${patient.accountStatus}',
          );
        }
        _currentPatients = patients;
        print('💾 UsersBloc: Cached ${_currentPatients.length} patients');
        emit(PatientsLoaded(patients));
      },
    );
  }

  Future<void> _onLoadDoctors(
    LoadDoctors event,
    Emitter<UsersState> emit,
  ) async {
    print('👨‍⚕️ UsersBloc: LoadDoctors event received');
    print('⏳ UsersBloc: Emitting DoctorsLoading state');
    emit(DoctorsLoading());

    print('🔍 UsersBloc: Calling getAllDoctorsUseCase...');
    final result = await getAllDoctorsUseCase();

    result.fold(
      (failure) {
        print(
          '❌ UsersBloc: Failed to load doctors - Type: ${failure.runtimeType}',
        );
        print('❌ UsersBloc: Failure details: ${_getFailureMessage(failure)}');
        emit(UsersError(_getFailureMessage(failure)));
      },
      (doctors) {
        print('✅ UsersBloc: Successfully loaded ${doctors.length} doctors');
        print('👨‍⚕️ UsersBloc: Doctor details:');
        for (int i = 0; i < doctors.length; i++) {
          final doctor = doctors[i];
          print(
            '   Doctor $i: ${doctor.fullName} - Email: ${doctor.email}, Specialty: ${doctor.speciality}, Active: ${doctor.accountStatus}',
          );
        }
        _currentDoctors = doctors;
        print('💾 UsersBloc: Cached ${_currentDoctors.length} doctors');
        emit(DoctorsLoaded(doctors));
      },
    );
  }

  Future<void> _onLoadAllUsers(
    LoadAllUsers event,
    Emitter<UsersState> emit,
  ) async {
    print('👥 UsersBloc: LoadAllUsers event received');
    print('⏳ UsersBloc: Emitting AllUsersLoading state');
    emit(AllUsersLoading());

    // Load both patients and doctors
    print('🔍 UsersBloc: Loading patients and doctors simultaneously...');
    final patientsResult = await getAllPatientsUseCase();
    final doctorsResult = await getAllDoctorsUseCase();

    print(
      '📊 UsersBloc: Results received - Patients: ${patientsResult.isRight() ? 'SUCCESS' : 'FAILED'}, Doctors: ${doctorsResult.isRight() ? 'SUCCESS' : 'FAILED'}',
    );

    if (patientsResult.isLeft() || doctorsResult.isLeft()) {
      final errorMessage =
          patientsResult.isLeft()
              ? patientsResult.fold((l) => _getFailureMessage(l), (r) => '')
              : doctorsResult.fold((l) => _getFailureMessage(l), (r) => '');
      print('❌ UsersBloc: Failed to load all users: $errorMessage');
      emit(UsersError(errorMessage));
      return;
    }

    final patients = patientsResult.fold((l) => <PatientEntity>[], (r) => r);
    final doctors = doctorsResult.fold((l) => <DoctorEntity>[], (r) => r);

    print('✅ UsersBloc: Successfully loaded all users');
    print(
      '📊 UsersBloc: Total patients: ${patients.length}, Total doctors: ${doctors.length}',
    );

    // Log detailed information about loaded users
    print('👤 UsersBloc: Patient summary:');
    for (var patient in patients) {
      print(
        '   - ${patient.fullName.isEmpty ? 'NO NAME' : patient.fullName} - ${patient.email}',
      );
    }

    print('👨‍⚕️ UsersBloc: Doctor summary:');
    for (var doctor in doctors) {
      print(
        '   - ${doctor.fullName.isEmpty ? 'NO NAME' : doctor.fullName} - ${doctor.email}',
      );
    }

    _currentPatients = patients;
    _currentDoctors = doctors;
    print(
      '💾 UsersBloc: Updated cache - Patients: ${_currentPatients.length}, Doctors: ${_currentDoctors.length}',
    );

    emit(AllUsersLoaded(patients: patients, doctors: doctors));
    print('✅ UsersBloc: Emitted AllUsersLoaded state');

    // Start listening for real-time updates
    print('🔄 UsersBloc: Starting real-time listeners...');
    add(StartListeningToUsers());
  }

  Future<void> _onLoadUserStatistics(
    LoadUserStatistics event,
    Emitter<UsersState> emit,
  ) async {
    print('📈 UsersBloc: LoadUserStatistics event received');
    print('⏳ UsersBloc: Emitting UserStatisticsLoading state');
    emit(UserStatisticsLoading());

    print('🔍 UsersBloc: Calling getUserStatistics...');
    final result = await getUserStatistics();

    result.fold(
      (failure) {
        print(
          '❌ UsersBloc: Failed to load user statistics - Type: ${failure.runtimeType}',
        );
        print(
          '❌ UsersBloc: Statistics failure details: ${_getFailureMessage(failure)}',
        );
        emit(UsersError(_getFailureMessage(failure)));
      },
      (statistics) {
        print('✅ UsersBloc: Successfully loaded user statistics');
        print('📊 UsersBloc: Statistics details:');
        statistics.forEach((key, value) {
          print('   - $key: $value');
        });
        emit(UserStatisticsLoaded(statistics));
      },
    );
  }

  Future<void> _onStartListeningToUsers(
    StartListeningToUsers event,
    Emitter<UsersState> emit,
  ) async {
    print('🎧 UsersBloc: StartListeningToUsers event received');

    try {
      // Cancel existing subscriptions
      print('🔄 UsersBloc: Canceling existing subscriptions...');
      await _patientsSubscription?.cancel();
      await _doctorsSubscription?.cancel();
      print('✅ UsersBloc: Existing subscriptions cancelled');

      // Start listening to patients stream
      print('👤 UsersBloc: Starting patients stream subscription...');
      _patientsSubscription = remoteDataSource.getPatientsStream().listen(
        (patients) {
          print(
            '🔔 UsersBloc: Real-time patients update - ${patients.length} patients received',
          );
          print('📊 UsersBloc: Updated patients list:');
          for (var patient in patients) {
            print('   - ${patient.fullName}');
          }
          add(PatientsUpdated(patients));
        },
        onError: (error) {
          print('❌ UsersBloc: Error in patients stream: $error');
          print(
            '❌ UsersBloc: Patients stream error type: ${error.runtimeType}',
          );
          emit(UsersError('Real-time update failed: $error'));
        },
      );

      // Start listening to doctors stream
      print('👨‍⚕️ UsersBloc: Starting doctors stream subscription...');
      _doctorsSubscription = remoteDataSource.getDoctorsStream().listen(
        (doctors) {
          print(
            '🔔 UsersBloc: Real-time doctors update - ${doctors.length} doctors received',
          );
          print('📊 UsersBloc: Updated doctors list:');
          for (var doctor in doctors) {
            print('   - ${doctor.fullName}');
          }
          add(DoctorsUpdated(doctors));
        },
        onError: (error) {
          print('❌ UsersBloc: Error in doctors stream: $error');
          print('❌ UsersBloc: Doctors stream error type: ${error.runtimeType}');
          emit(UsersError('Real-time update failed: $error'));
        },
      );

      print('✅ UsersBloc: Real-time listeners started successfully');
    } catch (e) {
      print('❌ UsersBloc: Exception in starting real-time listeners: $e');
      print('❌ UsersBloc: Exception type: ${e.runtimeType}');
      emit(UsersError('Failed to start real-time updates: $e'));
    }
  }

  Future<void> _onStopListeningToUsers(
    StopListeningToUsers event,
    Emitter<UsersState> emit,
  ) async {
    print('🛑 UsersBloc: StopListeningToUsers event received');
    print('🔄 UsersBloc: Canceling real-time subscriptions...');
    await _patientsSubscription?.cancel();
    await _doctorsSubscription?.cancel();
    _patientsSubscription = null;
    _doctorsSubscription = null;
    print('✅ UsersBloc: Real-time listeners stopped successfully');
  }

  Future<void> _onRefreshAllUsers(
    RefreshAllUsers event,
    Emitter<UsersState> emit,
  ) async {
    print('🔄 UsersBloc: RefreshAllUsers event received');

    try {
      print('🔄 UsersBloc: Calling remoteDataSource.refreshData()...');
      await remoteDataSource.refreshData();
      print('✅ UsersBloc: Data refresh completed, triggering LoadAllUsers...');
      add(LoadAllUsers());
    } catch (e) {
      print('❌ UsersBloc: Failed to refresh data: $e');
      print('❌ UsersBloc: Refresh error type: ${e.runtimeType}');
      emit(UsersError('Failed to refresh data: $e'));
    }
  }

  void _onPatientsUpdated(PatientsUpdated event, Emitter<UsersState> emit) {
    print(
      '🔔 UsersBloc: PatientsUpdated event received - ${event.patients.length} patients',
    );
    print(
      '💾 UsersBloc: Previous patients cache size: ${_currentPatients.length}',
    );

    _currentPatients = event.patients;
    print(
      '💾 UsersBloc: Updated patients cache size: ${_currentPatients.length}',
    );

    print('✅ UsersBloc: Emitting AllUsersLoaded with updated patients');
    emit(AllUsersLoaded(patients: _currentPatients, doctors: _currentDoctors));
  }

  void _onDoctorsUpdated(DoctorsUpdated event, Emitter<UsersState> emit) {
    print(
      '🔔 UsersBloc: DoctorsUpdated event received - ${event.doctors.length} doctors',
    );
    print(
      '💾 UsersBloc: Previous doctors cache size: ${_currentDoctors.length}',
    );

    _currentDoctors = event.doctors;
    print(
      '💾 UsersBloc: Updated doctors cache size: ${_currentDoctors.length}',
    );

    print('✅ UsersBloc: Emitting AllUsersLoaded with updated doctors');
    emit(AllUsersLoaded(patients: _currentPatients, doctors: _currentDoctors));
  }

  // CRUD Event Handlers
  Future<void> _onCreatePatient(
    CreatePatientEvent event,
    Emitter<UsersState> emit,
  ) async {
    print(
      '➕👤 UsersBloc: CreatePatientEvent received - ${event.patient.email}',
    );
    print('⏳ UsersBloc: Emitting UserOperationLoading state');
    emit(UserOperationLoading());

    print('🔍 UsersBloc: Calling createPatientUseCase...');
    final result = await createPatientUseCase(event.patient, event.password);

    result.fold(
      (failure) {
        print(
          '❌ UsersBloc: Failed to create patient - Type: ${failure.runtimeType}',
        );
        print(
          '❌ UsersBloc: Create patient failure: ${_getFailureMessage(failure)}',
        );
        emit(UserOperationError(_getFailureMessage(failure)));
      },
      (_) {
        print(
          '✅ UsersBloc: Patient created successfully - ${event.patient.email}',
        );
        emit(UserCreated('Patient created successfully'));
        print('🔄 UsersBloc: Triggering data reload after patient creation');
        add(LoadAllUsers());
      },
    );
  }

  Future<void> _onCreateDoctor(
    CreateDoctorEvent event,
    Emitter<UsersState> emit,
  ) async {
    print(
      '➕👨‍⚕️ UsersBloc: CreateDoctorEvent received - ${event.doctor.email}',
    );
    print('⏳ UsersBloc: Emitting UserOperationLoading state');
    emit(UserOperationLoading());

    print('🔍 UsersBloc: Calling createDoctorUseCase...');
    final result = await createDoctorUseCase(event.doctor, event.password);

    result.fold(
      (failure) {
        print(
          '❌ UsersBloc: Failed to create doctor - Type: ${failure.runtimeType}',
        );
        print(
          '❌ UsersBloc: Create doctor failure: ${_getFailureMessage(failure)}',
        );
        emit(UserOperationError(_getFailureMessage(failure)));
      },
      (_) {
        print(
          '✅ UsersBloc: Doctor created successfully - ${event.doctor.email}',
        );
        emit(UserCreated('Doctor created successfully'));
        print('🔄 UsersBloc: Triggering data reload after doctor creation');
        add(LoadAllUsers());
      },
    );
  }

  Future<void> _onUpdatePatient(
    UpdatePatientEvent event,
    Emitter<UsersState> emit,
  ) async {
    print(
      '✏️👤 UsersBloc: UpdatePatientEvent received - ${event.patient.fullName}',
    );
    print('⏳ UsersBloc: Emitting UserOperationLoading state');
    emit(UserOperationLoading());

    print('🔍 UsersBloc: Calling updatePatientUseCase...');
    final result = await updatePatientUseCase(event.patient);

    result.fold(
      (failure) {
        print(
          '❌ UsersBloc: Failed to update patient - Type: ${failure.runtimeType}',
        );
        print(
          '❌ UsersBloc: Update patient failure: ${_getFailureMessage(failure)}',
        );
        emit(UserOperationError(_getFailureMessage(failure)));
      },
      (_) {
        print(
          '✅ UsersBloc: Patient updated successfully - ${event.patient.fullName}',
        );
        emit(UserUpdated('Patient updated successfully'));
        print('🔄 UsersBloc: Triggering data reload after patient update');
        add(LoadAllUsers());
      },
    );
  }

  Future<void> _onUpdateDoctor(
    UpdateDoctorEvent event,
    Emitter<UsersState> emit,
  ) async {
    print(
      '✏️👨‍⚕️ UsersBloc: UpdateDoctorEvent received - ${event.doctor.fullName}',
    );
    print('⏳ UsersBloc: Emitting UserOperationLoading state');
    emit(UserOperationLoading());

    print('🔍 UsersBloc: Calling updateDoctorUseCase...');
    final result = await updateDoctorUseCase(event.doctor);

    result.fold(
      (failure) {
        print(
          '❌ UsersBloc: Failed to update doctor - Type: ${failure.runtimeType}',
        );
        print(
          '❌ UsersBloc: Update doctor failure: ${_getFailureMessage(failure)}',
        );
        emit(UserOperationError(_getFailureMessage(failure)));
      },
      (_) {
        print(
          '✅ UsersBloc: Doctor updated successfully - ${event.doctor.fullName}',
        );
        emit(UserUpdated('Doctor updated successfully'));
        print('🔄 UsersBloc: Triggering data reload after doctor update');
        add(LoadAllUsers());
      },
    );
  }

  Future<void> _onDeleteUser(
    DeleteUserEvent event,
    Emitter<UsersState> emit,
  ) async {
    print(
      '🗑️ UsersBloc: DeleteUserEvent received - ${event.userId} (${event.userType})',
    );
    print('⏳ UsersBloc: Emitting UserOperationLoading state');
    emit(UserOperationLoading());

    print('🔍 UsersBloc: Calling deleteUserUseCase...');
    final result = await deleteUserUseCase(event.userId, event.userType);

    result.fold(
      (failure) {
        print(
          '❌ UsersBloc: Failed to delete user - Type: ${failure.runtimeType}',
        );
        print(
          '❌ UsersBloc: Delete user failure: ${_getFailureMessage(failure)}',
        );
        emit(UserOperationError(_getFailureMessage(failure)));
      },
      (_) {
        print('✅ UsersBloc: User deleted successfully - ${event.userId}');
        emit(UserDeleted('User deleted successfully'));
        print('🔄 UsersBloc: Triggering data reload after user deletion');
        add(LoadAllUsers());
      },
    );
  }

  String _getFailureMessage(Failure failure) {
    print(
      '🔍 UsersBloc: Mapping failure to message - Type: ${failure.runtimeType}',
    );

    if (failure is ServerFailure) {
      final message = failure.message ?? 'Server error occurred';
      print('📡 UsersBloc: Server failure - $message');
      return message;
    } else if (failure is CacheFailure) {
      print('💾 UsersBloc: Cache failure');
      return 'Cache error occurred';
    } else {
      print('❓ UsersBloc: Unknown failure type');
      return 'An unexpected error occurred';
    }
  }
}
