import 'dart:async';

// Paket cloud_firestore i sam ima klasu Order (za sortiranje upita), pa je ovde
// sakrivamo da se ne bi mešala sa našom porudžbinom.
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../models/order.dart';
import 'order_store.dart';

/// Porudžbine koje žive u Firestore kolekciji `orders`.
///
/// Sluša bazu neprekidno (`snapshots`), pa se svaka promena — bilo da je upiše
/// agent na serveru ili kurir u aplikaciji — vidi odmah, bez osvežavanja.
///
/// Firestore i sam čuva kopiju podataka na telefonu, pa lista radi i kad nema
/// signala; upis se pošalje čim se veza vrati.
class FirestoreOrderStore extends OrderStore {
  FirestoreOrderStore({FirebaseFirestore? firestore})
    : _collection = (firestore ?? FirebaseFirestore.instance).collection(
        collectionName,
      ) {
    _pretplati();
  }

  /// Ime kolekcije u bazi (isto kao u dokumentaciji projekta).
  static const collectionName = 'orders';

  final CollectionReference<Map<String, dynamic>> _collection;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _pretplata;

  bool _loading = true;
  String? _error;

  @override
  bool get loading => _loading;

  @override
  String? get error => _error;

  void _pretplati() {
    _pretplata = _collection.snapshots().listen(
      (snapshot) {
        orders = snapshot.docs
            .map((doc) => Order.fromMap(doc.id, _sredi(doc.data())))
            .toList();
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object greska) {
        _loading = false;
        _error = 'Neuspešno čitanje porudžbina: $greska';
        notifyListeners();
      },
    );
  }

  /// Firestore vreme (`Timestamp`) pretvara u obično `DateTime`, da model
  /// porudžbine ne mora ništa da zna o Firestore-u.
  Map<String, dynamic> _sredi(Map<String, dynamic> data) {
    final sredjeno = Map<String, dynamic>.from(data);
    final vreme = sredjeno['createdAt'];
    if (vreme is Timestamp) {
      sredjeno['createdAt'] = vreme.toDate();
    }
    return sredjeno;
  }

  /// Upisuje novi status u bazu. Firestore odmah javi promenu nazad kroz
  /// `snapshots`, pa se ekran osveži sam — i kad telefon nema signal.
  @override
  void setStatus(String id, String newStatus) {
    if (id.isEmpty) return;
    _collection.doc(id).update({'status': newStatus}).catchError((
      Object greska,
    ) {
      _error = 'Neuspešan upis statusa: $greska';
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _pretplata?.cancel();
    super.dispose();
  }
}
