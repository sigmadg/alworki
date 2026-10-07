import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/project_item.dart';
import '../../models/service_order.dart';
import '../../services/catalog_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/secondary_screen_scaffold.dart';

enum _ProjectFilter { todos, enCurso, completados }

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  _ProjectFilter _filter = _ProjectFilter.todos;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderService>().loadOrders();
      context.read<CatalogService>().loadProjects();
    });
  }

  List<ProjectItem> _filteredProjects(List<ProjectItem> projects) {
    return switch (_filter) {
      _ProjectFilter.todos => projects,
      _ProjectFilter.enCurso => projects
          .where((p) => p.status == ProjectStatus.enCurso || p.status == ProjectStatus.planificacion)
          .toList(),
      _ProjectFilter.completados => projects.where((p) => p.status == ProjectStatus.completado).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final projects = context.watch<CatalogService>().projects;
    final orders = context.watch<OrderService>().orders;
    final filteredProjects = _filteredProjects(projects);
    final isEmpty = projects.isEmpty && orders.isEmpty;

    return SecondaryScreenScaffold(
      title: 'Proyectos y órdenes',
      subtitle: 'Seguimiento de trabajos en curso y realizados',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-project'),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo proyecto'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isEmpty)
            _EmptyState()
          else ...[
            if (orders.isNotEmpty) ...[
              Text('Mis órdenes', style: AppTypography.titleSmall),
              const SizedBox(height: 4),
              Text(
                'Servicios contratados y su estado de entrega',
                style: AppTypography.caption,
              ),
              const SizedBox(height: 12),
              ...orders.map((o) => _OrderCard(order: o)),
              const SizedBox(height: 24),
            ],
            Text('Proyectos de intercambio', style: AppTypography.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Toca un proyecto para ver la guía de entrega',
              style: AppTypography.caption,
            ),
            const SizedBox(height: 12),
            _FilterChips(
              selected: _filter,
              onSelected: (f) => setState(() => _filter = f),
            ),
            const SizedBox(height: 12),
            if (filteredProjects.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No hay proyectos en esta categoría.',
                  style: AppTypography.sectionSubtitle,
                ),
              )
            else
              ...filteredProjects.map((p) => _ProjectCard(project: p)),
          ],
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelected});

  final _ProjectFilter selected;
  final ValueChanged<_ProjectFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final entry in [
          (_ProjectFilter.todos, 'Todos'),
          (_ProjectFilter.enCurso, 'En curso'),
          (_ProjectFilter.completados, 'Completados'),
        ])
          FilterChip(
            label: Text(entry.$2),
            selected: selected == entry.$1,
            onSelected: (_) => onSelected(entry.$1),
            selectedColor: AppColors.navBar.withValues(alpha: 0.2),
            checkmarkColor: AppColors.navBar,
            labelStyle: TextStyle(
              color: selected == entry.$1 ? AppColors.navBar : AppColors.textSecondary,
              fontWeight: selected == entry.$1 ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.folder_open_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('Sin actividad aún', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Aquí verás tus órdenes de servicio y proyectos de intercambio cuando contrates o intercambies favores.',
            style: AppTypography.sectionSubtitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => context.go('/categories'),
            icon: const Icon(Icons.search),
            label: const Text('Buscar servicios'),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final ServiceOrder order;

  static const _steps = ['Contratado', 'En trabajo', 'Entregado'];

  int _activeStep(String status) => switch (status) {
        'entregado' => 2,
        'en_curso' => 1,
        _ => 0,
      };

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (order.status) {
      'entregado' => AppColors.proximity,
      'en_curso' => Colors.orange,
      _ => AppColors.localBadge,
    };
    final active = _activeStep(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/order/${order.trackingNumber}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.receipt_long, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(order.title, style: AppTypography.titleSmall.copyWith(fontSize: 15)),
                  ),
                  Chip(
                    label: Text(_statusLabel(order.status), style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('Orden #${order.trackingNumber}', style: AppTypography.caption),
              const SizedBox(height: 4),
              Text('Con: ${order.providerName}', style: AppTypography.bodySmall),
              const SizedBox(height: 6),
              Text(
                'AL\$ ${order.totalAl}',
                style: AppTypography.titleSmall.copyWith(color: AppColors.navBar),
              ),
              const SizedBox(height: 14),
              _ProgressStepper(
                steps: _steps,
                activeIndex: active,
                accentColor: statusColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) => switch (status) {
        'entregado' => 'Entregado',
        'en_curso' => 'En curso',
        _ => 'Pendiente',
      };
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project});
  final ProjectItem project;

  static const _steps = ProjectItem.deliverySteps;

  int _activeIndex(ProjectItem project) => project.deliveryStepIndex;

  bool _isPaused(ProjectStatus status) => status == ProjectStatus.pausado;

  @override
  Widget build(BuildContext context) {
    final color = switch (project.status) {
      ProjectStatus.planificacion => Colors.blue,
      ProjectStatus.enCurso => Colors.orange,
      ProjectStatus.completado => AppColors.proximity,
      ProjectStatus.pausado => Colors.grey,
    };
    final active = _activeIndex(project);
    final done = project.deliveryStatus == DeliveryStatus.confirmado ||
        project.status == ProjectStatus.completado;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/project/${project.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      done ? Icons.check_circle_outline : Icons.folder_open,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(project.name, style: AppTypography.titleSmall.copyWith(fontSize: 15))),
                  Chip(label: Text(project.deliveryLabel), visualDensity: VisualDensity.compact),
                ],
              ),
              const SizedBox(height: 10),
              Text(project.description, style: AppTypography.bodySmall),
              const SizedBox(height: 6),
              if (project.trackingNumber != null && project.trackingNumber!.isNotEmpty)
                Text(project.trackingNumber!, style: AppTypography.caption),
              Text('Con: ${project.partnerName}', style: AppTypography.caption),
              if (_isPaused(project.status)) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.pause_circle_outline, size: 16, color: Colors.grey.shade400),
                    const SizedBox(width: 6),
                    Text('Proyecto en pausa', style: AppTypography.caption.copyWith(color: Colors.grey.shade400)),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              _ProgressStepper(
                steps: _steps,
                activeIndex: active,
                accentColor: color,
                completed: done,
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _ProgressStepper extends StatelessWidget {
  const _ProgressStepper({
    required this.steps,
    required this.activeIndex,
    required this.accentColor,
    this.completed = false,
  });

  final List<String> steps;
  final int activeIndex;
  final Color accentColor;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (i > 0)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: (i <= activeIndex || completed)
                              ? accentColor.withValues(alpha: 0.6)
                              : AppColors.border,
                        ),
                      ),
                    _StepDot(
                      done: completed || i < activeIndex,
                      active: i == activeIndex && !completed,
                      color: accentColor,
                    ),
                    if (i < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: (i < activeIndex || completed)
                              ? accentColor.withValues(alpha: 0.6)
                              : AppColors.border,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  steps[i],
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    fontSize: 10,
                    fontWeight: i == activeIndex ? FontWeight.w600 : FontWeight.normal,
                    color: i <= activeIndex ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.done, required this.active, required this.color});

  final bool done;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (done) {
      return Icon(Icons.check_circle, size: 18, color: color);
    }
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? color : Colors.transparent,
        border: Border.all(color: active ? color : AppColors.border, width: 2),
      ),
    );
  }
}
