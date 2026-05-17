// lib/views/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../controllers/auth_controller.dart';
import '../controllers/job_card_controller.dart';
import '../models/job_card_model.dart';
import '../widgets/app_widgets.dart';
import '../widgets/main_scaffold.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      context.read<JobCardController>().watchJobCards(
        isAdmin: auth.isAdmin,
        uid: auth.currentUser?.uid ?? '',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<JobCardController>();
    final auth = context.watch<AuthController>();

    return MainScaffold(
      title: AppStrings.appName,
      actions: [
        // Notifications / profile
        if (auth.isAdmin)
          IconButton(
            icon: const Icon(Icons.people_rounded, color: AppColors.textPrimary, size: 22),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.staffManagement),
            tooltip: 'Staff',
          ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: AppColors.textMuted, size: 20),
          onPressed: () => _confirmLogout(context, auth),
          tooltip: 'Logout',
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.vehicleEntry),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Job Card', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ctrl.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.surface,
              onRefresh: () async {
                final auth = context.read<AuthController>();
                context.read<JobCardController>().watchJobCards(
                  isAdmin: auth.isAdmin,
                  uid: auth.currentUser?.uid ?? '',
                );
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome
                    Text('Hello, ${auth.currentUser?.name ?? 'User'} 👋',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 4),
                    const Text("Today's Overview",
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),

                    // Stat grid 2x3
                    _buildStatGrid(ctrl),
                    const SizedBox(height: 24),

                    // Recent job cards
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Recent Jobs',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.customerHistory),
                          child: const Text('See all', style: TextStyle(color: AppColors.accent, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildRecentList(ctrl),
                    const SizedBox(height: 80), // FAB space
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatGrid(JobCardController ctrl) {
    final stats = [
      _StatData('Cars Today',    ctrl.todayCars.toString(),           Icons.directions_car_rounded,      AppColors.info),
      _StatData('Open Jobs',     ctrl.openJobs.toString(),            Icons.work_outline_rounded,        AppColors.warning),
      _StatData('Completed',     ctrl.completedJobs.toString(),       Icons.check_circle_outline_rounded, AppColors.success),
      _StatData('Pending Bills', ctrl.allJobCards.where((c) => c.hasBalance).length.toString(), Icons.receipt_outlined, AppColors.error),
      _StatData('Revenue',       _currency(ctrl.todayRevenue),        Icons.currency_rupee_rounded,      AppColors.success),
      _StatData('EMI Pending',   _currency(ctrl.emiPending),          Icons.warning_amber_rounded,       ctrl.emiPending > 0 ? AppColors.error : AppColors.textMuted),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.7,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) => _MobileStatCard(stat: stats[i]),
    );
  }

  Widget _buildRecentList(JobCardController ctrl) {
    final recent = ctrl.getRecentJobCards(limit: 8);
    if (recent.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text('No job cards yet. Tap + to create one.',
              style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
        ),
      );
    }
    return Column(
      children: recent
          .map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: JobCardListTile(
                  card: c,
                  onTap: () {
                    context.read<JobCardController>().setActiveJobCard(c);
                    Navigator.pushNamed(context, AppRoutes.labourBilling);
                  },
                ),
              ))
          .toList(),
    );
  }

  Future<void> _confirmLogout(BuildContext ctx, AuthController auth) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Logout', style: AppTextStyles.heading3),
        content: const Text('Are you sure you want to logout?',
            style: AppTextStyles.bodySecondary),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (ok == true) await auth.signOut();
  }

  String _currency(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }
}

class _StatData {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatData(this.title, this.value, this.icon, this.color);
}

class _MobileStatCard extends StatelessWidget {
  final _StatData stat;
  const _MobileStatCard({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(stat.title,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: stat.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(stat.icon, color: stat.color, size: 14),
              ),
            ],
          ),
          Text(stat.value,
              style: TextStyle(
                  color: stat.color,
                  fontSize: 18, fontWeight: FontWeight.w800),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
