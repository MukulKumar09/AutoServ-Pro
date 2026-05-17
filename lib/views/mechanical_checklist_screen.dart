// lib/views/mechanical_checklist_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../controllers/job_card_controller.dart';
import '../models/job_card_model.dart';
import '../widgets/app_widgets.dart';
import '../widgets/main_scaffold.dart';

class MechanicalChecklistScreen extends StatefulWidget {
  const MechanicalChecklistScreen({super.key});
  @override
  State<MechanicalChecklistScreen> createState() => _MechanicalChecklistScreenState();
}

class _MechanicalChecklistScreenState extends State<MechanicalChecklistScreen> {
  late MechanicalChecklist _cl;
  bool _saving = false;

  static const _items = [
    ('coolantLeakage',   'Coolant Leakage Check',    Icons.water_drop_outlined),
    ('clutchOperation',  'Clutch Operation',          Icons.settings_outlined),
    ('transmissionOil',  'Transmission Oil Check',    Icons.opacity),
    ('handBrake',        'Hand Brake Check',          Icons.back_hand_outlined),
    ('steeringCheck',    'Steering Check',            Icons.rotate_right),
    ('doorFunctions',    'Door Functions',            Icons.door_front_door_outlined),
    ('engineOilReplace', 'Engine Oil Replace',        Icons.local_gas_station_outlined),
    ('brakeClutchFluid', 'Brake & Clutch Fluid',      Icons.car_repair),
    ('wipersCheck',      'Wipers Check',              Icons.water),
    ('headTailLamp',     'Head / Tail Lamp',          Icons.light_mode_outlined),
    ('acMovement',       'AC Movement',               Icons.ac_unit),
    ('suspension',       'Suspension',                Icons.compress),
    ('batteryWaterLevel','Battery Water Level',       Icons.battery_charging_full_outlined),
    ('tyreInflation',    'Tyre Inflation',            Icons.tire_repair),
    ('switchesCheck',    'Switches Check',            Icons.toggle_on_outlined),
    ('brakePadLinear',   'Brake Pad & Linear',        Icons.disc_full),
  ];

  @override
  void initState() {
    super.initState();
    final card = context.read<JobCardController>().activeJobCard;
    _cl = card?.mechanicalChecklist ?? const MechanicalChecklist();
  }

  bool _get(String k) => switch (k) {
    'coolantLeakage'   => _cl.coolantLeakage,
    'clutchOperation'  => _cl.clutchOperation,
    'transmissionOil'  => _cl.transmissionOil,
    'handBrake'        => _cl.handBrake,
    'steeringCheck'    => _cl.steeringCheck,
    'doorFunctions'    => _cl.doorFunctions,
    'engineOilReplace' => _cl.engineOilReplace,
    'brakeClutchFluid' => _cl.brakeClutchFluid,
    'wipersCheck'      => _cl.wipersCheck,
    'headTailLamp'     => _cl.headTailLamp,
    'acMovement'       => _cl.acMovement,
    'suspension'       => _cl.suspension,
    'batteryWaterLevel'=> _cl.batteryWaterLevel,
    'tyreInflation'    => _cl.tyreInflation,
    'switchesCheck'    => _cl.switchesCheck,
    'brakePadLinear'   => _cl.brakePadLinear,
    _ => false,
  };

  void _set(String k, bool v) => setState(() { _cl = switch (k) {
    'coolantLeakage'   => _cl.copyWith(coolantLeakage:    v),
    'clutchOperation'  => _cl.copyWith(clutchOperation:   v),
    'transmissionOil'  => _cl.copyWith(transmissionOil:   v),
    'handBrake'        => _cl.copyWith(handBrake:         v),
    'steeringCheck'    => _cl.copyWith(steeringCheck:     v),
    'doorFunctions'    => _cl.copyWith(doorFunctions:     v),
    'engineOilReplace' => _cl.copyWith(engineOilReplace:  v),
    'brakeClutchFluid' => _cl.copyWith(brakeClutchFluid:  v),
    'wipersCheck'      => _cl.copyWith(wipersCheck:       v),
    'headTailLamp'     => _cl.copyWith(headTailLamp:      v),
    'acMovement'       => _cl.copyWith(acMovement:        v),
    'suspension'       => _cl.copyWith(suspension:        v),
    'batteryWaterLevel'=> _cl.copyWith(batteryWaterLevel: v),
    'tyreInflation'    => _cl.copyWith(tyreInflation:     v),
    'switchesCheck'    => _cl.copyWith(switchesCheck:     v),
    'brakePadLinear'   => _cl.copyWith(brakePadLinear:    v),
    _ => _cl,
  }; });

  int get _checkedCount => _items.where((i) => _get(i.$1)).length;

  Future<void> _save({bool goNext = false}) async {
    final ctrl = context.read<JobCardController>();
    final card = ctrl.activeJobCard;
    if (card == null) { showSnackBar(context, 'No active job card', isError: true); return; }
    setState(() => _saving = true);
    final ok = await ctrl.updateJobCard(card.copyWith(mechanicalChecklist: _cl));
    setState(() => _saving = false);
    if (ok && mounted) {
      if (goNext) Navigator.pushReplacementNamed(context, AppRoutes.demandedJobs);
      else showSnackBar(context, 'Mechanical checklist saved ✓');
    } else if (mounted) showSnackBar(context, ctrl.error ?? 'Failed', isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final card = context.watch<JobCardController>().activeJobCard;
    return MainScaffold(
      title: 'Mechanical Checklist',
      showBack: true,
      body: card == null
          ? Center(child: PrimaryButton(label: 'Create Job Card', icon: Icons.add,
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.vehicleEntry)))
          : LoadingOverlay(
              isLoading: _saving,
              child: Column(children: [
                // Progress
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('$_checkedCount / ${_items.length} checked',
                          style: AppTextStyles.bodySecondary),
                      Row(children: [
                        TextButton(onPressed: () => setState(() {
                          _cl = MechanicalChecklist(coolantLeakage: true, clutchOperation: true,
                            transmissionOil: true, handBrake: true, steeringCheck: true,
                            doorFunctions: true, engineOilReplace: true, brakeClutchFluid: true,
                            wipersCheck: true, headTailLamp: true, acMovement: true,
                            suspension: true, batteryWaterLevel: true, tyreInflation: true,
                            switchesCheck: true, brakePadLinear: true);
                        }), child: const Text('All', style: TextStyle(color: AppColors.accent, fontSize: 12))),
                        TextButton(onPressed: () => setState(() => _cl = const MechanicalChecklist()),
                          child: const Text('Clear', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                      ]),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _checkedCount / _items.length,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation(
                          _checkedCount == _items.length ? AppColors.success : AppColors.accent),
                        minHeight: 5,
                      ),
                    ),
                  ]),
                ),

                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (ctx, i) {
                      final (key, label, icon) = _items[i];
                      final checked = _get(key);
                      return GestureDetector(
                        onTap: () => _set(key, !checked),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: checked ? AppColors.success.withOpacity(0.08) : AppColors.cardBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: checked ? AppColors.success.withOpacity(0.4) : AppColors.border,
                            ),
                          ),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: checked ? AppColors.success.withOpacity(0.15) : AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(icon, size: 17,
                                  color: checked ? AppColors.success : AppColors.textMuted),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(label, style: TextStyle(
                              color: checked ? AppColors.textPrimary : AppColors.textSecondary,
                              fontSize: 14, fontWeight: checked ? FontWeight.w600 : FontWeight.w400,
                            ))),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 24, height: 24,
                              decoration: BoxDecoration(
                                color: checked ? AppColors.success : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: checked ? AppColors.success : AppColors.border, width: 1.5),
                              ),
                              child: checked ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
                ),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(children: [
                    Expanded(child: SecondaryButton(label: 'Save', icon: Icons.save,
                        onPressed: _saving ? null : () => _save())),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: PrimaryButton(label: 'Next →',
                        isLoading: _saving, onPressed: () => _save(goNext: true))),
                  ]),
                ),
              ]),
            ),
    );
  }
}
