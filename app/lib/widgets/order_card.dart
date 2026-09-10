import 'package:flutter/material.dart';

import '../format.dart';
import '../models/order.dart';

/// Kartica jedne porudžbine u listi.
///
/// Dizajn je namerno krupan i miran: traka u boji sa strane govori hitnost,
/// najveći tekst je ime mušterije i adresa — to je ono što se čita u pokretu.
class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, this.onTap, this.leading});

  final Order order;
  final VoidCallback? onTap;

  /// Neobavezan sadržaj sa leve strane (npr. redni broj u ruti).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bojaHitnosti = urgencyColor(order.urgency, scheme);
    final dostavljena = order.status == OrderStatus.dostavljena;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Traka u boji: hitnost na prvi pogled.
              Container(width: 8, color: bojaHitnosti),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (leading != null) ...[
                            leading!,
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Text(
                              orPlaceholder(order.customerName, 'Bez imena'),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                decoration: dostavljena
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          Text(
                            timeLabel(order.createdAt),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _RedSaIkonom(
                        icon: Icons.place_outlined,
                        text: orPlaceholder(order.address, 'Adresa nije uneta'),
                        istaknuto: true,
                      ),
                      const SizedBox(height: 4),
                      _RedSaIkonom(
                        icon: Icons.shopping_basket_outlined,
                        text: itemsLine(order.items),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _Oznaka(
                            text: urgencyLabel(order.urgency),
                            boja: bojaHitnosti,
                          ),
                          _Oznaka(
                            text: statusLabel(order.status),
                            boja: scheme.outline,
                          ),
                          Text(
                            priceLabel(order.price),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Red: mala ikonica pa tekst uz nju.
class _RedSaIkonom extends StatelessWidget {
  const _RedSaIkonom({
    required this.icon,
    required this.text,
    this.istaknuto = false,
  });

  final IconData icon;
  final String text;
  final bool istaknuto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stil = istaknuto
        ? theme.textTheme.bodyLarge
        : theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: stil)),
      ],
    );
  }
}

/// Mala oznaka u boji (hitnost, status).
class _Oznaka extends StatelessWidget {
  const _Oznaka({required this.text, required this.boja});

  final String text;
  final Color boja;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: boja.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: boja.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: boja),
      ),
    );
  }
}
