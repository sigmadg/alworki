import 'package:flutter/material.dart';

import '../../data/service_categories.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Selector de oficio/categoría con búsqueda y grupos.
class CategoryPickerField extends StatelessWidget {
  const CategoryPickerField({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.hint = 'Elige un oficio o categoría',
  });

  final String label;
  final ServiceCategory? selected;
  final ValueChanged<ServiceCategory> onSelected;
  final String hint;

  Future<void> _open(BuildContext context) async {
    final picked = await showCategoryPickerSheet(context, selected: selected);
    if (picked != null) onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          selected?.label ?? hint,
          style: selected == null
              ? AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)
              : AppTypography.bodySmall,
        ),
      ),
    );
  }
}

Future<ServiceCategory?> showCategoryPickerSheet(
  BuildContext context, {
  ServiceCategory? selected,
}) {
  return showModalBottomSheet<ServiceCategory>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _CategoryPickerSheet(initial: selected),
  );
}

class _CategoryPickerSheet extends StatefulWidget {
  const _CategoryPickerSheet({this.initial});

  final ServiceCategory? initial;

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final groups = <String, List<ServiceCategory>>{};
    for (final entry in kServiceCategoryGroups.entries) {
      final filtered = entry.value.where((c) => c.matchesQuery(_query)).toList();
      if (filtered.isNotEmpty) groups[entry.key] = filtered;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Oficios y categorías', style: AppTypography.titleMedium),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _search,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar: enfermera, plomero, veterinario…',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: groups.isEmpty
                  ? Center(
                      child: Text('Sin resultados para «$_query»', style: AppTypography.caption),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                      itemCount: groups.length,
                      itemBuilder: (context, i) {
                        final groupName = groups.keys.elementAt(i);
                        final items = groups[groupName]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                              child: Text(groupName, style: AppTypography.titleSmall.copyWith(fontSize: 13)),
                            ),
                            ...items.map(
                              (cat) => ListTile(
                                leading: Icon(
                                  widget.initial?.id == cat.id ? Icons.check_circle : Icons.work_outline,
                                  color: widget.initial?.id == cat.id
                                      ? AppColors.proximity
                                      : AppColors.textSecondary,
                                ),
                                title: Text(cat.label),
                                subtitle: Text(cat.group, style: AppTypography.caption),
                                onTap: () => Navigator.pop(context, cat),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chips horizontales de categorías para búsqueda rápida.
class CategorySearchChips extends StatelessWidget {
  const CategorySearchChips({
    super.key,
    required this.onCategoryTap,
    this.categories,
  });

  final void Function(ServiceCategory category) onCategoryTap;
  final List<ServiceCategory>? categories;

  @override
  Widget build(BuildContext context) {
    final items = categories ?? kFeaturedServiceCategories;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = items[i];
          return ActionChip(
            label: Text(cat.label, style: const TextStyle(fontSize: 12)),
            onPressed: () => onCategoryTap(cat),
            backgroundColor: AppColors.card,
            side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
          );
        },
      ),
    );
  }
}
