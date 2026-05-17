// lib/widgets/app_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../models/job_card_model.dart';
import 'package:intl/intl.dart';

final _currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
final _dateFmt     = DateFormat('dd MMM yyyy');
final _timeFmt     = DateFormat('hh:mm a');

// ─── Formatters ───────────────────────────────────────────────────────────────
String formatCurrency(double v) => _currencyFmt.format(v);
String formatDate(DateTime d)   => _dateFmt.format(d);
String formatTime(DateTime d)   => _timeFmt.format(d);
String formatDuration(Duration? d) {
  if (d == null) return '—';
  return '${d.inHours}h ${d.inMinutes % 60}m';
}

// ─── Section Header ───────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(children: [
        Container(
          width: 3, height: 18,
          decoration: BoxDecoration(
            color: AppColors.accent, borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(title, style: AppTextStyles.heading3),
      ]),
      if (trailing != null) trailing!,
    ],
  );
}

// ─── App Card ─────────────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? borderColor;

  const AppCard({super.key, required this.child, this.padding, this.onTap, this.borderColor});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: borderColor ?? AppColors.border),
      ),
      child: child,
    ),
  );
}

// ─── App Text Field ───────────────────────────────────────────────────────────
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool required;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffix;
  final Widget? prefix;
  final bool readOnly;
  final VoidCallback? onTap;
  final void Function(String)? onChanged;
  final TextInputAction? textInputAction;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.required = false,
    this.maxLines = 1,
    this.inputFormatters,
    this.suffix,
    this.prefix,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Text(label, style: AppTextStyles.label),
        if (required)
          const Text(' *', style: TextStyle(color: AppColors.error, fontSize: 12)),
      ]),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
        textInputAction: textInputAction,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.caption,
          suffixIcon: suffix,
          prefixIcon: prefix,
          filled: true,
          fillColor: AppColors.surfaceElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ],
  );
}

// ─── Primary Button ───────────────────────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  const PrimaryButton({super.key, required this.label, this.onPressed, this.icon, this.isLoading = false});

  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: isLoading ? null : onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.buttonRadius)),
      elevation: 0,
    ),
    child: isLoading
        ? const SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 17), const SizedBox(width: 8)],
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
  );
}

// ─── Secondary Button ─────────────────────────────────────────────────────────
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const SecondaryButton({super.key, required this.label, this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.textPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.buttonRadius)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[Icon(icon, size: 17), const SizedBox(width: 8)],
      Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
    ]),
  );
}

// ─── Status Badge ─────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const StatusBadge({super.key, required this.label, required this.color});

  factory StatusBadge.jobStatus(JobStatus s) {
    final (l, c) = switch (s) {
      JobStatus.open        => ('Open',        AppColors.info),
      JobStatus.inProgress  => ('In Progress', AppColors.warning),
      JobStatus.completed   => ('Completed',   AppColors.success),
      JobStatus.delivered   => ('Delivered',   AppColors.success),
      JobStatus.cancelled   => ('Cancelled',   AppColors.error),
    };
    return StatusBadge(label: l, color: c);
  }

  factory StatusBadge.paymentStatus(PaymentStatus s) {
    final (l, c) = switch (s) {
      PaymentStatus.paid    => ('Paid',    AppColors.paid),
      PaymentStatus.partial => ('Partial', AppColors.partial),
      PaymentStatus.pending => ('Pending', AppColors.pending),
    };
    return StatusBadge(label: l, color: c);
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
  );
}

// ─── Info Row ─────────────────────────────────────────────────────────────────
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const InfoRow({super.key, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 120,
        child: Text(label, style: AppTextStyles.label),
      ),
      Expanded(
        child: Text(value.isEmpty ? '—' : value,
            style: AppTextStyles.body.copyWith(color: valueColor)),
      ),
    ]),
  );
}

// ─── Job Card List Tile ───────────────────────────────────────────────────────
class JobCardListTile extends StatelessWidget {
  final JobCardModel card;
  final VoidCallback? onTap;
  const JobCardListTile({super.key, required this.card, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPending = card.hasBalance;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isPending ? AppColors.error.withOpacity(0.05) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPending ? AppColors.error.withOpacity(0.4) : AppColors.border,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(card.roNumber, style: AppTextStyles.accent.copyWith(fontSize: 12)),
            Row(children: [
              StatusBadge.jobStatus(card.status),
              const SizedBox(width: 4),
              StatusBadge.paymentStatus(card.paymentStatus),
            ]),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(card.customerName,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${card.vehicleMake} ${card.vehicleModel}',
                  style: AppTextStyles.bodySecondary),
              Text(card.registrationNumber, style: AppTextStyles.monospace),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(formatCurrency(card.grandTotal),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
              if (isPending)
                Text('Due: ${formatCurrency(card.balanceDue)}',
                    style: const TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.access_time, size: 11, color: AppColors.textMuted),
            const SizedBox(width: 3),
            Text(formatDate(card.entryDate), style: AppTextStyles.caption),
            const Spacer(),
            const Icon(Icons.phone, size: 11, color: AppColors.textMuted),
            const SizedBox(width: 3),
            Text(card.contactNumber, style: AppTextStyles.caption),
          ]),
        ]),
      ),
    );
  }
}

// ─── Checklist Row ────────────────────────────────────────────────────────────
class ChecklistRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const ChecklistRow({super.key, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => onChanged(!value),
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 22, height: 22,
          decoration: BoxDecoration(
            color: value ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: value ? AppColors.accent : AppColors.border, width: 1.5),
          ),
          child: value ? const Icon(Icons.check, size: 14, color: Colors.black) : null,
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: AppTextStyles.body)),
      ]),
    ),
  );
}

// ─── Loading Overlay ──────────────────────────────────────────────────────────
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  const LoadingOverlay({super.key, required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) => Stack(children: [
    child,
    if (isLoading)
      Container(
        color: Colors.black.withOpacity(0.4),
        child: const Center(child: CircularProgressIndicator(color: AppColors.accent)),
      ),
  ]);
}

// ─── Snackbar Helper ──────────────────────────────────────────────────────────
void showSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 3),
    ),
  );
}

// ─── Confirm Dialog ───────────────────────────────────────────────────────────
Future<bool> showConfirmDialog(BuildContext context, {
  required String title, required String message,
  String confirmLabel = 'Confirm', bool isDestructive = false,
}) async {
  return await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(title, style: AppTextStyles.heading3),
      content: Text(message, style: AppTextStyles.bodySecondary),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDestructive ? AppColors.error : AppColors.accent,
            foregroundColor: isDestructive ? Colors.white : Colors.black,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  ) ?? false;
}

// ─── Uppercase formatter ──────────────────────────────────────────────────────
class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) =>
      n.copyWith(text: n.text.toUpperCase());
}
