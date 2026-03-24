import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true; 

  // ... (Tengo le funzioni _registrati, _accedi, _esci, _mostraErrore identiche a prima per brevità della logica)
  Future<void> _registrati() async {
    setState(() => _isLoading = true);
    try { await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _emailController.text.trim(), password: _passwordController.text.trim()); } 
    on FirebaseAuthException catch (e) { _mostraErrore(e.message ?? "Errore registrazione"); }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _accedi() async {
    setState(() => _isLoading = true);
    try { await FirebaseAuth.instance.signInWithEmailAndPassword(email: _emailController.text.trim(), password: _passwordController.text.trim()); } 
    on FirebaseAuthException catch (e) { _mostraErrore(e.message ?? "Errore accesso"); }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _esci() async { await FirebaseAuth.instance.signOut(); }

  void _mostraErrore(String messaggio) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(messaggio), backgroundColor: Colors.redAccent));
  }

  @override
  void dispose() { _emailController.dispose(); _passwordController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // 1. SEZIONE ACCOUNT (Firebase)
            StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final user = snapshot.data!;
                  return Card(
                    color: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const CircleAvatar(radius: 40, backgroundColor: Color(0xFFE53935), child: Icon(Icons.person, size: 40, color: Colors.white)),
                          const SizedBox(height: 16),
                          const Text("Account", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Text(user.email ?? "", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            onPressed: _esci,
                            icon: const Icon(Icons.logout),
                            label: const Text("Disconnetti"),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Card(
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(_isLogin ? "Accedi per sincronizzare" : "Crea un Account", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        TextField(controller: _emailController, decoration: InputDecoration(hintText: "Email", prefixIcon: const Icon(Icons.email), filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))),
                        const SizedBox(height: 10),
                        TextField(controller: _passwordController, obscureText: true, decoration: InputDecoration(hintText: "Password", prefixIcon: const Icon(Icons.lock), filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))),
                        const SizedBox(height: 20),
                        if (_isLoading) const CircularProgressIndicator()
                        else Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton(
                              onPressed: _isLogin ? _accedi : _registrati,
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                              child: Text(_isLogin ? "ACCEDI" : "REGISTRATI", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            TextButton(onPressed: () => setState(() { _isLogin = !_isLogin; }), child: Text(_isLogin ? "Non hai account? Registrati" : "Hai già account? Accedi")),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 30),

            // 2. SEZIONE IMPOSTAZIONI APP
            const Align(alignment: Alignment.centerLeft, child: Text("Impostazioni App", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
            Card(
              color: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.brightness_6),
                    title: const Text("Tema"),
                    trailing: DropdownButton<ThemeMode>(
                      value: themeProvider.themeMode,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: ThemeMode.system, child: Text("Sistema")),
                        DropdownMenuItem(value: ThemeMode.light, child: Text("Chiaro")),
                        DropdownMenuItem(value: ThemeMode.dark, child: Text("Scuro")),
                      ],
                      onChanged: (mode) { if (mode != null) themeProvider.setTema(mode); },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text("Versione App"),
                    trailing: const Text("2.0.0 Premium", style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () {}, // Eventuale easter egg ;)
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}