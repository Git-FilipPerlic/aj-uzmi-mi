import 'package:flutter/material.dart';

import '../data/order_store.dart';
import '../format.dart';
import '../models/order.dart';

/// Ekran sa detaljima jedne porudžbine i dugmadima „Preuzeto" i „Dostavljeno".
///
/// Porudžbina se traži po identifikatoru (a ne prosleđuje kao gotov objekat),
/// da bi ekran uvek pokazivao poslednje stanje kad se status promeni.
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({
    super.key,
    required this.store,
    required this.orderId,
  });

  final OrderStore store;
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final porudzbina = store.byId(orderId);

        if (porudzbina == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Porudžbina')),
            body: const Center(child: Text('Porudžbina više ne postoji.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(orPlaceholder(porudzbina.customerName, 'Bez imena')),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _Zaglavlje(order: porudzbina),
              const SizedBox(height: 16),
              _Red(
                icon: Icons.storefront_outlined,
                naslov: 'Radnja',
                tekst: orPlaceholder(porudzbina.shop, 'Radnja nije uneta'),
              ),
              _Red(
                icon: Icons.place_outlined,
                naslov: 'Adresa',
                tekst: orPlaceholder(porudzbina.address, 'Adresa nije uneta'),
              ),
              _Red(
                icon: Icons.phone_outlined,
                naslov: 'Kontakt',
                tekst: orPlaceholder(
                  porudzbina.customerContact,
                  'Kontakt nije unet',
                ),
              ),
              _Red(
                icon: Icons.chat_outlined,
                naslov: 'Kanal',
                tekst: channelLabel(porudzbina.channel),
              ),
              _Red(
                icon: Icons.payments_outlined,
                naslov: 'Cena',
                tekst: priceLabel(porudzbina.price),
              ),
              _Red(
                icon: Icons.alt_route_outlined,
                naslov: 'Mesto u ruti',
                tekst: porudzbina.routeOrder == null
                    ? 'Ruta još nije isplanirana'
                    : '${porudzbina.routeOrder}.',
              ),
              const SizedBox(height: 8),
              _Spisak(items: porudzbina.items),
              const SizedBox(height: 24),
              _Dugmad(store: store, order: porudzbina),
            ],
          ),
        );
      },
    );
  }
}

/// Hitnost i status u vrhu ekrana.
class _Zaglavlje extends StatelessWidget {
  const _Zaglavlje({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final boja = urgencyColor(order.urgency, theme.colorScheme);

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: boja.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: boja.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Text(
                urgencyLabel(order.urgency),
                style: theme.textTheme.titleMedium?.copyWith(color: boja),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                statusLabel(order.status),
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Jedan podatak: ikonica, naslov, vrednost.
class _Red extends StatelessWidget {
  const _Red({required this.icon, required this.naslov, required this.tekst});

  final IconData icon;
  final String naslov;
  final String tekst;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  naslov,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(tekst, style: theme.textTheme.titleMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista artikala za kupovinu.
class _Spisak extends StatelessWidget {
  const _Spisak({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spisak za kupovinu',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        if (items.isEmpty)
          Text('Nema unetih artikala', style: theme.textTheme.titleMedium)
        else
          ...items.map(
            (artikal) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  '),
                  Expanded(
                    child: Text(artikal, style: theme.textTheme.titleMedium),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Dugmad koja pomeraju porudžbinu kroz statuse.
///
/// „Preuzeto" radi dok porudžbina nije preuzeta; „Dostavljeno" tek kad jeste —
/// tako se redosled ne može preskočiti greškom u vožnji.
class _Dugmad extends StatelessWidget {
  const _Dugmad({required this.store, required this.order});

  final OrderStore store;
  final Order order;

  @override
  Widget build(BuildContext context) {
    final preuzeta = order.status == OrderStatus.preuzeta;
    final dostavljena = order.status == OrderStatus.dostavljena;

    return Column(
      children: [
        FilledButton.icon(
          onPressed: (preuzeta || dostavljena)
              ? null
              : () => _promeni(context, OrderStatus.preuzeta, 'Preuzeto'),
          icon: const Icon(Icons.shopping_bag_outlined),
          label: const Text('Preuzeto'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: dostavljena
              ? null
              : () => _promeni(context, OrderStatus.dostavljena, 'Dostavljeno'),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Dostavljeno'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
      ],
    );
  }

  void _promeni(BuildContext context, String noviStatus, String poruka) {
    store.setStatus(order.id, noviStatus);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$poruka — status je sačuvan.')));
  }
}
