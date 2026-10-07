import 'package:flutter/material.dart';

import '../auth_colors.dart';

class AuthUnderlineField extends StatefulWidget {
  const AuthUnderlineField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  @override
  State<AuthUnderlineField> createState() => _AuthUnderlineFieldState();
}

class _AuthUnderlineFieldState extends State<AuthUnderlineField> {
  String? _error;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  String? _validate(String? v) {
    final err = widget.validator?.call(v);
    setState(() => _error = err);
    return err;
  }

  @override
  Widget build(BuildContext context) {
    final showToggle = widget.obscureText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(color: AuthColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: showToggle && _obscure,
          style: const TextStyle(color: AuthColors.textPrimary, fontSize: 15),
          cursorColor: AuthColors.textPrimary,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onSubmitted,
          validator: _validate,
          onChanged: (_) {
            if (_error != null) _validate(widget.controller.text);
          },
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(color: AuthColors.textMuted, fontSize: 14),
            border: const UnderlineInputBorder(borderSide: BorderSide(color: AuthColors.underline)),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AuthColors.underline)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AuthColors.textPrimary, width: 1.5)),
            errorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AuthColors.error)),
            focusedErrorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AuthColors.error)),
            contentPadding: const EdgeInsets.only(bottom: 8),
            errorStyle: const TextStyle(height: 0, fontSize: 0),
            suffixIcon: showToggle
                ? IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AuthColors.textMuted,
                      size: 22,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AuthColors.errorBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AuthColors.error.withValues(alpha: 0.5)),
            ),
            child: Text(
              _error!,
              style: const TextStyle(color: AuthColors.error, fontSize: 12, height: 1.35),
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}
