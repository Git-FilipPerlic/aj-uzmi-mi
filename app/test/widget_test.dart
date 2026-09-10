import 'package:dispecer/data/order_store.dart';
import 'package:dispecer/data/test_orders.dart';
import 'package:dispecer/main.dart';
import 'package:dispecer/models/order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Order.fromMap', () {
    test('prazna mapa ne puca, sva polja su prazna', () {
      final order = Order.fromMap('x', null);

      expect(order.id, 'x');
      expect(order.customerName, '');
      expect(order.items, isEmpty);
      expect(order.price, isNull);
      expect(order.routeOrder, isNull);
      expect(order.createdAt, isNull);
    });

    test('pogrešni tipovi se tiho pretvaraju u prazno stanje', () {
      final order = Order.fromMap('x', {
        'customerName': 123,
        'items': 'hleb',
        'price': 'skupo',
        'routeOrder': 'prvi',
      });

      expect(order.customerName, '');
      expect(order.items, isEmpty);
      expect(order.price, isNull);
      expect(order.routeOrder, isNull);
    });

    test('prazni artikli se izbacuju iz spiska', () {
      final order = Order.fromMap('x', {
        'items': ['hleb', '', '  ', 'mleko'],
      });

      expect(order.items, ['hleb', 'mleko']);
    });
  });

  group('OrderStore', () {
    OrderStore storeSa(List<Order> orders) => OrderStore(orders: orders);

    test('aktivne izostavljaju dostavljene porudžbine', () {
      final store = storeSa([
        const Order(id: '1', status: OrderStatus.nova),
        const Order(id: '2', status: OrderStatus.dostavljena),
      ]);

      expect(store.active.map((o) => o.id), ['1']);
    });

    test('ruta ide po routeOrder, a porudžbine bez rute idu na kraj', () {
      final store = storeSa([
        const Order(id: 'bez', status: OrderStatus.nova),
        const Order(id: 'drugi', status: OrderStatus.nova, routeOrder: 2),
        const Order(id: 'prvi', status: OrderStatus.nova, routeOrder: 1),
      ]);

      expect(store.route.map((o) => o.id), ['prvi', 'drugi', 'bez']);
    });

    test('promena statusa menja porudžbinu i javlja slušaocima', () {
      final store = storeSa([const Order(id: '1', status: OrderStatus.nova)]);
      var javljeno = 0;
      store.addListener(() => javljeno++);

      store.setStatus('1', OrderStatus.preuzeta);

      expect(store.byId('1')?.status, OrderStatus.preuzeta);
      expect(javljeno, 1);
    });

    test('nepoznat identifikator ne puca', () {
      final store = storeSa([const Order(id: '1')]);

      store.setStatus('nema me', OrderStatus.preuzeta);

      expect(store.byId('nema me'), isNull);
    });
  });

  testWidgets('aplikacija prikaže listu porudžbina i otvori detalje', (
    tester,
  ) async {
    await tester.pumpWidget(
      DispecerApp(store: OrderStore(orders: testOrders())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Porudžbine'), findsWidgets);
    expect(find.text('Milica Jovanović'), findsOneWidget);

    await tester.tap(find.text('Milica Jovanović'));
    await tester.pumpAndSettle();

    expect(find.text('Bulevar Kneza Miloša 45, Novi Sad'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Preuzeto'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Preuzeto'));
    await tester.pumpAndSettle();

    expect(find.text('Preuzeta'), findsOneWidget);
  });

  testWidgets('porudžbina bez podataka prikazuje jasne poruke o praznom', (
    tester,
  ) async {
    await tester.pumpWidget(
      DispecerApp(store: OrderStore(orders: testOrders())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Adresa nije uneta'), findsOneWidget);
    expect(find.text('Nema unetih artikala'), findsOneWidget);
    expect(find.text('Cena nije određena'), findsOneWidget);
  });
}
