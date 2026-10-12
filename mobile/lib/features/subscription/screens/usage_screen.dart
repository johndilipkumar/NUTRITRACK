import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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
  Map<String, dynamic>? _generationData;
  Map<String, dynamic>? _subscriptionDetails;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUsage();
  }

  Future<void> _fetchUsage() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _subscriptionService.getGenerationStatus(),
        _subscriptionService.getSubscriptionStatus().catchError((_) => <String, dynamic>{}),
      ]);

      setState(() {
        _generationData = results[0];
        _subscriptionDetails = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load usage data. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelSubscription() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'Are you sure you want to cancel? You will retain access until the end of your billing cycle.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Plan'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel Plan'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _subscriptionService.cancelSubscription();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subscription cancellation scheduled.')),
          );
          _fetchUsage();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel subscription: $e')),
          );
        }
      }
    }
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateValue.toString());
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return dateValue.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Plan & Usage',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchUsage,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchUsage,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildContent(isDark),
    );
  }

  Widget _buildContent(bool isDark) {
    final gen = _generationData ?? {};
    final hasSubscription = gen['hasSubscription'] == true;

    if (!hasSubscription) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.card_membership_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No active subscription found.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Subscribe to a plan to start analyzing meals with AI.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.push('/pricing'),
                child: const Text('View Available Plans'),
              ),
            ],
          ),
        ),
      );
    }

    final planName = (gen['planName'] ?? 'Free').toString();
    final planSlug = (gen['planSlug'] ?? 'free').toString().toLowerCase();
    final isFree = planSlug == 'free';
    final isUnlimited = gen['isUnlimited'] == true || (gen['generationLimit'] ?? 0) == -1;
    final generationsUsed = (gen['generationsUsed'] ?? 0) as int;
    final generationLimit = (gen['generationLimit'] ?? 2) as int;
    final generationsRemaining = (gen['generationsRemaining'] ?? 0) as int;
    final percentUsed = isUnlimited ? 0 : ((gen['percentUsed'] ?? 0) as int);
    final isLimitReached = !isUnlimited && generationsRemaining <= 0;
    final billingEnd = gen['billingPeriodEnd'];
    final isCancelled = gen['cancelAtPeriodEnd'] == true;
    final isMock = gen['isMock'] == true;
    final status = (gen['status'] ?? 'active').toString();

    // Progress bar color according to prompt:
    // Low usage: normal state
    // Approaching limit (>= 75%): subtle warning
    // Limit reached (100%): clear exhausted state
    Color progressColor;
    if (isUnlimited) {
      progressColor = Colors.purple;
    } else if (percentUsed >= 100 || isLimitReached) {
      progressColor = AppColors.error;
    } else if (percentUsed >= 75) {
      progressColor = Colors.orange;
    } else {
      progressColor = AppColors.success;
    }

    return RefreshIndicator(
      onRefresh: _fetchUsage,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // 1. LIMIT REACHED ALERT BANNER (If exhausted) or UNLIMITED VIP BANNER (If unlimited)
          if (isUnlimited) ...[
            Container(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withValues(alpha: 0.15),
                    AppColors.primary.withValues(alpha: 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.purple.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.all_inclusive_rounded, color: Colors.purple, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unlimited Generations Active',
                          style: TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your account has unlimited AI meal scans with zero credit restrictions.',
                          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isLimitReached) ...[
            Container(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Generation Limit Reached',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "You've reached your generation limit for this plan.",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Upgrade your plan to access a higher generation allowance.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                      label: const Text('Upgrade Plan Now'),
                      onPressed: () async {
                        await context.push('/pricing');
                        _fetchUsage();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 2. CURRENT PLAN CARD
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: isDark ? const Color(0xFF1E1E26) : Colors.white,
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'CURRENT PLAN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                        if (isUnlimited) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'UNLIMITED ∞',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.purple),
                            ),
                          ),
                        ],
                        if (isMock) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'DEMO',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.blue),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isCancelled ? Colors.orange : AppColors.success).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isCancelled ? 'Cancelling' : status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isCancelled ? Colors.orange : AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  planName,
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isUnlimited
                      ? 'Allowance: Unlimited AI food generations (∞)'
                      : 'Allowance: $generationLimit AI food generations per billing period',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.upgrade_rounded, size: 20),
                        label: const Text('Upgrade Plan', style: TextStyle(fontWeight: FontWeight.w700)),
                        onPressed: () async {
                          await context.push('/pricing');
                          _fetchUsage();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // 3. GENERATION USAGE SECTION
          Text(
            'Generation Allowance',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: isDark ? const Color(0xFF1E1E26) : Colors.white,
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Generations Used',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      isUnlimited ? '$generationsUsed / ∞' : '$generationsUsed / $generationLimit',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: progressColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Usage Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: isUnlimited
                        ? 1.0
                        : (generationLimit > 0 ? (generationsUsed / generationLimit).clamp(0.0, 1.0) : 0.0),
                    backgroundColor: isDark ? Colors.white12 : Colors.black12,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 12,
                  ),
                ),
                const SizedBox(height: 16),

                // Progress Info Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isUnlimited ? 'Generations Remaining: Unlimited (∞)' : 'Generations Remaining: $generationsRemaining',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isLimitReached ? AppColors.error : (isUnlimited ? Colors.purple : (isDark ? Colors.white70 : Colors.black87)),
                      ),
                    ),
                    Text(
                      isUnlimited ? 'Usage: Unlimited' : 'Usage: $percentUsed%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: progressColor,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28),

                // Reset Date
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Next Reset Date: ', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    Text(
                      _formatDate(billingEnd),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // 4. SECONDARY CREDIT DETAILS (From existing architecture)
          if (_subscriptionDetails?['usage'] != null) ...[
            Text(
              'Technical Quota Details',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: isDark ? const Color(0xFF1E1E26) : Colors.white,
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                children: [
                  _buildStatRow(
                    'Daily Requests',
                    '${_subscriptionDetails!['usage']['dailyRequestsUsed']} / ${_subscriptionDetails!['plan']['dailyRequestLimit']}',
                    Icons.speed_rounded,
                  ),
                  const Divider(height: 20),
                  _buildStatRow(
                    'Monthly Credits',
                    '${_subscriptionDetails!['usage']['monthlyCreditsUsed']} / ${_subscriptionDetails!['plan']['monthlyCreditLimit']}',
                    Icons.token_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],

          // 5. CANCEL SUBSCRIPTION (For non-free plans)
          if (!isFree && !isCancelled) ...[
            Center(
              child: TextButton(
                onPressed: _cancelSubscription,
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Cancel Subscription'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
