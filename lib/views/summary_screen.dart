import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../constants/app_constants.dart';
import '../controllers/job_card_controller.dart';
import '../services/cloudinary_service.dart';
import '../services/pdf_service.dart';
import '../widgets/main_scaffold.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});
  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  bool _uploading = false;
  bool _success = false;
  String _progressText = '';

  Future<void> _submit() async {
    setState(() { _uploading = true; _progressText = 'Saving Job Card Data...'; });
    final ctrl = context.read<JobCardController>();
    
    // Save to Firestore
    final id = await ctrl.submitDraftJobCard();
    if (id == null) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ctrl.error ?? 'Failed to save job card'), backgroundColor: AppColors.error));
      }
      setState(() => _uploading = false);
      return;
    }

    final card = ctrl.activeJobCard!;
    
    // Upload images
    setState(() => _progressText = 'Uploading Photos...');
    final updatedImages = Map<String, String>.from(card.inspectionImages);
    final draftImages = ctrl.draftInspectionImages;
    int uploaded = 0;
    
    if (draftImages.isNotEmpty) {
      for (final entry in draftImages.entries) {
        final slot = entry.key;
        final file = entry.value;
        try {
           setState(() => _progressText = 'Uploading Photos (${uploaded + 1}/${draftImages.length})...');
           final url = await CloudinaryService.uploadFile(file, folder: 'garage/inspections/$id');
           updatedImages[slot] = url;
           uploaded++;
        } catch(e) {
           debugPrint('Failed to upload $slot: $e');
        }
      }
    }

    // Update remote DB with new URLs
    setState(() => _progressText = 'Finalizing...');
    await ctrl.updateJobCard(card.copyWith(
      inspectionImages: updatedImages,
      fuelGaugeImage: updatedImages['fuel'] ?? card.fuelGaugeImage,
    ));

    ctrl.draftInspectionImages.clear();

    setState(() {
      _uploading = false;
      _success = true;
    });
  }

  Future<void> _sharePdf() async {
     final card = context.read<JobCardController>().activeJobCard;
     if (card == null) return;
     final bytes = await PdfService.generateJobCardPdf(card);
     await Printing.sharePdf(bytes: bytes, filename: 'JobCard_${card.roNumber}.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final card = context.watch<JobCardController>().activeJobCard;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_uploading) return;
        if (_success) {
           Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
           return;
        }
        Navigator.pop(context);
      },
      child: MainScaffold(
        title: _success ? 'Job Card Created' : 'Summary',
        showBack: !_uploading && !_success,
        actions: _success || _uploading ? [] : [
          TextButton(
            onPressed: () {
               // Discard logic
               Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
            },
            child: const Text('Discard', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
        body: card == null
            ? const Center(child: Text('No active job card', style: AppTextStyles.bodySecondary))
            : Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                             _buildSection('Customer Details', [
                               _buildRow('Name', card.customerName),
                               _buildRow('Contact', card.contactNumber),
                               _buildRow('Address', card.address),
                             ]),
                             const SizedBox(height: 12),
                             _buildSection('Vehicle Details', [
                               _buildRow('Vehicle', '${card.vehicleMake} ${card.vehicleModel}'),
                               _buildRow('Registration', card.registrationNumber),
                               _buildRow('KM Reading', card.kmReading),
                             ]),
                             const SizedBox(height: 12),
                             _buildSection('Jobs', [
                               _buildRow('Demanded', card.demandedJobs.isEmpty ? 'None' : card.demandedJobs.join(', ')),
                               _buildRow('Recommended', card.recommendedJobs.isEmpty ? 'None' : card.recommendedJobs.join(', ')),
                             ]),
                             const SizedBox(height: 12),
                             _buildSection('Notes', [
                               _buildRow('Damage Notes', card.damageNotes.isEmpty ? 'None' : card.damageNotes),
                             ]),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                            color: AppColors.surface,
                            border: Border(top: BorderSide(color: AppColors.border))),
                        child: _success 
                            ? Row(children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.dashboard),
                                    icon: const Icon(Icons.close, size: 15),
                                    label: const Text('Close'),
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
                                    onPressed: _sharePdf,
                                    icon: const Icon(Icons.share, size: 17),
                                    label: const Text('Share PDF', style: TextStyle(fontWeight: FontWeight.w700)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.info,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              ])
                            : Row(children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => Navigator.pop(context),
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
                                    onPressed: _submit,
                                    icon: const Icon(Icons.cloud_upload_outlined, size: 17),
                                    label: const Text('Create Job Card', style: TextStyle(fontWeight: FontWeight.w700)),
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
                    ],
                  ),
                  if (_uploading)
                    Container(
                      color: Colors.black.withOpacity(0.85),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: AppColors.accent),
                          const SizedBox(height: 24),
                          Text(_progressText, style: AppTextStyles.heading2),
                          const SizedBox(height: 8),
                          const Text('Please do not close the app', style: AppTextStyles.bodySecondary),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading3),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: AppTextStyles.bodySecondary)),
          Expanded(child: Text(value, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}
