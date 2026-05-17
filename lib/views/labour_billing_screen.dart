// lib/views/labour_billing_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';
import '../controllers/job_card_controller.dart';
import '../models/job_card_model.dart';
import '../widgets/app_widgets.dart';
import '../widgets/main_scaffold.dart';

class LabourBillingScreen extends StatefulWidget {
  const LabourBillingScreen({super.key});
  @override
  State<LabourBillingScreen> createState() => _LabourBillingScreenState();
}

class _LabourBillingScreenState extends State<LabourBillingScreen>
    with SingleTickerProviderStateMixin {
  final _uuid = const Uuid();
  late TabController _tab;
  List<_Row> _labour = [];
  List<_Row> _sublet = [];
  final _spareCtrl   = TextEditingController();
  final _advanceCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    final card = context.read<JobCardController>().activeJobCard;
    if (card != null) {
      _labour = card.labourItems.isEmpty ? [_newRow()] : card.labourItems.map(_fromItem).toList();
      _sublet = card.subletItems.isEmpty ? [_newRow()] : card.subletItems.map(_fromItem).toList();
      _spareCtrl.text   = card.spareParts > 0 ? card.spareParts.toStringAsFixed(2) : '';
      _advanceCtrl.text = card.advance    > 0 ? card.advance.toStringAsFixed(2)    : '';
    } else {
      _labour = [_newRow()];
      _sublet = [_newRow()];
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    _spareCtrl.dispose();
    _advanceCtrl.dispose();
    for (final r in [..._labour, ..._sublet]) r.dispose();
    super.dispose();
  }

  _Row _newRow()              => _Row(id: _uuid.v4(), d: TextEditingController(), a: TextEditingController());
  _Row _fromItem(BillingItem i) => _Row(id: i.id,
    d: TextEditingController(text: i.description),
    a: TextEditingController(text: i.amount > 0 ? i.amount.toStringAsFixed(2) : ''));

  double _sum(List<_Row> rows) => rows.map((r) => double.tryParse(r.a.text) ?? 0).fold(0, (a, b) => a + b);
  double get _labourTotal   => _sum(_labour);
  double get _gst           => _labourTotal * 0.18;
  double get _subletTotal   => _sum(_sublet);
  double get _spare         => double.tryParse(_spareCtrl.text)   ?? 0;
  double get _advance       => double.tryParse(_advanceCtrl.text) ?? 0;
  double get _grandTotal    => _spare + _labourTotal + _gst + _subletTotal;
  double get _balanceDue    => _grandTotal - _advance -
      (context.read<JobCardController>().activeJobCard?.payments
        .fold<double>(0, (s, p) => s + p.amount) ?? 0);

  List<BillingItem> _items(List<_Row> rows) => rows
      .map((r) => BillingItem(id: r.id, description: r.d.text.trim(), amount: double.tryParse(r.a.text) ?? 0))
      .where((i) => i.description.isNotEmpty || i.amount > 0).toList();

  Future<void> _save({bool goNext = false}) async {
    final ctrl = context.read<JobCardController>();
    final card = ctrl.activeJobCard;
    if (card == null) { showSnackBar(context, 'No active job card', isError: true); return; }
    setState(() => _saving = true);
    final ok = await ctrl.updateBilling(
      card: card, labourItems: _items(_labour), subletItems: _items(_sublet),
      spareParts: _spare, advance: _advance);
    setState(() => _saving = false);
    if (ok && mounted) {
      if (goNext) Navigator.pushReplacementNamed(context, AppRoutes.emiPayment);
      else showSnackBar(context, 'Billing saved ✓');
    } else if (mounted) showSnackBar(context, ctrl.error ?? 'Failed', isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final card = context.watch<JobCardController>().activeJobCard;
    return MainScaffold(
      title: 'Labour & Billing',
      showBack: true,
      body: card == null
          ? Center(child: PrimaryButton(label: 'Create Job Card', icon: Icons.add,
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.vehicleEntry)))
          : Column(children: [
              // Tabs
              Container(
                color: AppColors.surface,
                child: TabBar(
                  controller: _tab,
                  labelColor: AppColors.accent,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.accent,
                  tabs: const [
                    Tab(text: 'Labour'),
                    Tab(text: 'Sublet'),
                    Tab(text: 'Summary'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(controller: _tab, children: [
                  _BillingTab(rows: _labour, label: 'Labour',
                      total: _labourTotal, gst: _gst,
                      onAdd: () => setState(() => _labour.add(_newRow())),
                      onRemove: (i) { if (_labour.length > 1) { _labour[i].dispose(); setState(() => _labour.removeAt(i)); } },
                      onChanged: () => setState(() {})),
                  _BillingTab(rows: _sublet, label: 'Sublet',
                      total: _subletTotal,
                      onAdd: () => setState(() => _sublet.add(_newRow())),
                      onRemove: (i) { if (_sublet.length > 1) { _sublet[i].dispose(); setState(() => _sublet.removeAt(i)); } },
                      onChanged: () => setState(() {})),
                  _SummaryTab(
                    labourTotal: _labourTotal, gst: _gst,
                    subletTotal: _subletTotal, spare: _spare, grandTotal: _grandTotal,
                    advance: _advance, balance: _balanceDue,
                    spareCtrl: _spareCtrl, advanceCtrl: _advanceCtrl,
                    onChanged: () => setState(() {}),
                  ),
                ]),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.border))),
                child: Row(children: [
                  Expanded(child: SecondaryButton(label: 'Save', icon: Icons.save,
                      onPressed: _saving ? null : () => _save())),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: PrimaryButton(label: 'Next →',
                      isLoading: _saving, onPressed: () => _save(goNext: true))),
                ]),
              ),
            ]),
    );
  }
}

class _Row { final String id; final TextEditingController d, a;
  _Row({required this.id, required this.d, required this.a});
  void dispose() { d.dispose(); a.dispose(); } }

class _BillingTab extends StatelessWidget {
  final List<_Row> rows;
  final String label;
  final double total;
  final double? gst;
  final VoidCallback onAdd, onChanged;
  final ValueChanged<int> onRemove;
  const _BillingTab({required this.rows, required this.label, required this.total,
    this.gst, required this.onAdd, required this.onRemove, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Total display
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.accent.withOpacity(0.3)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('$label Total', style: AppTextStyles.label),
            Text(formatCurrency(total),
                style: const TextStyle(color: AppColors.accent, fontSize: 18, fontWeight: FontWeight.w800)),
          ]),
        ),
        if (gst != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('GST @ 18%', style: AppTextStyles.bodySecondary),
              Text(formatCurrency(gst!), style: AppTextStyles.body),
            ]),
          ),
        ],
        const SizedBox(height: 14),
        // Rows
        ...List.generate(rows.length, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Container(width: 24, height: 24, decoration: BoxDecoration(
                color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text('${i+1}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)))),
            const SizedBox(width: 8),
            Expanded(flex: 3, child: TextField(
              controller: rows[i].d, style: AppTextStyles.body,
              textInputAction: TextInputAction.next,
              onChanged: (_) => onChanged(),
              decoration: _deco('Description...'),
            )),
            const SizedBox(width: 8),
            SizedBox(width: 90, child: TextField(
              controller: rows[i].a, style: AppTextStyles.body, textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
              onChanged: (_) => onChanged(),
              decoration: _deco('0.00'),
            )),
            const SizedBox(width: 4),
            if (rows.length > 1)
              IconButton(onPressed: () => onRemove(i),
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 18),
                padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          ]),
        )),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 16),
          label: Text('Add $label Item'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accent,
            side: const BorderSide(color: AppColors.accent),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  InputDecoration _deco(String hint) => InputDecoration(
    hintText: hint, hintStyle: AppTextStyles.caption,
    filled: true, fillColor: AppColors.surfaceElevated,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  );
}

class _SummaryTab extends StatelessWidget {
  final double labourTotal, gst, subletTotal, spare, grandTotal, advance, balance;
  final TextEditingController spareCtrl, advanceCtrl;
  final VoidCallback onChanged;
  const _SummaryTab({required this.labourTotal, required this.gst, required this.subletTotal,
    required this.spare, required this.grandTotal, required this.advance, required this.balance,
    required this.spareCtrl, required this.advanceCtrl, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Spare parts input
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Spare Parts Total', style: AppTextStyles.label),
          const SizedBox(height: 8),
          TextField(
            controller: spareCtrl, onChanged: (_) => onChanged(),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
            decoration: InputDecoration(
              prefixText: '₹ ', prefixStyle: AppTextStyles.bodySecondary,
              hintText: '0.00', hintStyle: AppTextStyles.caption,
              filled: true, fillColor: AppColors.surfaceElevated,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ])),
        const SizedBox(height: 14),
        // Billing breakdown
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionHeader(title: 'Bill Summary'),
          const SizedBox(height: 14),
          _SRow('Spare Parts', spare),
          _SRow('Labour', labourTotal),
          _SRow('  GST (18%)', gst, isIndented: true),
          _SRow('Sublet', subletTotal),
          const Divider(color: AppColors.border, height: 20),
          _SRow('Grand Total', grandTotal, isBold: true),
        ])),
        const SizedBox(height: 14),
        // Advance input
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Advance Paid', style: AppTextStyles.label),
          const SizedBox(height: 8),
          TextField(
            controller: advanceCtrl, onChanged: (_) => onChanged(),
            style: AppTextStyles.body,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
            decoration: InputDecoration(
              prefixText: '₹ ', hintText: '0.00', hintStyle: AppTextStyles.caption,
              filled: true, fillColor: AppColors.surfaceElevated,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Balance Due', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            Text(formatCurrency(balance), style: TextStyle(
              color: balance > 0 ? AppColors.error : AppColors.success,
              fontSize: 20, fontWeight: FontWeight.w800,
            )),
          ]),
          if (balance > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.2))),
              child: const Row(children: [
                Icon(Icons.info_outline, color: AppColors.error, size: 14),
                SizedBox(width: 8),
                Expanded(child: Text('EMI payment tracking on next screen.',
                    style: TextStyle(color: AppColors.error, fontSize: 12))),
              ]),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.08), borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withOpacity(0.2))),
              child: const Row(children: [
                Icon(Icons.check_circle_outline, color: AppColors.success, size: 14),
                SizedBox(width: 8),
                Text('Fully paid!', style: TextStyle(color: AppColors.success, fontSize: 12)),
              ]),
            ),
          ],
        ])),
        const SizedBox(height: 20),
      ]),
    );
  }
}

class _SRow extends StatelessWidget {
  final String label; final double amount; final bool isBold, isIndented;
  const _SRow(this.label, this.amount, {this.isBold = false, this.isIndented = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: isIndented ? 12 : 0, bottom: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: isBold ? const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)
          : AppTextStyles.bodySecondary),
      Text(formatCurrency(amount), style: isBold
          ? const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)
          : AppTextStyles.body),
    ]),
  );
}
