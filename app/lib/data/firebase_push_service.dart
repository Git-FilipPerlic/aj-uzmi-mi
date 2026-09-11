import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'push.dart';

/// Push obaveštenja preko Firebase Cloud Messaging-a (radi samo na Androidu).
///
/// Telefon se po prijavi upisuje na temu „kurir". Poruka poslata na tu temu
/// stiže na sve telefone prijavljenih kurira — za sad se šalje ručno iz
/// Firebase konzole, a kasnije će je slati backend agent čim upiše novu
/// porudžbinu. Tema umesto pojedinačnih adresa telefona: ništa ne mora da se
/// čuva u bazi, a kurir je za sad jedan.
class FirebasePushService extends Push {
  FirebasePushService();

  static const tema = 'kurir';

  StreamSubscription<RemoteMessage>? _pretplata;

  /// Firebase push na Windowsu ne postoji, pa se tamo sve preskače.
  bool get _podrzano =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<void> start(void Function(String naslov, String tekst) onPoruka) async {
    if (!_podrzano) return;

    await _pretplata?.cancel();
    _pretplata = FirebaseMessaging.onMessage.listen((poruka) {
      debugPrint('Push stigao dok je aplikacija otvorena');
      final obavestenje = poruka.notification;
      onPoruka(
        obavestenje?.title?.trim() ?? '',
        obavestenje?.body?.trim() ?? '',
      );
    });

    // Bez signala ovo može da ne uspe. Aplikacija tada radi normalno, samo
    // bez push-a, a upis na temu se ponovi pri sledećoj prijavi ili pokretanju.
    try {
      final messaging = FirebaseMessaging.instance;
      // Android 13+ pita kurira da dozvoli obaveštenja. Ako odbije,
      // porudžbine se i dalje vide u aplikaciji.
      await messaging.requestPermission();
      await messaging.subscribeToTopic(tema);
    } catch (greska) {
      debugPrint('Push nije uključen: $greska');
    }
  }

  @override
  Future<void> stop() async {
    await _pretplata?.cancel();
    _pretplata = null;
    if (!_podrzano) return;

    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(tema);
    } catch (greska) {
      debugPrint('Odjava sa push-a nije uspela: $greska');
    }
  }
}
