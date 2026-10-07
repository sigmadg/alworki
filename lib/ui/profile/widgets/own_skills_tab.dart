import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/provider_demo_data.dart';
import '../../../data/service_categories.dart';
import '../../../models/user_profile.dart';
import '../../../services/catalog_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../widgets/app_modal.dart';
import '../../widgets/category_picker.dart';

/// Pestaña Perfil del trabajador propio: servicios y materiales editables (Figma no verificado).
class OwnSkillsTab extends StatefulWidget {
  const OwnSkillsTab({super.key, required this.profile, this.embeddedInScroll = false});

  final UserProfile profile;
  final bool embeddedInScroll;

  @override
  State<OwnSkillsTab> createState() => _OwnSkillsTabState();
}

class _OwnSkillsTabState extends State<OwnSkillsTab> {
  int _section = 0;

  List<ProfileSkill> get _skills => ProviderDemoData.demoSkills(widget.profile.skills);
  List<ProfileSkill> get _materials => ProviderDemoData.demoMaterials(widget.profile.materials);

  Future<void> _editItem({
    required String title,
    required String initial,
    required Future<void> Function(String name) onSave,
  }) async {
    final ctrl = TextEditingController(text: initial);
    final ok = await showAppDialog<bool>(
      context: context,
      builder: (dlg) => AlertDialog(
        title: Text(title, style: AppTypography.titleMedium),
        content: TextField(
          controller: ctrl,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dlg, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dlg, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty && mounted) {
      await onSave(ctrl.text.trim());
    }
    ctrl.dispose();
  }

  Future<void> _addItem({required bool materials}) async {
    if (materials) {
      final ctrl = TextEditingController();
      final ok = await showAppDialog<bool>(
        context: context,
        builder: (dlg) => AlertDialog(
          title: Text('Nuevo material', style: AppTypography.titleMedium),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(hintText: 'Ej. Cedro'),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dlg, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(dlg, true), child: const Text('Agregar')),
          ],
        ),
      );
      if (ok == true && ctrl.text.trim().isNotEmpty && mounted) {
        await context.read<CatalogService>().addMaterial(ctrl.text.trim());
      }
      ctrl.dispose();
      return;
    }

    ServiceCategory? picked;
    final ok = await showAppDialog<bool>(
      context: context,
      builder: (dlg) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Text('Nuevo servicio', style: AppTypography.titleMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CategoryPickerField(
                label: 'Oficio o categoría',
                selected: picked,
                onSelected: (cat) => setDlgState(() => picked = cat),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dlg, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: picked == null ? null : () => Navigator.pop(dlg, true),
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && picked != null && mounted) {
      await context.read<CatalogService>().addSkill(picked!.label);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _section == 0 ? _skills : _materials;
    final isMaterials = _section == 1;
    final catalog = context.read<CatalogService>();
    final hasPersisted = isMaterials ? widget.profile.materials.isNotEmpty : widget.profile.skills.isNotEmpty;

    final listSection = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(item.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.localBadge, size: 20),
                  onPressed: hasPersisted
                      ? () => _editItem(
                            title: isMaterials ? 'Editar material' : 'Editar servicio',
                            initial: item.name,
                            onSave: (name) => isMaterials
                                ? catalog.updateMaterial(item.id, name)
                                : catalog.updateSkill(item.id, name),
                          )
                      : () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Usa + para guardar tu primer elemento')),
                          ),
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton.filled(
            onPressed: () => _addItem(materials: isMaterials),
            icon: const Icon(Icons.add, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: AppColors.localBadge),
          ),
        ),
      ],
    );

    if (widget.embeddedInScroll) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._headerWidgets(isMaterials),
          Padding(padding: const EdgeInsets.all(16), child: listSection),
        ],
      );
    }

    return Column(
      children: [
        ..._headerWidgets(isMaterials),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length + 1,
            itemBuilder: (context, i) {
              if (i == items.length) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton.filled(
                    onPressed: () => _addItem(materials: isMaterials),
                    icon: const Icon(Icons.add, color: Colors.white),
                    style: IconButton.styleFrom(backgroundColor: AppColors.localBadge),
                  ),
                );
              }
              final item = items[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(item.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.localBadge, size: 20),
                      onPressed: hasPersisted
                          ? () => _editItem(
                                title: isMaterials ? 'Editar material' : 'Editar servicio',
                                initial: item.name,
                                onSave: (name) => isMaterials
                                    ? catalog.updateMaterial(item.id, name)
                                    : catalog.updateSkill(item.id, name),
                              )
                          : () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Usa + para guardar tu primer elemento')),
                              ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _headerWidgets(bool isMaterials) => [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              isMaterials ? 'Materiales que utilizas' : 'Servicios que ofreces',
              style: AppTypography.titleSmall.copyWith(fontSize: 14),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              isMaterials
                  ? 'Lista los insumos o herramientas con los que trabajas'
                  : 'Agrega las habilidades que otros pueden contratar',
              style: AppTypography.caption,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              _SectionChip(
                label: 'Servicios',
                selected: _section == 0,
                onTap: () => setState(() => _section = 0),
              ),
              const SizedBox(width: 8),
              _SectionChip(
                label: 'Materiales',
                selected: _section == 1,
                onTap: () => setState(() => _section = 1),
              ),
            ],
          ),
        ),
      ];
}

class _SectionChip extends StatelessWidget {
  const _SectionChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceElevated : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.textMuted : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
