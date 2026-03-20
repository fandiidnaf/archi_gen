class FeatureTemplates {
  // ─── Domain: Entity ───────────────────────────────────────────────────────

  static String entity({
    required String featureName,
    required String className,
  }) =>
      '''
import 'package:equatable/equatable.dart';

class ${className}Entity extends Equatable {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ${className}Entity({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  ${className}Entity copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ${className}Entity(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, createdAt, updatedAt];
}
''';

  // ─── Domain: Repository (abstract) ────────────────────────────────────────

  static String repository({
    required String featureName,
    required String className,
    required String projectName,
  }) =>
      '''
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/${featureName}_entity.dart';

abstract class ${className}Repository {
  Future<Either<Failure, List<${className}Entity>>> getAll();
  Future<Either<Failure, ${className}Entity>> getById(String id);
  Future<Either<Failure, ${className}Entity>> create(${className}Entity entity);
  Future<Either<Failure, ${className}Entity>> update(${className}Entity entity);
  Future<Either<Failure, Unit>> delete(String id);
}
''';

  // ─── Domain: UseCase ──────────────────────────────────────────────────────

  static String usecase({
    required String featureName,
    required String className,
    required String projectName,
  }) =>
      '''
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/${featureName}_entity.dart';
import '../repositories/${featureName}_repository.dart';

class Get${className}UseCase implements UseCase<List<${className}Entity>, NoParams> {
  final ${className}Repository repository;
  Get${className}UseCase(this.repository);

  @override
  Future<Either<Failure, List<${className}Entity>>> call(NoParams params) =>
      repository.getAll();
}

class Get${className}ByIdUseCase implements UseCase<${className}Entity, String> {
  final ${className}Repository repository;
  Get${className}ByIdUseCase(this.repository);

  @override
  Future<Either<Failure, ${className}Entity>> call(String id) =>
      repository.getById(id);
}
''';

  // ─── Data: Model ──────────────────────────────────────────────────────────

  static String model({
    required String featureName,
    required String className,
    required String projectName,
  }) =>
      '''
import '../../domain/entities/${featureName}_entity.dart';

class ${className}Model extends ${className}Entity {
  const ${className}Model({
    required super.id,
    required super.name,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ${className}Model.fromJson(Map<String, dynamic> json) {
    return ${className}Model(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  ${className}Entity toEntity() => ${className}Entity(
        id: id,
        name: name,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory ${className}Model.fromEntity(${className}Entity entity) => ${className}Model(
        id: entity.id,
        name: entity.name,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      );
}
''';

  // ─── Data: Remote Datasource (Dio) ────────────────────────────────────────

  static String remoteDatasource({
    required String featureName,
    required String className,
    required String projectName,
  }) =>
      '''
import 'package:dio/dio.dart';
import '../models/${featureName}_model.dart';

abstract class ${className}RemoteDatasource {
  Future<List<${className}Model>> getAll({Map<String, dynamic>? queryParams});
  Future<${className}Model> getById(String id);
  Future<${className}Model> create(${className}Model model);
  Future<${className}Model> update(${className}Model model);
  Future<void> delete(String id);
}

class ${className}RemoteDatasourceImpl implements ${className}RemoteDatasource {
  final Dio dio;

  /// Change this to match your API endpoint.
  static const _path = '/${featureName}s';

  ${className}RemoteDatasourceImpl({required this.dio});

  @override
  Future<List<${className}Model>> getAll({Map<String, dynamic>? queryParams}) async {
    final response = await dio.get<List<dynamic>>(
      _path,
      queryParameters: queryParams,
    );
    return (response.data ?? [])
        .map((json) => ${className}Model.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<${className}Model> getById(String id) async {
    final response = await dio.get<Map<String, dynamic>>('\$_path/\$id');
    return ${className}Model.fromJson(response.data!);
  }

  @override
  Future<${className}Model> create(${className}Model model) async {
    final response = await dio.post<Map<String, dynamic>>(
      _path,
      data: model.toJson(),
    );
    return ${className}Model.fromJson(response.data!);
  }

  @override
  Future<${className}Model> update(${className}Model model) async {
    final response = await dio.put<Map<String, dynamic>>(
      '\$_path/\${model.id}',
      data: model.toJson(),
    );
    return ${className}Model.fromJson(response.data!);
  }

  @override
  Future<void> delete(String id) async {
    await dio.delete('\$_path/\$id');
  }
}
''';

  // ─── Data: Repository Impl ────────────────────────────────────────────────

  static String repositoryImpl({
    required String featureName,
    required String className,
    required String projectName,
    bool withDatasource = true,
  }) {
    final datasourceImport = withDatasource
        ? "import '../datasources/${featureName}_remote_datasource.dart';\n"
        : '';
    final modelImport =
        withDatasource ? "import '../models/${featureName}_model.dart';\n" : '';
    final field = withDatasource
        ? '  final ${className}RemoteDatasource remoteDatasource;\n\n  ${className}RepositoryImpl({required this.remoteDatasource});'
        : '  ${className}RepositoryImpl();';

    return '''
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/${featureName}_entity.dart';
import '../../domain/repositories/${featureName}_repository.dart';
$modelImport$datasourceImport
class ${className}RepositoryImpl implements ${className}Repository {
$field

  @override
  Future<Either<Failure, List<${className}Entity>>> getAll() async {
    try {
      ${withDatasource ? 'final result = await remoteDatasource.getAll();\n      return Right(result.map((m) => m.toEntity()).toList());' : 'return const Right([]);'}
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Network error'));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ${className}Entity>> getById(String id) async {
    try {
      ${withDatasource ? 'final result = await remoteDatasource.getById(id);\n      return Right(result.toEntity());' : "return Left(const ServerFailure('Not implemented'));"}
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Network error'));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ${className}Entity>> create(${className}Entity entity) async {
    try {
      ${withDatasource ? 'final model = ${className}Model.fromEntity(entity);\n      final result = await remoteDatasource.create(model);\n      return Right(result.toEntity());' : "return Left(const ServerFailure('Not implemented'));"}
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Network error'));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ${className}Entity>> update(${className}Entity entity) async {
    try {
      ${withDatasource ? 'final model = ${className}Model.fromEntity(entity);\n      final result = await remoteDatasource.update(model);\n      return Right(result.toEntity());' : "return Left(const ServerFailure('Not implemented'));"}
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Network error'));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> delete(String id) async {
    try {
      ${withDatasource ? 'await remoteDatasource.delete(id);\n      return const Right(unit);' : "return Left(const ServerFailure('Not implemented'));"}
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Network error'));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
''';
  }

  // ─── Presentation: BLoC Event ─────────────────────────────────────────────

  static String blocEvent({
    required String featureName,
    required String className,
  }) =>
      '''
part of '${featureName}_bloc.dart';

sealed class ${className}Event {
  const ${className}Event();
}

class ${className}LoadAll extends ${className}Event {
  const ${className}LoadAll();
}

class ${className}LoadById extends ${className}Event {
  final String id;
  const ${className}LoadById(this.id);
}

class ${className}Create extends ${className}Event {
  final ${className}Entity entity;
  const ${className}Create(this.entity);
}

class ${className}Update extends ${className}Event {
  final ${className}Entity entity;
  const ${className}Update(this.entity);
}

class ${className}Delete extends ${className}Event {
  final String id;
  const ${className}Delete(this.id);
}

class ${className}Reset extends ${className}Event {
  const ${className}Reset();
}
''';

  // ─── Presentation: BLoC State ─────────────────────────────────────────────

  static String blocState({
    required String featureName,
    required String className,
  }) =>
      '''
part of '${featureName}_bloc.dart';

sealed class ${className}State {
  const ${className}State();
}

class ${className}Initial extends ${className}State {
  const ${className}Initial();
}

class ${className}Loading extends ${className}State {
  const ${className}Loading();
}

class ${className}Loaded extends ${className}State {
  final List<${className}Entity> items;
  const ${className}Loaded(this.items);
}

class ${className}DetailLoaded extends ${className}State {
  final ${className}Entity item;
  const ${className}DetailLoaded(this.item);
}

class ${className}ActionSuccess extends ${className}State {
  final String message;
  const ${className}ActionSuccess(this.message);
}

class ${className}Error extends ${className}State {
  final String message;
  const ${className}Error(this.message);
}
''';

  // ─── Presentation: BLoC ───────────────────────────────────────────────────

  static String bloc({
    required String featureName,
    required String className,
    required String projectName,
    bool withUsecase = true,
  }) {
    final usecaseImport = withUsecase
        ? "import '../../domain/usecases/get_${featureName}_usecase.dart';\n"
        : '';
    final repoImport = !withUsecase
        ? "import '../../domain/repositories/${featureName}_repository.dart';\n"
        : '';
    final field = withUsecase
        ? '  final Get${className}UseCase get$className;\n\n  ${className}Bloc({required this.get$className})'
        : '  final ${className}Repository repository;\n\n  ${className}Bloc({required this.repository})';
    final loadAllCall = withUsecase
        ? 'final result = await get$className(const NoParams());\n        result.fold(\n          (f) => emit(${className}Error(f.message)),\n          (items) => emit(${className}Loaded(items)),\n        );'
        : 'final result = await repository.getAll();\n        result.fold(\n          (f) => emit(${className}Error(f.message)),\n          (items) => emit(${className}Loaded(items)),\n        );';

    return '''
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/${featureName}_entity.dart';
$usecaseImport$repoImport
part '${featureName}_event.dart';
part '${featureName}_state.dart';

class ${className}Bloc extends Bloc<${className}Event, ${className}State> {
$field : super(const ${className}Initial()) {
    on<${className}LoadAll>(_onLoadAll);
    on<${className}LoadById>(_onLoadById);
    on<${className}Create>(_onCreate);
    on<${className}Update>(_onUpdate);
    on<${className}Delete>(_onDelete);
    on<${className}Reset>((_, emit) => emit(const ${className}Initial()));
  }

  Future<void> _onLoadAll(
    ${className}LoadAll event,
    Emitter<${className}State> emit,
  ) async {
    emit(const ${className}Loading());
    try {
      $loadAllCall
    } catch (e) {
      emit(${className}Error(e.toString()));
    }
  }

  Future<void> _onLoadById(
    ${className}LoadById event,
    Emitter<${className}State> emit,
  ) async {
    emit(const ${className}Loading());
    try {
      ${withUsecase ? '// Inject Get${className}ByIdUseCase if needed\n      emit(const ${className}Error(\'Not implemented\'));' : 'final result = await repository.getById(event.id);\n      result.fold(\n        (f) => emit(${className}Error(f.message)),\n        (item) => emit(${className}DetailLoaded(item)),\n      );'}
    } catch (e) {
      emit(${className}Error(e.toString()));
    }
  }

  Future<void> _onCreate(
    ${className}Create event,
    Emitter<${className}State> emit,
  ) async {
    emit(const ${className}Loading());
    try {
      ${withUsecase ? '// Inject Create${className}UseCase if needed\n      emit(const ${className}Error(\'Not implemented\'));' : 'final result = await repository.create(event.entity);\n      result.fold(\n        (f) => emit(${className}Error(f.message)),\n        (_) => emit(const ${className}ActionSuccess(\'Created successfully\')),\n      );'}
    } catch (e) {
      emit(${className}Error(e.toString()));
    }
  }

  Future<void> _onUpdate(
    ${className}Update event,
    Emitter<${className}State> emit,
  ) async {
    emit(const ${className}Loading());
    try {
      ${withUsecase ? '// Inject Update${className}UseCase if needed\n      emit(const ${className}Error(\'Not implemented\'));' : 'final result = await repository.update(event.entity);\n      result.fold(\n        (f) => emit(${className}Error(f.message)),\n        (_) => emit(const ${className}ActionSuccess(\'Updated successfully\')),\n      );'}
    } catch (e) {
      emit(${className}Error(e.toString()));
    }
  }

  Future<void> _onDelete(
    ${className}Delete event,
    Emitter<${className}State> emit,
  ) async {
    emit(const ${className}Loading());
    try {
      ${withUsecase ? '// Inject Delete${className}UseCase if needed\n      emit(const ${className}Error(\'Not implemented\'));' : 'final result = await repository.delete(event.id);\n      result.fold(\n        (f) => emit(${className}Error(f.message)),\n        (_) => emit(const ${className}ActionSuccess(\'Deleted successfully\')),\n      );'}
    } catch (e) {
      emit(${className}Error(e.toString()));
    }
  }
}
''';
  }

  // ─── Presentation: Page ───────────────────────────────────────────────────

  static String page({
    required String featureName,
    required String className,
    required String projectName,
  }) =>
      '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/router/route_structure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/common/empty_state.dart';
import '../../../../core/widgets/common/loading_widget.dart';
import '../bloc/${featureName}_bloc.dart';

class ${className}Page extends StatelessWidget {
  static const RouteStructure route = RouteStructure(
    path: '/${featureName}s',
    name: '${featureName}s',
  );

  const ${className}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<${className}Bloc>()..add(const ${className}LoadAll()),
      child: const _${className}View(),
    );
  }
}

class _${className}View extends StatelessWidget {
  const _${className}View();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$className'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navigate to form:
              // context.push('${featureName}s/new');
            },
          ),
        ],
      ),
      body: BlocConsumer<${className}Bloc, ${className}State>(
        listener: (context, state) {
          if (state is ${className}ActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
            context.read<${className}Bloc>().add(const ${className}LoadAll());
          } else if (state is ${className}Error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) => switch (state) {
          ${className}Loading() => const LoadingWidget(message: 'Loading...'),
          ${className}Loaded(items: final items) when items.isEmpty =>
            EmptyState(
              title: 'No $className found',
              icon: Icons.inbox_outlined,
              actionLabel: 'Add New',
              onAction: () {
                // context.push('/${featureName}s/new');
              },
            ),
          ${className}Loaded(items: final items) => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text(item.id),
                    trailing: PopupMenuButton(
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit',   child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                      onSelected: (value) {
                        if (value == 'delete') {
                          context
                              .read<${className}Bloc>()
                              .add(${className}Delete(item.id));
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ${className}Error(message: final msg) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(msg, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<${className}Bloc>()
                        .add(const ${className}LoadAll()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}
''';
}
