import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // LA NOSTRA NUOVA LIBRERIA
import '../services/favorites_provider.dart';
import '../widgets/shimmer_card.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final String baseUrl = "motorsport-hub1-0-1.onrender.com"; 
  
  List<dynamic> campionati = [];
  List<dynamic> campionatiFiltrati = [];
  bool inCaricamento = true;
  bool haErrore = false;
  String messaggioErrore = "";
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _inizializzaApp();
  }

  // 1. IL NUOVO ORDINE DI ACCENSIONE
  Future<void> _inizializzaApp() async {
    await _caricaDatiLocali(); // Prima guardiamo in memoria...
    _scaricaCatalogo();        // ...poi aggiorniamo da internet di nascosto!
  }

  // 2. FUNZIONE PER LEGGERE LA MEMORIA DEL TELEFONO
  Future<void> _caricaDatiLocali() async {
    final prefs = await SharedPreferences.getInstance();
    final datiSalvati = prefs.getString('catalogo_cache'); // Cerchiamo il salvataggio
    
    if (datiSalvati != null) {
      if (mounted) {
        setState(() {
          campionati = json.decode(datiSalvati);
          campionatiFiltrati = campionati;
          inCaricamento = false; // Togliamo subito lo shimmer!
        });
        debugPrint("Dati caricati istantaneamente dalla memoria locale ⚡");
      }
    }
  }

  // 3. LA FUNZIONE DI DOWNLOAD AGGIORNATA
  Future<void> _scaricaCatalogo() async {
    // Mostriamo lo shimmer SOLO se non abbiamo dati salvati
    if (campionati.isEmpty) {
      setState(() {
        inCaricamento = true;
        haErrore = false;
      });
    }

    try {
      final response = await http.get(Uri.parse('https://$baseUrl/api/campionati'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // SALVIAMO I NUOVI DATI IN MEMORIA PER LA PROSSIMA VOLTA
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('catalogo_cache', json.encode(data['campionati']));

        if (mounted) {
          setState(() {
            campionati = data['campionati'];
            campionatiFiltrati = campionati;
            inCaricamento = false;
            haErrore = false;
          });
          debugPrint("Dati aggiornati dal server ☁️");
        }
      } else {
        if (campionati.isEmpty) _mostraErrore("I server sono ai box. Riprova tra poco!");
      }
    } catch (e) {
      debugPrint("Errore di rete: $e");
      if (campionati.isEmpty) _mostraErrore("Nessuna connessione a internet. Sei offline?");
    }
  }

  void _mostraErrore(String messaggio) {
    if (mounted) {
      setState(() {
        haErrore = true;
        messaggioErrore = messaggio;
        inCaricamento = false;
      });
    }
  }

  Future<void> _sincronizza(String urlSorgente, String nome) async {
    final urlCodificato = Uri.encodeComponent(urlSorgente);
    final nomeCodificato = Uri.encodeComponent(nome);
    final Uri webcalUrl = Uri.parse('webcal://$baseUrl/calendari/genera?url=$urlCodificato&nome=$nomeCodificato');
    
    if (!await launchUrl(webcalUrl)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossibile aprire il calendario del telefono", style: TextStyle(color: Colors.white))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra di ricerca
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (testo) {
              setState(() {
                campionatiFiltrati = campionati.where((camp) {
                  return camp['nome'].toString().toLowerCase().contains(testo.toLowerCase());
                }).toList();
              });
            },
            decoration: InputDecoration(
              hintText: "Cerca un campionato...",
              prefixIcon: const Icon(Icons.search, color: Color(0xFFE53935)),
              suffixIcon: _searchController.text.isNotEmpty 
                ? IconButton(icon: const Icon(Icons.clear, color: Colors.white54), onPressed: () {
                    _searchController.clear();
                    setState(() => campionatiFiltrati = campionati);
                  })
                : null,
              filled: true,
              fillColor: const Color(0xFF2A2A2A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
            ),
          ),
        ),
        
        // Logica a Bivio
        Expanded(
          child: inCaricamento 
            ? ListView.builder(
                padding: const EdgeInsets.only(top: 10, bottom: 20),
                itemCount: 8,
                itemBuilder: (context, index) => const ShimmerCard(),
              )
            : haErrore 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 80, color: Colors.white24),
                      const SizedBox(height: 16),
                      const Text("Ops! Motore in stallo", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      Text(messaggioErrore, style: const TextStyle(fontSize: 16, color: Colors.white54), textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _scaricaCatalogo,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text("Riprova", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      )
                    ],
                  ),
                )
              : campionatiFiltrati.isEmpty 
                ? const Center(child: Text("Nessun campionato trovato 🏎️💨", style: TextStyle(color: Colors.white54)))
                : RefreshIndicator(
                    color: const Color(0xFFE53935),
                    backgroundColor: const Color(0xFF1E1E1E),
                    onRefresh: _scaricaCatalogo,
                    child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 10, bottom: 20),
                        itemCount: campionatiFiltrati.length,
                        itemBuilder: (context, index) {
                          final camp = campionatiFiltrati[index];
                          final nomeCampionato = camp['nome'] != "" ? camp['nome'] : "Campionato Sconosciuto";
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            color: const Color(0xFF1E1E1E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color(0xFFE53935).withOpacity(0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.sports_score, color: Color(0xFFE53935)),
                              ),
                              title: Text(nomeCampionato, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              subtitle: const Text("Aggiungi all'agenda", style: TextStyle(color: Colors.white54, fontSize: 12)),
                              
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Consumer<FavoritesProvider>(
                                    builder: (context, favorites, child) {
                                      final isFav = favorites.isFavorite(camp);
                                      return IconButton(
                                        icon: Icon(
                                          isFav ? Icons.star : Icons.star_border,
                                          color: isFav ? Colors.amber : Colors.white54,
                                        ),
                                        onPressed: () {
                                          favorites.toggleFavorite(camp);
                                          ScaffoldMessenger.of(context).clearSnackBars();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(isFav ? "Rimosso dai preferiti" : "Aggiunto ai preferiti! ⭐️"),
                                              duration: const Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Color(0xFFE53935)),
                                    onPressed: () => _sincronizza(camp['url_sorgente'], nomeCampionato),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                ),
        ),
      ],
    );
  }
}