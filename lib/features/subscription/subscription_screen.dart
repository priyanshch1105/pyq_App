import 'package:flutter/material.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unlock Full Access')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const _PricingCard(
              title: 'Pro Plan',
              price: '₹299/mo',
              features: [
                'Unlimited PYQs (All exams)',
                'AI Topic Recommendations',
                'Advanced Performance Filtering',
                'Detailed Solutions & Explanations',
                'Download Prep-Notes as PDF',
              ],
              isPopular: true,
            ),
            const SizedBox(height: 24),
            const _PricingCard(
              title: 'Standard',
              price: 'Free',
              features: [
                '25 PYQs per day',
                'Basic Performance Stats',
                'Access to UPSC/JEE core topics',
              ],
              isPopular: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  const _PricingCard({
    required this.title,
    required this.price,
    required this.features,
    required this.isPopular,
  });

  final String title;
  final String price;
  final List<String> features;
  final bool isPopular;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isPopular ? Colors.indigo.shade900.withOpacity(0.4) : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPopular ? Colors.indigoAccent : Theme.of(context).dividerColor,
          width: isPopular ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: isPopular ? Colors.indigoAccent.shade100 : Colors.white,
              )),
              if (isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.indigoAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('RECOMMENDED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(price, style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 32)),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 24),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.indigoAccent, size: 18),
                const SizedBox(width: 12),
                Expanded(child: Text(f, style: const TextStyle(color: Colors.white70))),
              ],
            ),
          )),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: isPopular ? Colors.indigoAccent : Colors.white10,
              foregroundColor: Colors.white,
            ),
            child: Text(isPopular ? 'Get Started' : 'Current Plan'),
          ),
        ],
      ),
    );
  }
}
