// lib/views/vehicle_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../controllers/auth_controller.dart';
import '../controllers/job_card_controller.dart';
import '../models/job_card_model.dart';
import '../widgets/app_widgets.dart';
import '../widgets/main_scaffold.dart';
import '../widgets/wizard_step_bar.dart';

class VehicleEntryScreen extends StatefulWidget {
  const VehicleEntryScreen({super.key});
  @override
  State<VehicleEntryScreen> createState() => _VehicleEntryScreenState();
}

const List<String> _carMakes = [
  'Maruti Suzuki', 'Hyundai', 'Tata', 'Mahindra', 'Toyota', 'Kia', 'Honda',
  'Volkswagen', 'Skoda', 'Renault', 'Nissan', 'MG Motor', 'Citroen', 'Force Motors', 'Jeep'
];

class _VehicleEntryScreenState extends State<VehicleEntryScreen> {
  // ── Separate form keys per step ──────────────────────────────────────────
  final _step0Key = GlobalKey<FormState>(); // Customer step
  final _step1Key = GlobalKey<FormState>(); // Vehicle step

  // Customer
  final _nameCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _altCtrl = TextEditingController();

  // Vehicle
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _regCtrl = TextEditingController();
  final _chassisCtrl = TextEditingController();
  final _engineCtrl = TextEditingController();
  final _kmCtrl = TextEditingController();

  int _step = 0;
  bool _submitting = false;

  GlobalKey<FormState> get _currentKey => _step == 0 ? _step0Key : _step1Key;

  @override
  void initState() {
    super.initState();
    final card = context.read<JobCardController>().activeJobCard;
    if (card != null && card.id.isEmpty) {
      // Pre-fill from existing draft
      _nameCtrl.text = card.customerName;
      _addrCtrl.text = card.address;
      _contactCtrl.text = card.contactNumber;
      _altCtrl.text = card.alternateNumber;
      _makeCtrl.text = card.vehicleMake;
      _modelCtrl.text = card.vehicleModel;
      _regCtrl.text = card.registrationNumber;
      _chassisCtrl.text = card.chassisNumber;
      _engineCtrl.text = card.engineNumber;
      _kmCtrl.text = card.kmReading;
      if (_nameCtrl.text.isNotEmpty) _step = 1;
    } else {
      // Fresh start, clear any old active card
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<JobCardController>().setActiveJobCard(
          JobCardModel(
            id: '', roNumber: '', entryDate: DateTime.now(), inTime: DateTime.now(),
            customerName: '', address: '', contactNumber: '', alternateNumber: '',
            vehicleMake: '', vehicleModel: '', registrationNumber: '', chassisNumber: '',
            engineNumber: '', kmReading: '', createdBy: '', createdAt: DateTime.now(), updatedAt: DateTime.now(),
          )
        );
      });
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _addrCtrl,
      _contactCtrl,
      _altCtrl,
      _makeCtrl,
      _modelCtrl,
      _regCtrl,
      _chassisCtrl,
      _engineCtrl,
      _kmCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Next step — validate current step only ────────────────────────────────
  void _onNext() {
    FocusScope.of(context).unfocus();
    if (_currentKey.currentState!.validate()) {
      setState(() => _step = 1);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_step1Key.currentState!.validate()) return;

    final ctrl = context.read<JobCardController>();
    final auth = context.read<AuthController>();

    final draft = JobCardModel(
      id: '', roNumber: '', // Draft has empty ID
      entryDate: DateTime.now(), inTime: DateTime.now(),
      customerName: _nameCtrl.text.trim(),
      address: _addrCtrl.text.trim(),
      contactNumber: _contactCtrl.text.trim(),
      alternateNumber: _altCtrl.text.trim(),
      vehicleMake: _makeCtrl.text.trim(),
      vehicleModel: _modelCtrl.text.trim(),
      registrationNumber: _regCtrl.text.trim().toUpperCase(),
      chassisNumber: _chassisCtrl.text.trim(),
      engineNumber: _engineCtrl.text.trim(),
      kmReading: _kmCtrl.text.trim(),
      createdBy: auth.currentUser?.uid ?? '',
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );

    ctrl.setActiveJobCard(draft);
    Navigator.pushNamed(context, AppRoutes.inventoryChecklist);
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
    if (_step == 1) {
      setState(() => _step = 0);
    } else {
      _handleDiscard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _onBack();
      },
      child: MainScaffold(
        title: 'New Job Card',
        showBack: true,
        actions: [
          TextButton(
            onPressed: _handleDiscard,
            child: const Text('Discard', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
        body: Column(children: [
        // ── Step indicator ────────────────────────────────────────────────
        WizardStepBar(currentStep: _step),

        // ── RO info chip (Hidden for wizard journey) ──────────────────────
        /*
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.accent.withOpacity(0.25)),
          ),
          child: Row(children: [
            const Icon(Icons.confirmation_number_outlined,
                color: AppColors.accent, size: 15),
            const SizedBox(width: 8),
            Text(
              'RO Number auto-generated on save  (RO-${DateTime.now().year}-XXXX)',
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ]),
        ),
        */

        // ── Form pages (each step has its OWN Form widget) ────────────────
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.06, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: _step == 0
                ? _CustomerStep(
                    key: const ValueKey('step0'),
                    formKey: _step0Key,
                    controllers: _CustomerCtrls(
                      name: _nameCtrl,
                      addr: _addrCtrl,
                      contact: _contactCtrl,
                      alt: _altCtrl,
                    ))
                : _VehicleStep(
                    key: const ValueKey('step1'),
                    formKey: _step1Key,
                    controllers: _VehicleCtrls(
                      make: _makeCtrl,
                      model: _modelCtrl,
                      reg: _regCtrl,
                      chassis: _chassisCtrl,
                      engine: _engineCtrl,
                      km: _kmCtrl,
                    )),
          ),
        ),

        // ── Bottom action bar ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(children: [
            if (_step == 1) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _step = 0),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 15),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: _step == 0
                  ? ElevatedButton.icon(
                      onPressed: _onNext,
                      icon:
                          const Icon(Icons.arrow_forward_ios_rounded, size: 15),
                      label: const Text('Next',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_card_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Next',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15)),
                              ],
                            ),
                    ),
            ),
          ]),
        ),
      ]),
      ),
    );
  }
}

// ── Simple data holders ────────────────────────────────────────────────────
class _CustomerCtrls {
  final TextEditingController name, addr, contact, alt;
  const _CustomerCtrls(
      {required this.name,
      required this.addr,
      required this.contact,
      required this.alt});
}

class _VehicleCtrls {
  final TextEditingController make, model, reg, chassis, engine, km;
  const _VehicleCtrls(
      {required this.make,
      required this.model,
      required this.reg,
      required this.chassis,
      required this.engine,
      required this.km});
}

// ── Step 0 — Customer Info (has its OWN Form) ─────────────────────────────
class _CustomerStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final _CustomerCtrls controllers;

  const _CustomerStep(
      {super.key, required this.formKey, required this.controllers});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        children: [
          // Section label
          _SectionLabel('Customer Information', Icons.person_outline),
          const SizedBox(height: 16),

          // Name
          _Field(
            label: 'Customer Name *',
            hint: 'Full name',
            controller: controllers.name,
            icon: Icons.person,
            inputAction: TextInputAction.next,
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Customer name is required'
                : null,
          ),
          const SizedBox(height: 14),

          // Address
          _Field(
            label: 'Address',
            hint: 'Full address (optional)',
            controller: controllers.addr,
            icon: Icons.location_on_outlined,
            maxLines: 2,
            inputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),

          // Contact
          _Field(
            label: 'Contact Number *',
            hint: '9876543210',
            controller: controllers.contact,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            inputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (v) {
              if (v == null || v.isEmpty) return 'Contact number is required';
              if (v.length < 10) return 'Enter 10-digit number';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Alternate
          _Field(
            label: 'Alternate Number',
            hint: 'Optional',
            controller: controllers.alt,
            icon: Icons.phone_callback_outlined,
            keyboardType: TextInputType.phone,
            inputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Step 1 — Vehicle Info (has its OWN Form) ──────────────────────────────
class _VehicleStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final _VehicleCtrls controllers;

  const _VehicleStep(
      {super.key, required this.formKey, required this.controllers});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        children: [
          _SectionLabel('Vehicle Information', Icons.directions_car_outlined),
          const SizedBox(height: 16),

          // Make + Model side by side
          Row(children: [
            Expanded(
              child: RawAutocomplete<String>(
                textEditingController: controllers.make,
                focusNode: FocusNode(),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                  return _carMakes.where((make) => make.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return _Field(
                    label: 'Make *',
                    hint: 'Maruti, Honda...',
                    controller: controller,
                    icon: Icons.branding_watermark_outlined,
                    inputAction: TextInputAction.next,
                    focusNode: focusNode,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      color: AppColors.surfaceElevated,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width / 2 - 22,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final option = options.elementAt(index);
                            return ListTile(
                              title: Text(option, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Field(
                label: 'Model *',
                hint: 'Swift, City...',
                controller: controllers.model,
                icon: Icons.directions_car_filled_outlined,
                inputAction: TextInputAction.next,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
            ),
          ]),
          const SizedBox(height: 14),

          // Registration
          _Field(
            label: 'Registration Number *',
            hint: 'MH12AB1234',
            controller: controllers.reg,
            icon: Icons.pin_outlined,
            inputAction: TextInputAction.next,
            inputFormatters: [UpperCaseFormatter()],
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Registration number is required'
                : null,
          ),
          const SizedBox(height: 14),

          // Chassis
          _Field(
            label: 'Chassis Number',
            hint: 'VIN / Chassis No.',
            controller: controllers.chassis,
            icon: Icons.qr_code_outlined,
            inputAction: TextInputAction.next,
            inputFormatters: [UpperCaseFormatter()],
          ),
          const SizedBox(height: 14),

          // Engine
          _Field(
            label: 'Engine Number',
            hint: 'Engine No.',
            controller: controllers.engine,
            icon: Icons.settings_outlined,
            inputAction: TextInputAction.next,
            inputFormatters: [UpperCaseFormatter()],
          ),
          const SizedBox(height: 14),

          // KM
          _Field(
            label: 'KM Reading *',
            hint: 'Current odometer reading',
            controller: controllers.km,
            icon: Icons.speed_outlined,
            keyboardType: TextInputType.number,
            inputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'KM reading is required' : null,
          ),
        ],
      ),
    );
  }
}

// ── Reusable field widget ─────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final TextInputAction inputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final FocusNode? focusNode;

  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.inputAction = TextInputAction.next,
    this.inputFormatters,
    this.maxLines = 1,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        focusNode: focusNode,
        validator: validator,
        keyboardType: keyboardType,
        textInputAction: inputAction,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          prefixIcon: Icon(icon, color: AppColors.textMuted, size: 18),
          filled: true,
          fillColor: AppColors.surfaceElevated,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.accent, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.error)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
      ),
    ]);
  }
class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel(this.label, this.icon);

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.accent, size: 18),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
      ]);
}
