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
  String _vehicleType = 'Four-Wheeler';

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
    // Note: helmet is already updated via its inline setter if toggled
  );

  Future<void> _saveAndNext() async {
    final ctrl = context.read<JobCardController>();
    final card = ctrl.activeJobCard;
    if (card == null) return;
    
    // In-memory update
    ctrl.setActiveJobCard(card.copyWith(inventoryChecklist: _build()));
    Navigator.pushNamed(context, AppRoutes.visualInspection);
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

  void _onBack() {
    // In-memory update before popping back
    final ctrl = context.read<JobCardController>();
    if (ctrl.activeJobCard != null) {
      ctrl.setActiveJobCard(ctrl.activeJobCard!.copyWith(inventoryChecklist: _build()));
    }
    Navigator.pop(context);
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
        title: 'Inventory Checklist',
        showBack: true,
        actions: [
          TextButton(
            onPressed: _handleDiscard,
            child: const Text('Discard', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
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
                      // Vehicle Type Segmented Control
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(children: [
                          Expanded(child: _SegmentBtn('Two-Wheeler', _vehicleType == 'Two-Wheeler', () => setState(() => _vehicleType = 'Two-Wheeler'))),
                          Expanded(child: _SegmentBtn('Four-Wheeler', _vehicleType == 'Four-Wheeler', () => setState(() => _vehicleType = 'Four-Wheeler'))),
                        ]),
                      ),
                      const SizedBox(height: 20),

                      _Section('Accessories & Interior', children: [
                        _Check('Key Remote', _checklist.keyRemote,
                            (v) => setState(() => _checklist = _checklist.copyWith(keyRemote: v))),
                        if (_vehicleType == 'Four-Wheeler') ...[
                          _Check('Audio System with Face Plate', _checklist.audioSystem,
                              (v) => setState(() => _checklist = _checklist.copyWith(audioSystem: v))),
                          _Check('CD/DVD Changer', _checklist.cdDvdChanger,
                              (v) => setState(() => _checklist = _checklist.copyWith(cdDvdChanger: v))),
                          _NumRow('Speakers (Nos)', _speakersCtrl),
                        ],
                        _Check('Owner Manual', _checklist.ownerManual,
                            (v) => setState(() => _checklist = _checklist.copyWith(ownerManual: v))),
                        if (_vehicleType == 'Four-Wheeler') ...[
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
                        ],
                        _TextRow('Seat Covers', _seatCtrl),
                      ]),
                      const SizedBox(height: 16),
                      _Section('Safety & Exterior', children: [
                        if (_vehicleType == 'Four-Wheeler') ...[
                          _Check('Jack & Handle', _checklist.jackHandle,
                              (v) => setState(() => _checklist = _checklist.copyWith(jackHandle: v))),
                          _Toggle('Underbody', 'Scratches/Damages', _checklist.underbodyDamages,
                              (v) => setState(() => _checklist = _checklist.copyWith(underbodyDamages: v))),
                          _Check('Boot Mat', _checklist.bootMat,
                              (v) => setState(() => _checklist = _checklist.copyWith(bootMat: v))),
                        ],
                        _Check('First Aid Kit', _checklist.firstAidKit,
                            (v) => setState(() => _checklist = _checklist.copyWith(firstAidKit: v))),
                        _TextRow('Tool List', _toolCtrl),
                        if (_vehicleType == 'Four-Wheeler') ...[
                          _Check('Wheel Cover/Cap', _checklist.wheelCoverCap,
                              (v) => setState(() => _checklist = _checklist.copyWith(wheelCoverCap: v))),
                          _Check('Mud Flaps', _checklist.mudFlaps,
                              (v) => setState(() => _checklist = _checklist.copyWith(mudFlaps: v))),
                          _Check('Spare Wheel', _checklist.spareWheel,
                              (v) => setState(() => _checklist = _checklist.copyWith(spareWheel: v))),
                        ],
                        _NumRow('Side Mirror (Nos)', _mirrorCtrl),
                        if (_vehicleType == 'Four-Wheeler') ...[
                          _NumRow('Fog Lamp (Nos)', _fogCtrl),
                          _Check('Wiper Arms/Blades', _checklist.wiperArmsBlades,
                              (v) => setState(() => _checklist = _checklist.copyWith(wiperArmsBlades: v))),
                        ],
                        if (_vehicleType == 'Two-Wheeler') ...[
                          _Check('Helmet', _checklist.helmet,
                              (v) => setState(() => _checklist = _checklist.copyWith(helmet: v))),
                        ],
                        _Check('Fuel Cap', _checklist.fuelCap,
                            (v) => setState(() => _checklist = _checklist.copyWith(fuelCap: v))),
                        _Toggle('Horns', 'Low/High Tone', _checklist.hornLowHigh,
                            (v) => setState(() => _checklist = _checklist.copyWith(hornLowHigh: v))),
                        _MultilineRow('Others', _othersCtrl),
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
      ),
    );
  }

  Widget _SegmentBtn(String label, bool isActive, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? AppColors.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: isActive ? [BoxShadow(color: AppColors.accent.withOpacity(0.2), blurRadius: 8)] : [],
      ),
      alignment: Alignment.center,
      child: Text(label, style: TextStyle(
        fontSize: 13, fontWeight: FontWeight.w700,
        color: isActive ? Colors.black : AppColors.textSecondary,
      )),
    ),
  );

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

  Widget _MultilineRow(String label, TextEditingController ctrl) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.body),
      const SizedBox(height: 8),
      TextField(
        controller: ctrl, 
        style: AppTextStyles.body,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Describe any other items or damages...', hintStyle: AppTextStyles.caption,
          filled: true, fillColor: AppColors.surfaceElevated,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
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
