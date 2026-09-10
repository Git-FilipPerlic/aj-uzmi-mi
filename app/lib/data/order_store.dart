import 'package:flutter/foundation.dart';

import '../models/order.dart';

/// Držač svih porudžbina u aplikaciji.
///
/// Ova osnovna verzija drži porudžbine u memoriji i koristi se u testovima.
/// Prava aplikacija koristi `FirestoreOrderStore` (nasleđuje ovu klasu), koji
/// iste podatke uzima iz baze. Ekrani rade sa jednom i sa drugom isto — ne
/// znaju odakle podaci stižu.
class OrderStore extends ChangeNotifier {
  OrderStore({List<Order>? orders}) : orders = List<Order>.from(orders ?? []);

  /// Trenutne porudžbine. Nasleđene klase ovu listu zamenjuju kad stigne novo
  /// stanje iz baze.
  @protected
  List<Order> orders;

  /// Da li se podaci još učitavaju. U memorijskoj verziji nikad — podaci su
  /// već tu.
  bool get loading => false;

  /// Poruka o grešci, ili `null` ako je sve u redu.
  String? get error => null;

  /// Sve porudžbine, najnovija prva.
  List<Order> get all {
    final lista = List<Order>.from(orders);
    lista.sort((a, b) {
      final aVreme = a.createdAt;
      final bVreme = b.createdAt;
      if (aVreme == null && bVreme == null) return 0;
      if (aVreme == null) return 1;
      if (bVreme == null) return -1;
      return bVreme.compareTo(aVreme);
    });
    return lista;
  }

  /// Porudžbine koje još nisu dostavljene.
  List<Order> get active =>
      all.where((o) => o.status != OrderStatus.dostavljena).toList();

  /// Predložena ruta: aktivne porudžbine poređane po `routeOrder`.
  /// Porudžbine bez broja u ruti idu na kraj (agent ih još nije rasporedio).
  List<Order> get route {
    final lista = active;
    lista.sort((a, b) {
      final aMesto = a.routeOrder;
      final bMesto = b.routeOrder;
      if (aMesto == null && bMesto == null) return 0;
      if (aMesto == null) return 1;
      if (bMesto == null) return -1;
      return aMesto.compareTo(bMesto);
    });
    return lista;
  }

  /// Vraća porudžbinu po identifikatoru, ili `null` ako je više nema.
  Order? byId(String id) {
    for (final o in orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  /// Menja status porudžbine (dugmad „Preuzeto" i „Dostavljeno").
  void setStatus(String id, String newStatus) {
    final index = orders.indexWhere((o) => o.id == id);
    if (index == -1) return;
    orders[index] = orders[index].copyWithStatus(newStatus);
    notifyListeners();
  }
}
