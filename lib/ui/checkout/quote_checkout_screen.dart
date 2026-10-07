import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/quote_checkout_data.dart';
import '../../services/profile_actions_service.dart';
import '../../services/wallet_service.dart';
import '../../state/auth_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../profile/widgets/profile_chrome_label.dart';
import '../widgets/app_modal.dart';

/// Checkout de cotización con pago en monedas rojas/azules (Figma).
class QuoteCheckoutScreen extends StatefulWidget {
  const QuoteCheckoutScreen({super.key, required this.quote});

  final QuoteCheckoutData quote;

  @override
  State<QuoteCheckoutScreen> createState() => _QuoteCheckoutScreenState();
}

class _QuoteCheckoutScreenState extends State<QuoteCheckoutScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();

  CoinPaymentType _coinType = CoinPaymentType.red;
  bool _payEnabled = true;
  bool _dismissedInsufficient = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().user;
    if (user != null && !user.isGuest) {
      _firstName.text = user.firstname.isNotEmpty ? user.firstname : 'Stablo';
      _lastName.text = user.lastname.isNotEmpty ? user.lastname : 'Penley';
      _email.text = user.email.isNotEmpty ? user.email : 'stablopenley@bluqapp.com';
    } else {
      _firstName.text = 'Stablo';
      _lastName.text = 'Penley';
      _email.text = 'stablopenley@bluqapp.com';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletService>().load();
    });
    for (final c in [_firstName, _lastName, _email]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    super.dispose();
  }

  bool get _formValid =>
      _firstName.text.trim().isNotEmpty &&
      _lastName.text.trim().isNotEmpty &&
      _email.text.contains('@');

  bool _hasEnough(WalletBalance b) {
    final cost = b.quoteCost;
    return _coinType == CoinPaymentType.red ? b.hasEnoughRed(cost) : b.hasEnoughBlue(cost);
  }

  Future<void> _showBuyBlueDialog() async {
    final buy = await showAppDialog<bool>(
      context: context,
      builder: (dlg) => AppDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.localBadge, width: 2),
              ),
              child: const Icon(Icons.close, color: AppColors.reportRed, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'No cuentas con suficientes monedas azules.',
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '¿Deseas comprar monedas azules?',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dlg, false),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(dlg, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.stripePay,
                    ),
                    child: const Text('Comprar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (buy == true && mounted) {
      final wallet = context.read<WalletService>().balance;
      final needed = wallet.quoteCost - wallet.blueCoins;
      final mxn = needed > 0 ? (needed / 0.9).ceil().clamp(100, 9999) : 100;
      await context.push('/buy-blue-coins?mxn=$mxn');
      if (mounted) await context.read<WalletService>().load();
    }
  }

  Future<void> _submit() async {
    if (!_formValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa tus datos de contacto')),
      );
      return;
    }
    if (!_payEnabled) return;

    final wallet = context.read<WalletService>().balance;
    if (!_hasEnough(wallet)) {
      if (_coinType == CoinPaymentType.blue) {
        await _showBuyBlueDialog();
        return;
      }
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await context.read<ProfileActionsService>().createQuote(
            providerId: widget.quote.providerId,
            providerName: widget.quote.providerName,
            services: widget.quote.services,
            materials: widget.quote.materials,
            date: widget.quote.date,
            timeSlot: widget.quote.timeSlot,
            payWith: _coinType == CoinPaymentType.red ? 'red' : 'blue',
            coinCost: wallet.quoteCost,
            contactFirstName: _firstName.text.trim(),
            contactLastName: _lastName.text.trim(),
            contactEmail: _email.text.trim(),
          );
      await context.read<WalletService>().load();
      if (mounted) {
        final tracking = result['trackingNumber'] as String? ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡Cotización confirmada! $tracking')),
        );
        context.push('/order/$tracking');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletService>().balance;
    final enough = _payEnabled && _hasEnough(wallet);
    final isRed = _coinType == CoinPaymentType.red;
    final showInsufficientBanner =
        _payEnabled && !enough && isRed && !_dismissedInsufficient;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ProfileChromeLabel(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _PaymentCard(
                    coinType: _coinType,
                    enabled: _payEnabled,
                    balance: wallet,
                    onTogglePay: (v) => setState(() => _payEnabled = v),
                    onSelectType: (t) => setState(() {
                      _coinType = t;
                      _dismissedInsufficient = false;
                    }),
                  ),
                  if (showInsufficientBanner) ...[
                    const SizedBox(height: 12),
                    _InsufficientBanner(
                      onDismiss: () => setState(() => _dismissedInsufficient = true),
                    ),
                  ],
                  if (_payEnabled && enough) ...[
                    const SizedBox(height: 12),
                    _SuccessBanner(
                      coinLabel: isRed ? 'rojas' : 'azules',
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Datos de contacto',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _ContactField(label: 'Nombre(s)', controller: _firstName),
                  const SizedBox(height: 12),
                  _ContactField(label: 'Apellido(s)', controller: _lastName),
                  const SizedBox(height: 12),
                  _ContactField(
                    label: 'Correo electrónico',
                    controller: _email,
                    keyboard: TextInputType.emailAddress,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: enough
                  ? OutlinedButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.check_circle, color: AppColors.proximity.withValues(alpha: 0.9)),
                      label: const Text('Continuar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.proximity,
                        side: const BorderSide(color: AppColors.navBar, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                    )
                  : !isRed && _payEnabled
                      ? OutlinedButton.icon(
                          onPressed: _submitting ? null : _submit,
                          icon: Icon(Icons.check_circle, color: AppColors.proximity.withValues(alpha: 0.9)),
                          label: const Text('Continuar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.proximity,
                            side: const BorderSide(color: AppColors.navBar, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          ),
                        )
                      : OutlinedButton(
                          onPressed: () => context.pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.reportRed,
                            side: const BorderSide(color: AppColors.reportRed, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          ),
                          child: const Text('Cancelar'),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.coinType,
    required this.enabled,
    required this.balance,
    required this.onTogglePay,
    required this.onSelectType,
  });

  final CoinPaymentType coinType;
  final bool enabled;
  final WalletBalance balance;
  final ValueChanged<bool> onTogglePay;
  final ValueChanged<CoinPaymentType> onSelectType;

  @override
  Widget build(BuildContext context) {
    final isRed = coinType == CoinPaymentType.red;
    final cost = balance.quoteCost;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => onSelectType(CoinPaymentType.red),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: isRed ? const Color(0xFFFFE8E8) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isRed ? AppColors.reportRed : Colors.grey.shade300,
                      width: isRed ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pago con monedas rojas',
                          style: TextStyle(
                            color: AppColors.reportRed,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (isRed)
                        Switch(
                          value: enabled,
                          onChanged: onTogglePay,
                          activeThumbColor: AppColors.reportRed,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => onSelectType(CoinPaymentType.blue),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: !isRed ? AppColors.localBadge : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: !isRed ? AppColors.localBadge : Colors.grey.shade300,
                      width: !isRed ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pago con monedas azules',
                          style: TextStyle(
                            color: !isRed ? Colors.white : AppColors.localBadge,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (!isRed)
                        Switch(
                          value: enabled,
                          onChanged: onTogglePay,
                          activeThumbColor: Colors.white,
                          activeTrackColor: Colors.white54,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Costo: $cost monedas · Saldo ${isRed ? 'rojo' : 'azul'}: ${isRed ? balance.redCoins : balance.blueCoins}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _InsufficientBanner extends StatelessWidget {
  const _InsufficientBanner({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8E8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: AppColors.reportRed, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Saldo insuficiente ! con monedas rojas',
              style: TextStyle(fontSize: 13, color: AppColors.reportRed),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.coinLabel});

  final String coinLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.proximity.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.proximity.withValues(alpha: 0.9), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Felicidades! Tu saldo es suficiente para pagar con monedas $coinLabel..',
              style: TextStyle(fontSize: 13, color: AppColors.proximity.withValues(alpha: 0.95)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactField extends StatelessWidget {
  const _ContactField({
    required this.label,
    required this.controller,
    this.keyboard,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboard;

  @override
  Widget build(BuildContext context) {
    final valid = controller.text.trim().isNotEmpty &&
        (label.contains('Correo') ? controller.text.contains('@') : true);

    return TextField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: valid ? Icon(Icons.check_circle, color: AppColors.proximity.withValues(alpha: 0.85)) : null,
      ),
    );
  }
}
