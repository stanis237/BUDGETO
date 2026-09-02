import '../core/api/api_client.dart';
import '../models/project.dart';
import 'package:intl/intl.dart';

class ProjectRepository {
  final ApiClient _api = ApiClient();

  Future<List<ProjectModel>> getProjects(String userId) async {
    try {
      final response = await _api.dio.get('/projects/');
      final data = response.data is Map ? response.data['results'] as List : response.data as List;
      return data.map((e) => ProjectModel.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<ProjectModel> getProject(String id) async {
    final response = await _api.dio.get('/projects/$id/');
    return ProjectModel.fromMap(response.data);
  }

  Future<ProjectModel> createProject({
    required String title,
    String? description,
    required double targetAmount,
    required DateTime startDate,
    DateTime? endDate,
    String color = '0xFF2563EB',
    String icon = 'rocket_launch',
  }) async {
    final response = await _api.dio.post('/projects/', data: {
      'title': title,
      'description': description,
      'target_amount': targetAmount,
      'start_date': DateFormat('yyyy-MM-dd').format(startDate),
      'end_date': endDate != null ? DateFormat('yyyy-MM-dd').format(endDate) : null,
      'color': color,
      'icon': icon,
    });
    return ProjectModel.fromMap(response.data);
  }

  Future<void> updateProject(ProjectModel project) async {
    await _api.dio.patch('/projects/${project.id}/', data: {
      'title': project.title,
      'description': project.description,
      'target_amount': project.targetAmount,
      'status': project.status,
      'start_date': DateFormat('yyyy-MM-dd').format(project.startDate),
      'end_date': project.endDate != null ? DateFormat('yyyy-MM-dd').format(project.endDate!) : null,
      'color': project.color,
      'icon': project.icon,
    });
  }

  Future<void> deleteProject(String id) async {
    await _api.dio.delete('/projects/$id/');
  }

  Future<ProjectModel> contribute(String projectId, double amount) async {
    final response = await _api.dio.post('/projects/$projectId/contribute/', data: {
      'amount': amount,
    });
    return ProjectModel.fromMap(response.data);
  }

  Future<void> updateProjectStatus(String projectId, String status) async {
    await _api.dio.post('/projects/$projectId/update-status/', data: {
      'status': status,
    });
  }

  // ── Milestones ──

  Future<ProjectMilestone> addMilestone({
    required String projectId,
    required String title,
    String? description,
    double targetAmount = 0,
    DateTime? dueDate,
    int order = 0,
  }) async {
    final response = await _api.dio.post('/project-milestones/', data: {
      'project': projectId,
      'title': title,
      'description': description,
      'target_amount': targetAmount,
      'due_date': dueDate != null ? DateFormat('yyyy-MM-dd').format(dueDate) : null,
      'order': order,
    });
    return ProjectMilestone.fromMap(response.data);
  }

  Future<void> updateMilestone(ProjectMilestone milestone) async {
    await _api.dio.patch('/project-milestones/${milestone.id}/', data: {
      'title': milestone.title,
      'description': milestone.description,
      'target_amount': milestone.targetAmount,
      'current_amount': milestone.currentAmount,
      'status': milestone.status,
      'due_date': milestone.dueDate != null ? DateFormat('yyyy-MM-dd').format(milestone.dueDate!) : null,
      'order': milestone.order,
    });
  }

  Future<void> updateMilestoneStatus(String milestoneId, String status) async {
    await _api.dio.post('/project-milestones/$milestoneId/update-status/', data: {
      'status': status,
    });
  }

  Future<void> deleteMilestone(String id) async {
    await _api.dio.delete('/project-milestones/$id/');
  }
}
