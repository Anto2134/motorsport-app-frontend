import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../services/favorites_provider.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  // Il link del tuo server Render
  final String baseUrl = "motorsport-hub1-0-1.onrender.com"; 
  
  List<dynamic> campionati = [];
  List<dynamic> campionatiFiltrati = [];
  bool inCaricamento = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scaricaCatalogo();
  }

  Future<void> _scaricaCatalogo() async {
    try {
      final response = await http.get(Uri.parse('https://$baseUrl/api/campionati'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            campionati = data['campionati'];
            campionatiFiltrati = campionati;
            inCaricamento = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Errore: $e");
      if (mounted) setState(() => inCaricamento = false);
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
              hintText: "Cerca un campionatoooo...",
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
        
        // Lista
        Expanded(
          child: inCaricamento 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
            : campionatiFiltrati.isEmpty 
              ? const Center(child: Text("Nessun campionato trovato 🏎️💨", style: TextStyle(color: Colors.white54)))
              : ListView.builder(
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
                        
                        // ROW CON STELLA E BOTTONE CALENDARIO
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
      ],
    );
  }
}   