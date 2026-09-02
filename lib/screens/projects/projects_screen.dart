import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/project_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/project.dart';
import 'project_detail_screen.dart';
import 'add_project_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});
  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final userId = context.read<AuthProvider>().currentUser?.id ?? 'guest';
    context.read<ProjectProvider>().loadProjects(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStatsRow(),
            _buildTabBar(),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.floatingShadow,
        ),
        child: FloatingActionButton.extended(
          heroTag: 'add_project',
          onPressed: () => _openAddProject(),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nouveau projet', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mes Projets',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                ),
                Text(
                  'Planifiez et suivez vos objectifs',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Consumer<ProjectProvider>(
      builder: (context, provider, _) {
        final total = provider.projects.length;
        final active = provider.activeProjects.length;
        final completed = provider.completedProjects.length;
        final progress = (provider.overallProgress * 100).toInt();

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              _statCard('Total', '$total', Icons.folder_rounded, AppTheme.primary),
              const SizedBox(width: 10),
              _statCard('Actifs', '$active', Icons.play_arrow_rounded, AppTheme.accent),
              const SizedBox(width: 10),
              _statCard('Terminés', '$completed', Icons.check_circle_rounded, AppTheme.success),
              const SizedBox(width: 10),
              _statCard('Progrès', '$progress%', Icons.trending_up_rounded, AppTheme.secondary),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: TextStyle(fontSize: 9, color: AppTheme.textHint, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      decoration: BoxDecoration(
        color: AppTheme.divider.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Tous'),
          Tab(text: 'En cours'),
          Tab(text: 'Terminés'),
          Tab(text: 'En pause'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return Consumer<ProjectProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildProjectList(provider.projects),
            _buildProjectList(provider.activeProjects),
            _buildProjectList(provider.completedProjects),
            _buildProjectList(provider.pausedProjects),
          ],
        );
      },
    );
  }

  Widget _buildProjectList(List<ProjectModel> projects) {
    if (projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rocket_launch_outlined, size: 64, color: AppTheme.textHint.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text('Aucun projet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textHint)),
            const SizedBox(height: 8),
            Text('Créez votre premier projet !', style: TextStyle(fontSize: 13, color: AppTheme.textHint.withOpacity(0.7))),
            const SizedBox(height: 80),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: projects.length,
      itemBuilder: (context, index) => _buildProjectCard(projects[index]),
    );
  }

  Widget _buildProjectCard(ProjectModel project) {
    final cardColor = Color(int.parse(project.color));
    final progressPercent = (project.percentage * 100).toInt();

    return GestureDetector(
      onTap: () => _openProjectDetail(project),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.divider),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top colored strip
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cardColor, cardColor.withOpacity(0.5)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_getIconData(project.icon), color: cardColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                _statusBadge(project),
                                const SizedBox(width: 8),
                                if (project.daysRemaining != null)
                                  Text(
                                    '${project.daysRemaining}j restants',
                                    style: TextStyle(fontSize: 11, color: AppTheme.textHint),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Circular progress
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: project.percentage,
                              backgroundColor: cardColor.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation(cardColor),
                              strokeWidth: 4,
                              strokeCap: StrokeCap.round,
                            ),
                            Text(
                              '$progressPercent%',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: cardColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Amount row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Collecté', style: TextStyle(fontSize: 10, color: AppTheme.textHint)),
                          Text(
                            _currencyFormat.format(project.currentAmount),
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cardColor),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Objectif', style: TextStyle(fontSize: 10, color: AppTheme.textHint)),
                          Text(
                            _currencyFormat.format(project.targetAmount),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: project.percentage,
                      backgroundColor: cardColor.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation(cardColor),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Milestones info
                  Row(
                    children: [
                      Icon(Icons.flag_rounded, size: 14, color: AppTheme.textHint),
                      const SizedBox(width: 4),
                      Text(
                        '${project.completedMilestones}/${project.milestoneCount} étapes',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                      const Spacer(),
                      Icon(Icons.calendar_today_rounded, size: 12, color: AppTheme.textHint),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd MMM yyyy', 'fr_FR').format(project.startDate),
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(ProjectModel project) {
    Color color;
    switch (project.status) {
      case 'in_progress':
        color = AppTheme.accent;
        break;
      case 'completed':
        color = AppTheme.success;
        break;
      case 'paused':
        color = AppTheme.warning;
        break;
      default:
        color = AppTheme.secondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        project.statusLabel,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'rocket_launch': return Icons.rocket_launch_rounded;
      case 'home': return Icons.home_rounded;
      case 'school': return Icons.school_rounded;
      case 'directions_car': return Icons.directions_car_rounded;
      case 'flight': return Icons.flight_rounded;
      case 'business': return Icons.business_rounded;
      case 'shopping_bag': return Icons.shopping_bag_rounded;
      case 'devices': return Icons.devices_rounded;
      case 'favorite': return Icons.favorite_rounded;
      case 'savings': return Icons.savings_rounded;
      case 'build': return Icons.build_rounded;
      case 'celebration': return Icons.celebration_rounded;
      default: return Icons.rocket_launch_rounded;
    }
  }

  void _openAddProject() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddProjectScreen(),
    ).then((_) => _loadData());
  }

  void _openProjectDetail(ProjectModel project) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProjectDetailScreen(projectId: project.id)),
    ).then((_) => _loadData());
  }
}
