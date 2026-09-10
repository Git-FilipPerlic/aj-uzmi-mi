import 'package:flutter/material.dart';

import 'models/order.dart';

/// Sitne pomoćne funkcije za ispis podataka na ekranu.
///
/// Sve rade i kad je podatak prazan — tada vraćaju kratak, jasan tekst umesto
/// prazne rupe, da se na terenu odmah vidi da podatak fali.

/// Tekst, ili zamena ako je prazan.
String orPlaceholder(String value, String placeholder) =>
    value.trim().isEmpty ? placeholder : value.trim();

/// „Hitno" / „Zakazano" / „Normalno".
String urgencyLabel(String urgency) {
  switch (urgency) {
    case OrderUrgency.hitno:
      return 'Hitno';
    case OrderUrgency.zakazano:
      return 'Zakazano';
    case OrderUrgency.normal:
      return 'Normalno';
    default:
      return 'Hitnost nepoznata';
  }
}

/// Boja kojom se označava hitnost. Hitno je crveno, zakazano plavo,
/// normalno neutralno — da se razlika vidi u jednom pogledu.
Color urgencyColor(String urgency, ColorScheme scheme) {
  switch (urgency) {
    case OrderUrgency.hitno:
      return scheme.error;
    case OrderUrgency.zakazano:
      return scheme.tertiary;
    case OrderUrgency.normal:
      return scheme.primary;
    default:
      return scheme.outline;
  }
}

/// „Nova" / „Potvrđena" / „Preuzeta" / „Dostavljena".
String statusLabel(String status) {
  switch (status) {
    case OrderStatus.nova:
      return 'Nova';
    case OrderStatus.potvrdjena:
      return 'Potvrđena';
    case OrderStatus.preuzeta:
      return 'Preuzeta';
    case OrderStatus.dostavljena:
      return 'Dostavljena';
    default:
      return 'Status nepoznat';
  }
}

/// Cena u dinarima; ako cene nema, kaže se to otvoreno.
String priceLabel(num? price) {
  if (price == null) return 'Cena nije određena';
  final ceo = price.round();
  return price == ceo ? '$ceo din' : '${price.toStringAsFixed(2)} din';
}

/// Vreme u obliku 14:05. Prazno vreme daje crticu.
String timeLabel(DateTime? time) {
  if (time == null) return '—';
  final sati = time.hour.toString().padLeft(2, '0');
  final minuti = time.minute.toString().padLeft(2, '0');
  return '$sati:$minuti';
}

/// Kanal sa kog je porudžbina stigla, sa velikim početnim slovom.
String channelLabel(String channel) {
  final c = channel.trim();
  if (c.isEmpty) return 'Nepoznat kanal';
  switch (c) {
    case 'viber':
      return 'Viber';
    case 'whatsapp':
      return 'WhatsApp';
    case 'messenger':
      return 'Messenger';
    case 'sms':
      return 'SMS';
    case 'web':
      return 'Sajt';
    default:
      return c[0].toUpperCase() + c.substring(1);
  }
}

/// Artikli u jednom redu („hleb, mleko 2l"), ili poruka da spiska nema.
String itemsLine(List<String> items) =>
    items.isEmpty ? 'Nema unetih artikala' : items.join(', ');
