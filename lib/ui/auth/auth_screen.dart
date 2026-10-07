import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/auth_api.dart';
import '../../services/catalog_service.dart';
import '../../services/exchange_repository.dart';
import '../../state/auth_controller.dart';
import 'auth_colors.dart';
import 'auth_validators.dart';
import 'widgets/auth_gradient_scaffold.dart';
import 'widgets/auth_primary_button.dart';
import 'widgets/auth_social_row.dart';
import 'widgets/auth_underline_field.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.initialTab = 1});

  /// 0 = Regístrate, 1 = Inicia Sesión
  final int initialTab;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _loginIdentity = TextEditingController();
  final _loginPassword = TextEditingController();

  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _acceptedTerms = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this, initialIndex: widget.initialTab.clamp(0, 1));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _loginIdentity.dispose();
    _loginPassword.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _afterLogin(AuthController auth) async {
    if (!mounted) return;
    await context.read<CatalogService>().refresh();
    await context.read<ExchangeRepository>().load();
    if (!mounted) return;
    context.go('/home');
  }

  Future<void> _continueAsGuest() async {
    final auth = context.read<AuthController>();
    await auth.continueAsGuest();
    if (!mounted) return;
    await _afterLogin(auth);
  }

  Future<void> _submitLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final identity = _loginIdentity.text.trim();
    final email = identity.contains('@') ? identity : '${identity.replaceAll(RegExp(r'\D'), '')}@alworki.local';
    await auth.login(email, _loginPassword.text);
    if (!mounted) return;
    if (auth.isLoggedIn) {
      await _afterLogin(auth);
    } else if (auth.lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.lastError!)));
    }
  }

  Future<void> _submitRegister() async {
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes aceptar los términos y condiciones')),
      );
      return;
    }
    if (!_registerFormKey.currentState!.validate()) return;

    final auth = context.read<AuthController>();
    final mail = _email.text.trim();
    final localPart = mail.split('@').first;
    try {
      await auth.register(
        email: mail,
        password: _password.text,
        firstname: localPart,
        lastname: 'Usuario',
      );
      if (!mounted) return;
      context.push(
        '/verify-whatsapp',
        extra: {
          'phone': _phone.text.trim(),
          'email': mail,
          'password': _password.text,
        },
      );
    } on AuthApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _social(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Acceso con $provider — próximamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return AuthGradientScaffold(
      child: Column(
        children: [
          const SizedBox(height: 32),
          const Icon(Icons.swap_horiz, size: 40, color: AuthColors.textPrimary),
          const SizedBox(height: 12),
          const Text(
            'Alworki',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AuthColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Encuentra servicios, intercambia favores\no contrata profesionales de confianza',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AuthColors.textMuted.withValues(alpha: 0.9),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          TabBar(
            controller: _tabs,
            indicatorColor: AuthColors.textPrimary,
            indicatorWeight: 2.5,
            labelColor: AuthColors.textPrimary,
            unselectedLabelColor: AuthColors.textMuted,
            labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Regístrate'),
              Tab(text: 'Inicia Sesión'),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _RegisterTab(
                  formKey: _registerFormKey,
                  email: _email,
                  phone: _phone,
                  password: _password,
                  confirmPassword: _confirmPassword,
                  acceptedTerms: _acceptedTerms,
                  onTermsChanged: (v) => setState(() => _acceptedTerms = v),
                  loading: auth.isLoading,
                  onSubmit: _submitRegister,
                  onLoginTap: () => _tabs.animateTo(1),
                ),
                _LoginTab(
                  formKey: _loginFormKey,
                  identity: _loginIdentity,
                  password: _loginPassword,
                  loading: auth.isLoading,
                  onSubmit: _submitLogin,
                  onForgot: () => context.push('/forgot-password'),
                  onRegisterTap: () => _tabs.animateTo(0),
                  onSocial: _social,
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: TextButton(
                onPressed: auth.isLoading ? null : _continueAsGuest,
                child: const Text(
                  'Continuar como invitado',
                  style: TextStyle(
                    color: AuthColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                    decorationColor: AuthColors.underline,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginTab extends StatelessWidget {
  const _LoginTab({
    required this.formKey,
    required this.identity,
    required this.password,
    required this.loading,
    required this.onSubmit,
    required this.onForgot,
    required this.onRegisterTap,
    required this.onSocial,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController identity;
  final TextEditingController password;
  final bool loading;
  final VoidCallback onSubmit;
  final VoidCallback onForgot;
  final VoidCallback onRegisterTap;
  final void Function(String) onSocial;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthUnderlineField(
              label: 'Correo electrónico o telefono',
              hint: 'Tu correo electrónico o telefono',
              controller: identity,
              keyboardType: TextInputType.emailAddress,
              validator: AuthValidators.loginIdentity,
            ),
            AuthUnderlineField(
              label: 'Contraseña',
              hint: 'Ingresa tu contraseña',
              controller: password,
              obscureText: true,
              validator: (v) => v == null || v.isEmpty ? 'Ingresa tu contraseña' : null,
            ),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: onForgot,
                child: const Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(color: AuthColors.textPrimary, decoration: TextDecoration.underline),
                ),
              ),
            ),
            const SizedBox(height: 8),
            AuthPrimaryButton(label: 'Inicia Sesión', loading: loading, onPressed: onSubmit),
            const SizedBox(height: 28),
            AuthSocialRow(onTap: onSocial),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: onRegisterTap,
                child: const Text(
                  '¿No tienes cuenta? Regístrate',
                  style: TextStyle(color: AuthColors.textMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterTab extends StatelessWidget {
  const _RegisterTab({
    required this.formKey,
    required this.email,
    required this.phone,
    required this.password,
    required this.confirmPassword,
    required this.acceptedTerms,
    required this.onTermsChanged,
    required this.loading,
    required this.onSubmit,
    required this.onLoginTap,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController phone;
  final TextEditingController password;
  final TextEditingController confirmPassword;
  final bool acceptedTerms;
  final ValueChanged<bool> onTermsChanged;
  final bool loading;
  final VoidCallback onSubmit;
  final VoidCallback onLoginTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthUnderlineField(
              label: 'Correo electrónico',
              hint: 'Escribe aquí tu correo electrónico',
              controller: email,
              keyboardType: TextInputType.emailAddress,
              validator: AuthValidators.email,
            ),
            AuthUnderlineField(
              label: 'Número de teléfono',
              hint: 'Escribe aquí tu número de whatsapp',
              controller: phone,
              keyboardType: TextInputType.phone,
              validator: AuthValidators.phone,
            ),
            AuthUnderlineField(
              label: 'Introduzca la contraseña',
              hint: 'Contraseña',
              controller: password,
              obscureText: true,
              validator: AuthValidators.password,
            ),
            AuthUnderlineField(
              label: 'Confirmar contraseña',
              hint: '**********',
              controller: confirmPassword,
              obscureText: true,
              validator: (v) => AuthValidators.confirmPassword(v, password.text),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: Checkbox(
                    value: acceptedTerms,
                    onChanged: (v) => onTermsChanged(v ?? false),
                    activeColor: AuthColors.accent,
                    side: const BorderSide(color: AuthColors.textMuted),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Aceptar los términos y condiciones',
                    style: TextStyle(color: AuthColors.textPrimary, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AuthPrimaryButton(label: 'Comencemos', loading: loading, onPressed: onSubmit),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: onLoginTap,
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: AuthColors.textMuted, fontSize: 14),
                    children: [
                      TextSpan(text: '¿Tienes una cuenta? '),
                      TextSpan(
                        text: 'Inicia sesión.',
                        style: TextStyle(
                          color: AuthColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
