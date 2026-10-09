import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/subscription_service.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isLoading = true;
  List<dynamic> _plans = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    try {
      final plans = await _subscriptionService.getPlans();
      setState(() {
        _plans = plans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load plans.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleCheckout(String planId, int price) async {
    if (price == 0) return; // Free plan
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final checkoutData = await _subscriptionService.createCheckout(planId);
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // In a real app, this is where we'd open the Razorpay SDK widget.
      // For this implementation, we simulate a successful payment.
      _showMockPaymentDialog(checkoutData);

    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout failed: $e')),
        );
      }
    }
  }

  void _showMockPaymentDialog(Map<String, dynamic> checkoutData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simulate Payment'),
        content: Text('Simulating Razorpay flow for ${checkoutData['planName']} (₹${checkoutData['amount'] / 100}).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Verify simulated payment
              try {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );

                await _subscriptionService.verifyPayment(
                  paymentId: checkoutData['paymentId'],
                  razorpayPaymentId: 'pay_simulated_123',
                );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment successful! Plan activated.')),
                  );
                  context.go('/usage');
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Payment verification failed: $e')),
                  );
                }
              }
            },
            child: const Text('Pay Successfully'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1A1A2E), const Color(0xFF16213E), const Color(0xFF0F3460)]
                      : [const Color(0xFFF0F4FF), const Color(0xFFE5E5E5), const Color(0xFFFFFFFF)],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        children: [
                          Text(
                            'Upgrade your nutrition journey',
                            style: GoogleFonts.outfit(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Unlock advanced AI capabilities, detailed insights, and unlimited scanning.',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 48),

                          // Plan Cards
                          ..._plans.map((plan) {
                            final isPremium = plan['priceAmount'] > 0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: _buildPlanCard(plan, isPremium, isDark),
                            );
                          }).toList(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(dynamic plan, bool isPremium, bool isDark) {
    final price = plan['priceAmount'] / 100; // Convert paise to INR
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: isPremium
            ? const LinearGradient(
                colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: !isPremium ? (isDark ? AppColors.darkCard : AppColors.lightCard) : null,
        boxShadow: isPremium
            ? [
                BoxShadow(
                  color: const Color(0xFFE94057).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ]
            : [],
        border: !isPremium
            ? Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider)
            : null,
      ),
      child: Padding(
        // Inner padding for the gradient border effect if we wanted one, but here we just pad the content
        padding: EdgeInsets.all(isPremium ? 2 : 0), 
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: isPremium ? (isDark ? const Color(0xFF111111) : Colors.white) : Colors.transparent,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE94057).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'RECOMMENDED',
                    style: TextStyle(
                      color: isDark ? const Color(0xFFFF8A9B) : const Color(0xFFE94057),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              Text(
                plan['name'].toString().toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: isPremium ? (isDark ? Colors.white : Colors.black) : null,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price == 0 ? 'Free' : '₹${price.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  if (price > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 4),
                      child: Text(
                        '/${plan['billingInterval'] == 'monthly' ? 'mo' : 'yr'}',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                plan['description'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              
              // Features
              _buildFeatureRow('Monthly Credits: ${plan['monthlyCreditLimit']}', Icons.token_rounded),
              _buildFeatureRow('Daily Request Limit: ${plan['dailyRequestLimit']}', Icons.speed_rounded),
              _buildFeatureRow('Advanced AI Models', Icons.psychology_rounded),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPremium 
                        ? (isDark ? Colors.white : Colors.black)
                        : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                    foregroundColor: isPremium 
                        ? (isDark ? Colors.black : Colors.white)
                        : (isDark ? Colors.white : Colors.black),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: price == 0 ? null : () => _handleCheckout(plan['id'], plan['priceAmount']),
                  child: Text(
                    price == 0 ? 'Current Plan' : 'Upgrade Now',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.success),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
