import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // IL FIX DELLO SCHERMO ROSSO È QUI
import '../services/favorites_provider.dart';
import '../widgets/shimmer_card.dart';
import 'championship_detail_screen.dart'; // IMPORTIAMO LA PAGINA DETTAGLIO

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  //final String serverUrl = "http://127.0.0.1:5000"; 
  final String serverUrl = "https://motorsport-hub1-0-1.onrender.com";

  List<dynamic> campionati = [];
  List<dynamic> campionatiFiltrati = [];
  List<dynamic> _newsList = []; // Prepariamo la valigia per le notizie
  bool inCaricamento = true;
  bool haErrore = false;
  String messaggioErrore = "";
  final TextEditingController _searchController = TextEditingController();
  
  String _filtroAttivo = 'Tutti 🌍';
  List<String> _categorie = ['Tutti 🌍']; 
  
  @override
  void initState() {
    super.initState();
    // ECCO LA RIGA CHE MANCAVA!
    initializeDateFormatting('it_IT', null);
    
    _caricaDatiLocali().then((_) {
      _scaricaCatalogo();
      _scaricaNews(); // Scarichiamo anche le notizie
    });
  }

  Future<void> _caricaDatiLocali() async {
    final prefs = await SharedPreferences.getInstance();
    final dati = prefs.getString('catalogo_cache');
    if (dati != null && mounted) { 
      setState(() { 
        campionati = json.decode(dati); 
        _estraiCategorie();
        _applicaFiltri(); 
        inCaricamento = false; 
      }); 
    }
  }

  Future<void> _scaricaCatalogo() async {
    if (campionati.isEmpty) setState(() { inCaricamento = true; haErrore = false; });
    try {
      final res = await http.get(Uri.parse('$serverUrl/api/campionati'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('catalogo_cache', json.encode(data['campionati']));
        if (mounted) {
          setState(() { 
            campionati = data['campionati']; 
            _estraiCategorie();
            _applicaFiltri(); 
            inCaricamento = false; 
            haErrore = false; 
          });
        }
      } else {
        if (mounted) setState(() { inCaricamento = false; });
      }
    } catch (e) {
      if (mounted) setState(() { inCaricamento = false; });
    }
  }

  Future<void> _scaricaNews() async {
    try {
      final res = await http.get(Uri.parse('$serverUrl/api/news'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (mounted) setState(() { _newsList = data['news']; });
      }
    } catch (e) { debugPrint("Errore news: $e"); }
  }

  void _estraiCategorie() {
    final Set<String> catsTrovate = {};
    for (var camp in campionati) {
      if (camp['categoria'] != null && camp['categoria'].toString().isNotEmpty) {
        catsTrovate.add(camp['categoria'].toString());
      }
    }
    _categorie = ['Tutti 🌍', ...catsTrovate.toList()];
  }

  void _applicaFiltri() {
    setState(() {
      campionatiFiltrati = campionati.where((camp) {
        final nome = camp['nome'].toString().toLowerCase();
        final testo = _searchController.text.toLowerCase();
        final matchTesto = nome.contains(testo);
        final matchPillola = _filtroAttivo == 'Tutti 🌍' || camp['categoria'] == _filtroAttivo;
        return matchTesto && matchPillola;
      }).toList();
    });
  }

  Future<void> _sincronizza(String u, String n) async {
    final domain = serverUrl.replaceAll("https://", "").replaceAll("http://", "");
    final webcalUrl = Uri.parse('webcal://$domain/calendari/genera?url=${Uri.encodeComponent(u)}&nome=${Uri.encodeComponent(n)}');
    if (!await launchUrl(webcalUrl) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Impossibile aprire il calendario")));
    }
  }

  Color _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return const Color(0xFFE53935);
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) hexColor = 'FF$hexColor'; 
    return Color(int.parse(hexColor, radix: 16));
  }

  String _formatDate(double timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
    return DateFormat('d MMM yyyy', 'it_IT').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(title: const Text("Esplora", style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true, elevation: 0),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (t) => _applicaFiltri(),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: "Cerca un campionato...",
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFE53935)),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.black12,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _categorie.map((cat) {
                      final isSelected = _filtroAttivo == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(cat, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          selected: isSelected,
                          selectedColor: const Color(0xFFE53935).withOpacity(0.8),
                          labelStyle: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87)),
                          backgroundColor: isDark ? Colors.black26 : Colors.grey.shade200,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          onSelected: (sel) { if (sel) { HapticFeedback.lightImpact(); setState(() { _filtroAttivo = cat; _applicaFiltri(); }); } },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: inCaricamento 
              ? ListView.builder(itemCount: 8, itemBuilder: (c, i) => const ShimmerCard())
              : campionatiFiltrati.isEmpty 
                  ? const Center(child: Text("Nessun campionato trovato 🏁", style: TextStyle(color: Colors.grey, fontSize: 16)))
                  : RefreshIndicator(
                      color: const Color(0xFFE53935),
                      onRefresh: () async {
                        await _scaricaCatalogo();
                        await _scaricaNews();
                      },
                      child: AnimationLimiter(
                        child: ListView.builder(
                            padding: const EdgeInsets.only(top: 10, bottom: 30, left: 16, right: 16),
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            itemCount: campionatiFiltrati.length,
                            itemBuilder: (context, index) {
                              final camp = campionatiFiltrati[index];
                              final coloreCamp = _parseColor(camp['colore']);
                              final logoFile = camp['logo_file'] ?? "";
                              final categoria = camp['categoria'] ?? "Motorsport";
                              
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 375),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    
                                    // ECCO IL GESTURE DETECTOR PER APRIRE L'ANTEPRIMA!
                                    child: GestureDetector(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ChampionshipDetailScreen(
                                              campionato: camp, 
                                              allNews: _newsList,
                                              serverUrl: serverUrl,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 16),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: coloreCamp.withOpacity(0.3), width: 1.5),
                                          boxShadow: [BoxShadow(color: coloreCamp.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                                          gradient: LinearGradient(
                                            colors: [
                                              isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                              coloreCamp.withOpacity(0.05)
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // LOGO
                                              Container(
                                                width: 70, height: 70,
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                                                child: logoFile.isNotEmpty 
                                                  ? Image.asset('assets/logos/$logoFile', fit: BoxFit.contain, errorBuilder: (c,e,s) => Icon(Icons.sports_score, color: coloreCamp, size: 30))
                                                  : Icon(Icons.sports_motorsports, color: coloreCamp, size: 30),
                                              ),
                                              const SizedBox(width: 16),
                                              
                                              // INFORMAZIONI
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(camp['nome'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                    const SizedBox(height: 6),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(color: coloreCamp.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                                      child: Text(categoria, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: coloreCamp)),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    if (camp['prossima_gara'] != null) ...[
                                                      const Text("PROSSIMA GARA", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                                      Text(camp['prossima_gara']['gara_titolo'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                      Text(_formatDate(camp['prossima_gara']['timestamp']), style: TextStyle(fontSize: 12, color: coloreCamp, fontWeight: FontWeight.bold)),
                                                    ] else ...[
                                                      const Text("Dati in aggiornamento...", style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                                                    ]
                                                  ],
                                                ),
                                              ),
                                              
                                              // AZIONI (Preferiti & Sync)
                                              Column(
                                                children: [
                                                  Consumer<FavoritesProvider>(
                                                    builder: (c, favs, child) {
                                                      final isFav = favs.isFavorite(camp);
                                                      return IconButton(
                                                        icon: Icon(isFav ? Icons.star : Icons.star_border, color: isFav ? Colors.amber : Colors.grey, size: 30),
                                                        onPressed: () { HapticFeedback.selectionClick(); favs.toggleFavorite(camp); },
                                                      );
                                                    },
                                                  ),
                                                  IconButton(
                                                    icon: Icon(Icons.calendar_month, color: coloreCamp.withOpacity(0.7)), 
                                                    onPressed: () => _sincronizza(camp['url_sorgente'], camp['nome'])
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}