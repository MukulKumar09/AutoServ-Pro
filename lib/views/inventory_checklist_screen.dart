// lib/views/inventory_checklist_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../controllers/job_card_controller.dart';
import '../models/job_card_model.dart';
import '../widgets/app_widgets.dart';
import '../widgets/main_scaffold.dart';

class InventoryChecklistScreen extends StatefulWidget {
  const InventoryChecklistScreen({super.key});
  @override
  State<InventoryChecklistScreen> createState() => _InventoryChecklistScreenState();
}

class _InventoryChecklistScreenState extends State<InventoryChecklistScreen> {
  late InventoryChecklist _checklist;
  final _speakersCtrl  = TextEditingController();
  final _dollCtrl      = TextEditingController();
  final _floorMatCtrl  = TextEditingController();
  final _seatCtrl      = TextEditingController();
  final _toolCtrl      = TextEditingController();
  final _mirrorCtrl    = TextEditingController();
  final _fogCtrl       = TextEditingController();
  final _othersCtrl    = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final card = context.read<JobCardController>().activeJobCard;
    _checklist = card?.inventoryChecklist ?? const InventoryChecklist();
    _speakersCtrl.text = _checklist.speakers > 0 ? '${_checklist.speakers}' : '';
    _dollCtrl.text     = _checklist.dollIdol > 0  ? '${_checklist.dollIdol}'  : '';
    _floorMatCtrl.text = _checklist.floorMat > 0  ? '${_checklist.floorMat}'  : '';
    _seatCtrl.text     = _checklist.seatCovers;
    _toolCtrl.text     = _checklist.toolList;
    _mirrorCtrl.text   = _checklist.sideMirror > 0 ? '${_checklist.sideMirror}' : '';
    _fogCtrl.text      = _checklist.fogLamp > 0    ? '${_checklist.fogLamp}'    : '';
    _othersCtrl.text   = _checklist.others;
  }

  @override
  void dispose() {
    for (final c in [_speakersCtrl,_dollCtrl,_floorMatCtrl,_seatCtrl,_toolCtrl,_mirrorCtrl,_fogCtrl,_othersCtrl]) c.dispose();
    super.dispose();
  }

  InventoryChecklist _build() => _checklist.copyWith(
    speakers:   int.tryParse(_speakersCtrl.text) ?? 0,
    dollIdol:   int.tryParse(_dollCtrl.text)      ?? 0,
    floorMat:   int.tryParse(_floorMatCtrl.text)  ?? 0,
    seatCovers: _seatCtrl.text,
    toolList:   _toolCtrl.text,
    sideMirror: int.tryParse(_mirrorCtrl.text)    ?? 0,
    fogLamp:    int.tryParse(_fogCtrl.text)        ?? 0,
    others:     _othersCtrl.text,
  );

  Future<void> _save({bool goNext = false}) async {
    final ctrl = context.read<JobCardController>();
    final card = ctrl.activeJobCard;
    if (card == null) { showSnackBar(context, 'No active job card', isError: true); return; }
    setState(() => _saving = true);
    final ok = await ctrl.updateJobCard(card.copyWith(inventoryChecklist: _build()));
    setState(() => _saving = false);
    if (ok && mounted) {
      if (goNext) Navigator.pushReplacementNamed(context, AppRoutes.visualInspection);
      else showSnackBar(context, 'Inventory saved ✓');
    } else if (mounted) showSnackBar(context, ctrl.error ?? 'Failed', isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final card = context.watch<JobCardController>().activeJobCard;
    return MainScaffold(
      title: 'Inventory Checklist',
      showBack: true,
      body: card == null
          ? _noCard()
          : LoadingOverlay(
              isLoading: _saving,
              child: Column(children: [
                // RO chip
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(children: [
                    const Icon(Icons.checklist_rounded, color: AppColors.accent, size: 16),
                    const SizedBox(width: 8),
                    Text('${card.roNumber} — ${card.customerName}',
                        style: AppTextStyles.accent.copyWith(fontSize: 12)),
                  ]),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _Section('Accessories & Interior', children: [
                        _Check('Key Remote', _checklist.keyRemote,
                            (v) => setState(() => _checklist = _checklist.copyWith(keyRemote: v))),
                        _Check('Audio System with Face Plate', _checklist.audioSystem,
                            (v) => setState(() => _checklist = _checklist.copyWith(audioSystem: v))),
                        _Check('CD/DVD Changer', _checklist.cdDvdChanger,
                            (v) => setState(() => _checklist = _checklist.copyWith(cdDvdChanger: v))),
                        _NumRow('Speakers (Nos)', _speakersCtrl),
                        _Check('Owner Manual', _checklist.ownerManual,
                            (v) => setState(() => _checklist = _checklist.copyWith(ownerManual: v))),
                        _Check('Mobile Charger', _checklist.mobileCharger,
                            (v) => setState(() => _checklist = _checklist.copyWith(mobileCharger: v))),
                        _Check('Key Chain', _checklist.keyChain,
                            (v) => setState(() => _checklist = _checklist.copyWith(keyChain: v))),
                        _NumRow('Doll/Idol (Nos)', _dollCtrl),
                        _Check('Air Freshener', _checklist.airFreshener,
                            (v) => setState(() => _checklist = _checklist.copyWith(airFreshener: v))),
                        _Toggle('Upholstery', 'Torn/Broken', _checklist.upholsteryTornBroken,
                            (v) => setState(() => _checklist = _checklist.copyWith(upholsteryTornBroken: v))),
                        _NumRow('Floor Mat (Nos)', _floorMatCtrl),
                        _TextRow('Seat Covers', _seatCtrl),
                      ]),
                      const SizedBox(height: 16),
                      _Section('Safety & Exterior', children: [
                        _Check('Jack & Handle', _checklist.jackHandle,
                            (v) => setState(() => _checklist = _checklist.copyWith(jackHandle: v))),
                        _Toggle('Underbody', 'Scratches/Damages', _checklist.underbodyDamages,
                            (v) => setState(() => _checklist = _checklist.copyWith(underbodyDamages: v))),
                        _Check('Boot Mat', _checklist.bootMat,
                            (v) => setState(() => _checklist = _checklist.copyWith(bootMat: v))),
                        _Check('First Aid Kit', _checklist.firstAidKit,
                            (v) => setState(() => _checklist = _checklist.copyWith(firstAidKit: v))),
                        _TextRow('Tool List', _toolCtrl),
                        _Check('Wheel Cover/Cap', _checklist.wheelCoverCap,
                            (v) => setState(() => _checklist = _checklist.copyWith(wheelCoverCap: v))),
                        _Check('Mud Flaps', _checklist.mudFlaps,
                            (v) => setState(() => _checklist = _checklist.copyWith(mudFlaps: v))),
                        _Check('Spare Wheel', _checklist.spareWheel,
                            (v) => setState(() => _checklist = _checklist.copyWith(spareWheel: v))),
                        _NumRow('Side Mirror (Nos)', _mirrorCtrl),
                        _NumRow('Fog Lamp (Nos)', _fogCtrl),
                        _Check('Wiper Arms/Blades', _checklist.wiperArmsBlades,
                            (v) => setState(() => _checklist = _checklist.copyWith(wiperArmsBlades: v))),
                        _Check('Fuel Cap', _checklist.fuelCap,
                            (v) => setState(() => _checklist = _checklist.copyWith(fuelCap: v))),
                        _Toggle('Horns', 'Low/High Tone', _checklist.hornLowHigh,
                            (v) => setState(() => _checklist = _checklist.copyWith(hornLowHigh: v))),
                        _TextRow('Others', _othersCtrl),
                      ]),
                      const SizedBox(height: 80),
                    ]),
                  ),
                ),
                // Bottom buttons
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

  Widget _noCard() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.assignment_outlined, size: 56, color: AppColors.textMuted),
    const SizedBox(height: 12),
    const Text('No active job card', style: AppTextStyles.bodySecondary),
    const SizedBox(height: 16),
    PrimaryButton(label: 'Create Job Card', icon: Icons.add,
        onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.vehicleEntry)),
  ]));

  Widget _Section(String title, {required List<Widget> children}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.accent.withOpacity(0.2)),
        ),
        child: Row(children: [
          Container(width: 3, height: 14, decoration: BoxDecoration(
              color: AppColors.accent, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
      ),
      const SizedBox(height: 2),
      Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: children.map((c) => Column(children: [c,
          if (children.last != c) const Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16),
        ])).toList()),
      ),
    ],
  );

  Widget _Check(String label, bool val, ValueChanged<bool> onChange) =>
      ChecklistRow(label: label, value: val, onChanged: onChange);

  Widget _NumRow(String label, TextEditingController ctrl) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(children: [
      Expanded(child: Text(label, style: AppTextStyles.body)),
      SizedBox(width: 70, child: TextField(
        controller: ctrl, textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: AppTextStyles.body,
        decoration: InputDecoration(
          hintText: '0', hintStyle: AppTextStyles.caption,
          filled: true, fillColor: AppColors.surfaceElevated,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
      )),
    ]),
  );

  Widget _TextRow(String label, TextEditingController ctrl) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(children: [
      Expanded(child: Text(label, style: AppTextStyles.body)),
      SizedBox(width: 140, child: TextField(
        controller: ctrl, style: AppTextStyles.body,
        decoration: InputDecoration(
          hintText: 'Enter...', hintStyle: AppTextStyles.caption,
          filled: true, fillColor: AppColors.surfaceElevated,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
      )),
    ]),
  );

  Widget _Toggle(String label, String sub, bool val, ValueChanged<bool> onChange) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTextStyles.body),
        Text(sub, style: AppTextStyles.caption),
      ])),
      Switch(value: val, onChanged: onChange,
          activeColor: AppColors.accent,
          activeTrackColor: AppColors.accent.withOpacity(0.3),
          inactiveThumbColor: AppColors.textMuted,
          inactiveTrackColor: AppColors.border),
      SizedBox(width: 36, child: Text(val ? 'YES' : 'NO',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: val ? AppColors.error : AppColors.textMuted),
          textAlign: TextAlign.center)),
    ]),
  );
}
