import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../state/auth_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final u = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alworki'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Salir',
            onPressed: () async {
              await auth.logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, ${u?.name ?? "usuario"}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (auth.isGuest) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Modo invitado: regístrate para guardar tu perfil en este dispositivo.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Autenticación local', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Registro, login, JWT y almacenamiento de usuarios viven en la app '
            '(Sembast + mismas reglas que el backend Flask de ejemplo). '
            'Opcional: define JWT_SECRET al compilar si quieres otra clave de firma.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}
