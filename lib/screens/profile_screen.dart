import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/favorites_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Variabili per il modulo di Login/Registrazione
  bool _isLogin = true;
  bool _isLoading = false;
  String _errorMessage = '';
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Funzione unificata per Accedere o Registrarsi
  Future<void> _submitAuth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        // Traduzioni base degli errori Firebase
        if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _errorMessage = "Email o password errati.";
        } else if (e.code == 'email-already-in-use') {
          _errorMessage = "Questa email è già registrata.";
        } else if (e.code == 'weak-password') {
          _errorMessage = "La password è troppo debole (min. 6 caratteri).";
        } else {
          _errorMessage = e.message ?? "Errore di autenticazione";
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Errore imprevisto: $e";
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _svuotaCache(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('catalogo_cache');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cache dell'app svuotata con successo!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ==========================================
  // SCHERMATA OSPITE (MODULO LOGIN/REGISTRAZIONE)
  // ==========================================
  Widget _buildAuthForm() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.sports_motorsports, size: 80, color: Color(0xFFE53935)),
            const SizedBox(height: 24),
            Text(
              _isLogin ? "Bentornato Pilota!" : "Unisciti al Paddock",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Accedi per salvare i tuoi campionati preferiti nel Cloud.",
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email",
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _submitAuth,
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_isLogin ? "Accedi" : "Registrati", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLogin = !_isLogin;
                  _errorMessage = '';
                });
              },
              child: Text(
                _isLogin ? "Non hai un account? Registrati" : "Hai già un account? Accedi", 
                style: const TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold)
              ),
            )
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SCHERMATA VIP (PROFILO LOGGATO)
  // ==========================================
  Widget _buildProfile(User user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCloudSynced = context.watch<FavoritesProvider>().isCloudSynced;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.redAccent.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Color(0xFFE53935)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Bentornato!", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(user.email ?? "Pilota VIP", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text("Stato Sincronizzazione", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: Icon(
                isCloudSynced ? Icons.cloud_done : Icons.cloud_off,
                color: isCloudSynced ? Colors.green : Colors.grey,
                size: 30,
              ),
              title: Text(isCloudSynced ? "Sincronizzazione Cloud Attiva" : "Salvataggio Locale"),
              subtitle: Text(
                isCloudSynced 
                  ? "I tuoi campionati preferiti sono salvati in modo sicuro sui server."
                  : "Salvataggio nel cloud non disponibile.",
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text("Impostazioni App", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.storage, color: Colors.blue),
                  title: const Text("Svuota Cache Offline"),
                  subtitle: const Text("Libera memoria e forza l'aggiornamento dei dati", style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _svuotaCache(context),
                ),
                Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                const ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.orange),
                  title: Text("Versione App"),
                  trailing: Text("1.0.0", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text("Esci dall'Account", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                foregroundColor: isDark ? Colors.redAccent : Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                elevation: 0,
              ),
              onPressed: () async {
                await _auth.signOut();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Scollegato con successo.")));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Il Mio Box", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      // MAGIA: StreamBuilder reagisce in tempo reale allo stato di Firebase!
      body: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snapshot.data;
          
          if (user == null) {
            return _buildAuthForm(); // Mostra Login/Registrazione
          } else {
            return _buildProfile(user); // Mostra il box VIP
          }
        },
      ),
    );
  }
}