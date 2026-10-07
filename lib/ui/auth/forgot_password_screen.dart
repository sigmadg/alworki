import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'auth_colors.dart';
import 'auth_validators.dart';
import 'widgets/auth_gradient_scaffold.dart';
import 'widgets/auth_primary_button.dart';
import 'widgets/auth_underline_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identity = TextEditingController();
  final _confirm = TextEditingController();
  bool _captchaDone = false;
  bool _usePhone = false;
  bool _loading = false;

  @override
  void dispose() {
    _identity.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_captchaDone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa la verificación captcha')),
      );
      return;
    }
    if (_identity.text.trim() != _confirm.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_usePhone ? 'Los teléfonos no coinciden' : 'Los correos no coinciden')),
      );
      return;
    }

    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Si existe la cuenta, recibirás instrucciones para recuperar tu contraseña.')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return AuthGradientScaffold(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AuthColors.textPrimary),
                  onPressed: () => context.pop(),
                ),
                const Expanded(
                  child: Text(
                    'Recuperar contraseña',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AuthColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('Correo'),
                selected: !_usePhone,
                onSelected: (_) => setState(() => _usePhone = false),
                selectedColor: AuthColors.accent,
                labelStyle: TextStyle(color: !_usePhone ? Colors.white : AuthColors.textMuted),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Teléfono'),
                selected: _usePhone,
                onSelected: (_) => setState(() => _usePhone = true),
                selectedColor: AuthColors.accent,
                labelStyle: TextStyle(color: _usePhone ? Colors.white : AuthColors.textMuted),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthUnderlineField(
                      label: 'Correo electrónico o telefono',
                      hint: 'Tu correo electrónico o telefono',
                      controller: _identity,
                      keyboardType: _usePhone ? TextInputType.phone : TextInputType.emailAddress,
                      validator: _usePhone ? AuthValidators.phone : AuthValidators.email,
                    ),
                    AuthUnderlineField(
                      label: _usePhone ? 'Confirma tu telefono' : 'Confirma tu correo electrónico',
                      hint: _usePhone ? 'telefono' : 'Correo electronico',
                      controller: _confirm,
                      keyboardType: _usePhone ? TextInputType.phone : TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Campo requerido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AuthColors.underline),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Verificación de seguridad',
                            style: TextStyle(color: AuthColors.textPrimary, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Cuando la imagen principal esté en la posición correcta, toque ¡Listo!',
                            style: TextStyle(color: AuthColors.textMuted, fontSize: 12, height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Checkbox(
                                value: _captchaDone,
                                onChanged: (v) => setState(() => _captchaDone = v ?? false),
                                activeColor: AuthColors.accent,
                                side: const BorderSide(color: AuthColors.textMuted),
                              ),
                              const Expanded(
                                child: Text(
                                  'Confirmo que no soy un robot',
                                  style: TextStyle(color: AuthColors.textPrimary, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    AuthPrimaryButton(
                      label: 'Recuperar contraseña',
                      loading: _loading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
