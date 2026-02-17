import '../services/task_service.dart';
import '../models/task_model.dart';

class TaskRepository {
  final TaskService _service;

  TaskRepository(this._service);

  Future<List<TaskModel>> getTasks() async {
    return _service.getTasks();
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
