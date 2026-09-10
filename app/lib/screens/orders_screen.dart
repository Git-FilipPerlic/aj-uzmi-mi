import 'package:flutter/material.dart';

import '../data/order_store.dart';
import '../models/order.dart';
import '../widgets/message_view.dart';
import '../widgets/order_card.dart';
import 'order_detail_screen.dart';

/// Ekran „Porudžbine": lista kartica, najnovija na vrhu.
///
/// Podrazumevano se vide samo aktivne (nedostavljene) porudžbine. Prekidač
/// „Sve" postoji da dostavljena porudžbina ne bi nestala bez traga — korisno i
/// za proveru šta je danas urađeno.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, required this.store});

  final OrderStore store;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _samoAktivne = true;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final store = widget.store;

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

        final porudzbine = _samoAktivne ? store.active : store.all;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Aktivne')),
                  ButtonSegment(value: false, label: Text('Sve')),
                ],
                selected: {_samoAktivne},
                onSelectionChanged: (izbor) =>
                    setState(() => _samoAktivne = izbor.first),
              ),
            ),
            Expanded(
              child: porudzbine.isEmpty
                  ? MessageView(
                      icon: Icons.inbox_outlined,
                      text: _samoAktivne
                          ? 'Nema aktivnih porudžbina'
                          : 'Nema nijedne porudžbine',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: porudzbine.length,
                      itemBuilder: (context, i) {
                        final porudzbina = porudzbine[i];
                        return OrderCard(
                          order: porudzbina,
                          onTap: () => _otvoriDetalje(context, porudzbina),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _otvoriDetalje(BuildContext context, Order porudzbina) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            OrderDetailScreen(store: widget.store, orderId: porudzbina.id),
      ),
    );
  }
}
