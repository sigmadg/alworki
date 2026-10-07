import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/catalog_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final _caption = TextEditingController();
  bool _saving = false;

  static const _images = [
    'background1.png',
    'background2.png',
    'background3.png',
    'background4.png',
    'background5.png',
  ];
  String _image = _images.first;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_caption.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un pie de historia')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<CatalogService>().createStory(
            caption: _caption.text.trim(),
            imageKey: _image,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Historia publicada')),
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Nueva historia')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Se verá 24 h en la fila de historias', style: AppTypography.sectionSubtitle),
          const SizedBox(height: 16),
          TextField(
            controller: _caption,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Qué estás ofreciendo o buscando',
              hintText: 'Disponible hoy para plomería express',
            ),
          ),
          const SizedBox(height: 16),
          Text('Fondo', style: AppTypography.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _images
                .map(
                  (img) => ChoiceChip(
                    label: Text(img.replaceAll('.png', '')),
                    selected: _image == img,
                    onSelected: (_) => setState(() => _image = img),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _submit,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Publicar historia'),
          ),
        ],
      ),
    );
  }
}
