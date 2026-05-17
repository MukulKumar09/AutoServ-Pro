// lib/views/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../controllers/job_card_controller.dart';
import '../models/job_card_model.dart';
import '../widgets/app_widgets.dart';
import '../widgets/main_scaffold.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int _year  = DateTime.now().year;
  int _month = DateTime.now().month;
  bool _loading = false;
  Map<String, double> _monthlyRevenue = {};

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _monthlyRevenue = await context.read<JobCardController>().getMonthlyRevenue(_year);
    setState(() => _loading = false);
  }

  List<JobCardModel> get _all   => context.read<JobCardController>().allJobCards;
  List<JobCardModel> get _yearly => _all.where((c) => c.entryDate.year == _year).toList();
  List<JobCardModel> get _monthly => _yearly.where((c) => c.entryDate.month == _month).toList();
  List<JobCardModel> get _pending => _all.where((c) => c.hasBalance).toList();

  double get _totalRevenue   => _yearly.fold(0, (s, c) => s + c.grandTotal);
  double get _totalCollected => _yearly.fold(0, (s, c) => s + c.totalPaid);
  double get _totalPending   => _yearly.fold(0, (s, c) => s + c.balanceDue);

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Reports',
      showBack: true,
      actions: [
        // Year selector
        GestureDetector(
          onTap: _showYearPicker,
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: Row(children: [
              Text('$_year', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, color: AppColors.accent, size: 18),
            ]),
          ),
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : Column(children: [
              // Summary strip
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(children: [
                  _Strip('Jobs', '${_yearly.length}', AppColors.info),
                  _vd(),
                  _Strip('Revenue', _short(_totalRevenue), AppColors.accent),
                  _vd(),
                  _Strip('Collected', _short(_totalCollected), AppColors.success),
                  _vd(),
                  _Strip('Pending', _short(_totalPending), AppColors.error),
                ]),
              ),
              // Tabs
              Container(
                color: AppColors.surface,
                child: TabBar(
                  controller: _tab,
                  labelColor: AppColors.accent,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.accent,
                  tabs: const [
                    Tab(text: 'Monthly'),
                    Tab(text: 'Pending EMI'),
                    Tab(text: 'Analysis'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(controller: _tab, children: [
                  _monthlyTab(),
                  _pendingTab(),
                  _analysisTab(),
                ]),
              ),
            ]),
    );
  }

  // ── Monthly tab ────────────────────────────────────────────────────────────
  Widget _monthlyTab() {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return Column(children: [
      // Month chips
      Container(
        height: 60,
        color: AppColors.background,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          scrollDirection: Axis.horizontal,
          itemCount: 12,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final m = i + 1;
            final rev = _monthlyRevenue[m.toString()] ?? 0;
            final isSel = m == _month;
            return GestureDetector(
              onTap: () => setState(() => _month = m),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.accent.withOpacity(0.15) : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSel ? AppColors.accent : AppColors.border),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(months[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: isSel ? AppColors.accent : AppColors.textSecondary)),
                  Text('₹${_short(rev)}', style: TextStyle(fontSize: 10,
                      color: isSel ? AppColors.accent : AppColors.textMuted)),
                ]),
              ),
            );
          },
        ),
      ),
      // Bar chart — simple horizontal bars
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${months[_month-1]} $_year — ${_monthly.length} jobs',
              style: AppTextStyles.bodySecondary),
          Text(formatCurrency(_monthly.fold(0.0, (s, c) => s + c.grandTotal)),
              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
      ),
      Expanded(
        child: _monthly.isEmpty
            ? const Center(child: Text('No jobs this month', style: AppTextStyles.bodySecondary))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _monthly.length,
                itemBuilder: (ctx, i) {
                  final c = _monthly[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: JobCardListTile(card: c, onTap: () {
                      context.read<JobCardController>().setActiveJobCard(c);
                      Navigator.pushNamed(context, AppRoutes.labourBilling);
                    }),
                  );
                },
              ),
      ),
    ]);
  }

  // ── Pending EMI tab ────────────────────────────────────────────────────────
  Widget _pendingTab() {
    final total = _pending.fold<double>(0, (s, c) => s + c.balanceDue);
    return Column(children: [
      if (_pending.isNotEmpty)
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error.withOpacity(0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${_pending.length} customers have pending dues',
                  style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 13)),
              Text('Total: ${formatCurrency(total)}',
                  style: const TextStyle(color: AppColors.error, fontSize: 12)),
            ])),
          ]),
        ),
      Expanded(
        child: _pending.isEmpty
            ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.check_circle_outline, color: AppColors.success, size: 48),
                SizedBox(height: 12),
                Text('No pending EMIs!', style: AppTextStyles.bodySecondary),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _pending.length,
                itemBuilder: (ctx, i) {
                  final c = _pending[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: JobCardListTile(card: c, onTap: () {
                      context.read<JobCardController>().setActiveJobCard(c);
                      Navigator.pushNamed(context, AppRoutes.emiPayment);
                    }),
                  );
                },
              ),
      ),
    ]);
  }

  // ── Analysis tab ───────────────────────────────────────────────────────────
  Widget _analysisTab() {
    final open      = _yearly.where((c) => c.status == JobStatus.open || c.status == JobStatus.inProgress).length;
    final completed = _yearly.where((c) => c.status == JobStatus.completed || c.status == JobStatus.delivered).length;
    final cancelled = _yearly.where((c) => c.status == JobStatus.cancelled).length;
    final paid      = _yearly.where((c) => c.paymentStatus == PaymentStatus.paid).length;
    final partial   = _yearly.where((c) => c.paymentStatus == PaymentStatus.partial).length;
    final pending   = _yearly.where((c) => c.paymentStatus == PaymentStatus.pending).length;
    final total     = _yearly.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionHeader(title: 'Job Status'),
          const SizedBox(height: 16),
          _Bar('Open / In Progress', open, total, AppColors.warning),
          const SizedBox(height: 10),
          _Bar('Completed / Delivered', completed, total, AppColors.success),
          const SizedBox(height: 10),
          _Bar('Cancelled', cancelled, total, AppColors.error),
        ])),
        const SizedBox(height: 14),
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionHeader(title: 'Payment Status'),
          const SizedBox(height: 16),
          _Bar('Paid', paid, total, AppColors.success),
          const SizedBox(height: 10),
          _Bar('Partial', partial, total, AppColors.warning),
          const SizedBox(height: 10),
          _Bar('Pending', pending, total, AppColors.error),
        ])),
        const SizedBox(height: 14),
        // Revenue breakdown
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionHeader(title: 'Revenue — $_year'),
          const SizedBox(height: 14),
          _RevRow('Total Invoiced', _totalRevenue, AppColors.textPrimary),
          _RevRow('Total Collected', _totalCollected, AppColors.success),
          _RevRow('Total Pending', _totalPending, _totalPending > 0 ? AppColors.error : AppColors.success),
          const Divider(color: AppColors.border, height: 20),
          _RevRow('Collection Rate',
            _totalRevenue > 0 ? (_totalCollected / _totalRevenue * 100) : 0,
            AppColors.accent, isPercent: true),
        ])),
        const SizedBox(height: 20),
      ]),
    );
  }

  void _showYearPicker() {
    final years = List.generate(5, (i) => DateTime.now().year - i);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Select Year', style: AppTextStyles.heading3),
          const SizedBox(height: 12),
          ...years.map((y) => ListTile(
            title: Text('$y', style: AppTextStyles.body),
            trailing: y == _year ? const Icon(Icons.check, color: AppColors.accent) : null,
            onTap: () {
              setState(() => _year = y);
              Navigator.pop(context);
              _load();
            },
          )),
        ]),
      ),
    );
  }

  Widget _vd() => Container(width: 1, height: 30, color: AppColors.border, margin: const EdgeInsets.symmetric(horizontal: 4));

  Widget _Strip(String label, String value, Color color) => Expanded(
    child: Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
      Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
    ]),
  );

  String _short(double v) {
    if (v >= 100000) return '${(v/100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return '${(v/1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  Widget _Bar(String label, int count, int total, Color color) {
    final pct = total > 0 ? count / total : 0.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: AppTextStyles.bodySecondary),
        Text('$count (${(pct*100).toStringAsFixed(0)}%)',
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
      const SizedBox(height: 5),
      ClipRRect(borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(value: pct, backgroundColor: AppColors.border,
          valueColor: AlwaysStoppedAnimation(color), minHeight: 7)),
    ]);
  }

  Widget _RevRow(String label, double amount, Color color, {bool isPercent = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: AppTextStyles.bodySecondary),
      Text(isPercent ? '${amount.toStringAsFixed(1)}%' : formatCurrency(amount),
          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
    ]),
  );
}
