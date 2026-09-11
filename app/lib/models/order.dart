/// Model jedne porudžbine.
///
/// Polja su namerno ista kao u Firestore kolekciji `orders` (vidi CLAUDE.md,
/// odeljak 5), da kasnije prelazak na pravu bazu bude prepisivanje jedan-na-jedan.
///
/// Pravilo: svako polje može biti prazno. Zato model nikad ne baca grešku na
/// praznom podatku — umesto toga vraća prazan string, praznu listu ili null,
/// a ekran sam odlučuje šta da prikaže kad podatka nema.
class Order {
  const Order({
    required this.id,
    this.customerName = '',
    this.customerContact = '',
    this.channel = '',
    this.items = const [],
    this.shop = '',
    this.address = '',
    this.urgency = '',
    this.price,
    this.status = '',
    this.routeOrder,
    this.createdAt,
  });

  /// Identifikator dokumenta (u Firestore-u je to ime dokumenta).
  final String id;
  final String customerName;
  final String customerContact;

  /// Odakle je porudžbina stigla: "viber", "whatsapp", "sms", "web", "messenger".
  final String channel;
  final List<String> items;

  /// Radnja: naziv i adresa, npr. "Maxi, Futoška 1". Kuriru je to prva stvar
  /// koju treba da zna — odatle kreće.
  final String shop;
  final String address;

  /// "normal", "hitno", "zakazano", "kad_stignes" — može biti i prazno.
  final String urgency;

  /// Cena u dinarima. `null` znači da cena još nije izračunata.
  final num? price;

  /// "nova", "potvrdjena", "preuzeta", "dostavljena".
  final String status;

  /// Mesto u ruti. `null` znači da ruta još nije isplanirana.
  final int? routeOrder;
  final DateTime? createdAt;

  /// Pravi porudžbinu iz mape (ovako će stizati podaci iz Firestore-a).
  /// Sve nepoznato ili pogrešnog tipa se tiho pretvara u prazno stanje.
  factory Order.fromMap(String id, Map<String, dynamic>? data) {
    final map = data ?? const <String, dynamic>{};

    String text(String key) {
      final value = map[key];
      return value is String ? value.trim() : '';
    }

    return Order(
      id: id,
      customerName: text('customerName'),
      customerContact: text('customerContact'),
      channel: text('channel'),
      items: (map['items'] is List)
          ? (map['items'] as List)
                .map((e) => e?.toString().trim() ?? '')
                .where((e) => e.isNotEmpty)
                .toList()
          : const [],
      shop: text('shop'),
      address: text('address'),
      urgency: text('urgency'),
      price: map['price'] is num ? map['price'] as num : null,
      status: text('status'),
      routeOrder: map['routeOrder'] is num
          ? (map['routeOrder'] as num).toInt()
          : null,
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt'] as DateTime
          : null,
    );
  }

  /// Kopija porudžbine sa promenjenim statusom.
  Order copyWithStatus(String newStatus) => Order(
    id: id,
    customerName: customerName,
    customerContact: customerContact,
    channel: channel,
    items: items,
    shop: shop,
    address: address,
    urgency: urgency,
    price: price,
    status: newStatus,
    routeOrder: routeOrder,
    createdAt: createdAt,
  );
}

/// Statusi porudžbine, redom kojim se dešavaju.
class OrderStatus {
  static const nova = 'nova';
  static const potvrdjena = 'potvrdjena';
  static const preuzeta = 'preuzeta';
  static const dostavljena = 'dostavljena';
}

/// Hitnost porudžbine.
class OrderUrgency {
  static const normal = 'normal';
  static const hitno = 'hitno';
  static const zakazano = 'zakazano';

  /// Sitnice i posao bez žurbe („donesi kad god").
  static const kadStignes = 'kad_stignes';
}
