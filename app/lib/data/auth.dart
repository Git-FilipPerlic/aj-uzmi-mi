import 'package:flutter/foundation.dart';

/// Ko je trenutno prijavljen u aplikaciji.
///
/// Ova osnovna verzija pamti prijavu samo u memoriji i koristi se u testovima.
/// Prava aplikacija koristi `FirebaseAuth` (nasleđuje ovu klasu), koji prijavu
/// proverava kod Firebase-a. Ekrani rade sa jednom i sa drugom isto — ne znaju
/// ko zapravo proverava lozinku.
class Auth extends ChangeNotifier {
  Auth({this._email});

  String? _email;

  /// Mejl prijavljenog kurira, ili `null` ako niko nije prijavljen.
  String? get email => _email;

  bool get signedIn => _email != null;

  /// Da li se još proverava da li je neko ostao prijavljen od ranije.
  /// U memorijskoj verziji nikad — odgovor je odmah poznat.
  bool get loading => false;

  /// Prijavljuje kurira. Vraća `null` ako je prošlo, ili poruku o grešci
  /// napisanu tako da se razume bez objašnjenja.
  ///
  /// Prazna polja se hvataju ovde, da se ne šalje uzaludan zahtev.
  Future<String?> signIn(String email, String password) async {
    final mejl = email.trim();
    if (mejl.isEmpty) return 'Unesi mejl.';
    if (password.isEmpty) return 'Unesi lozinku.';

    _email = mejl;
    notifyListeners();
    return null;
  }

  Future<void> signOut() async {
    _email = null;
    notifyListeners();
  }
}
