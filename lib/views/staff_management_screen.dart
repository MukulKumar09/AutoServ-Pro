// lib/views/staff_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../widgets/app_widgets.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});
  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (!auth.isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text('Staff Management', style: AppTextStyles.heading3),
        ),
        body: const Center(
          child: Text('Access Denied — Admin only',
              style: AppTextStyles.bodySecondary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Staff Management', style: AppTextStyles.heading3),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      // FAB opens Add Staff bottom sheet
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStaffSheet(context, auth),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Staff',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: FirebaseService().watchAllStaff(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.accent));
          }
          final all = snap.data ?? [];
          if (all.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.people_outline,
                        size: 48, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  const Text('No staff members yet',
                      style: AppTextStyles.heading3),
                  const SizedBox(height: 8),
                  const Text('Tap + Add Staff to create an account',
                      style: AppTextStyles.bodySecondary),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: all.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) => _StaffTile(
              user: all[i],
              isCurrentUser: all[i].uid == auth.currentUser?.uid,
              onToggle: (val) async {
                await FirebaseService().toggleStaffActive(all[i].uid, val);
              },
            ),
          );
        },
      ),
    );
  }

  void _showAddStaffSheet(BuildContext context, AuthController auth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddStaffSheet(),
    );
  }
}

// ── Add Staff Bottom Sheet ────────────────────────────────────────────────────
class _AddStaffSheet extends StatefulWidget {
  const _AddStaffSheet();
  @override
  State<_AddStaffSheet> createState() => _AddStaffSheetState();
}

class _AddStaffSheetState extends State<_AddStaffSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  UserRole _role = UserRole.serviceAdvisor;
  bool _obscure = true;
  bool _adding = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _adding = true);

    try {
      await FirebaseService().createStaffUser(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        role: _role,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${_nameCtrl.text.trim()} added successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(12),
        ));
      }
    } catch (e) {
      setState(() => _adding = false);
      if (mounted) {
        showSnackBar(
          context,
          e.toString().contains('email-already-in-use')
              ? 'Email already in use. Choose a different email.'
              : 'Failed: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_add_rounded,
                    color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add Staff Member', style: AppTextStyles.heading3),
                  Text('Fill details to create login account',
                      style: AppTextStyles.caption),
                ],
              ),
            ]),
            const SizedBox(height: 24),

            // Full Name
            const Text('Full Name', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameCtrl,
              style: AppTextStyles.body,
              textInputAction: TextInputAction.next,
              decoration: _deco('e.g. Rahul Patil', Icons.person_outline),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),

            // Email
            const Text('Email Address', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailCtrl,
              style: AppTextStyles.body,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: _deco('staff@autoserv.com', Icons.email_outlined),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Invalid email address';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Password
            const Text('Password', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passCtrl,
              style: AppTextStyles.body,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration:
                  _deco('Min 6 characters', Icons.lock_outlined).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) return 'Minimum 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Role selector
            const Text('Role', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Row(children: [
              _RoleChip(
                label: 'Service Advisor',
                icon: Icons.build_circle_outlined,
                color: AppColors.info,
                selected: _role == UserRole.serviceAdvisor,
                onTap: () => setState(() => _role = UserRole.serviceAdvisor),
              ),
              const SizedBox(width: 10),
              _RoleChip(
                label: 'Accountant',
                icon: Icons.calculate_outlined,
                color: AppColors.success,
                selected: _role == UserRole.accountant,
                onTap: () => setState(() => _role = UserRole.accountant),
              ),
            ]),
            const SizedBox(height: 24),

            // Info note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withOpacity(0.2)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 15),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Staff can log in immediately from the login screen using this email & password.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _adding ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _adding
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Add Staff Member',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _deco(String hint, IconData icon) => InputDecoration(
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
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.error)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );
}

// ── Role Chip ─────────────────────────────────────────────────────────────────
class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? color.withOpacity(0.15)
                  : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? color : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(children: [
              Icon(icon,
                  color: selected ? color : AppColors.textMuted, size: 22),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                    color: selected ? color : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center),
            ]),
          ),
        ),
      );
}

// ── Staff Tile ────────────────────────────────────────────────────────────────
class _StaffTile extends StatelessWidget {
  final UserModel user;
  final bool isCurrentUser;
  final ValueChanged<bool> onToggle;

  const _StaffTile({
    required this.user,
    required this.isCurrentUser,
    required this.onToggle,
  });

  Color get _roleColor => switch (user.role) {
        UserRole.admin => AppColors.accent,
        UserRole.serviceAdvisor => AppColors.info,
        UserRole.accountant => AppColors.success,
      };

  IconData get _roleIcon => switch (user.role) {
        UserRole.admin => Icons.admin_panel_settings_rounded,
        UserRole.serviceAdvisor => Icons.build_circle_rounded,
        UserRole.accountant => Icons.calculate_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: user.isActive
            ? AppColors.cardBg
            : AppColors.cardBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: user.isActive
              ? AppColors.border
              : AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Row(children: [
        // Avatar circle
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _roleColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(23),
          ),
          child: Center(
            child: user.name.isNotEmpty
                ? Text(
                    user.name[0].toUpperCase(),
                    style: TextStyle(
                      color: _roleColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : Icon(_roleIcon, color: _roleColor, size: 20),
          ),
        ),
        const SizedBox(width: 12),

        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + "You" badge
              Row(children: [
                Expanded(
                  child: Text(
                    user.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isCurrentUser) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('You',
                        style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800)),
                  ),
                ],
              ]),
              const SizedBox(height: 3),

              // Email
              Text(user.email,
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),

              // Role badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _roleColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_roleIcon, color: _roleColor, size: 12),
                  const SizedBox(width: 4),
                  Text(user.roleLabel,
                      style: TextStyle(
                          color: _roleColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ],
          ),
        ),

        // Toggle — only non-self
        if (!isCurrentUser)
          Column(children: [
            Transform.scale(
              scale: 0.85,
              child: Switch(
                value: user.isActive,
                onChanged: onToggle,
                activeColor: AppColors.accent,
                activeTrackColor: AppColors.accent.withOpacity(0.3),
                inactiveThumbColor: AppColors.textMuted,
                inactiveTrackColor: AppColors.border,
              ),
            ),
            Text(
              user.isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: user.isActive ? AppColors.success : AppColors.error,
              ),
            ),
          ])
        else
          const SizedBox(width: 8),
      ]),
    );
  }
}
