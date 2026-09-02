import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/project_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/project.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});
  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€', decimalDigits: 0);
  String get _userId => context.read<AuthProvider>().currentUser?.id ?? 'guest';

  ProjectModel? _findProject() {
    final provider = context.watch<ProjectProvider>();
    try {
      return provider.projects.firstWhere((p) => p.id == widget.projectId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = _findProject();
    if (project == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('Projet')),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    final cardColor = Color(int.parse(project.color));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(project, cardColor),
          SliverToBoxAdapter(child: _buildHeroSection(project, cardColor)),
          SliverToBoxAdapter(child: _buildInfoCards(project, cardColor)),
          SliverToBoxAdapter(child: _buildMilestonesHeader(project)),
          SliverToBoxAdapter(child: _buildMilestoneTimeline(project, cardColor)),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Contribute button
          FloatingActionButton.extended(
            heroTag: 'contribute_project',
            onPressed: () => _showContributeDialog(project),
            backgroundColor: AppTheme.accent,
            foregroundColor: Colors.white,
            elevation: 0,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Contribuer', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          // Add milestone button
          FloatingActionButton(
            heroTag: 'add_milestone',
            onPressed: () => _showAddMilestoneDialog(project),
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            mini: true,
            child: const Icon(Icons.flag_rounded, size: 20),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(ProjectModel project, Color color) {
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: AppTheme.textPrimary,
      title: Text(project.title, style: const TextStyle(fontWeight: FontWeight.w700)),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (value) => _handleMenuAction(value, project),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'planning', child: Text('⏳ Planification')),
            const PopupMenuItem(value: 'in_progress', child: Text('▶️ En cours')),
            const PopupMenuItem(value: 'paused', child: Text('⏸️ En pause')),
            const PopupMenuItem(value: 'completed', child: Text('✅ Terminé')),
            const PopupMenuItem(value: 'delete', child: Text('🗑️ Supprimer', style: TextStyle(color: AppTheme.error))),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroSection(ProjectModel project, Color color) {
    final progressPercent = (project.percentage * 100).toInt();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Large circular progress
              SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CircularProgressIndicator(
                        value: project.percentage,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$progressPercent%',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        const Text('complet', style: TextStyle(fontSize: 10, color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Amount details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Collecté', style: TextStyle(fontSize: 12, color: Colors.white70)),
                    Text(
                      _currencyFormat.format(project.currentAmount),
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'sur ${_currencyFormat.format(project.targetAmount)}',
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    // Remaining
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Reste: ${_currencyFormat.format(project.remaining)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards(ProjectModel project, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          _infoCard(
            Icons.calendar_today_rounded,
            'Début',
            DateFormat('dd/MM/yyyy').format(project.startDate),
            color,
          ),
          const SizedBox(width: 10),
          _infoCard(
            Icons.event_rounded,
            'Fin',
            project.endDate != null ? DateFormat('dd/MM/yyyy').format(project.endDate!) : 'Non défini',
            AppTheme.secondary,
          ),
          const SizedBox(width: 10),
          _infoCard(
            Icons.flag_rounded,
            'Étapes',
            '${project.completedMilestones}/${project.milestoneCount}',
            AppTheme.accent,
          ),
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            Text(label, style: TextStyle(fontSize: 10, color: AppTheme.textHint)),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestonesHeader(ProjectModel project) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          const Icon(Icons.timeline_rounded, color: AppTheme.primary, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Étapes du projet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
          const Spacer(),
          if (project.milestones.isNotEmpty)
            Text(
              '${project.completedMilestones} terminées',
              style: TextStyle(fontSize: 12, color: AppTheme.textHint),
            ),
        ],
      ),
    );
  }

  Widget _buildMilestoneTimeline(ProjectModel project, Color projectColor) {
    if (project.milestones.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          children: [
            Icon(Icons.flag_outlined, size: 48, color: AppTheme.textHint.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text('Aucune étape', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textHint)),
            const SizedBox(height: 4),
            Text('Ajoutez des étapes pour suivre votre progression', style: TextStyle(fontSize: 12, color: AppTheme.textHint.withOpacity(0.7))),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(project.milestones.length, (index) {
          final milestone = project.milestones[index];
          final isLast = index == project.milestones.length - 1;
          return _buildMilestoneItem(milestone, projectColor, isLast);
        }),
      ),
    );
  }

  Widget _buildMilestoneItem(ProjectMilestone milestone, Color projectColor, bool isLast) {
    Color statusColor;
    IconData statusIcon;
    switch (milestone.status) {
      case 'completed':
        statusColor = AppTheme.success;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'in_progress':
        statusColor = AppTheme.primary;
        statusIcon = Icons.play_circle_rounded;
        break;
      default:
        statusColor = AppTheme.textHint;
        statusIcon = Icons.circle_outlined;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline connector
        SizedBox(
          width: 32,
          child: Column(
            children: [
              Icon(statusIcon, color: statusColor, size: 24),
              if (!isLast)
                Container(
                  width: 2,
                  height: 60,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: milestone.isCompleted ? AppTheme.success.withOpacity(0.3) : AppTheme.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Milestone card
        Expanded(
          child: GestureDetector(
            onTap: () => _showMilestoneOptions(milestone),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: milestone.isCompleted ? AppTheme.success.withOpacity(0.3) : AppTheme.divider,
                ),
                boxShadow: [
                  if (milestone.status == 'in_progress')
                    BoxShadow(color: AppTheme.primary.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          milestone.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: milestone.isCompleted ? AppTheme.textHint : AppTheme.textPrimary,
                            decoration: milestone.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          milestone.statusLabel,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
                        ),
                      ),
                    ],
                  ),
                  if (milestone.description != null && milestone.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      milestone.description!,
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (milestone.targetAmount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          _currencyFormat.format(milestone.currentAmount),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: projectColor),
                        ),
                        Text(
                          ' / ${_currencyFormat.format(milestone.targetAmount)}',
                          style: TextStyle(fontSize: 12, color: AppTheme.textHint),
                        ),
                        const Spacer(),
                        if (milestone.dueDate != null)
                          Text(
                            DateFormat('dd/MM', 'fr_FR').format(milestone.dueDate!),
                            style: TextStyle(fontSize: 11, color: AppTheme.textHint),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: milestone.percentage,
                        backgroundColor: projectColor.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation(projectColor),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Actions ──

  void _handleMenuAction(String action, ProjectModel project) {
    if (action == 'delete') {
      _confirmDelete(project);
    } else {
      context.read<ProjectProvider>().updateProjectStatus(project.id, action, _userId);
    }
  }

  void _confirmDelete(ProjectModel project) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer le projet ?'),
        content: Text('Le projet "${project.title}" et toutes ses étapes seront supprimés.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ProjectProvider>().deleteProject(project.id, _userId);
              Navigator.pop(context);
            },
            child: const Text('Supprimer', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  void _showContributeDialog(ProjectModel project) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Contribuer au projet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reste: ${_currencyFormat.format(project.remaining)}', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Montant',
                prefixText: '€ ',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                context.read<ProjectProvider>().contribute(project.id, amount, _userId);
                Navigator.pop(context);
              }
            },
            child: const Text('Contribuer'),
          ),
        ],
      ),
    );
  }

  void _showAddMilestoneDialog(ProjectModel project) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final amountController = TextEditingController();
    DateTime? dueDate;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Nouvelle étape'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Titre de l\'étape'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description (optionnel)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Budget cible (optionnel)', prefixText: '€ '),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_rounded, color: AppTheme.primary),
                  title: Text(
                    dueDate != null ? DateFormat('dd/MM/yyyy').format(dueDate!) : 'Date d\'échéance',
                    style: TextStyle(fontSize: 14, color: dueDate != null ? AppTheme.textPrimary : AppTheme.textHint),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setDialogState(() => dueDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) return;
                context.read<ProjectProvider>().addMilestone(
                  userId: _userId,
                  projectId: project.id,
                  title: titleController.text.trim(),
                  description: descController.text.trim().isNotEmpty ? descController.text.trim() : null,
                  targetAmount: double.tryParse(amountController.text) ?? 0,
                  dueDate: dueDate,
                  order: project.milestones.length,
                );
                Navigator.pop(ctx);
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMilestoneOptions(ProjectMilestone milestone) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(milestone.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            ListTile(
              leading: const Icon(Icons.circle_outlined, color: AppTheme.textHint),
              title: const Text('En attente'),
              onTap: () {
                Navigator.pop(context);
                context.read<ProjectProvider>().updateMilestoneStatus(milestone.id, 'pending', _userId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.play_circle_rounded, color: AppTheme.primary),
              title: const Text('En cours'),
              onTap: () {
                Navigator.pop(context);
                context.read<ProjectProvider>().updateMilestoneStatus(milestone.id, 'in_progress', _userId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_rounded, color: AppTheme.success),
              title: const Text('Terminé'),
              onTap: () {
                Navigator.pop(context);
                context.read<ProjectProvider>().updateMilestoneStatus(milestone.id, 'completed', _userId);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: AppTheme.error),
              title: const Text('Supprimer', style: TextStyle(color: AppTheme.error)),
              onTap: () {
                Navigator.pop(context);
                context.read<ProjectProvider>().deleteMilestone(milestone.id, _userId);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
