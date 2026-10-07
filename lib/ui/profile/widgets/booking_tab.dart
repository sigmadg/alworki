import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/provider_demo_data.dart';
import '../../../models/quote_checkout_data.dart';
import '../../../theme/app_colors.dart';

class BookingTab extends StatefulWidget {
  const BookingTab({
    super.key,
    required this.isOwnProfile,
    required this.providerId,
    required this.providerName,
    this.verified = true,
    this.embeddedInScroll = false,
  });

  final bool isOwnProfile;
  final int providerId;
  final String providerName;
  final bool verified;
  final bool embeddedInScroll;

  @override
  State<BookingTab> createState() => _BookingTabState();
}

class _BookingTabState extends State<BookingTab> {
  int _step = 0;
  final _selectedServices = <int>{3};
  final _selectedMaterials = <int>{3, 4};
  DateTime? _selectedDate;
  String? _selectedTime;

  static final _timeSlots = _buildTimeSlots();

  static List<String> _buildTimeSlots() {
    final slots = <String>[];
    for (var h = 15; h <= 22; h++) {
      for (final m in [0, 30]) {
        if (h == 22 && m == 30) break;
        final hour12 = h > 12 ? h - 12 : h;
        final period = h >= 12 ? 'PM' : 'AM';
        final min = m == 0 ? '00' : '30';
        slots.add('$hour12:$min $period');
      }
    }
    return slots;
  }

  String get _actionLabel => switch (_step) {
        0 => 'Siguiente',
        1 => 'Cotizar',
        2 => 'Siguiente',
        _ => 'Cotizar',
      };

  Future<void> _next() async {
    if (widget.isOwnProfile) {
      _snack('Configura tu disponibilidad desde tu perfil');
      return;
    }
    if (_step == 0 && _selectedServices.isEmpty) {
      _snack('Selecciona al menos un servicio');
      return;
    }
    if (_step == 1 && _selectedMaterials.isEmpty) {
      _snack('Selecciona al menos un material');
      return;
    }
    if (_step == 2 && _selectedDate == null) {
      _snack('Elige una fecha');
      return;
    }
    if (_step < 3) {
      setState(() {
        _step++;
        if (_step == 3 && _selectedTime == null) {
          _selectedTime = widget.verified ? '6:30 PM' : null;
        }
      });
      return;
    }
    if (_selectedTime == null) {
      _snack('Elige un horario');
      return;
    }
    final serviceNames = ProviderDemoData.services
        .where((s) => _selectedServices.contains(s.id))
        .map((s) => s.name)
        .toList();
    final materialNames = ProviderDemoData.materials
        .where((m) => _selectedMaterials.contains(m.id))
        .map((m) => m.name)
        .toList();
    final date = _selectedDate!;
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    context.push(
      '/quote-checkout',
      extra: QuoteCheckoutData(
        providerId: widget.providerId,
        providerName: widget.providerName,
        services: serviceNames,
        materials: materialNames,
        date: dateStr,
        timeSlot: _selectedTime!,
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final stepContent = switch (_step) {
      0 => _SelectableList(
          items: ProviderDemoData.services,
          selected: _selectedServices,
          onToggle: (id) => setState(() {
            if (_selectedServices.contains(id)) {
              _selectedServices.remove(id);
            } else {
              _selectedServices.add(id);
            }
          }),
        ),
      1 => _SelectableList(
          items: ProviderDemoData.materials,
          selected: _selectedMaterials,
          onToggle: (id) => setState(() {
            if (_selectedMaterials.contains(id)) {
              _selectedMaterials.remove(id);
            } else {
              _selectedMaterials.add(id);
            }
          }),
        ),
      2 => _CalendarPicker(
          verified: widget.verified,
          selected: _selectedDate,
          onSelect: (d) => setState(() => _selectedDate = d),
        ),
      _ => _TimePicker(
          slots: _timeSlots,
          selected: _selectedTime,
          onSelect: (t) => setState(() => _selectedTime = t),
        ),
    };

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_step > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _step--),
              icon: const Icon(Icons.chevron_left, size: 20),
              label: const Text('Atrás'),
            ),
          ),
        Padding(padding: const EdgeInsets.all(16), child: stepContent),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _next,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.proximity,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: Text(_actionLabel),
            ),
          ),
        ),
      ],
    );

    if (widget.embeddedInScroll) return body;

    return Column(
      children: [
        if (_step > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _step--),
              icon: const Icon(Icons.chevron_left, size: 20),
              label: const Text('Atrás'),
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: stepContent,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _next,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.proximity,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: Text(_actionLabel),
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectableList extends StatelessWidget {
  const _SelectableList({
    required this.items,
    required this.selected,
    required this.onToggle,
  });

  final List<BookableItem> items;
  final Set<int> selected;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) {
        final isOn = selected.contains(item.id);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isOn ? AppColors.navBar.withValues(alpha: 0.3) : Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < item.rating ? Icons.star : Icons.star_border,
                    size: 18,
                    color: Colors.amber.shade700,
                  ),
                ),
              ),
              Checkbox(
                value: isOn,
                onChanged: (_) => onToggle(item.id),
                activeColor: AppColors.navBar,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CalendarPicker extends StatelessWidget {
  const _CalendarPicker({required this.verified, required this.selected, required this.onSelect});

  final bool verified;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelect;

  bool _isGreen(int day) => verified ? (day >= 16 && day <= 18) : (day >= 14 && day <= 17);
  bool _isRed(int day) => verified ? day == 15 : day == 13;
  bool _isGrey(int day) => day == 24 || day == 25 || day == 26;
  bool _isSelectable(int day) => _isGreen(day);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final month = DateTime(now.year, 12);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    const weekdays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final firstWeekday = DateTime(month.year, month.month, 1).weekday;
    final leading = firstWeekday - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Diciembre', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekdays.map((d) => Text(d, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))).toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: leading + daysInMonth,
          itemBuilder: (context, i) {
            if (i < leading) return const SizedBox.shrink();
            final day = i - leading + 1;
            final date = DateTime(month.year, month.month, day);
            final isSelected = selected?.day == day && selected?.month == 12;
            final selectable = _isSelectable(day);

            Color? bg;
            Color fg = AppColors.textPrimary;
            if (isSelected) {
              bg = AppColors.navBar;
              fg = Colors.white;
            } else if (_isRed(day)) {
              bg = Colors.red.shade100;
            } else if (_isGreen(day)) {
              bg = AppColors.proximity.withValues(alpha: 0.35);
            } else if (_isGrey(day)) {
              bg = Colors.grey.shade200;
              fg = AppColors.textSecondary;
            }

            return GestureDetector(
              onTap: selectable ? () => onSelect(date) : null,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? null
                      : Border.all(
                          color: _isGreen(day)
                              ? AppColors.proximity
                              : _isRed(day)
                                  ? Colors.red.shade300
                                  : Colors.grey.shade300,
                        ),
                ),
                child: Text(
                  '$day',
                  style: TextStyle(color: fg, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TimePicker extends StatelessWidget {
  const _TimePicker({required this.slots, required this.selected, required this.onSelect});

  final List<String> slots;
  final String? selected;
  final ValueChanged<String> onSelect;

  bool _filled(String slot) {
    const filled = {'3:00 PM', '3:30 PM', '4:00 PM', '4:30 PM', '5:00 PM'};
    return filled.contains(slot);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Elige un horario', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            Icon(Icons.chevron_right, color: AppColors.textSecondary.withValues(alpha: 0.8)),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) {
            final isSelected = selected == slot;
            final filled = _filled(slot);
            return GestureDetector(
              onTap: () => onSelect(slot),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.localBadge
                      : filled
                          ? AppColors.localBadge.withValues(alpha: 0.22)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.localBadge,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  slot,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.localBadge,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
