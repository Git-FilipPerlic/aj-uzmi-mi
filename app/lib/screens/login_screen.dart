import 'package:flutter/material.dart';

import '../data/auth.dart';

/// Ekran za prijavu kurira: mejl i lozinka.
///
/// Nema dugmeta za pravljenje naloga — nalog se pravi u Firebase konzoli.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth});

  final Auth auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mejl = TextEditingController();
  final _lozinka = TextEditingController();

  bool _radi = false;
  bool _sakrijLozinku = true;
  String? _greska;

  @override
  void dispose() {
    _mejl.dispose();
    _lozinka.dispose();
    super.dispose();
  }

  Future<void> _prijavi() async {
    if (_radi) return;

    setState(() {
      _radi = true;
      _greska = null;
    });

    final greska = await widget.auth.signIn(_mejl.text, _lozinka.text);

    // Ekran je možda već zamenjen listom porudžbina dok se čekao odgovor.
    if (!mounted) return;

    setState(() {
      _radi = false;
      _greska = greska;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.pedal_bike,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Aj uzmi mi',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Prijava kurira',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _mejl,
                    enabled: !_radi,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Mejl',
                      prefixIcon: Icon(Icons.alternate_email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _lozinka,
                    enabled: !_radi,
                    obscureText: _sakrijLozinku,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _prijavi(),
                    decoration: InputDecoration(
                      labelText: 'Lozinka',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: _sakrijLozinku
                            ? 'Prikaži lozinku'
                            : 'Sakrij lozinku',
                        icon: Icon(
                          _sakrijLozinku
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _sakrijLozinku = !_sakrijLozinku),
                      ),
                    ),
                  ),
                  if (_greska != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 20,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _greska!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _radi ? null : _prijavi,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _radi
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Prijava'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
