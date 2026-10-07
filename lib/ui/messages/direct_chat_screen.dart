import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/quote_checkout_data.dart';
import '../../services/social_service.dart';
import '../../theme/app_colors.dart';
import '../profile/widgets/review_action_flows.dart';
import '../widgets/alworki_image.dart';

enum _ChatPhase { chatting, quotePending, schedulingDate, schedulingTime, done }

/// Chat 1:1 con negociación de precio y agenda (Figma — James).
class DirectChatScreen extends StatefulWidget {
  const DirectChatScreen({super.key, required this.threadId});

  final int threadId;

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  ChatPreview? _thread;
  List<ChatMessage> _messages = [];
  bool _loading = true;
  _ChatPhase _phase = _ChatPhase.chatting;
  bool _quoteAccepted = false;
  bool _dateEnabled = true;
  int _monthIndex = 3;
  int _dayIndex = 14;
  int _yearIndex = 2;
  int _hourIndex = 2;
  int _minuteIndex = 1;
  int _ampmIndex = 1;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  String _draftQuote = '2800';

  static const _months = ['August', 'September', 'October', 'November', 'December'];
  static final _days = List<String>.generate(31, (i) => '${i + 1}');
  static const _years = ['1993', '1994', '1995', '1996', '1997'];
  static const _hours = ['9', '10', '11', '12', '1'];
  static const _minutes = ['56', '57', '58', '59', '00'];
  static const _ampm = ['AM', 'PM'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await context.read<SocialService>().loadThread(widget.threadId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (data != null) {
        _thread = data.thread;
        _messages = data.messages;
        final hasQuote = _messages.any((m) => m.type == 'quote');
        _phase = hasQuote ? _ChatPhase.quotePending : _ChatPhase.chatting;
      }
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    setState(() {
      _messages = [
        ..._messages,
        ChatMessage(id: _messages.length + 100, sender: 'me', type: 'text', body: text),
      ];
    });
    _scrollToEnd();
    await context.read<SocialService>().sendMessage(widget.threadId, text);
  }

  void _acceptQuote() {
    setState(() {
      _quoteAccepted = true;
      _phase = _ChatPhase.schedulingDate;
      _messages = [
        ..._messages,
        const ChatMessage(id: 900, sender: 'system', type: 'text', body: 'Cotización aceptada'),
      ];
    });
    _scrollToEnd();
  }

  Future<void> _sendQuote() async {
    if (_draftQuote.trim().isEmpty) return;
    final msg = await context.read<SocialService>().sendQuoteMessage(widget.threadId, _draftQuote.trim());
    if (!mounted) return;
    if (msg != null) {
      setState(() => _messages = [..._messages, msg]);
      _scrollToEnd();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cotización enviada')),
      );
    }
  }

  void _cancelQuote() {
    setState(() {
      _phase = _ChatPhase.chatting;
      _draftQuote = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cotización cancelada')),
    );
  }

  void _addMoreSchedules() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selecciona otro horario disponible')),
    );
  }

  void _confirmDate() {
    setState(() => _phase = _ChatPhase.schedulingTime);
    _scrollToEnd();
  }

  void _confirmTime() {
    setState(() => _phase = _ChatPhase.done);
    _scrollToEnd();
    final name = _thread?.name ?? 'Proveedor';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cita agendada con $name')),
    );
  }

  void _goToBooking() {
    context.push(
      '/quote-checkout',
      extra: QuoteCheckoutData(
        providerId: _thread?.peerId ?? 2,
        providerName: _thread?.name ?? 'James',
        services: const ['Mesa de madera'],
        materials: const ['Mármol'],
        date: '2025-12-17',
        timeSlot: '${_hours[_hourIndex]}:${_minutes[_minuteIndex]} ${_ampm[_ampmIndex]}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final thread = _thread;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: thread == null
            ? const Text('Chat')
            : Row(
                children: [
                  AlworkiAvatar(avatarKey: thread.avatarKey, radius: 18),
                  const SizedBox(width: 10),
                  Text(thread.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => showReportProblemFlow(context, providerId: thread?.peerId ?? 10),
            child: const Text('Reportar', style: TextStyle(color: AppColors.reportRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: const Color(0xFF5D4037).withValues(alpha: 0.85),
                  child: const Text(
                    'Ten cuidado al compartir información personal. Protege tu seguridad.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 12, height: 1.35),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    children: [
                      ..._messages.map(_buildMessage),
                      if (_phase == _ChatPhase.quotePending) _buildQuoteActions(),
                      if (_phase == _ChatPhase.schedulingDate) _buildDatePicker(),
                      if (_phase == _ChatPhase.schedulingTime) _buildTimePicker(),
                      if (_phase == _ChatPhase.done) _buildDoneActions(),
                    ],
                  ),
                ),
                if (_phase == _ChatPhase.chatting || _phase == _ChatPhase.quotePending)
                  _buildInputBar(),
              ],
            ),
    );
  }

  Widget _buildMessage(ChatMessage m) {
    if (m.type == 'contact_request' || (m.sender == 'system' && m.type != 'text')) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.navBar,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(m.body, style: const TextStyle(color: Colors.white, height: 1.35)),
      );
    }
    if (m.type == 'quote') {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.proximity.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.proximity.withValues(alpha: 0.5)),
          ),
          child: Text('\$$_draftQuote MX', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      );
    }
    final isMe = m.sender == 'me';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF424242) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          m.body,
          style: TextStyle(color: isMe ? Colors.white : AppColors.textPrimary, height: 1.35),
        ),
      ),
    );
  }

  Widget _buildQuoteActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.proximity.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('\$$_draftQuote MX', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => _draftQuote = '')),
            FilledButton(
              onPressed: _draftQuote.trim().isEmpty ? null : _sendQuote,
              style: FilledButton.styleFrom(backgroundColor: AppColors.navBar),
              child: const Text('Enviar'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _acceptQuote,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.reportRed,
                  side: const BorderSide(color: AppColors.reportRed),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Aceptar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _cancelQuote,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.reportRed,
                  side: const BorderSide(color: AppColors.reportRed),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Cancelar'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_quoteAccepted)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.navBar,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('Cotización aceptada', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        const Text('Agenda tu disponibilidad', style: TextStyle(color: AppColors.trustButton, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.proximity.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Fecha de disponibilidad', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Switch(
                    value: _dateEnabled,
                    onChanged: (v) => setState(() => _dateEnabled = v),
                    activeThumbColor: AppColors.localBadge,
                  ),
                ],
              ),
              const Text('Selecciona las fechas disponibles', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              SizedBox(
                height: 140,
                child: Row(
                  children: [
                    Expanded(child: _CupertinoColumn(items: _months, index: _monthIndex, onChanged: (i) => setState(() => _monthIndex = i))),
                    Expanded(child: _CupertinoColumn(items: _days, index: _dayIndex, onChanged: (i) => setState(() => _dayIndex = i))),
                    Expanded(child: _CupertinoColumn(items: _years, index: _yearIndex, onChanged: (i) => setState(() => _yearIndex = i))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _dateEnabled ? _confirmDate : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.localBadge,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: const Text('Continuar'),
        ),
      ],
    );
  }

  Widget _buildTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.proximity.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.proximity, size: 20),
              SizedBox(width: 8),
              Text('Hora de disponibilidad!', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: Row(
            children: [
              Expanded(child: _CupertinoColumn(items: _hours, index: _hourIndex, onChanged: (i) => setState(() => _hourIndex = i))),
              Expanded(child: _CupertinoColumn(items: _minutes, index: _minuteIndex, onChanged: (i) => setState(() => _minuteIndex = i))),
              Expanded(child: _CupertinoColumn(items: _ampm, index: _ampmIndex, onChanged: (i) => setState(() => _ampmIndex = i))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ScheduleOption(question: '¿Deseas agregar más horarios?', onYes: _addMoreSchedules, onNo: _confirmTime),
        const SizedBox(height: 8),
        _ScheduleOption(question: '¿Deseas agregar más fechas?', onYes: () => setState(() => _phase = _ChatPhase.schedulingDate), onNo: _confirmTime),
      ],
    );
  }

  Widget _buildDoneActions() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: FilledButton(
        onPressed: _goToBooking,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navBar,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: const Text('Contratar servicio'),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                decoration: InputDecoration(
                  hintText: 'Enviar mensaje',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _send,
              icon: const Icon(Icons.send, color: AppColors.fabStart),
            ),
          ],
        ),
      ),
    );
  }
}

class _CupertinoColumn extends StatelessWidget {
  const _CupertinoColumn({required this.items, required this.index, required this.onChanged});

  final List<String> items;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return CupertinoPicker(
      scrollController: FixedExtentScrollController(initialItem: index),
      itemExtent: 36,
      onSelectedItemChanged: onChanged,
      children: items.map((e) => Center(child: Text(e))).toList(),
    );
  }
}

class _ScheduleOption extends StatelessWidget {
  const _ScheduleOption({required this.question, required this.onYes, required this.onNo});

  final String question;
  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.proximity.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(child: Text(question, style: const TextStyle(fontSize: 13))),
          TextButton(onPressed: onYes, child: const Text('Si')),
          TextButton(onPressed: onNo, child: const Text('No')),
        ],
      ),
    );
  }
}
