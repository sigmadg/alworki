import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/service_order.dart';
import '../../services/order_service.dart';
import '../../services/social_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/social_navigation.dart';
import '../widgets/alworki_image.dart';
import '../widgets/app_bottom_bar.dart';

/// Finalización del servicio — Actividad, Detalles, Requisitos, Entrega (Figma).
class ServiceCompletionScreen extends StatefulWidget {
  const ServiceCompletionScreen({
    super.key,
    required this.tracking,
    this.initialTab = 0,
  });

  final String tracking;
  final int initialTab;

  @override
  State<ServiceCompletionScreen> createState() => _ServiceCompletionScreenState();
}

class _ServiceCompletionScreenState extends State<ServiceCompletionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  ServiceOrder? _order;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final order = await context.read<OrderService>().fetchOrder(widget.tracking);
    if (mounted) {
      setState(() {
        _order = order;
        _loading = false;
      });
    }
  }

  void _goTab(String? tabName) {
    final index = switch (tabName) {
      'detalles' => 1,
      'requisitos' => 2,
      'entrega' => 3,
      _ => 0,
    };
    _tabs.animateTo(index);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<SocialService>().unreadMessages;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OrderHeader(tracking: widget.tracking),
            _OrderTabBar(controller: _tabs),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _order == null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('No se encontró la orden'),
                              const SizedBox(height: 12),
                              TextButton(onPressed: _load, child: const Text('Reintentar')),
                            ],
                          ),
                        )
                      : TabBarView(
                          controller: _tabs,
                          children: [
                            _ActivityTab(order: _order!, onLinkTap: _goTab),
                            _DetailsTab(order: _order!),
                            _RequirementsTab(order: _order!),
                            _DeliveryTab(order: _order!, onSubmitted: _load),
                          ],
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomBar(
        currentIndex: 0,
        messageBadge: unread,
        onTap: (i) {
          switch (i) {
            case 0:
              context.go('/home');
            case 1:
              context.go('/categories');
            case 2:
              context.go('/profile');
            case 3:
              context.go('/messages');
          }
        },
        onFabTap: () => context.push('/create-post'),
      ),
    );
  }
}

class _OrderHeader extends StatelessWidget {
  const _OrderHeader({required this.tracking});

  final String tracking;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('Inicio', style: TextStyle(color: AppColors.commentBlue)),
          ),
          Expanded(
            child: Text(
              'Orden # $tracking',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}

class _OrderTabBar extends StatelessWidget {
  const _OrderTabBar({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: AppColors.navBar,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.navBar,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(text: 'Actividad'),
          Tab(text: 'Detalles'),
          Tab(text: 'Requisitos'),
          Tab(text: 'Entrega'),
        ],
      ),
    );
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab({required this.order, required this.onLinkTap});

  final ServiceOrder order;
  final ValueChanged<String?> onLinkTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: order.activities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, i) {
        final item = order.activities[i];
        return _TimelineTile(item: item, onLinkTap: onLinkTap);
      },
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.item, required this.onLinkTap});

  final OrderActivity item;
  final ValueChanged<String?> onLinkTap;

  Color get _iconColor => switch (item.icon) {
        'pink' => AppColors.fabStart,
        'yellow' => const Color(0xFFF1C40F),
        'blue' => AppColors.localBadge,
        'green' => AppColors.proximity,
        _ => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              _ActivityIcon(item: item, color: _iconColor),
              Expanded(
                child: Container(width: 2, color: Colors.grey.shade300),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(item.timestamp, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  if (item.linkLabel != null)
                    GestureDetector(
                      onTap: () => onLinkTap(item.linkTab),
                      child: Text(
                        item.linkLabel!,
                        style: const TextStyle(color: AppColors.commentBlue, fontSize: 12),
                      ),
                    ),
                  if (item.rating != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            Icons.star,
                            size: 14,
                            color: i < item.rating!.round() ? Colors.amber : Colors.grey.shade300,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('${item.rating!.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                  if (item.text != null && item.text!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(item.text!, style: const TextStyle(fontSize: 13, height: 1.35)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityIcon extends StatelessWidget {
  const _ActivityIcon({required this.item, required this.color});

  final OrderActivity item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (item.icon == 'avatar' && item.avatar != null) {
      return AlworkiAvatar(avatarKey: item.avatar!, radius: 14);
    }
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
      child: Icon(Icons.circle, size: 12, color: color),
    );
  }
}

class _DetailsTab extends StatelessWidget {
  const _DetailsTab({required this.order});

  final ServiceOrder order;

  String _formatDate(String? iso, String timeSlot) {
    if (iso == null || iso.isEmpty) return timeSlot;
    final parts = iso.split('-');
    if (parts.length != 3) return '$iso $timeSlot';
    final months = [
      '',
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    final m = int.tryParse(parts[1]) ?? 1;
    final d = int.tryParse(parts[2]) ?? 1;
    return '$d de ${months[m.clamp(1, 12)]} a las $timeSlot';
  }

  int _durationDays() {
    if (order.orderStartDate == null || order.deliveryDate == null) return 3;
    try {
      final start = DateTime.parse(order.orderStartDate!);
      final end = DateTime.parse(order.deliveryDate!);
      return end.difference(start).inDays.abs().clamp(1, 99);
    } catch (_) {
      return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(order.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          _formatDate(order.deliveryDate, order.timeSlot),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        _DetailRow(label: 'Inicio del pedido', value: _formatDate(order.orderStartDate, order.timeSlot)),
        _DetailRow(label: 'Entrega del pedido', value: _formatDate(order.deliveryDate, order.timeSlot)),
        _DetailRow(label: 'Duración total', value: '${_durationDays()} días'),
        const SizedBox(height: 20),
        const Text('Desglose', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...order.lineItems.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(child: Text(item.label)),
                Text('MX\$ ${item.amount}', style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
        const Divider(height: 28),
        Row(
          children: [
            const Expanded(
              child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Text(
              'AL\$ ${order.totalAl}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.navBar),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }
}

class _RequirementsTab extends StatelessWidget {
  const _RequirementsTab({required this.order});

  final ServiceOrder order;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...order.requirements.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.question, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(r.answer, style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.navBar.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'La información proporcionada es precisa. Cualquier cambio puede requerir aprobación del vendedor y costos adicionales.',
            style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _DeliveryTab extends StatefulWidget {
  const _DeliveryTab({required this.order, required this.onSubmitted});

  final ServiceOrder order;
  final VoidCallback onSubmitted;

  @override
  State<_DeliveryTab> createState() => _DeliveryTabState();
}

class _DeliveryTabState extends State<_DeliveryTab> {
  final _message = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_message.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un mensaje de entrega')),
      );
      return;
    }
    setState(() => _submitting = true);
    final result = await context.read<OrderService>().submitDelivery(
          tracking: widget.order.trackingNumber,
          message: _message.text.trim(),
        );
    if (mounted) {
      setState(() => _submitting = false);
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entrega enviada')),
        );
        widget.onSubmitted();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.order.needsDelivery) {
      return _DeliveryForm(
        controller: _message,
        submitting: _submitting,
        onSubmit: _submit,
      );
    }
    final delivery = widget.order.delivery;
    if (delivery == null) {
      return const Center(child: Text('Aún no hay entrega registrada'));
    }
    return _DeliveryView(
      delivery: delivery,
      providerId: widget.order.providerId,
      providerName: widget.order.providerName,
    );
  }
}

class _DeliveryView extends StatelessWidget {
  const _DeliveryView({
    required this.delivery,
    required this.providerId,
    required this.providerName,
  });

  final OrderDelivery delivery;
  final int providerId;
  final String providerName;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Entrega ${delivery.number}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AlworkiAvatar(avatarKey: delivery.providerAvatar, radius: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(delivery.providerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(delivery.message, style: const TextStyle(height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AlworkiImage(
                imageKey: delivery.image,
                height: 140,
                width: double.infinity,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => context.push(
                      '/user/$providerId?name=${Uri.encodeComponent(providerName)}',
                    ),
                    child: const Text('Contacto'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => openChatWithPeer(
                      context,
                      peerId: providerId,
                      name: providerName,
                      avatarKey: delivery.providerAvatar,
                    ),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.localBadge),
                    child: const Text('Mensaje'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeliveryForm extends StatefulWidget {
  const _DeliveryForm({
    required this.controller,
    required this.submitting,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  State<_DeliveryForm> createState() => _DeliveryFormState();
}

class _DeliveryFormState extends State<_DeliveryForm> {
  String? _evidenceName;

  Future<void> _pickEvidence() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    if (file != null) {
      setState(() => _evidenceName = file.name);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evidencia adjuntada')),
      );
    }
  }

  void _saveDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Borrador guardado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: widget.controller,
          maxLines: 8,
          maxLength: 5000,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Mensaje de entrega al cliente...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            counterText: 'Usado ${widget.controller.text.length} / 5000',
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickEvidence,
          icon: const Icon(Icons.cloud_upload_outlined),
          label: Text(_evidenceName ?? 'Subir evidencia'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.submitting ? null : _saveDraft,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: const Text('Guardar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: widget.submitting ? null : widget.onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.localBadge,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: widget.submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Enviar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
