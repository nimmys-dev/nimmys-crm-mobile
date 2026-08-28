import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/features/duties/model/task_completed_model.dart';
import 'package:nimmys_crm/features/duties/model/task_details_model.dart';
import 'package:nimmys_crm/features/duties/model/task_type_model.dart';
import 'package:nimmys_crm/features/duties/model/tasks_list_model.dart';
import 'package:nimmys_crm/features/duties/service/tasks_service.dart';

class TasksRepository {
  TasksRepository(this._service);

  final TasksService _service;

  Future<Result<TaskListResponse>> getTasks({
    int page = 1,
    int perPage = 10,
    String? search,
  }) async {
    try {
      return await _service.getTasks(
        page: page,
        perPage: perPage,
        search: search,
      );
    } catch (e) {
      return Error<TaskListResponse>(ErrorWithMessage(message: e.toString()));
    }
  }

  Future<Result<TaskDetailsResponse>> getTaskDetails(int id) async {
    try {
      return await _service.getTaskDetails(id);
    } catch (e) {
      return Error<TaskDetailsResponse>(
        ErrorWithMessage(message: e.toString()),
      );
    }
  }

  Future<Result<TaskTypeModel>> getTaskTypes() async {
    try {
      return await _service.getTaskTypes();
    } catch (e) {
      return Error<TaskTypeModel>(ErrorWithMessage(message: e.toString()));
    }
  }

  Future<Result<dynamic>> createTask(Map<String, dynamic> payload) async {
    try {
      return await _service.createTask(payload);
    } catch (e) {
      return Error<dynamic>(ErrorWithMessage(message: e.toString()));
    }
  }

  Future<Result<TaskDetailsResponse>> updateTask(
    int id,
    Map<String, dynamic> payload,
  ) async {
    try {
      return await _service.updateTask(id, payload);
    } catch (e) {
      return Error<TaskDetailsResponse>(
        ErrorWithMessage(message: e.toString()),
      );
    }
  }

  Future<Result<TaskCompleteResponse>> completeTask(
    int id, {
    String? remarks,
  }) async {
    try {
      return await _service.completeTask(id, remarks: remarks);
    } catch (e) {
      return Error<TaskCompleteResponse>(
        ErrorWithMessage(message: e.toString()),
      );
    }
  }
}
