import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/service_categories.dart';
import '../../services/catalog_service.dart';
import '../../theme/app_colors.dart';
import '../widgets/category_picker.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _cost = TextEditingController(text: '1');
  bool _saving = false;
  int? _selectedCardId;
  ServiceCategory? _selectedCategory;

  @override
  void dispose() {
    _description.dispose();
    _location.dispose();
    _cost.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _description.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe una descripción')),
      );
      return;
    }
    if (_selectedCategory == null && _selectedCardId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un oficio o categoría')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final catalog = context.read<CatalogService>();
      final card = _selectedCardId != null ? catalog.cardById(_selectedCardId!) : null;
      await catalog.createPost(
        description: text,
        location: _location.text.trim(),
        cost: int.tryParse(_cost.text.trim()) ?? 1,
        cardId: card?.id,
        cardTitle: card?.title,
        category: _selectedCategory?.label ?? card?.category,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publicación creada')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = context.watch<CatalogService>().cards;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Nueva publicación'),
        backgroundColor: AppColors.navBar,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _description,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: '¿Qué favor ofreces o buscas?',
              hintText: 'Ej. Ofrezco 2h de inglés a la semana…',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          CategoryPickerField(
            label: 'Oficio o categoría',
            selected: _selectedCategory,
            onSelected: (cat) => setState(() => _selectedCategory = cat),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _location,
            decoration: InputDecoration(
              labelText: 'Ubicación (opcional)',
              prefixIcon: const Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cost,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Costo en favores',
              prefixIcon: const Icon(Icons.favorite_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(
            initialValue: _selectedCardId,
            decoration: InputDecoration(
              labelText: 'Tarjeta relacionada (opcional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Ninguna')),
              ...cards.map(
                (c) => DropdownMenuItem(value: c.id, child: Text(c.title)),
              ),
            ],
            onChanged: (v) => setState(() => _selectedCardId = v),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _saving ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.navBar,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Publicar', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
