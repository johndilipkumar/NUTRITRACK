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

  // ═══════════════════════════════════════════════════════════════════════════
  // PLAN MANAGEMENT MODAL
  // ═══════════════════════════════════════════════════════════════════════════
  void _showPlanManagementModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AdminPlanManagementSheet(adminService: _adminService),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // USER MANAGEMENT & USAGE INSPECTION MODAL
  // ═══════════════════════════════════════════════════════════════════════════
  void _showUserManagementModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AdminUserManagementSheet(adminService: _adminService),
    );
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
                            Text(
                              '${_overview!['usage']['totalInputTokens']} in / ${_overview!['usage']['totalOutputTokens']} out tokens',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                      Text('Quick Actions', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),

                      _buildActionTile(
                        'Manage Users & Inspect Usage',
                        'View users, check generation counts, manually assign plans',
                        Icons.manage_accounts_rounded,
                        isDark,
                        _showUserManagementModal,
                      ),
                      const SizedBox(height: 12),
                      _buildActionTile(
                        'Plan Configuration',
                        'Inspect configured plans, edit prices, generation limits',
                        Icons.settings_suggest_rounded,
                        isDark,
                        _showPlanManagementModal,
                      ),
                      const SizedBox(height: 12),
                      _buildActionTile(
                        'Global Safeguards',
                        'Emergency AI cutoff, budget limits',
                        Icons.security_rounded,
                        isDark,
                        () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Global safeguards are active.')),
                        ),
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
                color: AppColors.primary.withValues(alpha: 0.1),
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

// ═══════════════════════════════════════════════════════════════════════════
// PLAN MANAGEMENT BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════════
class _AdminPlanManagementSheet extends StatefulWidget {
  final AdminService adminService;
  const _AdminPlanManagementSheet({required this.adminService});

  @override
  State<_AdminPlanManagementSheet> createState() => _AdminPlanManagementSheetState();
}

class _AdminPlanManagementSheetState extends State<_AdminPlanManagementSheet> {
  bool _isLoading = true;
  List<dynamic> _plans = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final plans = await widget.adminService.getPlans();
      setState(() {
        _plans = plans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load plans: $e';
        _isLoading = false;
      });
    }
  }

  void _editPlan(Map<String, dynamic> plan) {
    final descController = TextEditingController(text: plan['description'] ?? '');
    final priceController = TextEditingController(text: ((plan['priceAmount'] ?? 0) / 100).toStringAsFixed(0));
    final limitController = TextEditingController(text: (plan['generationLimit'] ?? 2).toString());
    bool isActive = plan['isActive'] == true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit Plan: ${plan['name']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price (₹ INR)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: limitController,
                  decoration: const InputDecoration(labelText: 'Generation Limit per period'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (val) => setDialogState(() => isActive = val),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final messenger = ScaffoldMessenger.of(context);
                final pricePaise = ((double.tryParse(priceController.text) ?? 0) * 100).toInt();
                final genLimit = int.tryParse(limitController.text) ?? (plan['generationLimit'] ?? 2);
                try {
                  await widget.adminService.updatePlan(plan['id'], {
                    'description': descController.text,
                    'priceAmount': pricePaise,
                    'generationLimit': genLimit,
                    'isActive': isActive,
                  });
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Updated ${plan['name']} plan successfully.')),
                    );
                    _fetchPlans();
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to update plan: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E26) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Plan Management',
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Inspect configured plans, update generation limits, and toggle availability.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : ListView.builder(
                        itemCount: _plans.length,
                        itemBuilder: (context, index) {
                          final plan = _plans[index] as Map<String, dynamic>;
                          final price = ((plan['priceAmount'] ?? 0) / 100).toInt();
                          final genLimit = plan['generationLimit'] ?? 2;
                          final isActive = plan['isActive'] == true;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        plan['name'] ?? '',
                                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: (isActive ? AppColors.success : Colors.grey).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          isActive ? 'Active' : 'Inactive',
                                          style: TextStyle(
                                            color: isActive ? AppColors.success : Colors.grey,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Price: ₹$price / ${plan['billingInterval'] ?? 'month'} • Generation Limit: $genLimit per period',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  if (plan['description'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      plan['description'],
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.edit_rounded, size: 16),
                                      label: const Text('Edit Plan Limits'),
                                      onPressed: () => _editPlan(plan),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// USER MANAGEMENT & USAGE INSPECTION SHEET
// ═══════════════════════════════════════════════════════════════════════════
class _AdminUserManagementSheet extends StatefulWidget {
  final AdminService adminService;
  const _AdminUserManagementSheet({required this.adminService});

  @override
  State<_AdminUserManagementSheet> createState() => _AdminUserManagementSheetState();
}

class _AdminUserManagementSheetState extends State<_AdminUserManagementSheet> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<dynamic> _users = [];
  List<dynamic> _availablePlans = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData([String search = '']) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.adminService.getUsers(search: search),
        widget.adminService.getPlans(),
      ]);
      final usersData = results[0] as Map<String, dynamic>;
      final plans = results[1] as List<dynamic>;

      setState(() {
        _users = usersData['users'] ?? [];
        _availablePlans = plans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load users: $e';
        _isLoading = false;
      });
    }
  }

  void _assignPlanDialog(Map<String, dynamic> user) {
    if (_availablePlans.isEmpty) return;
    String selectedPlanId = _availablePlans.first['id'];
    final reasonController = TextEditingController(text: 'Admin manual assignment');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Assign Plan to ${user['name'] ?? user['email']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedPlanId,
                decoration: const InputDecoration(labelText: 'Select Plan'),
                items: _availablePlans.map((p) {
                  return DropdownMenuItem<String>(
                    value: p['id'].toString(),
                    child: Text('${p['name']} (₹${((p['priceAmount'] ?? 0) / 100).toInt()})'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedPlanId = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Reason for Assignment'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await widget.adminService.assignPlan(
                    userId: user['id'],
                    planId: selectedPlanId,
                    reason: reasonController.text,
                  );
                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Plan assigned successfully.')),
                    );
                    _loadData(_searchController.text);
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to assign plan: $e')),
                    );
                  }
                }
              },
              child: const Text('Assign Plan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleUnlimited(Map<String, dynamic> user) async {
    final currentlyUnlimited = user['unlimitedGenerations'] == true;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.adminService.toggleUnlimitedGenerations(
        userId: user['id'],
        enabled: !currentlyUnlimited,
      );
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              !currentlyUnlimited
                  ? 'Granted unlimited generations to ${user['email']}'
                  : 'Revoked unlimited generations from ${user['email']}',
            ),
          ),
        );
        _loadData(_searchController.text);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E26) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'User Inspection & Plans',
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Search box
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by email or name...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded),
                onPressed: () => _loadData(_searchController.text),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onSubmitted: (val) => _loadData(val),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : _users.isEmpty
                        ? const Center(child: Text('No users found.'))
                        : ListView.builder(
                            itemCount: _users.length,
                            itemBuilder: (context, index) {
                              final user = _users[index] as Map<String, dynamic>;
                              final plan = user['currentPlan'] as Map<String, dynamic>?;
                              final planName = plan?['name'] ?? 'Free';
                              final used = plan?['generationsUsed'] ?? 0;
                              final limit = plan?['generationLimit'] ?? 2;
                              final isUnlimited = user['unlimitedGenerations'] == true || user['role'] == 'admin';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              user['name'] ?? 'User',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              if (isUnlimited) ...[
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  margin: const EdgeInsets.only(right: 6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.purple.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.all_inclusive_rounded, size: 12, color: Colors.purple),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'UNLIMITED',
                                                        style: TextStyle(
                                                          color: Colors.purple,
                                                          fontWeight: FontWeight.w800,
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  planName,
                                                  style: const TextStyle(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user['email'] ?? '',
                                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Icon(
                                            isUnlimited ? Icons.all_inclusive_rounded : Icons.bolt_rounded,
                                            size: 16,
                                            color: isUnlimited ? Colors.purple : Colors.amber,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            isUnlimited
                                                ? 'Generations: $used / ∞ (Unlimited)'
                                                : 'Generations Used: $used / $limit',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isUnlimited ? Colors.purple : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: isUnlimited ? Colors.redAccent : Colors.purple,
                                              side: BorderSide(
                                                color: isUnlimited ? Colors.redAccent : Colors.purple,
                                              ),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                            icon: Icon(
                                              isUnlimited ? Icons.remove_circle_outline : Icons.add_task_rounded,
                                              size: 15,
                                            ),
                                            label: Text(
                                              isUnlimited ? 'Revoke ∞' : 'Grant ∞',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                            onPressed: () => _toggleUnlimited(user),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                            icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                                            label: const Text('Assign Plan'),
                                            onPressed: () => _assignPlanDialog(user),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
