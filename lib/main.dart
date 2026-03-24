import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importiamo le 3 nuove schermate principali
import 'screens/dashboard_screen.dart'; // LA TUA NUOVA HOME!
import 'screens/catalog_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/favorites_provider.dart';
import 'services/theme_provider.dart'; 

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
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Motorsport Hub',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode, 
      
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFE53935),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(bodyColor: Colors.white, displayColor: Colors.white),
        appBarTheme: AppBarTheme(backgroundColor: const Color(0xFF1E1E1E), elevation: 0, centerTitle: true, titleTextStyle: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: Color(0xFF1E1E1E), selectedItemColor: Color(0xFFE53935), unselectedItemColor: Colors.white54),
      ),
      
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

  // ECCO LA NUOVA DISPOSIZIONE DELLE SCHERMATE
  final List<Widget> _screens = [
    const DashboardScreen(), // 0: La nuova Plancia/Home
    const CatalogScreen(),   // 1: Esplora (Catalogo)
    const ProfileScreen(),   // 2: Il tuo Profilo
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Abbiamo rimosso l'AppBar globale. Ora ci pensano le singole schermate!
      
      // IndexedStack mantiene vive le schermate in background senza ricaricarle
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.speed), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Esplora'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profilo'),
        ],
      ),
    );
  }
}