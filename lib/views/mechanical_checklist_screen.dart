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
  final Map<String, TextEditingController> _noteCtrls = {};

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
    for (final i in _items) {
      _noteCtrls[i.$1] = TextEditingController(text: _get(i.$1).note);
    }
  }

  @override
  void dispose() {
    for (final c in _noteCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  MechanicalItem _get(String k) => switch (k) {
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
    _ => const MechanicalItem(),
  };

  void _setStatus(String k, String status) {
    setState(() {
      final old = _get(k);
      _set(k, MechanicalItem(status: status, note: old.note));
    });
  }

  void _set(String k, MechanicalItem v) => _cl = switch (k) {
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
  };

  void _syncNotes() {
    for (final i in _items) {
      final key = i.$1;
      final old = _get(key);
      _set(key, MechanicalItem(status: old.status, note: _noteCtrls[key]!.text));
    }
  }

  void _saveAndNext() {
    final ctrl = context.read<JobCardController>();
    final card = ctrl.activeJobCard;
    if (card == null) return;

    _syncNotes();
    ctrl.setActiveJobCard(card.copyWith(mechanicalChecklist: _cl));
    Navigator.pushNamed(context, AppRoutes.demandedJobs);
  }

  void _onBack() {
    final ctrl = context.read<JobCardController>();
    if (ctrl.activeJobCard != null) {
      _syncNotes();
      ctrl.setActiveJobCard(ctrl.activeJobCard!.copyWith(mechanicalChecklist: _cl));
    }
    Navigator.pop(context);
  }

  Future<void> _handleDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Discard changes?', style: AppTextStyles.heading3),
        content: const Text('Are you sure you want to discard this job card?', style: AppTextStyles.bodySecondary),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = context.watch<JobCardController>().activeJobCard;
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _onBack();
      },
      child: MainScaffold(
        title: 'Mechanical Checklist',
        showBack: true,
        actions: [
          TextButton(
            onPressed: _handleDiscard,
            child: const Text('Discard', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
        body: card == null
            ? Center(child: PrimaryButton(label: 'Create Job Card', icon: Icons.add,
                  onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.vehicleEntry)))
            : Column(children: [

                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final (key, label, icon) = _items[i];
                      return _buildItemRow(key, label, icon);
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
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _onBack,
                        icon: const Icon(Icons.arrow_back_ios_new, size: 15),
                        label: const Text('Back'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2, 
                      child: ElevatedButton.icon(
                        onPressed: _saveAndNext,
                        icon: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
                        label: const Text('Next', style: TextStyle(fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ]),
                ),
              ]),
      ),
    );
  }

  Widget _buildItemRow(String key, String label, IconData icon) {
    final item = _get(key);
    final ctrl = _noteCtrls[key]!;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13))),
          ]),
          const SizedBox(height: 12),
          // Bad / Normal / Good Toggle
          Row(children: [
            Expanded(child: _StatusBtn('Bad', AppColors.error, item.status == 'Bad', () => _setStatus(key, 'Bad'))),
            const SizedBox(width: 8),
            Expanded(child: _StatusBtn('Normal', AppColors.info, item.status == 'Normal', () => _setStatus(key, 'Normal'))),
            const SizedBox(width: 8),
            Expanded(child: _StatusBtn('Good', AppColors.success, item.status == 'Good', () => _setStatus(key, 'Good'))),
          ]),
          if (item.status == 'Bad') ...[
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: 'Specify exact issue...',
                hintStyle: AppTextStyles.caption,
                filled: true, fillColor: AppColors.surfaceElevated,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _StatusBtn(String label, Color color, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.15) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? color : AppColors.border),
        ),
        child: Text(label, style: TextStyle(
          color: isActive ? color : AppColors.textSecondary,
          fontSize: 12, fontWeight: FontWeight.w700,
        )),
      ),
    );
  }
}
