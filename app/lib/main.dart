import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'data/firestore_order_store.dart';
import 'data/order_store.dart';
import 'firebase_options.dart';
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

  runApp(DispecerApp(store: FirestoreOrderStore()));
}

/// Kurirska aplikacija „Aj uzmi mi" (Faza 2).
///
/// Porudžbine dobija preko `store`-a: u pravoj aplikaciji je to Firestore, a u
/// testovima memorijska verzija sa test podacima.
class DispecerApp extends StatefulWidget {
  const DispecerApp({super.key, required this.store});

  final OrderStore store;

  @override
  State<DispecerApp> createState() => _DispecerAppState();
}

class _DispecerAppState extends State<DispecerApp> {
  @override
  void dispose() {
    widget.store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aj uzmi mi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B6C3A)),
        useMaterial3: true,
      ),
      home: HomePage(store: widget.store),
    );
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
  const HomePage({super.key, required this.store});

  final OrderStore store;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _izabrani = 0;

  @override
  Widget build(BuildContext context) {
    final ekrani = [
      OrdersScreen(store: widget.store),
      RouteScreen(store: widget.store),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_izabrani == 0 ? 'Porudžbine' : 'Predložena ruta'),
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
