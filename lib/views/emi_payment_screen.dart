// lib/views/emi_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../controllers/job_card_controller.dart';
import '../models/job_card_model.dart';
import '../widgets/app_widgets.dart';
import '../widgets/main_scaffold.dart';
import 'package:intl/intl.dart';

class EmiPaymentScreen extends StatefulWidget {
  const EmiPaymentScreen({super.key});
  @override
  State<EmiPaymentScreen> createState() => _EmiPaymentScreenState();
}

class _EmiPaymentScreenState extends State<EmiPaymentScreen> {
  final _amountCtrl = TextEditingController();
  final _notesCtrl  = TextEditingController();
  String _mode = 'Cash';
  bool _adding = false;
  static const _modes = ['Cash', 'Card', 'UPI', 'NEFT/RTGS', 'Cheque', 'Other'];

  @override
  void dispose() { _amountCtrl.dispose(); _notesCtrl.dispose(); super.dispose(); }

  Future<void> _add() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) { showSnackBar(context, 'Enter valid amount', isError: true); return; }
    final ctrl = context.read<JobCardController>();
    final card = ctrl.activeJobCard;
    if (card == null) { showSnackBar(context, 'No active job card', isError: true); return; }
    if (amount > card.balanceDue + 0.01) {
      showSnackBar(context, 'Amount exceeds balance ${formatCurrency(card.balanceDue)}', isError: true); return;
    }
    setState(() => _adding = true);
    final ok = await ctrl.addPayment(card: card, amount: amount, paymentMode: _mode, notes: _notesCtrl.text.trim());
    setState(() => _adding = false);
    if (ok && mounted) {
      _amountCtrl.clear(); _notesCtrl.clear();
      final updated = ctrl.activeJobCard!;
      showSnackBar(context, updated.balanceDue <= 0 ? '✅ Bill fully paid!' : 'Payment added. Remaining: ${formatCurrency(updated.balanceDue)}');
    } else if (mounted) showSnackBar(context, ctrl.error ?? 'Failed', isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final card = context.watch<JobCardController>().activeJobCard;
    return MainScaffold(
      title: 'EMI Payments',
      showBack: true,
      body: card == null
          ? Center(child: PrimaryButton(label: 'Create Job Card', icon: Icons.add,
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.vehicleEntry)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Bill summary card
                AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('GRAND TOTAL', style: AppTextStyles.label),
                      Text(formatCurrency(card.grandTotal),
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
                    ]),
                    StatusBadge.paymentStatus(card.paymentStatus),
                  ]),
                  const SizedBox(height: 14),
                  // Progress bar
                  ClipRRect(borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: card.grandTotal > 0 ? (card.totalPaid / card.grandTotal).clamp(0, 1.0) : 0,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation(card.balanceDue <= 0 ? AppColors.success : AppColors.accent),
                      minHeight: 8,
                    )),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _MiniStat('Paid', formatCurrency(card.totalPaid), AppColors.success)),
                    const SizedBox(width: 8),
                    Expanded(child: _MiniStat('Balance Due', formatCurrency(card.balanceDue),
                        card.balanceDue > 0 ? AppColors.error : AppColors.success)),
                  ]),
                ])),
                const SizedBox(height: 16),

                // Add payment
                if (card.balanceDue > 0) ...[
                  AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SectionHeader(title: 'Add Payment'),
                    const SizedBox(height: 14),
                    // Amount
                    const Text('Amount', style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _amountCtrl,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                      decoration: InputDecoration(
                        prefixText: '₹ ', hintText: '0.00',
                        filled: true, fillColor: AppColors.surfaceElevated,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Quick fill
                    Row(children: [
                      _QuickBtn('Full', () => setState(() => _amountCtrl.text = card.balanceDue.toStringAsFixed(2))),
                      const SizedBox(width: 8),
                      _QuickBtn('Half', () => setState(() => _amountCtrl.text = (card.balanceDue/2).toStringAsFixed(2))),
                    ]),
                    const SizedBox(height: 14),
                    // Mode
                    const Text('Payment Mode', style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _modes.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) => GestureDetector(
                          onTap: () => setState(() => _mode = _modes[i]),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: _mode == _modes[i] ? AppColors.accent.withOpacity(0.15) : AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: _mode == _modes[i] ? AppColors.accent : AppColors.border),
                            ),
                            alignment: Alignment.center,
                            child: Text(_modes[i], style: TextStyle(
                              color: _mode == _modes[i] ? AppColors.accent : AppColors.textSecondary,
                              fontSize: 12, fontWeight: FontWeight.w600,
                            )),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(label: 'Notes (Optional)', hint: 'Transaction ID, cheque number...', controller: _notesCtrl),
                    const SizedBox(height: 16),
                    SizedBox(width: double.infinity,
                      child: PrimaryButton(label: 'Add Payment', icon: Icons.payments, isLoading: _adding, onPressed: _add)),
                  ])),
                  const SizedBox(height: 16),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: const Column(children: [
                      Icon(Icons.check_circle_rounded, color: AppColors.success, size: 40),
                      SizedBox(height: 8),
                      Text('Bill Fully Settled!', style: TextStyle(color: AppColors.success, fontSize: 16, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],

                // Payment timeline
                if (card.advance > 0 || card.payments.isNotEmpty) ...[
                  const SectionHeader(title: 'Payment History'),
                  const SizedBox(height: 12),
                  if (card.advance > 0)
                    _PaymentTile(date: card.entryDate, amount: card.advance, mode: 'Advance', notes: 'Advance at entry', index: 'A'),
                  ...card.payments.asMap().entries.map((e) => _PaymentTile(
                    date: e.value.date, amount: e.value.amount,
                    mode: e.value.paymentMode, notes: e.value.notes, index: '${e.key + 1}',
                  )),
                ],
                const SizedBox(height: 20),
              ]),
            ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value; final Color color;
  const _MiniStat(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
    ]),
  );
}

class _QuickBtn extends StatelessWidget {
  final String label; final VoidCallback onTap;
  const _QuickBtn(this.label, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Text(label, style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w700)),
    ),
  );
}

class _PaymentTile extends StatelessWidget {
  final DateTime date; final double amount; final String mode, notes, index;
  const _PaymentTile({required this.date, required this.amount, required this.mode, required this.notes, required this.index});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border)),
    child: Row(children: [
      Container(width: 30, height: 30,
        decoration: BoxDecoration(color: AppColors.success.withOpacity(0.15), borderRadius: BorderRadius.circular(15)),
        child: Center(child: Text(index, style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 11)))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(DateFormat('dd MMM yyyy, hh:mm a').format(date), style: AppTextStyles.caption),
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: AppColors.info.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(mode, style: const TextStyle(color: AppColors.info, fontSize: 10))),
          if (notes.isNotEmpty) ...[const SizedBox(width: 6),
            Expanded(child: Text(notes, style: AppTextStyles.caption, overflow: TextOverflow.ellipsis))],
        ]),
      ])),
      Text(formatCurrency(amount), style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 14)),
    ]),
  );
}
