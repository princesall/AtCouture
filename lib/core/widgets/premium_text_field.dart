import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class PremiumTextField extends StatefulWidget {
  const PremiumTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.enabled = true,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;
  final bool enabled;
  final bool autofocus;

  @override
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<PremiumTextField> {
  bool _obscured = true;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final isPassword = widget.obscureText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!.toUpperCase(),
            style: AppTextStyles.labelCaps.copyWith(
              color: _focused ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Focus(
          onFocusChange: (focused) => setState(() => _focused = focused),
          child: TextFormField(
            controller: widget.controller,
            obscureText: isPassword && _obscured,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            validator: widget.validator,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            maxLines: isPassword ? 1 : widget.maxLines,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurface),
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      size: 20,
                      color: _focused
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    )
                  : null,
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscured
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: AppColors.onSurfaceVariant,
                      ),
                      onPressed: () => setState(() => _obscured = !_obscured),
                    )
                  : widget.suffixIcon,
              filled: true,
              fillColor: _focused
                  ? AppColors.surfaceContainerLowest
                  : AppColors.surfaceContainerLow,
            ),
          ),
        ),
      ],
    );
  }
}

class PremiumPhoneField extends StatelessWidget {
  const PremiumPhoneField({
    super.key,
    required this.controller,
    this.validator,
  });

  final TextEditingController controller;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return PremiumTextField(
      controller: controller,
      label: 'Téléphone',
      hint: '70 00 00 00',
      prefixIcon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      validator: validator,
      onChanged: (_) {},
    );
  }
}
