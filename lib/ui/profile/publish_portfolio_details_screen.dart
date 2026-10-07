import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/service_categories.dart';
import '../../services/catalog_service.dart';
import '../../theme/app_colors.dart';
import '../widgets/alworki_image.dart';
import '../widgets/category_picker.dart';

/// Paso 2: descripción, etiqueta y precio (Figma).
class PublishPortfolioDetailsScreen extends StatefulWidget {
  const PublishPortfolioDetailsScreen({super.key, required this.imageKey});

  final String imageKey;

  @override
  State<PublishPortfolioDetailsScreen> createState() => _PublishPortfolioDetailsScreenState();
}

class _PublishPortfolioDetailsScreenState extends State<PublishPortfolioDetailsScreen> {
  final _description = TextEditingController();
  final _price = TextEditingController();
  String _modality = 'LOCAL';
  ServiceCategory? _category;
  bool _saving = false;

  @override
  void dispose() {
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final desc = _description.text.trim();
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega una descripción')),
      );
      return;
    }
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un oficio o categoría')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<CatalogService>().addPortfolioItem(
            imageKey: widget.imageKey,
            description: desc,
            tag: _modality,
            priceMxn: int.tryParse(_price.text.trim()) ?? 0,
            category: _category!.group,
            profession: _category!.label,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trabajo publicado en tu portafolio')),
        );
        context.go('/profile?tab=1');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<CatalogService>().profile;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AlworkiAvatar(avatarKey: profile.avatar, radius: 22),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _description,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Agregar descripción',
                    hintText: 'Pintura realista al óleo',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AlworkiImage(imageKey: widget.imageKey, width: 64, height: 64, fit: BoxFit.cover),
              ),
            ],
          ),
          const SizedBox(height: 20),
          CategoryPickerField(
            label: 'Oficio o categoría',
            selected: _category,
            onSelected: (cat) => setState(() => _category = cat),
          ),
          const SizedBox(height: 20),
          const Text('Modalidad', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: [
              _TagBadge(
                label: 'LOCAL',
                color: AppColors.localBadge,
                selected: _modality == 'LOCAL',
                onTap: () => setState(() => _modality = 'LOCAL'),
              ),
              const SizedBox(width: 8),
              _TagBadge(
                label: 'REMOTO',
                color: AppColors.remoteBadge,
                selected: _modality == 'REMOTO',
                onTap: () => setState(() => _modality = 'REMOTO'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Precio en pesos mexicanos',
              hintText: '200',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
              suffixText: '\$',
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: _saving ? null : _publish,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.check_circle_outline, color: AppColors.proximity.withValues(alpha: 0.9)),
            label: const Text('Continuar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navBar,
              side: const BorderSide(color: AppColors.navBar, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagBadge extends StatelessWidget {
  const _TagBadge({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
