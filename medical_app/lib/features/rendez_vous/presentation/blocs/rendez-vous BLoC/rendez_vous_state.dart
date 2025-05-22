part of 'rendez_vous_bloc.dart';

abstract class RendezVousState extends Equatable {
  const RendezVousState();

  @override
  List<Object?> get props => [];
}

class RendezVousInitial extends RendezVousState {}

class RendezVousLoading extends RendezVousState {}

class RendezVousLoaded extends RendezVousState {
  final List<RendezVousEntity> rendezVous;

  const RendezVousLoaded(this.rendezVous);

  @override
  List<Object> get props => [rendezVous];
}

class DoctorsLoaded extends RendezVousState {
  final List<MedecinEntity> doctors;

  const DoctorsLoaded(this.doctors);

  @override
  List<Object> get props => [doctors];
}

class RendezVousError extends RendezVousState {
  final String message;

  const RendezVousError(this.message);

  @override
  List<Object> get props => [message];
}

class RendezVousStatusUpdated extends RendezVousState {}

class RendezVousCreated extends RendezVousState {
  final String? rendezVousId;
  final String? patientName;

  const RendezVousCreated({this.rendezVousId, this.patientName});

  @override
  List<Object?> get props => [rendezVousId, patientName];
}

class RendezVousDoctorAssigned extends RendezVousState {}

class PastAppointmentsChecked extends RendezVousState {
  final int updatedCount;

  const PastAppointmentsChecked({required this.updatedCount});

  @override
  List<Object> get props => [updatedCount];
}

class UpdatingRendezVousState extends RendezVousState {}

class RendezVousStatusUpdatedState extends RendezVousState {
  final String id;
  final String status;

  const RendezVousStatusUpdatedState({required this.id, required this.status});

  @override
  List<Object> get props => [id, status];
}

class AddingRendezVousState extends RendezVousState {}

class RendezVousAddedState extends RendezVousState {}

class RendezVousErrorState extends RendezVousState {
  final String message;

  const RendezVousErrorState({required this.message});

  @override
  List<Object> get props => [message];
}
