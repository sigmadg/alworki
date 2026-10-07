import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/catalog_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _partner = TextEditingController();
  final _requirements = TextEditingController();
  bool _publishToFeed = true;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _partner.dispose();
    _requirements.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ponle un nombre al proyecto')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<CatalogService>().createProject(
            name: _name.text.trim(),
            description: _description.text.trim(),
            partnerName: _partner.text.trim(),
            publishToFeed: _publishToFeed,
            requirements: _requirements.text
                .split(RegExp(r'[,;]+'))
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_publishToFeed ? 'Proyecto publicado en el feed' : 'Proyecto creado')),
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
      appBar: AppBar(title: const Text('Nuevo proyecto')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Comparte un trabajo o intercambio', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          Text(
            'El proyecto aparece en tu tablero y, si quieres, en el feed tipo Instagram.',
            style: AppTypography.sectionSubtitle,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nombre', hintText: 'Inglés ↔ paseos'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Qué ofrecen y qué buscan',
              hintText: '2h de inglés semanal a cambio de pasear al perro',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _partner,
            decoration: const InputDecoration(labelText: 'Con quién (opcional)', hintText: 'Laura M.'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _requirements,
            decoration: const InputDecoration(
              labelText: 'Requisitos de entrega (opcional)',
              hintText: 'muebles a medida, herramientas, madera',
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _publishToFeed,
            onChanged: (v) => setState(() => _publishToFeed = v),
            title: const Text('Publicar en el feed'),
            subtitle: const Text('La comunidad podrá verlo y seguir el proyecto'),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _submit,
            icon: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.publish),
            label: const Text('Crear proyecto'),
          ),
        ],
      ),
    );
  }
}
