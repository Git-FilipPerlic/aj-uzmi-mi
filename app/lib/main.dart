import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'data/auth.dart';
import 'data/firebase_auth_service.dart';
import 'data/firebase_push_service.dart';
import 'data/firestore_order_store.dart';
import 'data/order_store.dart';
import 'data/push.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/route_screen.dart';
import 'widgets/message_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (greska) {
    // Ako Firebase ne uspe da se pokrene, aplikacija ne sme da ostane na
    // praznom belom ekranu — bolje je jasno reći šta ne valja.
    runApp(StartupErrorApp(message: '$greska'));
    return;
  }

  runApp(
    DispecerApp(
      auth: FirebaseAuthService(),
      createStore: () => FirestoreOrderStore(),
      push: FirebasePushService(),
    ),
  );
}

/// Kurirska aplikacija „Aj uzmi mi" (Faza 2).
///
/// Dok kurir nije prijavljen, prikazuje se ekran za prijavu. Porudžbine se
/// otvaraju tek posle prijave i zatvaraju čim se kurir odjavi — namerno, jer
/// pravila baze traže prijavljenog korisnika, pa čitanje bez prijave ionako ne
/// bi prošlo.
class DispecerApp extends StatefulWidget {
  const DispecerApp({
    super.key,
    required this.auth,
    required this.createStore,
    this.push = const Push(),
  });

  final Auth auth;

  /// Pravi držač porudžbina: u pravoj aplikaciji Firestore, u testovima
  /// memorijska verzija sa test podacima.
  final OrderStore Function() createStore;

  /// Push obaveštenja: uključuju se prijavom, isključuju odjavom — da telefon
  /// sa kog se kurir odjavio ne dobija porudžbine.
  final Push push;

  @override
  State<DispecerApp> createState() => _DispecerAppState();
}

class _DispecerAppState extends State<DispecerApp> {
  OrderStore? _store;

  /// Preko ovoga se prikazuje obaveštenje koje stigne dok je aplikacija
  /// otvorena, bez obzira na kom je ekranu kurir.
  final _poruke = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    widget.auth.addListener(_naPromenuPrijave);
    _uskladiSaPrijavom();
  }

  void _naPromenuPrijave() => setState(_uskladiSaPrijavom);

  /// Drži porudžbine i prijavu u skladu: prijava ih otvara, odjava zatvara.
  void _uskladiSaPrijavom() {
    if (widget.auth.signedIn && _store == null) {
      _store = widget.createStore();
      widget.push.start(_prikaziObavestenje);
    } else if (!widget.auth.signedIn && _store != null) {
      _store!.dispose();
      _store = null;
      widget.push.stop();
    }
  }

  /// Traka ostaje dok je kurir ne skloni: u vožnji se kratka traka lako
  /// propusti, a obaveštenje o novoj porudžbini ne sme da nestane samo od sebe.
  void _prikaziObavestenje(String naslov, String tekst) {
    final redovi = [naslov, tekst].where((t) => t.isNotEmpty).join('\n');
    _poruke.currentState?.showSnackBar(
      SnackBar(
        content: Text(redovi.isEmpty ? 'Nova porudžbina' : redovi),
        duration: const Duration(days: 1),
        action: SnackBarAction(label: 'U redu', onPressed: () {}),
      ),
    );
  }

  @override
  void dispose() {
    widget.auth.removeListener(_naPromenuPrijave);
    _store?.dispose();
    widget.auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aj uzmi mi',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _poruke,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B6C3A)),
        useMaterial3: true,
      ),
      home: _pocetniEkran(),
    );
  }

  Widget _pocetniEkran() {
    if (widget.auth.loading) {
      return const Scaffold(
        body: LoadingView(text: 'Provera prijave...'),
      );
    }

    final store = _store;
    if (!widget.auth.signedIn || store == null) {
      return LoginScreen(auth: widget.auth);
    }

    return HomePage(store: store, auth: widget.auth);
  }
}

/// Ekran koji se prikaže ako Firebase uopšte nije mogao da se pokrene.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aj uzmi mi',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: MessageView(
          icon: Icons.error_outline,
          text: 'Aplikacija ne može da se poveže na Firebase',
          detail: message,
          color: Colors.red,
        ),
      ),
    );
  }
}

/// Početna strana sa dva ekrana: „Porudžbine" i „Ruta".
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.store, required this.auth});

  final OrderStore store;
  final Auth auth;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _izabrani = 0;

  /// Odjava se pita za potvrdu: dugme je nadohvat ruke dok se vozi, a ponovna
  /// prijava traži kucanje lozinke na telefonu.
  Future<void> _odjavi() async {
    final potvrda = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Odjava'),
        content: Text(
          widget.auth.email?.isNotEmpty == true
              ? 'Odjaviti nalog ${widget.auth.email}?'
              : 'Odjaviti se sa ovog telefona?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Odjavi me'),
          ),
        ],
      ),
    );

    if (potvrda == true) {
      await widget.auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ekrani = [
      OrdersScreen(store: widget.store),
      RouteScreen(store: widget.store),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_izabrani == 0 ? 'Porudžbine' : 'Predložena ruta'),
        actions: [
          IconButton(
            tooltip: 'Odjava',
            icon: const Icon(Icons.logout),
            onPressed: _odjavi,
          ),
        ],
      ),
      body: SafeArea(child: ekrani[_izabrani]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _izabrani,
        onDestinationSelected: (i) => setState(() => _izabrani = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Porudžbine',
          ),
          NavigationDestination(
            icon: Icon(Icons.alt_route_outlined),
            selectedIcon: Icon(Icons.alt_route),
            label: 'Ruta',
          ),
        ],
      ),
    );
  }
}
