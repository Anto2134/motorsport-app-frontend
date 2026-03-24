import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // Ci serve per navigare verso la schermata principale

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _paginaCorrente = 0;

  // I contenuti delle nostre 3 slide
  final List<Map<String, dynamic>> _pagine = [
    {
      "titolo": "Tutto il Motorsport",
      "sottotitolo": "F1, MotoGP, WEC, Rally e molto altro.\nTutti i campionati del mondo a portata di dito.",
      "icona": Icons.sports_motorsports,
      "colore": const Color(0xFFE53935), // Rosso
    },
    {
      "titolo": "Sincronizza all'istante",
      "sottotitolo": "Tocca il tasto '+' per aggiungere automaticamente\ntutte le gare al calendario del tuo telefono.",
      "icona": Icons.calendar_month,
      "colore": Colors.blueAccent,
    },
    {
      "titolo": "Preferiti nel Cloud",
      "sottotitolo": "Crea un account per salvare i tuoi campionati\npreferiti e ritrovarli su qualsiasi dispositivo.",
      "icona": Icons.cloud_sync,
      "colore": Colors.green,
    },
  ];

  Future<void> _completaOnboarding() async {
    HapticFeedback.heavyImpact();
    // 1. Salviamo nella cassaforte che l'utente ha visto il tutorial
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ha_visto_onboarding', true);

    // 2. Lo catapultiamo nell'app vera e propria!
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            // Tasto "Salta" in alto a destra
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completaOnboarding,
                child: const Text("Salta", style: TextStyle(color: Colors.white54, fontSize: 16)),
              ),
            ),
            
            // Le 3 Pagine Scorrevoli
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  HapticFeedback.selectionClick();
                  setState(() => _paginaCorrente = index);
                },
                itemCount: _pagine.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_pagine[index]["icona"], size: 120, color: _pagine[index]["colore"]),
                        const SizedBox(height: 40),
                        Text(
                          _pagine[index]["titolo"],
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _pagine[index]["sottotitolo"],
                          style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicatori a pallini e Bottoni in basso
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Pallini
                  Row(
                    children: List.generate(
                      _pagine.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 10,
                        width: _paginaCorrente == index ? 24 : 10,
                        decoration: BoxDecoration(
                          color: _paginaCorrente == index ? const Color(0xFFE53935) : Colors.white24,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                  
                  // Bottone Avanti / Inizia
                  ElevatedButton(
                    onPressed: () {
                      if (_paginaCorrente == _pagine.length - 1) {
                        _completaOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                      _paginaCorrente == _pagine.length - 1 ? "Inizia 🏁" : "Avanti",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
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