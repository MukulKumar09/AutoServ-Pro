// lib/views/customer_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../constants/app_constants.dart';
import '../controllers/auth_controller.dart';
import '../controllers/job_card_controller.dart';
import '../models/job_card_model.dart';
import '../widgets/app_widgets.dart';
import '../widgets/main_scaffold.dart';
import 'package:intl/intl.dart';

class CustomerHistoryScreen extends StatefulWidget {
  const CustomerHistoryScreen({super.key});
  @override
  State<CustomerHistoryScreen> createState() => _CustomerHistoryScreenState();
}

class _CustomerHistoryScreenState extends State<CustomerHistoryScreen> {
  final _searchCtrl  = TextEditingController();
  List<JobCardModel> _results = [];
  bool _searching   = false;
  String? _expandedId;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _search();
    });
  }

  @override
  void dispose() { 
    _searchCtrl.dispose(); 
    _debounce?.cancel();
    super.dispose(); 
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _search();
    });
  }

  void _search() {
    final allCards = context.read<JobCardController>().allJobCards;
    final q = _searchCtrl.text.trim().toLowerCase();
    
    if (q.isEmpty) {
      setState(() {
        _results = List.from(allCards)..sort((a, b) => b.entryDate.compareTo(a.entryDate));
        _searching = false;
      });
      return;
    }
    
    setState(() => _searching = true);
    
    setState(() {
      _results = allCards.where((c) {
        return c.registrationNumber.toLowerCase().contains(q) ||
               c.customerName.toLowerCase().contains(q);
      }).toList()..sort((a, b) => b.entryDate.compareTo(a.entryDate));
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalPending = _results.fold<double>(0, (s, c) => s + (c.hasBalance ? c.balanceDue : 0));

    final auth = context.watch<AuthController>();

    return MainScaffold(
      title: auth.isAdmin ? 'All Job Cards' : 'Your Job Cards',
      showBack: true,
      body: Column(children: [
        // Search bar
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  style: AppTextStyles.body,
                  textInputAction: TextInputAction.search,
                  onChanged: _onSearchChanged,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: 'Search Customer Name/Vehicle Number',
                    hintStyle: AppTextStyles.caption,
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                            onPressed: () { _searchCtrl.clear(); _search(); })
                        : null,
                    filled: true, fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ]),
          ]),
        ),

        // Results summary
        if (_results.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.background,
            child: Row(children: [
              Text('${_results.length} result(s)', style: AppTextStyles.bodySecondary),
              const Spacer(),
              if (totalPending > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Text('Due: ${formatCurrency(totalPending)}',
                      style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
            ]),
          ),

        // Results list
        Expanded(
          child: _searching
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : _results.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.search, size: 56, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      const Text('Search for customer history', style: AppTextStyles.bodySecondary),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() => _results = context.read<JobCardController>().allJobCards);
                        },
                        child: const Text('Show All', style: TextStyle(color: AppColors.accent)),
                      ),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _results.length,
                      itemBuilder: (ctx, i) {
                        final card = _results[i];
                        final expanded = _expandedId == card.id;
                        return _HistoryCard(
                          card: card,
                          isExpanded: expanded,
                          onTap: () => setState(() => _expandedId = expanded ? null : card.id),
                          onOpenBilling: () {
                            context.read<JobCardController>().setActiveJobCard(card);
                            Navigator.pushNamed(context, AppRoutes.labourBilling);
                          },
                          onAddPayment: () {
                            context.read<JobCardController>().setActiveJobCard(card);
                            Navigator.pushNamed(context, AppRoutes.emiPayment);
                          },
                        );
                      },
                    ),
        ),
      ]),
    );
  }

}

class _HistoryCard extends StatelessWidget {
  final JobCardModel card;
  final bool isExpanded;
  final VoidCallback onTap, onOpenBilling, onAddPayment;
  const _HistoryCard({required this.card, required this.isExpanded,
    required this.onTap, required this.onOpenBilling, required this.onAddPayment});

  @override
  Widget build(BuildContext context) {
    final isPending = card.hasBalance;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isPending ? AppColors.error.withOpacity(0.05) : AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPending ? AppColors.error.withOpacity(0.4) : AppColors.border),
      ),
      child: Column(children: [
        // Header (always visible)
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Text(card.roNumber, style: AppTextStyles.accent.copyWith(fontSize: 12)),
                  if (isPending) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('EMI PENDING',
                          style: TextStyle(color: AppColors.error, fontSize: 9, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ]),
                Icon(isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textMuted, size: 20),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(card.customerName,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                  Text('${card.vehicleMake} ${card.vehicleModel} | ${card.registrationNumber}',
                      style: AppTextStyles.bodySecondary.copyWith(fontSize: 12)),
                  Text(formatDate(card.entryDate), style: AppTextStyles.caption),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(formatCurrency(card.grandTotal),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                  if (isPending)
                    Text('Due: ${formatCurrency(card.balanceDue)}',
                        style: const TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  StatusBadge.paymentStatus(card.paymentStatus),
                ]),
              ]),
            ]),
          ),
        ),

        // Expanded details
        if (isExpanded) ...[
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Service info
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('SERVICE', style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  InfoRow(label: 'In Time', value: formatTime(card.inTime)),
                  InfoRow(label: 'Out Time', value: card.outTime != null ? formatTime(card.outTime!) : '—'),
                  InfoRow(label: 'Duration', value: formatDuration(card.serviceDuration)),
                  InfoRow(label: 'KM Reading', value: card.kmReading),
                ])),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('BILLING', style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  InfoRow(label: 'Spare Parts', value: formatCurrency(card.spareParts)),
                  InfoRow(label: 'Labour', value: formatCurrency(card.labourTotal)),
                  InfoRow(label: 'Total Paid', value: formatCurrency(card.totalPaid), valueColor: AppColors.success),
                  if (isPending)
                    InfoRow(label: 'Balance Due', value: formatCurrency(card.balanceDue), valueColor: AppColors.error),
                ])),
              ]),

              // Jobs done
              if (card.demandedJobs.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('WORK DONE', style: AppTextStyles.label),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6,
                  children: card.demandedJobs.take(5).map((j) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Text(j, style: const TextStyle(color: AppColors.success, fontSize: 11)),
                  )).toList(),
                ),
                if (card.demandedJobs.length > 5)
                  Text('+${card.demandedJobs.length - 5} more', style: AppTextStyles.caption),
              ],

              // Payment history
              if (card.payments.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('PAYMENT HISTORY', style: AppTextStyles.label),
                const SizedBox(height: 6),
                ...card.payments.map((p) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 14),
                    const SizedBox(width: 8),
                    Text(formatDate(p.date), style: AppTextStyles.caption),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1), borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(p.paymentMode, style: const TextStyle(color: AppColors.info, fontSize: 10)),
                    ),
                    const Spacer(),
                    Text(formatCurrency(p.amount),
                        style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 13)),
                  ]),
                )),
              ],

              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: onOpenBilling,
                  icon: const Icon(Icons.receipt_long, size: 16),
                  label: const Text('Open', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                )),
                if (isPending) ...[
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton.icon(
                    onPressed: onAddPayment,
                    icon: const Icon(Icons.payments, size: 16),
                    label: const Text('Pay', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  )),
                ],
              ]),
            ]),
          ),
        ],
      ]),
    );
  }
}
