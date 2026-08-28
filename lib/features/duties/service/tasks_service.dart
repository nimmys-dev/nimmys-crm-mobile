import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/data/network/api_service.dart';
import 'package:nimmys_crm/data/network/api_urls.dart';
import 'package:nimmys_crm/features/duties/model/task_completed_model.dart';
import 'package:nimmys_crm/features/duties/model/task_details_model.dart';
import 'package:nimmys_crm/features/duties/model/task_type_model.dart';
import 'package:nimmys_crm/features/duties/model/tasks_list_model.dart';

/// Network access for task reads, writes and lookups.
class TasksService {
  TasksService(this._apiService);

  final ApiService _apiService;

  /// GET /api/tasks?per_page=10&page=1
  Future<Result<TaskListResponse>> getTasks({
    int page = 1,
    int perPage = 10,
    String? search,
  }) async {
    try {
      final String url = ApiUrls.tasks;
      final Map<String, dynamic> queryParams = <String, dynamic>{
        "page": page,
        "per_page": perPage,
        if (search != null && search.trim().isNotEmpty) "search": search.trim(),
      };
      final Result<dynamic> result = await _apiService.get(
        url,
        queryParams: queryParams,
      );
      if (result is Success<dynamic>) {
        return await _apiService.getResponseStatus<TaskListResponse>(
          result.value,
          (dynamic json) =>
              TaskListResponse.fromJson(json as Map<String, dynamic>),
        );
      } else if (result is Error<dynamic>) {
        return Error<TaskListResponse>(result.type);
      } else {
        return Error<TaskListResponse>(GenericError());
      }
    } catch (_) {
      return Error<TaskListResponse>(DeserializationError());
    }
  }

  /// GET /api/tasks/{id}. Returns details for a single task.
  Future<Result<TaskDetailsResponse>> getTaskDetails(int id) async {
    try {
      final String url = ApiUrls.viewTask(id);
      final Result<dynamic> result = await _apiService.get(url);
      if (result is Success<dynamic>) {
        return await _apiService.getResponseStatus<TaskDetailsResponse>(
          result.value,
          (dynamic json) =>
              TaskDetailsResponse.fromJson(json as Map<String, dynamic>),
        );
      } else if (result is Error<dynamic>) {
        return Error<TaskDetailsResponse>(result.type);
      } else {
        return Error<TaskDetailsResponse>(GenericError());
      }
    } catch (_) {
      return Error<TaskDetailsResponse>(DeserializationError());
    }
  }

  /// GET /api/task-types. Returns available task types.
  Future<Result<TaskTypeModel>> getTaskTypes() async {
    try {
      final String url = ApiUrls.taskTypes;
      final Result<dynamic> result = await _apiService.get(url);
      if (result is Success<dynamic>) {
        return await _apiService.getResponseStatus<TaskTypeModel>(
          result.value,
          (dynamic json) =>
              TaskTypeModel.fromJson(json as Map<String, dynamic>),
        );
      } else if (result is Error<dynamic>) {
        return Error<TaskTypeModel>(result.type);
      } else {
        return Error<TaskTypeModel>(GenericError());
      }
    } catch (_) {
      return Error<TaskTypeModel>(DeserializationError());
    }
  }

  /// POST /api/tasks. Creates a new task.
  Future<Result<dynamic>> createTask(Map<String, dynamic> payload) async {
    try {
      final Result<dynamic> result = await _apiService.post(
        ApiUrls.tasks,
        body: payload,
      );
      if (result is Success<dynamic> &&
          result.value is Map &&
          result.value['status'] == false) {
        final Object? message = result.value['message'];
        return Error(
          ErrorWithMessage(
            message: message is String ? message : 'Could not create task.',
          ),
        );
      }
      return result;
    } catch (_) {
      return Error(GenericError());
    }
  }

  /// PUT /api/update-task/{id}. Returns the same shape as task details.
  Future<Result<TaskDetailsResponse>> updateTask(
    int id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final Result<dynamic> result = await _apiService.put(
        ApiUrls.updateTask(id),
        body: payload,
      );
      if (result is Success<dynamic>) {
        return await _apiService.getResponseStatus<TaskDetailsResponse>(
          result.value,
          (dynamic json) =>
              TaskDetailsResponse.fromJson(json as Map<String, dynamic>),
        );
      } else if (result is Error<dynamic>) {
        return Error<TaskDetailsResponse>(result.type);
      }
      return Error<TaskDetailsResponse>(GenericError());
    } catch (_) {
      return Error<TaskDetailsResponse>(DeserializationError());
    }
  }

  /// POST /api/approval-task/{id}
  /// Marks a task as completed with optional remarks.
  Future<Result<TaskCompleteResponse>> completeTask(
    int id, {
    String? remarks,
  }) async {
    try {
      final String url = ApiUrls.approvalTask(
        id,
      ); // we need to add this constant
      final Map<String, dynamic> body = {};
      if (remarks != null && remarks.trim().isNotEmpty) {
        body['remarks'] = remarks.trim();
      }
      final Result<dynamic> result = await _apiService.post(url, body: body);
      if (result is Success<dynamic>) {
        return await _apiService.getResponseStatus<TaskCompleteResponse>(
          result.value,
          (json) => TaskCompleteResponse.fromJson(json as Map<String, dynamic>),
        );
      } else if (result is Error<dynamic>) {
        return Error<TaskCompleteResponse>(result.type);
      }
      return Error<TaskCompleteResponse>(GenericError());
    } catch (_) {
      return Error<TaskCompleteResponse>(DeserializationError());
    }
  }

  // /// DELETE /api/tasks/{id}. Deletes a task.
  Future<Result<dynamic>> deleteTask(int id) async {
    try {
      final Result<dynamic> result = await _apiService.delete(
        ApiUrls.deleteTask(id),
      );
      if (result is Success<dynamic> &&
          result.value is Map &&
          result.value['status'] == false) {
        final Object? message = result.value['message'];
        return Error(
          ErrorWithMessage(
            message: message is String ? message : 'Could not delete task.',
          ),
        );
      }
      return result;
    } catch (_) {
      return Error(GenericError());
    }
  }
}
