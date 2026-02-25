import '../services/task_service.dart';
import '../models/task_model.dart';

class TaskRepository {
  final TaskService _service;

  TaskRepository(this._service);

  Future<List<TaskModel>> getTasks({int page = 0, int pageSize = 20}) async {
    return _service.getTasks(page: page, pageSize: pageSize);
  }

  Future<TaskModel> addTask(TaskModel task) async {
    return _service.addTask(task);
  }

  Future<TaskModel> updateTask(TaskModel task) async {
    return _service.updateTask(task);
  }

  Future<void> deleteTask(String id) async {
    return _service.deleteTask(id);
  }
}
