import 'package:flutter/material.dart';

import '../data/order_store.dart';
import '../widgets/message_view.dart';
import '../widgets/order_card.dart';
import 'order_detail_screen.dart';

/// Ekran „Ruta": aktivne porudžbine poređane redom kojim ih treba obići.
///
/// Rutu računa backend (agent) i upisuje je u polje `routeOrder`; aplikacija je
/// samo prikazuje i ne menja redosled sama.
class RouteScreen extends StatelessWidget {
  const RouteScreen({super.key, required this.store});

  final OrderStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        if (store.loading) {
          return const LoadingView();
        }

        if (store.error != null) {
          return MessageView(
            icon: Icons.cloud_off_outlined,
            text: 'Nema veze sa bazom',
            detail: store.error,
            color: Theme.of(context).colorScheme.error,
          );
        }

        final ruta = store.route;

        if (ruta.isEmpty) {
          return const MessageView(
            icon: Icons.alt_route_outlined,
            text: 'Nema porudžbina u ruti',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          itemCount: ruta.length,
          itemBuilder: (context, i) {
            final porudzbina = ruta[i];
            return OrderCard(
              order: porudzbina,
              leading: _Broj(broj: i + 1),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      OrderDetailScreen(store: store, orderId: porudzbina.id),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Redni broj stajanja u ruti (1, 2, 3...).
class _Broj extends StatelessWidget {
  const _Broj({required this.broj});

  final int broj;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$broj',
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
