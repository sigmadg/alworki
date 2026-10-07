import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/profile_actions_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../widgets/app_modal.dart';

/// Flujo modal «Reportar problema» (3 pasos, tema rojo).
Future<void> showReportProblemFlow(BuildContext context, {int? providerId}) {
  return showAppDialog<void>(
    context: context,
    builder: (ctx) => _ReportProblemDialog(providerId: providerId),
  );
}

/// Flujo modal «Comentarios / Reseña» (3 pasos, tema azul).
Future<void> showCommentFlow(BuildContext context, {int? providerId}) {
  return showAppDialog<void>(
    context: context,
    builder: (ctx) => _CommentDialog(providerId: providerId),
  );
}

class _ReportProblemDialog extends StatefulWidget {
  const _ReportProblemDialog({this.providerId});
  final int? providerId;

  @override
  State<_ReportProblemDialog> createState() => _ReportProblemDialogState();
}

class _ReportProblemDialogState extends State<_ReportProblemDialog> {
  int _step = 0;
  final _tracking = TextEditingController();
  String? _action;
  bool _saving = false;

  static const _actions = [
    'Cancelar servicio',
    'Problema de calidad',
    'No se presentó',
    'Cobro incorrecto',
    'Otro',
  ];

  @override
  void dispose() {
    _tracking.dispose();
    super.dispose();
  }

  void _close() => Navigator.pop(context);

  Future<void> _continue() async {
    if (_step == 0) {
      if (_tracking.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa el número de seguimiento')),
        );
        return;
      }
      setState(() => _step = 1);
    } else if (_step == 1) {
      if (_action == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona una acción')),
        );
        return;
      }
      setState(() => _saving = true);
      try {
        await context.read<ProfileActionsService>().createReport(
              trackingNumber: _tracking.text.trim(),
              action: _action!,
              providerId: widget.providerId,
            );
        if (mounted) setState(() => _step = 2);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    } else {
      _close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_step < 2) ...[
            const Text('😑', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'Reportar problema',
              style: AppTypography.titleMedium.copyWith(color: AppColors.reportRed),
            ),
            const SizedBox(height: 20),
            if (_step == 0) ...[
              Text(
                'Ingresa el número de seguimiento de tu servicio',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tracking,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Ej. AW-2024-001',
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.reportRed, width: 2),
                  ),
                ),
              ),
            ] else ...[
              Text(
                '¿Qué acción quieres tomar?',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(height: 1.4),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _action,
                dropdownColor: AppColors.surfaceElevated,
                style: AppTypography.bodyMedium,
                decoration: const InputDecoration(labelText: 'Seleccionar'),
                items: _actions.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                onChanged: (v) => setState(() => _action = v),
              ),
            ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _close,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.reportRed,
                        side: const BorderSide(color: AppColors.reportRed),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Text('Cerrar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _continue,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.reportRed,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: Text(_step == 1 ? 'Reportar' : 'Continuar'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.reportRed.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.work_outline, size: 36, color: AppColors.reportRed),
              ),
              const SizedBox(height: 16),
              Text(
                'Tu reporte ha sido creado.\nLe notificaremos cuando resolvamos el problema.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(height: 1.45),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _close,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.reportRed,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text('Aceptar'),
                ),
              ),
            ],
          ],
        ),
    );
  }
}

class _CommentDialog extends StatefulWidget {
  const _CommentDialog({this.providerId});
  final int? providerId;

  @override
  State<_CommentDialog> createState() => _CommentDialogState();
}

class _CommentDialogState extends State<_CommentDialog> {
  int _step = 0;
  final _tracking = TextEditingController();
  final _comment = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _tracking.dispose();
    _comment.dispose();
    super.dispose();
  }

  void _close() => Navigator.pop(context);

  Future<void> _continue() async {
    if (_step == 0) {
      if (_tracking.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa el número de seguimiento')),
        );
        return;
      }
      setState(() => _step = 1);
    } else if (_step == 1) {
      if (_comment.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Escribe tu comentario')),
        );
        return;
      }
      if (widget.providerId == null) {
        setState(() => _step = 2);
        return;
      }
      setState(() => _saving = true);
      try {
        await context.read<ProfileActionsService>().createReview(
              providerId: widget.providerId!,
              trackingNumber: _tracking.text.trim(),
              text: _comment.text.trim(),
            );
        if (mounted) setState(() => _step = 2);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    } else {
      _close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_step < 2) ...[
            const Text('😉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'Comentarios',
              style: AppTypography.titleMedium.copyWith(color: AppColors.commentBlue),
            ),
            const SizedBox(height: 20),
            if (_step == 0) ...[
              Text(
                'Ingresa el número de seguimiento de tu servicio',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tracking,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Ej. AW-2024-001',
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.commentBlue, width: 2),
                  ),
                ),
              ),
            ] else ...[
              Text(
                'Dejar un comentario',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _comment,
                maxLines: 4,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Excelente trabajo…',
                  alignLabelWithHint: true,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.commentBlue, width: 2),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _close,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.commentBlue,
                      side: const BorderSide(color: AppColors.commentBlue),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('Cerrar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _continue,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.commentBlue,
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text(_step == 1 ? 'Enviar' : 'Continuar'),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.commentBlue.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline, size: 36, color: AppColors.commentBlue),
            ),
            const SizedBox(height: 16),
            Text(
              'Tu comentario se envió.\nGracias por tu preferencia.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(height: 1.45),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _close,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.commentBlue,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: const Text('Aceptar'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
