import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart'; // 1. L'importazione per la condivisione
import 'screens/catalog_screen.dart';
import 'screens/favorites_screen.dart';
import 'services/favorites_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => FavoritesProvider(),
      child: const MotorsportApp(),
    ),
  );
}

class MotorsportApp extends StatelessWidget {
  const MotorsportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motorsport Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFE53935),
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF1E1E1E),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: const MainScreen(),
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
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motorsport Hub 🏁', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // 2. IL NOSTRO NUOVO TASTO CONDIVIDI!
          IconButton(
            icon: const Icon(Icons.ios_share, color: Colors.white),
            tooltip: 'Condividi l\'app',
            onPressed: () {
              // RICORDA: Sostituisci il link qui sotto con quello vero!
              Share.share(
                '🏎️ Ehi! Sto usando Motorsport Hub per aggiungere gli orari di F1, WEC e MotoGP direttamente nel calendario del telefono.\n\nProvala gratis: https://motorsport-hub-frontend.netlify.app/'
              );
            },
          ),
          const SizedBox(width: 8), // Piccolo margine estetico
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: const Color(0xFFE53935),
        unselectedItemColor: Colors.white54,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Catalogo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Preferiti',
          ),
        ],
      ),
    );
  }
}