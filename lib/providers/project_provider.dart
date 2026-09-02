import 'package:flutter/material.dart';
import '../models/project.dart';
import '../repositories/project_repository.dart';

class ProjectProvider extends ChangeNotifier {
  final ProjectRepository _repo = ProjectRepository();

  List<ProjectModel> _projects = [];
  bool _isLoading = false;
  String? _error;

  List<ProjectModel> get projects => _projects;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ProjectModel> get activeProjects =>
      _projects.where((p) => p.status == 'in_progress').toList();
  List<ProjectModel> get completedProjects =>
      _projects.where((p) => p.isCompleted).toList();
  List<ProjectModel> get planningProjects =>
      _projects.where((p) => p.status == 'planning').toList();
  List<ProjectModel> get pausedProjects =>
      _projects.where((p) => p.status == 'paused').toList();

  double get totalBudgetAllocated =>
      _projects.fold(0, (s, p) => s + p.targetAmount);
  double get totalContributed =>
      _projects.fold(0, (s, p) => s + p.currentAmount);
  double get overallProgress =>
      totalBudgetAllocated > 0 ? totalContributed / totalBudgetAllocated : 0;

  Future<void> loadProjects(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _projects = await _repo.getProjects(userId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProject({
    required String userId,
    required String title,
    String? description,
    required double targetAmount,
    required DateTime startDate,
    DateTime? endDate,
    String color = '0xFF2563EB',
    String icon = 'rocket_launch',
  }) async {
    await _repo.createProject(
      title: title,
      description: description,
      targetAmount: targetAmount,
      startDate: startDate,
      endDate: endDate,
      color: color,
      icon: icon,
    );
    await loadProjects(userId);
  }

  Future<void> updateProject(ProjectModel project, String userId) async {
    await _repo.updateProject(project);
    await loadProjects(userId);
  }

  Future<void> deleteProject(String id, String userId) async {
    await _repo.deleteProject(id);
    await loadProjects(userId);
  }

  Future<void> contribute(String projectId, double amount, String userId) async {
    await _repo.contribute(projectId, amount);
    await loadProjects(userId);
  }

  Future<void> updateProjectStatus(String projectId, String status, String userId) async {
    await _repo.updateProjectStatus(projectId, status);
    await loadProjects(userId);
  }

  // ── Milestones ──

  Future<void> addMilestone({
    required String userId,
    required String projectId,
    required String title,
    String? description,
    double targetAmount = 0,
    DateTime? dueDate,
    int order = 0,
  }) async {
    await _repo.addMilestone(
      projectId: projectId,
      title: title,
      description: description,
      targetAmount: targetAmount,
      dueDate: dueDate,
      order: order,
    );
    await loadProjects(userId);
  }

  Future<void> updateMilestone(ProjectMilestone milestone, String userId) async {
    await _repo.updateMilestone(milestone);
    await loadProjects(userId);
  }

  Future<void> updateMilestoneStatus(String milestoneId, String status, String userId) async {
    await _repo.updateMilestoneStatus(milestoneId, status);
    await loadProjects(userId);
  }

  Future<void> deleteMilestone(String id, String userId) async {
    await _repo.deleteMilestone(id);
    await loadProjects(userId);
  }
}
