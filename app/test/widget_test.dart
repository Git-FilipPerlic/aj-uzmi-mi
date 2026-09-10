import 'package:dispecer/data/auth.dart';
import 'package:dispecer/data/order_store.dart';
import 'package:dispecer/data/test_orders.dart';
import 'package:dispecer/main.dart';
import 'package:dispecer/models/order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Aplikacija sa već prijavljenim kurirom i test porudžbinama.
DispecerApp prijavljenaAplikacija() => DispecerApp(
  auth: Auth(email: 'kurir@ajuzmimi.rs'),
  createStore: () => OrderStore(orders: testOrders()),
);

/// Aplikacija na kojoj niko nije prijavljen.
DispecerApp odjavljenaAplikacija() => DispecerApp(
  auth: Auth(),
  createStore: () => OrderStore(orders: testOrders()),
);

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
    await tester.pumpWidget(prijavljenaAplikacija());
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
    await tester.pumpWidget(prijavljenaAplikacija());
    await tester.pumpAndSettle();

    expect(find.text('Adresa nije uneta'), findsOneWidget);
    expect(find.text('Nema unetih artikala'), findsOneWidget);
    expect(find.text('Cena nije određena'), findsOneWidget);
  });

  group('Auth', () {
    test('prazan mejl ili lozinka ne šalju zahtev, nego vrate poruku', () async {
      final auth = Auth();

      expect(await auth.signIn('   ', 'lozinka'), 'Unesi mejl.');
      expect(await auth.signIn('kurir@ajuzmimi.rs', ''), 'Unesi lozinku.');
      expect(auth.signedIn, isFalse);
    });

    test('prijava i odjava menjaju stanje i javljaju slušaocima', () async {
      final auth = Auth();
      var javljeno = 0;
      auth.addListener(() => javljeno++);

      expect(await auth.signIn(' kurir@ajuzmimi.rs ', 'tajna'), isNull);
      expect(auth.signedIn, isTrue);
      expect(auth.email, 'kurir@ajuzmimi.rs');

      await auth.signOut();
      expect(auth.signedIn, isFalse);
      expect(javljeno, 2);
    });
  });

  testWidgets('bez prijave se vidi ekran za prijavu, pa posle nje porudžbine', (
    tester,
  ) async {
    await tester.pumpWidget(odjavljenaAplikacija());
    await tester.pumpAndSettle();

    expect(find.text('Prijava kurira'), findsOneWidget);
    expect(find.text('Milica Jovanović'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextField, 'Mejl'),
      'kurir@ajuzmimi.rs',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Lozinka'),
      'tajna123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Prijava'));
    await tester.pumpAndSettle();

    expect(find.text('Milica Jovanović'), findsOneWidget);
  });

  testWidgets('prazna polja pri prijavi javljaju šta fali', (tester) async {
    await tester.pumpWidget(odjavljenaAplikacija());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Prijava'));
    await tester.pumpAndSettle();

    expect(find.text('Unesi mejl.'), findsOneWidget);
    expect(find.text('Prijava kurira'), findsOneWidget);
  });

  testWidgets('odjava vraća na ekran za prijavu', (tester) async {
    await tester.pumpWidget(prijavljenaAplikacija());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Odjavi me'));
    await tester.pumpAndSettle();

    expect(find.text('Prijava kurira'), findsOneWidget);
    expect(find.text('Milica Jovanović'), findsNothing);
  });
}
