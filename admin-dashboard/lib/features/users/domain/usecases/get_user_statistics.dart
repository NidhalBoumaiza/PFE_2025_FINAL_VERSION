import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/users_repository.dart';

class GetUserStatistics implements UseCase<Map<String, int>> {
  final UsersRepository repository;

  GetUserStatistics(this.repository);

  @override
  Future<Either<Failure, Map<String, int>>> call() async {
    return await repository.getUserStatistics();
  }
}
