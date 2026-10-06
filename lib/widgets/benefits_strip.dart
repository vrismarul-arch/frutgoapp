import 'package:flutter/material.dart';

class BenefitsStrip extends StatelessWidget {
  const BenefitsStrip({
    super.key,
  });

  static const List<Benefit> benefits = [
    Benefit(
      icon: Icons.eco_outlined,
      title: 'Organic',
      subtitle: 'Fresh & Natural',
    ),
    Benefit(
      icon: Icons.timer_outlined,
      title: '45 Mins',
      subtitle: 'Fast Delivery',
    ),
    Benefit(
      icon: Icons.sell_outlined,
      title: 'Transparent',
      subtitle: 'Fair Pricing',
    ),
    Benefit(
      icon: Icons.recycling_outlined,
      title: 'Eco Friendly',
      subtitle: 'Green Delivery',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        14,
        22,
        14,
        20,
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8EDE5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.035,
            ),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: List.generate(
          benefits.length,
          (index) {
            final benefit =
                benefits[index];

            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _BenefitItem(
                      benefit: benefit,
                    ),
                  ),

                  if (index <
                      benefits.length - 1)
                    Container(
                      width: 1,
                      height: 42,
                      color: const Color(
                        0xFFE7EBE5,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// =============================================================
// BENEFIT ITEM
// =============================================================

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({
    required this.benefit,
  });

  final Benefit benefit;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration:
              const BoxDecoration(
            color: Color(0xFFF0F7ED),
            shape: BoxShape.circle,
          ),
          child: Icon(
            benefit.icon,
            size: 21,
            color: const Color(
              0xFF568D43,
            ),
          ),
        ),

        const SizedBox(
          height: 7,
        ),

        Text(
          benefit.title,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          textAlign:
              TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight:
                FontWeight.w700,
            color:
                Color(0xFF292D29),
          ),
        ),

        const SizedBox(
          height: 2,
        ),

        Text(
          benefit.subtitle,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          textAlign:
              TextAlign.center,
          style: const TextStyle(
            fontSize: 8.5,
            fontWeight:
                FontWeight.w400,
            color:
                Color(0xFF858985),
          ),
        ),
      ],
    );
  }
}

// =============================================================
// BENEFIT MODEL
// =============================================================

class Benefit {
  final IconData icon;
  final String title;
  final String subtitle;

  const Benefit({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}