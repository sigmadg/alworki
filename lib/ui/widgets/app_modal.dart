import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Color estándar del velo detrás de modales y bottom sheets.
const Color kModalBarrierColor = Color(0xA6000000);

RoundedRectangleBorder appDialogShape({double radius = 20}) => RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: const BorderSide(color: AppColors.border, width: 0.5),
    );

/// Contenedor visual para diálogos personalizados (tema oscuro).
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 28, 24, 20),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: appDialogShape(),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Diálogo modal con estilo oscuro consistente.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: kModalBarrierColor,
    builder: builder,
  );
}

/// AlertDialog con colores y forma del tema oscuro.
Future<T?> showAppAlertDialog<T>({
  required BuildContext context,
  String? title,
  Widget? content,
  List<Widget>? actions,
  bool barrierDismissible = true,
}) {
  return showAppDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      shape: appDialogShape(),
      title: title != null ? Text(title, style: AppTypography.titleMedium) : null,
      content: content,
      contentTextStyle: AppTypography.bodyMedium,
      actions: actions,
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actionsAlignment: MainAxisAlignment.end,
    ),
  );
}

/// Bottom sheet modal con estilo oscuro consistente.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool showHandle = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppColors.card,
    barrierColor: kModalBarrierColor,
    isScrollControlled: isScrollControlled,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      if (!showHandle) return builder(ctx);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          appBottomSheetHandle(),
          Flexible(child: builder(ctx)),
        ],
      );
    },
  );
}

Widget appBottomSheetHandle() {
  return Center(
    child: Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}
