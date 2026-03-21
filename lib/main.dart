import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // 1. L'importazione magica
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
        
        // 2. LA MAGIA DELLA TIPOGRAFIA
        // Usiamo "Inter" come font di base per tutti i testi dell'app
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
          // Usiamo "Montserrat" in grassetto solo per il Titolone in alto
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

// ... DA QUI IN POI LASCIA IL RESTO DEL CODICE IDENTICO (class MainScreen ecc.) ...

// Questa è l'impalcatura che contiene il menu in basso!
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // 0 = Catalogo, 1 = Preferiti

  // Le schermate tra cui navigare
  final List<Widget> _screens = [
    const CatalogScreen(),
    const FavoritesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motorsport Hub 🏁', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _screens[_currentIndex], // Mostra la schermata selezionata
      
      // Il nuovo menu di navigazione stile app nativa!
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