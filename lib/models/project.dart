class ProjectMilestone {
  final String id;
  final String projectId;
  final String title;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final String status; // pending, in_progress, completed
  final DateTime? dueDate;
  final int order;
  final DateTime createdAt;

  ProjectMilestone({
    required this.id,
    required this.projectId,
    required this.title,
    this.description,
    required this.targetAmount,
    required this.currentAmount,
    required this.status,
    this.dueDate,
    required this.order,
    required this.createdAt,
  });

  factory ProjectMilestone.fromMap(Map<String, dynamic> map) => ProjectMilestone(
    id: map['id']?.toString() ?? '',
    projectId: map['project']?.toString() ?? '',
    title: map['title']?.toString() ?? '',
    description: map['description']?.toString(),
    targetAmount: double.tryParse(map['target_amount']?.toString() ?? '0') ?? 0.0,
    currentAmount: double.tryParse(map['current_amount']?.toString() ?? '0') ?? 0.0,
    status: map['status']?.toString() ?? 'pending',
    dueDate: map['due_date'] != null ? DateTime.tryParse(map['due_date'].toString()) : null,
    order: int.tryParse(map['order']?.toString() ?? '0') ?? 0,
    createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'project': projectId,
    'title': title,
    'description': description,
    'target_amount': targetAmount,
    'current_amount': currentAmount,
    'status': status,
    'due_date': dueDate?.toIso8601String().split('T').first,
    'order': order,
    'created_at': createdAt.toIso8601String(),
  };

  double get percentage => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0;
  bool get isCompleted => status == 'completed';
  double get remaining => (targetAmount - currentAmount).clamp(0, double.infinity);

  String get statusLabel {
    switch (status) {
      case 'pending': return 'En attente';
      case 'in_progress': return 'En cours';
      case 'completed': return 'Terminé';
      default: return status;
    }
  }
}

class ProjectModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final String status; // planning, in_progress, completed, paused
  final DateTime startDate;
  final DateTime? endDate;
  final String color;
  final String icon;
  final List<ProjectMilestone> milestones;
  final DateTime createdAt;

  ProjectModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.targetAmount,
    required this.currentAmount,
    required this.status,
    required this.startDate,
    this.endDate,
    this.color = '0xFF2563EB',
    this.icon = 'rocket_launch',
    this.milestones = const [],
    required this.createdAt,
  });

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    final milestonesList = map['milestones'] as List? ?? [];
    return ProjectModel(
      id: map['id']?.toString() ?? '',
      userId: map['user']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString(),
      targetAmount: double.tryParse(map['target_amount']?.toString() ?? '0') ?? 0.0,
      currentAmount: double.tryParse(map['current_amount']?.toString() ?? '0') ?? 0.0,
      status: map['status']?.toString() ?? 'planning',
      startDate: map['start_date'] != null ? DateTime.parse(map['start_date']) : DateTime.now(),
      endDate: map['end_date'] != null ? DateTime.tryParse(map['end_date'].toString()) : null,
      color: map['color']?.toString() ?? '0xFF2563EB',
      icon: map['icon']?.toString() ?? 'rocket_launch',
      milestones: milestonesList.map((m) => ProjectMilestone.fromMap(m)).toList(),
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'user': userId,
    'title': title,
    'description': description,
    'target_amount': targetAmount,
    'current_amount': currentAmount,
    'status': status,
    'start_date': startDate.toIso8601String().split('T').first,
    'end_date': endDate?.toIso8601String().split('T').first,
    'color': color,
    'icon': icon,
    'created_at': createdAt.toIso8601String(),
  };

  double get percentage => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0;
  bool get isCompleted => status == 'completed' || currentAmount >= targetAmount;
  double get remaining => (targetAmount - currentAmount).clamp(0, double.infinity);
  int get milestoneCount => milestones.length;
  int get completedMilestones => milestones.where((m) => m.isCompleted).length;

  String get statusLabel {
    switch (status) {
      case 'planning': return 'Planification';
      case 'in_progress': return 'En cours';
      case 'completed': return 'Terminé';
      case 'paused': return 'En pause';
      default: return status;
    }
  }

  /// Days remaining until end_date
  int? get daysRemaining {
    if (endDate == null) return null;
    return endDate!.difference(DateTime.now()).inDays;
  }
}
