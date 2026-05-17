// lib/views/visual_inspection_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../controllers/job_card_controller.dart';
import '../widgets/app_widgets.dart';
import '../widgets/main_scaffold.dart';
import '../services/cloudinary_service.dart';

class VisualInspectionScreen extends StatefulWidget {
  const VisualInspectionScreen({super.key});
  @override
  State<VisualInspectionScreen> createState() => _VisualInspectionScreenState();
}
class _VisualInspectionScreenState extends State<VisualInspectionScreen> {
  final _damageCtrl = TextEditingController();
  final _picker     = ImagePicker();
  static const _slots = [
    ('front',    Icons.arrow_upward_rounded,           'Front'),
    ('rear',     Icons.arrow_downward_rounded,          'Rear'),
    ('left',     Icons.arrow_back_rounded,              'Left Side'),
    ('right',    Icons.arrow_forward_rounded,           'Right Side'),
    ('top',      Icons.crop_free_rounded,               'Top'),
    ('interior', Icons.airline_seat_recline_normal_rounded, 'Interior'),
    ('fuel',     Icons.local_gas_station_rounded,       'Fuel Gauge'),
  ];

  @override
  void initState() {
    super.initState();
    final card = context.read<JobCardController>().activeJobCard;
    if (card != null) _damageCtrl.text = card.damageNotes;
  }

  @override
  void dispose() { _damageCtrl.dispose(); super.dispose(); }

  Future<void> _pickImage(String slot) async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Select Image Source', style: AppTextStyles.heading3),
          const SizedBox(height: 16),
          ListTile(
            leading: Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.camera_alt, color: AppColors.accent, size: 20)),
            title: const Text('Camera', style: AppTextStyles.body),
            subtitle: const Text('Take a new photo', style: AppTextStyles.caption),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.info.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.photo_library, color: AppColors.info, size: 20)),
            title: const Text('Gallery', style: AppTextStyles.body),
            subtitle: const Text('Choose from gallery', style: AppTextStyles.caption),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (src == null) return;

    final xf = await _picker.pickImage(source: src, imageQuality: 70, maxWidth: 1200);
    if (xf == null) return;
    if (mounted) {
      context.read<JobCardController>().setDraftImage(slot, File(xf.path));
    }
  }

  void _saveAndNext() {
    final ctrl = context.read<JobCardController>();
    final card = ctrl.activeJobCard;
    if (card == null) return;

    final updated = card.copyWith(
      damageNotes: _damageCtrl.text.trim(),
    );
    ctrl.setActiveJobCard(updated);
    Navigator.pushNamed(context, AppRoutes.mechanicalChecklist);
  }

  void _onBack() {
    final ctrl = context.read<JobCardController>();
    if (ctrl.activeJobCard != null) {
      ctrl.setActiveJobCard(ctrl.activeJobCard!.copyWith(damageNotes: _damageCtrl.text.trim()));
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
    final ctrl = context.watch<JobCardController>();
    final card = ctrl.activeJobCard;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _onBack();
      },
      child: MainScaffold(
        title: 'Visual Inspection',
        showBack: true,
        actions: [
          TextButton(
            onPressed: _handleDiscard,
            child: const Text('Discard', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
        body: card == null
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.camera_alt_outlined, size: 56, color: AppColors.textMuted),
                const SizedBox(height: 12),
                const Text('No active job card', style: AppTextStyles.bodySecondary),
                const SizedBox(height: 16),
                PrimaryButton(label: 'Create Job Card', icon: Icons.add,
                    onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.vehicleEntry)),
              ]))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // RO info
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.camera_alt, color: AppColors.accent, size: 16),
                      const SizedBox(width: 8),
                      Text('${card.roNumber} — ${card.registrationNumber}',
                          style: AppTextStyles.accent.copyWith(fontSize: 13)),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  const Text('Vehicle Photos', style: AppTextStyles.heading3),
                  const SizedBox(height: 4),
                  const Text('Upload photos from all sides before service',
                      style: AppTextStyles.bodySecondary),
                  const SizedBox(height: 14),

                  // Image grid
                  GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: _slots.map((slot) {
                      final (key, icon, label) = slot;
                      final local  = ctrl.draftInspectionImages[key];
                      final remote = card.inspectionImages[key]
                          ?? (key == 'fuel' ? card.fuelGaugeImage : null);
                      return _ImageSlot(
                        label: label, icon: icon,
                        localFile: local, remoteUrl: remote,
                        isUploading: false,
                        onTap: () => _pickImage(key),
                        onRemove: () => ctrl.removeDraftImage(key),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Damage notes
                  const Text('Damage / Observations', style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _damageCtrl,
                    maxLines: 3,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: 'Note pre-existing damages, scratches, dents...',
                      hintStyle: AppTextStyles.caption,
                      filled: true, fillColor: AppColors.surfaceElevated,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(children: [
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
                  const SizedBox(height: 20),
                ]),
              ),
      ),
    );
  }
}

class _ImageSlot extends StatelessWidget {
  final String label;
  final IconData icon;
  final File? localFile;
  final String? remoteUrl;
  final bool isUploading;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ImageSlot({
    required this.label, required this.icon,
    required this.localFile, required this.remoteUrl,
    required this.isUploading, required this.onTap, required this.onRemove,
  });

  bool get hasImage => localFile != null || remoteUrl != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasImage ? AppColors.accent.withOpacity(0.5) : AppColors.border,
            width: hasImage ? 1.5 : 1,
          ),
        ),
        child: Stack(fit: StackFit.expand, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: hasImage
                ? (localFile != null
                    ? Image.file(localFile!, fit: BoxFit.cover)
                    : Image.network(remoteUrl!, fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) =>
                            progress == null ? child
                                : const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2)),
                        errorBuilder: (_, __, ___) =>
                            const Center(child: Icon(Icons.broken_image, color: AppColors.textMuted))))
                : Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(icon, size: 28, color: AppColors.textMuted),
                    const SizedBox(height: 6),
                    Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
                    const SizedBox(height: 2),
                    const Text('Tap to add', style: TextStyle(color: AppColors.accent, fontSize: 10)),
                  ])),
          ),
          if (isUploading)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2)),
            ),
          if (hasImage && !isUploading)
            Positioned(top: 4, right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                ),
              )),
          if (hasImage && !isUploading)
            Positioned(bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
                ),
                child: Row(children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 12),
                  const SizedBox(width: 4),
                  Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
                ]),
              )),
        ]),
      ),
    );
  }
}
