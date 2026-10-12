import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/subscription_service.dart';
import '../widgets/mock_checkout_modal.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isLoading = true;
  List<dynamic> _plans = [];
  Map<String, dynamic>? _userSubscription;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _subscriptionService.getPlans(),
        _subscriptionService.getGenerationStatus().catchError((_) => <String, dynamic>{}),
      ]);

      setState(() {
        _plans = results[0] as List<dynamic>;
        _userSubscription = results[1] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load plans. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  String get _currentPlanSlug {
    return (_userSubscription?['planSlug'] ?? _userSubscription?['planName'] ?? 'free')
        .toString()
        .toLowerCase();
  }

  void _onSelectPlan(Map<String, dynamic> plan) {
    final slug = (plan['slug'] ?? plan['name'] ?? '').toString().toLowerCase();
    final isCurrent = slug == _currentPlanSlug;

    if (isCurrent) return;

    MockCheckoutModal.show(
      context: context,
      plan: plan,
      onUpgradeSuccess: () {
        _loadData();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Choose Your Plan',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
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
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildPlanList(isDark),
    );
  }

  Widget _buildPlanList(bool isDark) {
    if (_plans.isEmpty) {
      return const Center(child: Text('No plans available at this time.'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 850;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 1100 : 540),
              child: Column(
                children: [
                  // Subtitle & Header description
                  Text(
                    'Choose Your Plan',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find the right plan for your workflow and create more with the right amount of generations.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white70 : Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_userSubscription?['isUnlimited'] == true) ...[
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.withValues(alpha: 0.35)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.all_inclusive_rounded, size: 18, color: Colors.purple),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'VIP Account: You have Unlimited Generations granted across all plans.',
                              style: TextStyle(fontSize: 12, color: Colors.purple, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Demo checkout hint banner
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Demo Mode Active: Upgrades are simulated. No payments required.',
                            style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Cards Container (Horizontal Row on desktop, Vertical Column on mobile)
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _plans.map((p) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: _buildPlanCard(p as Map<String, dynamic>, isDark),
                          ),
                        );
                      }).toList(),
                    )
                  else
                    Column(
                      children: _plans.map((p) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _buildPlanCard(p as Map<String, dynamic>, isDark),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 24),
                  // Link to view current usage
                  TextButton.icon(
                    icon: const Icon(Icons.analytics_outlined, size: 18),
                    label: const Text('View Your Current Usage & Limits'),
                    onPressed: () => context.push('/usage'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan, bool isDark) {
    final slug = (plan['slug'] ?? plan['name'] ?? '').toString().toLowerCase();
    final isCurrent = slug == _currentPlanSlug;
    final isPro = slug == 'pro';
    final isBasic = slug == 'basic';
    final isFree = slug == 'free';

    final priceInt = ((plan['priceAmount'] ?? 0) / 100).toInt();
    final interval = plan['billingInterval'] == 'yearly' ? 'year' : 'month';
    final generationLimit = plan['generationLimit'] ?? (isPro ? 8 : (isBasic ? 4 : 2));

    // Primary button text according to spec
    String buttonText;
    if (isCurrent) {
      buttonText = 'Current Plan';
    } else if (isFree) {
      buttonText = 'Get Started';
    } else if (isBasic) {
      buttonText = 'Choose Basic';
    } else {
      buttonText = 'Choose Pro';
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPro
              ? AppColors.primary
              : isCurrent
                  ? AppColors.success.withValues(alpha: 0.6)
                  : (isDark ? Colors.white12 : Colors.black12),
          width: isPro ? 2.2 : (isCurrent ? 2.0 : 1.0),
        ),
        color: isPro
            ? (isDark ? const Color(0xFF1B1B26) : const Color(0xFFFAF9FF))
            : (isDark ? const Color(0xFF1E1E24) : Colors.white),
        boxShadow: [
          if (isPro)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 18,
              offset: const Offset(0, 8),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Best Value Badge or Current Plan Badge
                if (isPro)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'BEST VALUE',
                        style: GoogleFonts.outfit(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  )
                else if (isCurrent)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'CURRENT PLAN',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),

                // Plan Name
                Text(
                  plan['name'] ?? '',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),

                // Price display
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      priceInt == 0 ? '₹0' : '₹$priceInt',
                      style: GoogleFonts.outfit(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    if (priceInt > 0)
                      Text(
                        '/$interval',
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Generation allowance highlight pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        size: 20,
                        color: isPro ? AppColors.primary : Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$generationLimit generations per period',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  plan['description'] ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),

                // Feature List
                if (isFree) ...[
                  _buildFeatureRow('2 AI Food Analyses per period'),
                  _buildFeatureRow('Core food & nutrition recognition'),
                  _buildFeatureRow('Daily macronutrient tracking'),
                  _buildFeatureRow('Generation usage tracking'),
                ] else if (isBasic) ...[
                  _buildFeatureRow('4 AI Food Analyses per period'),
                  _buildFeatureRow('All Free plan features included'),
                  _buildFeatureRow('Higher monthly generation allowance'),
                  _buildFeatureRow('Generation usage tracking'),
                ] else ...[
                  _buildFeatureRow('8 AI Food Analyses per period'),
                  _buildFeatureRow('All Basic plan features included'),
                  _buildFeatureRow('Maximum monthly generation allowance'),
                  _buildFeatureRow('Generation usage tracking'),
                ],

                const SizedBox(height: 28),

                // Main CTA Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCurrent
                        ? (isDark ? Colors.white12 : Colors.black12)
                        : (isPro ? AppColors.primary : (isDark ? Colors.white : Colors.black)),
                    foregroundColor: isCurrent
                        ? (isDark ? Colors.white54 : Colors.black45)
                        : (isPro ? Colors.white : (isDark ? Colors.black : Colors.white)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: isPro && !isCurrent ? 3 : 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: isCurrent ? null : () => _onSelectPlan(plan),
                  child: Text(
                    buttonText,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: AppColors.success,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.25),
            ),
          ),
        ],
      ),
    );
  }
}
