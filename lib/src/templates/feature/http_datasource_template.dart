/// Template for HTTP (Dio) based datasource — used with `--backend http`.
class HttpDatasourceTemplate {
  static String remoteDatasource({
    required String featureName,
    required String className,
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

  /// Base path for this resource on your REST API.
  /// e.g. '/api/v1/${featureName}s'
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
}
