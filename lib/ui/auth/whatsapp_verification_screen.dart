import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/catalog_service.dart';
import '../../services/exchange_repository.dart';
import '../../state/auth_controller.dart';
import 'auth_colors.dart';
import 'widgets/auth_gradient_scaffold.dart';
import 'widgets/auth_primary_button.dart';

class WhatsappVerificationScreen extends StatefulWidget {
  const WhatsappVerificationScreen({
    super.key,
    required this.phone,
    required this.email,
    required this.password,
  });

  final String phone;
  final String email;
  final String password;

  @override
  State<WhatsappVerificationScreen> createState() => _WhatsappVerificationScreenState();
}

class _WhatsappVerificationScreenState extends State<WhatsappVerificationScreen> {
  final _controllers = List.generate(4, (_) => TextEditingController());
  final _nodes = List.generate(4, (_) => FocusNode());
  bool _loading = false;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onDigit(int index, String value) {
    if (value.length > 1) {
      _controllers[index].text = value.substring(value.length - 1);
    }
    if (value.isNotEmpty && index < 3) {
      _nodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  Future<void> _verify() async {
    if (_code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el código de 4 dígitos')),
      );
      return;
    }

    setState(() => _loading = true);
    // Demo: cualquier código de 4 dígitos es válido (integración WhatsApp real pendiente).
    await Future.delayed(const Duration(milliseconds: 600));

    final auth = context.read<AuthController>();
    final catalog = context.read<CatalogService>();
    final exchange = context.read<ExchangeRepository>();
    await auth.login(widget.email, widget.password);
    if (!mounted) return;
    setState(() => _loading = false);

    if (auth.isLoggedIn) {
      await catalog.refresh();
      await exchange.load();
      if (!mounted) return;
      final verify = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cuenta creada'),
          content: const Text(
            'WhatsApp Business OTP está pendiente de API. '
            'Puedes verificar tu identidad ahora (INE + selfie) o hacerlo después.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Más tarde')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Verificar identidad')),
          ],
        ),
      );
      if (!mounted) return;
      if (verify == true) {
        context.go('/verify-identity');
      } else {
        context.go('/home');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.lastError ?? 'No se pudo iniciar sesión')),
      );
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthGradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AuthColors.textPrimary,
        title: const Text('Verificación por WhatsApp'),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Demo local: cualquier código de 4 dígitos. PENDIENTE: WhatsApp Business API para ${widget.phone}.',
              style: const TextStyle(color: AuthColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ingresa el codigo de verificación de whatsapp',
              style: TextStyle(color: AuthColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (i) {
                return SizedBox(
                  width: 56,
                  child: TextField(
                    controller: _controllers[i],
                    focusNode: _nodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(color: AuthColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                    cursorColor: AuthColors.textPrimary,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: const BorderSide(color: AuthColors.underline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: const BorderSide(color: AuthColors.textPrimary, width: 1.5),
                      ),
                    ),
                    onChanged: (v) => _onDigit(i, v),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Código reenviado (demo)')),
                  );
                },
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: AuthColors.textMuted, fontSize: 13),
                    children: [
                      TextSpan(text: '¿No recibiste ningún código? '),
                      TextSpan(
                        text: 'Reenviar.',
                        style: TextStyle(color: AuthColors.accent, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            AuthPrimaryButton(label: 'VERIFICAR', loading: _loading, onPressed: _verify),
          ],
        ),
      ),
    );
  }
}
