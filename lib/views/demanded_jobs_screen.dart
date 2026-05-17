// lib/views/demanded_jobs_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../controllers/job_card_controller.dart';
import '../widgets/app_widgets.dart';
import '../widgets/main_scaffold.dart';

class DemandedJobsScreen extends StatefulWidget {
  const DemandedJobsScreen({super.key});
  @override
  State<DemandedJobsScreen> createState() => _DemandedJobsScreenState();
}

class _DemandedJobsScreenState extends State<DemandedJobsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<TextEditingController> _demCtrls = [];
  List<TextEditingController> _recCtrls = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    final card = context.read<JobCardController>().activeJobCard;
    _demCtrls = card?.demandedJobs.isEmpty == false
        ? card!.demandedJobs.map((j) => TextEditingController(text: j)).toList()
        : [TextEditingController()];
    _recCtrls = card?.recommendedJobs.isEmpty == false
        ? card!.recommendedJobs.map((j) => TextEditingController(text: j)).toList()
        : [TextEditingController()];
  }

  @override
  void dispose() {
    _tab.dispose();
    for (final c in [..._demCtrls, ..._recCtrls]) c.dispose();
    super.dispose();
  }

  Future<void> _save({bool goNext = false}) async {
    final ctrl = context.read<JobCardController>();
    final card = ctrl.activeJobCard;
    if (card == null) { showSnackBar(context, 'No active job card', isError: true); return; }
    setState(() => _saving = true);
    final demanded    = _demCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    final recommended = _recCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    final ok = await ctrl.updateJobCard(card.copyWith(demandedJobs: demanded, recommendedJobs: recommended));
    setState(() => _saving = false);
    if (ok && mounted) {
      if (goNext) Navigator.pushReplacementNamed(context, AppRoutes.labourBilling);
      else showSnackBar(context, 'Jobs saved ✓');
    } else if (mounted) showSnackBar(context, ctrl.error ?? 'Failed', isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final card = context.watch<JobCardController>().activeJobCard;
    return MainScaffold(
      title: 'Jobs',
      showBack: true,
      body: card == null
          ? Center(child: PrimaryButton(label: 'Create Job Card', icon: Icons.add,
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.vehicleEntry)))
          : Column(children: [
              // Tab bar
              Container(
                color: AppColors.surface,
                child: TabBar(
                  controller: _tab,
                  labelColor: AppColors.accent,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.accent,
                  tabs: [
                    Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.person_outline, size: 16),
                      const SizedBox(width: 6),
                      Text('Demanded (${_demCtrls.where((c) => c.text.isNotEmpty).length})'),
                    ])),
                    Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.recommend_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text('Recommended (${_recCtrls.where((c) => c.text.isNotEmpty).length})'),
                    ])),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(controller: _tab, children: [
                  _JobList(
                    controllers: _demCtrls,
                    color: AppColors.error,
                    hint: 'e.g. Engine oil change',
                    onAdd: () => setState(() => _demCtrls.add(TextEditingController())),
                    onRemove: (i) {
                      if (_demCtrls.length <= 1) return;
                      _demCtrls[i].dispose();
                      setState(() => _demCtrls.removeAt(i));
                    },
                  ),
                  _JobList(
                    controllers: _recCtrls,
                    color: AppColors.warning,
                    hint: 'e.g. Air filter replacement',
                    onAdd: () => setState(() => _recCtrls.add(TextEditingController())),
                    onRemove: (i) {
                      if (_recCtrls.length <= 1) return;
                      _recCtrls[i].dispose();
                      setState(() => _recCtrls.removeAt(i));
                    },
                  ),
                ]),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                    color: AppColors.surface,
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

class _JobList extends StatelessWidget {
  final List<TextEditingController> controllers;
  final Color color;
  final String hint;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _JobList({required this.controllers, required this.color, required this.hint,
    required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...List.generate(controllers.length, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Container(width: 28, height: 28,
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text('${i + 1}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)))),
            const SizedBox(width: 10),
            Expanded(child: TextField(
              controller: controllers[i],
              style: AppTextStyles.body,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: hint, hintStyle: AppTextStyles.caption,
                filled: true, fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: color, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            )),
            if (controllers.length > 1) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => onRemove(i),
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
              ),
            ],
          ]),
        )),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: Icon(Icons.add_circle_outline, color: color, size: 18),
          label: Text('Add Job', style: TextStyle(color: color)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color.withOpacity(0.5)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
