import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _esci(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) Navigator.of(context).pushReplacementNamed('/'); 
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("Il tuo Profilo"), centerTitle: true, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // CARD PROFILO
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CircleAvatar(radius: 45, backgroundColor: const Color(0xFFE53935).withOpacity(0.1), child: const Icon(Icons.person, size: 45, color: Color(0xFFE53935))),
                  const SizedBox(height: 16),
                  Text(user?.email ?? "Ospite", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  
                  // Seleziona cosa mostrare: Badge VIP o Tasto Login
                  if (user != null)
                    Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: const Text("VIP Member (Cloud Sync)", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)))
                  else
                    ElevatedButton.icon(
                      icon: const Icon(Icons.login),
                      label: const Text("Accedi o Registrati"),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                      // SOSTITUISCI CON LA TUA SCHERMATA DI LOGIN:
                      onPressed: () { /* Navigator.push(context, MaterialPageRoute(builder: (c) => LoginScreen())); */ },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Padding(padding: EdgeInsets.only(left: 8.0, bottom: 8.0), child: Text("Impostazioni App", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: const Text("Tema Scuro"),
                  trailing: Switch(
                    value: isDark,
                    activeColor: const Color(0xFFE53935),
                    onChanged: (val) {
                      themeProvider.toggleTheme(val);
                    },
                  ),
                ),
                const Divider(height: 1),
                const ListTile(leading: Icon(Icons.info_outline), title: Text("Versione App"), trailing: Text("1.0.0 VIP", style: TextStyle(color: Colors.grey))),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // TASTI LOGOUT SOLO SE LOGGATO
          if (user != null) ...[
            const Padding(padding: EdgeInsets.only(left: 8.0, bottom: 8.0), child: Text("Account", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.orange),
                title: const Text("Esci", style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () { HapticFeedback.mediumImpact(); _esci(context); },
              ),
            ),
          ]
        ],
      ),
    );
  }
}


  // INTERRUTTORE SERVER (Scommenta quello che ti serve)
  // ===============================================
