import '../models/order.dart';

/// Privremene, izmišljene porudžbine — služe samo da se ekrani vide i probaju
/// pre nego što se aplikacija zakači na Firestore. Kad Firebase proradi, ovaj
/// fajl se briše, a ekrani ostaju isti.
///
/// Namerno su ubačeni i "rupičasti" slučajevi (bez cene, bez adrese, bez
/// artikala), da se odmah vidi kako aplikacija izgleda na praznim podacima.
List<Order> testOrders() {
  final sada = DateTime.now();

  return [
    Order(
      id: '1',
      customerName: 'Milica Jovanović',
      customerContact: '+381 63 111 222',
      channel: 'viber',
      items: ['1kg mlevenog mesa', '500g kajmaka'],
      shop: 'Kovilj mesara, Futoška 5',
      address: 'Bulevar Kneza Miloša 45, Novi Sad',
      urgency: OrderUrgency.hitno,
      price: 450,
      status: OrderStatus.nova,
      routeOrder: 1,
      createdAt: sada.subtract(const Duration(minutes: 8)),
    ),
    Order(
      id: '2',
      customerName: 'Jelena Kovač',
      customerContact: '+381 64 333 444',
      channel: 'whatsapp',
      items: ['hleb', 'mleko 1l', 'Plazma keks', 'ofingeri od kineza'],
      shop: 'Prodavnica mešovite robe, Mileve Marić 5',
      address: 'Momčila Tapavice 3, Novi Sad',
      urgency: OrderUrgency.normal,
      price: 150,
      status: OrderStatus.potvrdjena,
      routeOrder: 2,
      createdAt: sada.subtract(const Duration(minutes: 25)),
    ),
    Order(
      id: '3',
      customerName: 'Apoteka Sunce',
      customerContact: '021 555 666',
      channel: 'sms',
      items: ['paket lekova za g. Simića'],
      address: 'Narodnog fronta 8, Novi Sad',
      urgency: OrderUrgency.zakazano,
      price: 380,
      status: OrderStatus.preuzeta,
      routeOrder: 3,
      createdAt: sada.subtract(const Duration(hours: 1)),
    ),
    // Porudžbina koja je tek stigla: agent još nije izračunao cenu ni rutu.
    Order(
      id: '4',
      customerName: 'Nepoznat broj',
      customerContact: '+381 60 777 888',
      channel: 'sms',
      items: [],
      address: '',
      urgency: '',
      price: null,
      status: OrderStatus.nova,
      routeOrder: null,
      createdAt: sada.subtract(const Duration(minutes: 2)),
    ),
    Order(
      id: '5',
      customerName: 'Jovan Marić',
      customerContact: '+381 62 999 000',
      channel: 'web',
      items: ['2x burek sa sirom', 'jogurt'],
      address: 'Šafarikova 3, Novi Sad',
      urgency: OrderUrgency.normal,
      price: 280,
      status: OrderStatus.dostavljena,
      routeOrder: 0,
      createdAt: sada.subtract(const Duration(hours: 2)),
    ),
    // Sitnica bez žurbe.
    Order(
      id: '6',
      customerName: 'Ana Petrović',
      customerContact: '+381 65 123 456',
      channel: 'viber',
      items: ['baterije AA'],
      shop: 'Trafika, Futoška 20',
      address: 'Mileve Marić 14, Novi Sad',
      urgency: OrderUrgency.kadStignes,
      price: 0,
      status: OrderStatus.potvrdjena,
      routeOrder: 4,
      createdAt: sada.subtract(const Duration(minutes: 40)),
    ),
  ];
}
