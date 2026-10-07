import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/project_item.dart';
import '../../services/catalog_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/alworki_image.dart';

class ProjectTrackingScreen extends StatefulWidget {
  const ProjectTrackingScreen({super.key, required this.projectId});

  final int projectId;

  @override
  State<ProjectTrackingScreen> createState() => _ProjectTrackingScreenState();
}

class _ProjectTrackingScreenState extends State<ProjectTrackingScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogService>().fetchProject(widget.projectId);
    });
  }

  ProjectItem? _project(CatalogService catalog) {
    try {
      return catalog.projects.firstWhere((p) => p.id == widget.projectId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _advance(String status) async {
    setState(() => _busy = true);
    try {
      await context.read<CatalogService>().updateProjectDelivery(widget.projectId, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(status == 'confirmado' ? 'Entrega confirmada' : 'Estado actualizado')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deliver() async {
    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar entrega'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Qué se entregó',
            hintText: 'Closet instalado y limpio',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Entregar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (message == null || message.isEmpty || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<CatalogService>().submitProjectDelivery(
            projectId: widget.projectId,
            message: message,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrega registrada. El otro usuario puede confirmarla.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogService>();
    final project = _project(catalog);
    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Seguimiento')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final color = switch (project.deliveryStatus) {
      DeliveryStatus.solicitado => Colors.blue,
      DeliveryStatus.asignado => Colors.indigo,
      DeliveryStatus.enTrabajo => Colors.orange,
      DeliveryStatus.entregado => Colors.teal,
      DeliveryStatus.confirmado => AppColors.proximity,
    };

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: Text(project.trackingNumber ?? 'Proyecto')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(project.name, style: AppTypography.titleMedium),
          const SizedBox(height: 6),
          Text(project.description, style: AppTypography.bodySmall),
          if (project.partnerName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Con: ${project.partnerName}', style: AppTypography.caption),
          ],
          const SizedBox(height: 16),
          Chip(
            label: Text(project.deliveryLabel),
            backgroundColor: color.withValues(alpha: 0.18),
            labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < ProjectItem.deliverySteps.length; i++) ...[
                Expanded(
                  child: Column(
                    children: [
                      Icon(
                        i < project.deliveryStepIndex
                            ? Icons.check_circle
                            : i == project.deliveryStepIndex
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                        color: i <= project.deliveryStepIndex ? color : AppColors.border,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ProjectItem.deliverySteps[i],
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (project.requirements.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Requisitos del servicio', style: AppTypography.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: project.requirements.map((r) => Chip(label: Text(r))).toList(),
            ),
          ],
          if (project.delivery != null) ...[
            const SizedBox(height: 20),
            Text('Última entrega', style: AppTypography.titleSmall),
            const SizedBox(height: 8),
            Text(project.delivery!.message, style: AppTypography.bodySmall),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AlworkiImage(imageKey: project.delivery!.image, height: 140),
            ),
          ],
          if (project.events.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Historial', style: AppTypography.titleSmall),
            const SizedBox(height: 8),
            for (final event in project.events.reversed)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.flag_outlined, size: 20),
                title: Text(event.title),
                subtitle: Text(event.timestamp, style: AppTypography.caption),
              ),
          ],
          const SizedBox(height: 16),
          if (project.canStart)
            FilledButton.icon(
              onPressed: _busy ? null : () => _advance('en_trabajo'),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar trabajo'),
            ),
          if (project.canDeliver) ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _busy ? null : _deliver,
              icon: const Icon(Icons.local_shipping_outlined),
              label: const Text('Registrar entrega'),
            ),
          ],
          if (project.canConfirm) ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _busy ? null : () => _advance('confirmado'),
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Confirmar entrega'),
            ),
          ],
        ],
      ),
    );
  }
}
