import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/project_item.dart';
import '../../services/catalog_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class ProjectFeedCard extends StatelessWidget {
  const ProjectFeedCard({super.key, required this.project});

  final ProjectItem project;

  Color get _statusColor => switch (project.status) {
        ProjectStatus.planificacion => Colors.orange,
        ProjectStatus.enCurso => AppColors.trustButton,
        ProjectStatus.completado => Colors.green,
        ProjectStatus.pausado => Colors.blueGrey,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/projects'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: _statusColor.withValues(alpha: 0.18),
                child: Icon(Icons.handyman_outlined, color: _statusColor),
              ),
              title: Text(project.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                project.partnerName.isEmpty ? 'Proyecto de intercambio' : 'Con ${project.partnerName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Chip(
                label: Text(
                  project.statusLabel,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
                backgroundColor: _statusColor,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ),
            Container(
              height: 168,
              color: _statusColor.withValues(alpha: 0.12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_horiz, size: 42, color: _statusColor),
                  const SizedBox(height: 8),
                  Text('Proyecto en el feed', style: AppTypography.caption),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                project.description.isEmpty
                    ? 'Intercambio de favores en seguimiento.'
                    : project.description,
                style: AppTypography.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => context.read<CatalogService>().toggleFollowProject(project.id),
                  icon: Icon(project.followed || context.watch<CatalogService>().isFollowingProject(project.id)
                      ? Icons.bookmark
                      : Icons.bookmark_border),
                  label: Text(
                    project.followed || context.watch<CatalogService>().isFollowingProject(project.id)
                        ? 'Siguiendo proyecto'
                        : 'Seguir proyecto',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
