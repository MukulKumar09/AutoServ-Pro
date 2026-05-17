// lib/views/authorization_screen.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import '../constants/app_constants.dart';
import '../controllers/job_card_controller.dart';
import '../models/job_card_model.dart';
import '../services/cloudinary_service.dart';
import '../widgets/app_widgets.dart';
import '../widgets/main_scaffold.dart';

class AuthorizationScreen extends StatefulWidget {
  const AuthorizationScreen({super.key});
  @override
  State<AuthorizationScreen> createState() => _AuthorizationScreenState();
}

class _AuthorizationScreenState extends State<AuthorizationScreen> {
  final _customerSigKey = GlobalKey<SfSignaturePadState>();
  final _managerSigKey  = GlobalKey<SfSignaturePadState>();
  final _receivedCtrl   = TextEditingController();
  final _notesCtrl      = TextEditingController();

  DateTime? _outTime;
  bool _saving           = false;
  bool _customerSigned   = false;
  bool _managerSigned    = false;
  JobStatus _status      = JobStatus.delivered;

  @override
  void initState() {
    super.initState();
    final card = context.read<JobCardController>().activeJobCard;
    if (card != null) {
      _receivedCtrl.text = card.receivedBy;
      _notesCtrl.text    = card.deliveryNotes;
      _outTime = card.outTime ?? DateTime.now();
      _status  = card.status;
    } else {
      _outTime = DateTime.now();
    }
  }

  @override
  void dispose() {
    _receivedCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_outTime ?? now),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.accent),
        ),
        child: child!,
      ),
    );
    if (t != null) setState(() => _outTime = DateTime(now.year, now.month, now.day, t.hour, t.minute));
  }

  Future<Uint8List?> _capturePad(GlobalKey<SfSignaturePadState> key) async {
    try {
      final img   = await key.currentState!.toImage(pixelRatio: 2);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      return bytes?.buffer.asUint8List();
    } catch (_) { return null; }
  }

  Future<void> _save() async {
    final ctrl = context.read<JobCardController>();
    final card = ctrl.activeJobCard;
    if (card == null) { showSnackBar(context, 'No active job card', isError: true); return; }
    setState(() => _saving = true);

    try {
      String? custUrl = card.customerSignatureUrl;
      String? mgrUrl  = card.managerSignatureUrl;

      if (_customerSigned) {
        final bytes = await _capturePad(_customerSigKey);
        if (bytes != null) {
          custUrl = await CloudinaryService.uploadBytes(bytes,
              folder: 'garage/signatures/${card.id}', fileName: 'customer_sig');
        }
      }
      if (_managerSigned) {
        final bytes = await _capturePad(_managerSigKey);
        if (bytes != null) {
          mgrUrl = await CloudinaryService.uploadBytes(bytes,
              folder: 'garage/signatures/${card.id}', fileName: 'manager_sig');
        }
      }

      final updated = card.copyWith(
        outTime: _outTime, status: _status,
        receivedBy: _receivedCtrl.text.trim(),
        deliveryNotes: _notesCtrl.text.trim(),
        customerSignatureUrl: custUrl,
        managerSignatureUrl:  mgrUrl,
      );
      await ctrl.updateJobCard(updated);
      setState(() => _saving = false);
      if (mounted) showSnackBar(context, 'Authorization saved ✓');
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) showSnackBar(context, 'Failed: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = context.watch<JobCardController>().activeJobCard;

    return MainScaffold(
      title: 'Authorization & Delivery',
      showBack: true,
      body: card == null
          ? Center(child: PrimaryButton(label: 'Create Job Card', icon: Icons.add,
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.vehicleEntry)))
          : LoadingOverlay(
              isLoading: _saving,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Time & Duration Card
                  AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Service Duration', style: AppTextStyles.heading3),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: _TimeCell('IN TIME', formatTime(card.inTime), null, null)),
                      const SizedBox(width: 8),
                      Expanded(child: _TimeCell('OUT TIME',
                          _outTime != null ? formatTime(_outTime!) : 'Set Time',
                          AppColors.accent, _pickTime)),
                      const SizedBox(width: 8),
                      Expanded(child: _TimeCell('DURATION',
                          formatDuration(_outTime?.difference(card.inTime)), AppColors.info, null)),
                    ]),
                  ])),
                  const SizedBox(height: 14),

                  // Status
                  AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Job Status', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<JobStatus>(
                      value: _status,
                      dropdownColor: AppColors.surface,
                      decoration: InputDecoration(
                        filled: true, fillColor: AppColors.surfaceElevated,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: JobStatus.values.map((s) => DropdownMenuItem(
                        value: s, child: StatusBadge.jobStatus(s),
                      )).toList(),
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                  ])),
                  const SizedBox(height: 14),

                  // Delivery details
                  AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SectionHeader(title: 'Delivery Details'),
                    const SizedBox(height: 14),
                    AppTextField(label: 'Received By', hint: 'Name of person receiving vehicle',
                        controller: _receivedCtrl),
                    const SizedBox(height: 12),
                    AppTextField(label: 'Delivery Notes', hint: 'Any notes...',
                        controller: _notesCtrl, maxLines: 2),
                  ])),
                  const SizedBox(height: 14),

                  // Customer signature
                  _SignaturePadCard(
                    title: 'Customer Signature',
                    padKey: _customerSigKey,
                    signed: _customerSigned,
                    existingUrl: card.customerSignatureUrl,
                    onSigned: () => setState(() => _customerSigned = true),
                    onCleared: () => setState(() => _customerSigned = false),
                  ),
                  const SizedBox(height: 14),

                  // Manager signature
                  _SignaturePadCard(
                    title: 'Manager / Advisor Signature',
                    padKey: _managerSigKey,
                    signed: _managerSigned,
                    existingUrl: card.managerSignatureUrl,
                    onSigned: () => setState(() => _managerSigned = true),
                    onCleared: () => setState(() => _managerSigned = false),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(width: double.infinity,
                      child: PrimaryButton(label: 'Save Authorization', icon: Icons.verified,
                          isLoading: _saving, onPressed: _save)),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
    );
  }
}

class _TimeCell extends StatelessWidget {
  final String label, value;
  final Color? color;
  final VoidCallback? onTap;
  const _TimeCell(this.label, this.value, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color != null ? color!.withOpacity(0.3) : AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(
          color: color ?? AppColors.textPrimary,
          fontSize: 13, fontWeight: FontWeight.w700,
        )),
        if (onTap != null)
          const Text('tap to edit', style: TextStyle(color: AppColors.accent, fontSize: 9)),
      ]),
    ),
  );
}

class _SignaturePadCard extends StatelessWidget {
  final String title;
  final GlobalKey<SfSignaturePadState> padKey;
  final bool signed;
  final String? existingUrl;
  final VoidCallback onSigned, onCleared;
  const _SignaturePadCard({required this.title, required this.padKey,
    required this.signed, required this.existingUrl,
    required this.onSigned, required this.onCleared});

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: AppTextStyles.heading3),
        if (signed)
          const Row(children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 16),
            SizedBox(width: 4),
            Text('Signed', style: TextStyle(color: AppColors.success, fontSize: 12)),
          ]),
      ]),
      const SizedBox(height: 12),
      Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: signed ? AppColors.success : AppColors.border, width: signed ? 2 : 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: SfSignaturePad(
            key: padKey,
            backgroundColor: Colors.white,
            strokeColor: Colors.black,
            minimumStrokeWidth: 1.5,
            maximumStrokeWidth: 3,
            onDrawEnd: () => onSigned(),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Row(children: [
        TextButton.icon(
          onPressed: () { padKey.currentState?.clear(); onCleared(); },
          icon: const Icon(Icons.clear, size: 16),
          label: const Text('Clear'),
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
        ),
        if (existingUrl != null && !signed) ...[
          const Spacer(),
          const Icon(Icons.cloud_done, color: AppColors.success, size: 14),
          const SizedBox(width: 4),
          const Text('Previously saved', style: TextStyle(color: AppColors.success, fontSize: 11)),
        ],
      ]),
    ]),
  );
}
