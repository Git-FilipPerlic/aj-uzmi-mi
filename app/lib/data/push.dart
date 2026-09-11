/// Push obaveštenja o novim porudžbinama.
///
/// Ova osnovna verzija ne radi ništa — koristi se u testovima i na Windowsu,
/// gde Firebase push ne postoji. Prava verzija je `FirebasePushService`.
/// Aplikacija radi sa jednom i sa drugom isto.
class Push {
  const Push();

  /// Kurir se prijavio: počni da primaš obaveštenja na ovom telefonu.
  ///
  /// Obaveštenje koje stigne dok je aplikacija otvorena telefon sam ne
  /// prikazuje, pa se prosleđuje u [onPoruka] da ga aplikacija pokaže.
  /// Naslov i tekst mogu biti prazni.
  Future<void> start(void Function(String naslov, String tekst) onPoruka) async {}

  /// Kurir se odjavio: prestani da primaš obaveštenja na ovom telefonu.
  Future<void> stop() async {}
}
