import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/catalog_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/favorites_provider.dart';
import 'services/theme_provider.dart'; // 1. IMPORTIAMO IL TEMA

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCn18gBXsx_i3i0-3CCuyuX4nBXIWeieaw",
      authDomain: "motorsport-hub-66bd2.firebaseapp.com",
      projectId: "motorsport-hub-66bd2",
      storageBucket: "motorsport-hub-66bd2.firebasestorage.app",
      messagingSenderId: "210751206505",
      appId: "1:210751206505:web:6049b933dc7bbc9a555ef8",
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final bool haVistoOnboarding = prefs.getBool('ha_visto_onboarding') ?? false;

  runApp(
    // 2. MULTIPROVIDER: L'app ora ha DUE cervelli!
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => FavoritesProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: MotorsportApp(mostraOnboarding: !haVistoOnboarding),
    ),
  );
}

class MotorsportApp extends StatelessWidget {
  final bool mostraOnboarding;
  const MotorsportApp({super.key, required this.mostraOnboarding});

  @override
  Widget build(BuildContext context) {
    // Ascoltiamo il provider del tema
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Motorsport Hub',
      debugShowCheckedModeBanner: false,
      
      // 3. DEFINIAMO IL TEMA CHIARO E SCURO
      themeMode: themeProvider.themeMode, // Sceglie in automatico in base alle impostazioni
      
      // TEMA SCURO (Quello classico nostro)
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFE53935),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(bodyColor: Colors.white, displayColor: Colors.white),
        appBarTheme: AppBarTheme(backgroundColor: const Color(0xFF1E1E1E), elevation: 0, centerTitle: true, titleTextStyle: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: Color(0xFF1E1E1E), selectedItemColor: Color(0xFFE53935), unselectedItemColor: Colors.white54),
      ),
      
      // TEMA CHIARO (Pulito ed elegante)
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFFE53935),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        cardColor: Colors.white,
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).apply(bodyColor: Colors.black87, displayColor: Colors.black87),
        appBarTheme: AppBarTheme(backgroundColor: const Color(0xFFE53935), elevation: 0, centerTitle: true, titleTextStyle: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white), iconTheme: const IconThemeData(color: Colors.white)),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: Colors.white, selectedItemColor: Color(0xFFE53935), unselectedItemColor: Colors.black54),
      ),
      
      home: mostraOnboarding ? const OnboardingScreen() : const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CatalogScreen(),
    const FavoritesScreen(),
    const ProfileScreen(), 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motorsport Hub 🏁', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Condividi l\'app',
            onPressed: () {
              Share.share('🏎️ Ehi! Sto usando Motorsport Hub per aggiungere gli orari di F1, WEC e MotoGP direttamente nel calendario del telefono.\n\nProvala gratis: https://IL-TUO-LINK-NETLIFY.netlify.app');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Catalogo'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Preferiti'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Impostazioni'), // Rinominato in Impostazioni
        ],
      ),
    );
  }
}