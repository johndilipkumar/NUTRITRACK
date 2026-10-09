import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  Map<String, dynamic>? _overview;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOverview();
  }

  Future<void> _fetchOverview() async {
    try {
      final overview = await _adminService.getOverview();
      setState(() {
        _overview = overview;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load admin overview.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Control Panel', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : RefreshIndicator(
                  onRefresh: _fetchOverview,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text('System Overview', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      
                      // Stat Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        children: [
                          _buildStatCard('Total Users', _overview!['totalUsers'].toString(), Icons.people_rounded, isDark),
                          _buildStatCard('Active Subs', _overview!['activeSubscriptions'].toString(), Icons.card_membership_rounded, isDark),
                          _buildStatCard('Paid Users', _overview!['paidUsers'].toString(), Icons.monetization_on_rounded, isDark),
                          _buildStatCard('AI Requests (30d)', _overview!['usage']['totalRequests'].toString(), Icons.analytics_rounded, isDark),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.attach_money_rounded, color: AppColors.success),
                                SizedBox(width: 8),
                                Text('Est. API Cost (30d)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '\$${(_overview!['usage']['estimatedCostUsd'] ?? 0).toStringAsFixed(2)}',
                              style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text('${_overview!['usage']['totalInputTokens']} in / ${_overview!['usage']['totalOutputTokens']} out tokens', style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      Text('Quick Actions', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      
                      _buildActionTile(
                        'Manage Users',
                        'View users, adjust credits, override plans',
                        Icons.manage_accounts_rounded,
                        isDark,
                        () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User management coming soon!'))),
                      ),
                      const SizedBox(height: 12),
                      _buildActionTile(
                        'Plan Configuration',
                        'Edit plan limits and features',
                        Icons.settings_suggest_rounded,
                        isDark,
                        () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan config coming soon!'))),
                      ),
                      const SizedBox(height: 12),
                      _buildActionTile(
                        'Global Safeguards',
                        'Emergency AI cutoff, budget limits',
                        Icons.security_rounded,
                        isDark,
                        () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Safeguards coming soon!'))),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primaryLight),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const Spacer(),
          Text(value, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
