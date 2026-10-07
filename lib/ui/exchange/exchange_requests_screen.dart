import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/exchange_request.dart';
import '../../services/catalog_service.dart';
import '../../services/exchange_repository.dart';
import '../../state/auth_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_theme.dart';
import '../widgets/app_modal.dart';
import '../widgets/secondary_screen_scaffold.dart';

class ExchangeRequestsScreen extends StatefulWidget {
  const ExchangeRequestsScreen({super.key});

  @override
  State<ExchangeRequestsScreen> createState() => _ExchangeRequestsScreenState();
}

class _ExchangeRequestsScreenState extends State<ExchangeRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExchangeRepository>().load();
    });
  }

  Future<void> _createDialog() async {
    final title = TextEditingController();
    final desc = TextEditingController();
    final ok = await showAppDialog<bool>(
      context: context,
      builder: (dlg) => AlertDialog(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: AppTheme.appDialogShape(),
        title: Text('Nueva solicitud de intercambio', style: AppTypography.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(
                labelText: '¿Qué necesitas?',
                hintText: 'Ej: Ayuda con mudanza',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: desc,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Explica qué ofreces a cambio',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dlg, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dlg, true), child: const Text('Crear')),
        ],
      ),
    );
    if (ok == true && title.text.trim().isNotEmpty && mounted) {
      await context.read<ExchangeRepository>().create(
            title: title.text.trim(),
            description: desc.text.trim(),
          );
    }
    title.dispose();
    desc.dispose();
  }

  Color _statusColor(ExchangeStatus s) => switch (s) {
        ExchangeStatus.pendiente => Colors.orange,
        ExchangeStatus.aceptada => Colors.green,
        ExchangeStatus.rechazada => Colors.red,
        ExchangeStatus.completada => Colors.blue,
      };

  Future<void> _applyStatus(ExchangeRequest r, ExchangeStatus status) async {
    final updated = await context.read<ExchangeRepository>().updateStatus(r.id, status);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final repo = context.read<ExchangeRepository>();
    final catalog = context.read<CatalogService>();
    if (updated == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(repo.error ?? 'No se pudo actualizar')),
      );
      return;
    }
    if (status == ExchangeStatus.aceptada) {
      await catalog.loadProjects();
    }
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text('Intercambio ${updated.statusLabel.toLowerCase()}')),
    );
  }

  void _showDetail(ExchangeRequest r) {
    final me = context.read<AuthController>().user?.id;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(r.title, style: AppTypography.titleMedium),
              const SizedBox(height: 8),
              Chip(
                label: Text(r.statusLabel, style: const TextStyle(color: Colors.white)),
                backgroundColor: _statusColor(r.status),
              ),
              if (r.isIncomingFor(me))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Te la enviaron para intercambiar un favor', style: AppTypography.caption),
                ),
              if (r.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(r.description, style: AppTypography.bodySmall),
              ],
              if (r.offerTitle != null && r.offerTitle!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Oferta: ${r.offerTitle}', style: AppTypography.caption),
              ],
              const SizedBox(height: 16),
              if (r.canAccept(me))
                FilledButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _applyStatus(r, ExchangeStatus.aceptada);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Aceptar intercambio'),
                ),
              if (r.canReject(me)) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _applyStatus(r, ExchangeStatus.rechazada);
                  },
                  icon: const Icon(Icons.close),
                  label: Text(r.userId == me ? 'Cancelar solicitud' : 'Rechazar'),
                ),
              ],
              if (r.canComplete(me)) ...[
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _applyStatus(r, ExchangeStatus.completada);
                  },
                  icon: const Icon(Icons.task_alt),
                  label: const Text('Marcar como completado'),
                ),
              ],
              const SizedBox(height: 8),
              if (r.status == ExchangeStatus.aceptada)
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/messages');
                  },
                  child: const Text('Ir a mensajes'),
                )
              else
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cerrar'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ExchangeRepository>();
    final items = repo.items;

    return SecondaryScreenScaffold(
      title: 'Intercambios',
      subtitle: 'Solicitudes de favores entre usuarios',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nueva solicitud'),
      ),
      body: Column(
        children: [
          if (repo.error != null)
            MaterialBanner(
              content: Text(repo.error!),
              actions: [
                TextButton(onPressed: repo.load, child: const Text('Reintentar')),
              ],
            ),
          Expanded(
            child: repo.isLoading && items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? _EmptyState(onCreate: _createDialog)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final r = items[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _showDetail(r),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.swap_horiz, color: AppColors.trustButton, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(r.title, style: AppTypography.titleSmall),
                                        ),
                                        Chip(
                                          label: Text(
                                            r.statusLabel,
                                            style: const TextStyle(color: Colors.white, fontSize: 11),
                                          ),
                                          backgroundColor: _statusColor(r.status),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                        ),
                                      ],
                                    ),
                                    if (r.description.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(r.description, style: AppTypography.bodySmall),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_horiz, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('Sin solicitudes aún', style: AppTypography.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Propón intercambiar favores con otros usuarios. También puedes crear una desde el feed de la comunidad.',
              style: AppTypography.sectionSubtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Crear solicitud'),
            ),
          ],
        ),
      ),
    );
  }
}
