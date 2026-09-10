import 'dart:async';

// Paket firebase_auth i sam ima klasu FirebaseAuth; ovde nam treba pod tim
// imenom, a naša osnovna klasa se zove Auth, pa se ne mešaju.
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'auth.dart';

/// Prijava preko Firebase Authentication (mejl i lozinka).
///
/// Firebase sam pamti prijavu na telefonu, pa se kurir prijavljuje jednom i
/// posle toga aplikacija odmah otvara porudžbine — i kad nema signala.
///
/// Naloge se prave ručno u Firebase konzoli. U aplikaciji namerno nema
/// registracije, da neko ko instalira aplikaciju ne bi mogao sam sebi da
/// napravi nalog i uđe u porudžbine.
class FirebaseAuthService extends Auth {
  FirebaseAuthService({fb.FirebaseAuth? auth})
    : _auth = auth ?? fb.FirebaseAuth.instance {
    _pretplati();
  }

  final fb.FirebaseAuth _auth;
  StreamSubscription<fb.User?>? _pretplata;

  bool _loading = true;
  String? _email;

  @override
  bool get loading => _loading;

  @override
  String? get email => _email;

  @override
  bool get signedIn => _email != null;

  void _pretplati() {
    _pretplata = _auth.authStateChanges().listen((korisnik) {
      _email = korisnik == null ? null : (korisnik.email ?? '');
      _loading = false;
      notifyListeners();
    }, onError: (Object _) {
      _email = null;
      _loading = false;
      notifyListeners();
    });
  }

  @override
  Future<String?> signIn(String email, String password) async {
    final mejl = email.trim();
    if (mejl.isEmpty) return 'Unesi mejl.';
    if (password.isEmpty) return 'Unesi lozinku.';

    try {
      await _auth.signInWithEmailAndPassword(email: mejl, password: password);
      return null;
    } on fb.FirebaseAuthException catch (greska) {
      return _porukaZa(greska);
    } catch (greska) {
      return 'Prijava nije uspela: $greska';
    }
  }

  /// Firebase-ove šifre grešaka prevodi u rečenicu koja se razume bez
  /// traženja po internetu.
  String _porukaZa(fb.FirebaseAuthException greska) {
    switch (greska.code) {
      case 'invalid-email':
        return 'Mejl nije ispravno napisan.';
      case 'user-disabled':
        return 'Ovaj nalog je isključen.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Pogrešan mejl ili lozinka.';
      case 'too-many-requests':
        return 'Previše pokušaja. Sačekaj koji minut pa probaj ponovo.';
      case 'network-request-failed':
        return 'Nema veze sa internetom.';
      default:
        return greska.message?.trim().isNotEmpty == true
            ? greska.message!
            : 'Prijava nije uspela (${greska.code}).';
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  void dispose() {
    _pretplata?.cancel();
    super.dispose();
  }
}
