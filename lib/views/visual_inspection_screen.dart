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
  final Map<String, File?> _localFiles  = {};
  final Map<String, bool>  _uploading   = {};
  bool _saving = false;

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
    setState(() => _localFiles[slot] = File(xf.path));
  }

  Future<void> _save({bool goNext = false}) async {
    final ctrl = context.read<JobCardController>();
    final card = ctrl.activeJobCard;
    if (card == null) { showSnackBar(context, 'No active job card', isError: true); return; }
    setState(() => _saving = true);

    try {
      final updatedImages = Map<String, String>.from(card.inspectionImages);

      // Upload each local file to Cloudinary
      for (final entry in _localFiles.entries) {
        if (entry.value != null) {
          setState(() => _uploading[entry.key] = true);
          final url = await CloudinaryService.uploadFile(
            entry.value!, folder: 'garage/inspections/${card.id}');
          updatedImages[entry.key] = url;
          setState(() => _uploading[entry.key] = false);
        }
      }

      final updated = card.copyWith(
        inspectionImages: updatedImages,
        damageNotes: _damageCtrl.text.trim(),
        // fuel gauge separate field
        fuelGaugeImage: updatedImages['fuel'] ?? card.fuelGaugeImage,
      );
      await ctrl.updateJobCard(updated);
      setState(() => _saving = false);
      if (mounted) {
        if (goNext) Navigator.pushReplacementNamed(context, AppRoutes.mechanicalChecklist);
        else showSnackBar(context, 'Inspection photos saved to Cloudinary ✓');
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) showSnackBar(context, 'Upload failed: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = context.watch<JobCardController>().activeJobCard;

    return MainScaffold(
      title: 'Visual Inspection',
      showBack: true,
      body: card == null
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.camera_alt_outlined, size: 56, color: AppColors.textMuted),
              const SizedBox(height: 12),
              const Text('No active job card', style: AppTextStyles.bodySecondary),
              const SizedBox(height: 16),
              PrimaryButton(label: 'Create Job Card', icon: Icons.add,
                  onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.vehicleEntry)),
            ]))
          : LoadingOverlay(
              isLoading: _saving,
              child: SingleChildScrollView(
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
                      final local  = _localFiles[key];
                      final remote = card.inspectionImages[key]
                          ?? (key == 'fuel' ? card.fuelGaugeImage : null);
                      final isUploading = _uploading[key] == true;
                      return _ImageSlot(
                        label: label, icon: icon,
                        localFile: local, remoteUrl: remote,
                        isUploading: isUploading,
                        onTap: () => _pickImage(key),
                        onRemove: () => setState(() => _localFiles[key] = null),
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
                    Expanded(child: SecondaryButton(label: 'Save', icon: Icons.save,
                        onPressed: _saving ? null : () => _save())),
                    const SizedBox(width: 12),
                    Expanded(child: PrimaryButton(label: 'Next →', isLoading: _saving,
                        onPressed: () => _save(goNext: true))),
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
