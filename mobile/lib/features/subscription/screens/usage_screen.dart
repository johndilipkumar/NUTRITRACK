import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/subscription_service.dart';

class UsageScreen extends StatefulWidget {
  const UsageScreen({super.key});

  @override
  State<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends State<UsageScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isLoading = true;
  Map<String, dynamic>? _status;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    try {
      final status = await _subscriptionService.getSubscriptionStatus();
      setState(() {
        _status = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load usage data.';
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelSubscription() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text('Are you sure you want to cancel? You will retain access until the end of your billing cycle.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Plan'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Plan'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _subscriptionService.cancelSubscription();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription cancelled successfully.')),
        );
        _fetchStatus(); // Refresh status
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Plan & Usage', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _buildContent(isDark),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_status == null || _status!['hasSubscription'] == false) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No active subscription found.'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push('/pricing'),
              child: const Text('View Plans'),
            ),
          ],
        ),
      );
    }

    final plan = _status!['plan'];
    final usage = _status!['usage'];
    final bonus = _status!['bonusCredits'];
    final isFree = plan['priceAmount'] == 0;
    final isCancelled = _status!['cancelAtPeriodEnd'] == true;

    return RefreshIndicator(
      onRefresh: _fetchStatus,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Current Plan Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: isFree
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: isFree ? (isDark ? AppColors.darkCard : AppColors.lightCard) : null,
              border: isFree ? Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CURRENT PLAN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: isFree ? (isDark ? Colors.white54 : Colors.black54) : Colors.white70,
                      ),
                    ),
                    if (isCancelled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'CANCELLING',
                          style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      )
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  plan['name'],
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: isFree ? null : Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFree 
                              ? AppColors.primary
                              : Colors.white,
                          foregroundColor: isFree
                              ? Colors.white
                              : Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => context.push('/pricing'),
                        child: const Text('Upgrade Plan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          Text('Usage & Limits', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),

          // Usage Stats
          _buildUsageStat(
            'Monthly Credits',
            usage['monthlyCreditsUsed'],
            plan['monthlyCreditLimit'],
            isDark,
          ),
          const SizedBox(height: 16),
          _buildUsageStat(
            'Daily Requests',
            usage['dailyRequestsUsed'],
            plan['dailyRequestLimit'],
            isDark,
          ),

          if (bonus > 0) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bonus Credits Available', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('$bonus credits will be used if monthly limit is reached.', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 48),

          if (!isFree && !isCancelled)
            TextButton(
              onPressed: _cancelSubscription,
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Cancel Subscription'),
            ),
        ],
      ),
    );
  }

  Widget _buildUsageStat(String title, int used, int limit, bool isDark) {
    final percent = (used / limit).clamp(0.0, 1.0);
    final color = percent > 0.9 ? Colors.red : (percent > 0.7 ? Colors.orange : AppColors.success);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              Text('$used / $limit', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: isDark ? Colors.white12 : Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
