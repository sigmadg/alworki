import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/wallet_service.dart';
import '../../theme/app_colors.dart';
import '../profile/widgets/profile_chrome_label.dart';

/// Pasarela Stripe para comprar monedas azules (Figma).
class BuyBlueCoinsScreen extends StatefulWidget {
  const BuyBlueCoinsScreen({super.key, this.amountMxn = 220});

  final int amountMxn;

  @override
  State<BuyBlueCoinsScreen> createState() => _BuyBlueCoinsScreenState();
}

class _BuyBlueCoinsScreenState extends State<BuyBlueCoinsScreen> {
  int _step = 0;
  bool _payWithBlue = true;
  bool _showTooltip = false;
  bool _isDebit = false;
  String _method = 'card';
  int _cardIndex = 0;
  bool _paying = false;

  final _cardNumber = TextEditingController(text: '4242 4242 4242 4242');
  final _expiry = TextEditingController(text: '12/28');
  final _cvc = TextEditingController(text: '123');
  final _holder = TextEditingController(text: 'MELISSA MCCARTHY');

  static const _cards = [
    _SavedCard(label: 'Visa', last4: '4242', color: Color(0xFF1A1A2E), brand: 'VISA'),
    _SavedCard(label: 'Mastercard', last4: '1947', color: Color(0xFF5B2C6F), brand: 'MC'),
  ];

  int get _coins => (widget.amountMxn * 0.9).round();

  @override
  void dispose() {
    _cardNumber.dispose();
    _expiry.dispose();
    _cvc.dispose();
    _holder.dispose();
    super.dispose();
  }

  bool get _cardFormValid =>
      _cardNumber.text.replaceAll(' ', '').length >= 15 &&
      _expiry.text.contains('/') &&
      _cvc.text.length >= 3 &&
      _holder.text.trim().isNotEmpty;

  Future<void> _completePurchase() async {
    setState(() => _paying = true);
    final ok = await context.read<WalletService>().purchaseBlueCoins(amountMxn: widget.amountMxn);
    if (mounted) {
      setState(() => _paying = false);
      if (ok) {
        setState(() => _step = 3);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo completar el pago')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ProfileChromeLabel(),
            if (_step < 3)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Stripe pasarela de pagos',
                  style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.9), fontSize: 12),
                ),
              ),
            Expanded(child: _buildStep()),
            if (_step < 3) _buildBottomAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      0 => _buildCardForm(),
      1 => _buildMethodPicker(),
      2 => _buildSummary(),
      _ => _buildSuccess(),
    };
  }

  Widget _buildBlueBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.localBadge,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pago con monedas azules',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  '¿Deseas realizar tu pago con monedas azules?',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: _payWithBlue,
            onChanged: (v) => setState(() => _payWithBlue = v),
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.white38,
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionBanner() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => setState(() => _showTooltip = !_showTooltip),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.commissionOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.commissionOrange.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.commissionOrange, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Atención! Se cobrará el 15% de comisión en la compra de monedas azules.',
                    style: TextStyle(fontSize: 12, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showTooltip)
          Positioned(
            top: -36,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '\$100 MX de compra equivale a 90 monedas azules.',
                style: TextStyle(color: Colors.white, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCardForm() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBlueBanner(),
        const SizedBox(height: 12),
        _buildCommissionBanner(),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: 'card',
          decoration: InputDecoration(
            labelText: 'Método',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: const [
            DropdownMenuItem(value: 'card', child: Text('Tarjeta de crédito')),
            DropdownMenuItem(value: 'debit', child: Text('Tarjeta de débito')),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              _method = v;
              _isDebit = v == 'debit';
            });
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _cardNumber,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16)],
          onChanged: (_) => setState(() {}),
          decoration: _fieldDeco('Número de tarjeta'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _expiry,
                decoration: _fieldDeco('Fecha de expiración (MM/YY)'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _cvc,
                keyboardType: TextInputType.number,
                decoration: _fieldDeco('Código CVC'),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _holder,
          textCapitalization: TextCapitalization.characters,
          decoration: _fieldDeco('Nombre del titular de la tarjeta'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Text(
          'Total: \$${widget.amountMxn} MXN → $_coins monedas azules',
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  InputDecoration _fieldDeco(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _buildMethodPicker() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _step = 0)),
            const Text('Método de pago', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _TabChip(label: 'Crédito', selected: !_isDebit, onTap: () => setState(() => _isDebit = false)),
            const SizedBox(width: 8),
            _TabChip(label: 'Débito', selected: _isDebit, onTap: () => setState(() => _isDebit = true)),
          ],
        ),
        const SizedBox(height: 20),
        _MethodTile(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Paypal',
          selected: _method == 'paypal',
          onTap: () => setState(() => _method = 'paypal'),
        ),
        _MethodTile(
          icon: Icons.g_mobiledata,
          label: 'G Pay',
          selected: _method == 'gpay',
          onTap: () => setState(() => _method = 'gpay'),
        ),
        _MethodTile(
          icon: Icons.apple,
          label: 'Apple Pay',
          selected: _method == 'apple',
          onTap: () => setState(() => _method = 'apple'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => setState(() => _step = 0),
          icon: const Icon(Icons.add),
          label: const Text('Agregar cartera nueva'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        _TotalFooter(amount: widget.amountMxn),
      ],
    );
  }

  Widget _buildSummary() {
    final card = _cards[_cardIndex];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Pago', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton(onPressed: () => setState(() => _step = 1), child: const Text('Cambiar')),
          ],
        ),
        Row(
          children: [
            Icon(Icons.credit_card, size: 20, color: Colors.grey.shade700),
            const SizedBox(width: 6),
            Text('•••• ${card.last4}', style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 180,
          child: PageView.builder(
            itemCount: _cards.length,
            onPageChanged: (i) => setState(() => _cardIndex = i),
            itemBuilder: (context, i) {
              final c = _cards[i];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: c.color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.brand, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text(
                      _holder.text.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 8),
                    Text('•••• •••• •••• ${c.last4}', style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        _TotalFooter(amount: widget.amountMxn),
      ],
    );
  }

  Widget _buildSuccess() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
              const Text('Método de pago', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.proximity.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, size: 48, color: AppColors.proximity.withValues(alpha: 0.95)),
          ),
          const SizedBox(height: 24),
          const Text('Pago recibido', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Su orden ha sido enviada.\n+$_coins monedas azules acreditadas.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.stripePay,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              child: const Text('Continuar'),
            ),
          ),
          TextButton(
            onPressed: () => context.go('/profile'),
            child: const Text('Regresar al perfil'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    if (_step == 0) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: OutlinedButton.icon(
          onPressed: _cardFormValid ? () => setState(() => _step = 2) : null,
          icon: Icon(Icons.check_circle, color: AppColors.proximity.withValues(alpha: 0.9)),
          label: const Text('Continuar'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.proximity,
            side: const BorderSide(color: AppColors.navBar, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: FilledButton(
        onPressed: _paying ? null : _completePurchase,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.stripePay,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        child: _paying
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text('Pagar ahora'),
      ),
    );
  }
}

class _SavedCard {
  const _SavedCard({required this.label, required this.last4, required this.color, required this.brand});
  final String label;
  final String last4;
  final Color color;
  final String brand;
}

class _TabChip extends StatelessWidget {
  const _TabChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.navBar : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.navBar : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 28),
      title: Text(label),
      trailing: Radio<bool>(
        value: true,
        groupValue: selected,
        onChanged: (_) => onTap(),
      ),
      onTap: onTap,
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _TotalFooter extends StatelessWidget {
  const _TotalFooter({required this.amount});
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total a pagar', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          Text('\$$amount', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
