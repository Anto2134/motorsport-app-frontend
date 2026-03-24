import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
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
  
  String _filtroAttivo = 'Tutti 🌍';
  final List<String> _categorie = ['Tutti 🌍', 'Formula 🏎️', 'Moto 🏍️', 'Endurance ⏱️', 'Rally 🌲'];
  List<String> _cronologiaRicerche = [];

  @override
  void initState() {
    super.initState();
    _inizializzaApp();
  }

  Future<void> _inizializzaApp() async {
    await _caricaCronologia();
    await _caricaDatiLocali();
    _scaricaCatalogo();
  }

  Future<void> _caricaCronologia() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() { _cronologiaRicerche = prefs.getStringList('cronologia_ricerche') ?? []; });
  }

  Future<void> _salvaRicerca(String termine) async {
    if (termine.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    _cronologiaRicerche.remove(termine);
    _cronologiaRicerche.insert(0, termine);
    if (_cronologiaRicerche.length > 5) _cronologiaRicerche.removeLast();
    await prefs.setStringList('cronologia_ricerche', _cronologiaRicerche);
    setState(() {});
  }

  Future<void> _caricaDatiLocali() async {
    final prefs = await SharedPreferences.getInstance();
    final dati = prefs.getString('catalogo_cache');
    if (dati != null && mounted) { setState(() { campionati = json.decode(dati); _applicaFiltri(); inCaricamento = false; }); }
  }

  Future<void> _scaricaCatalogo() async {
    if (campionati.isEmpty) setState(() { inCaricamento = true; haErrore = false; });
    try {
      final res = await http.get(Uri.parse('https://$baseUrl/api/campionati'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('catalogo_cache', json.encode(data['campionati']));
        if (mounted) setState(() { campionati = data['campionati']; _applicaFiltri(); inCaricamento = false; haErrore = false; });
      } else if (campionati.isEmpty) _mostraErrore("Server ai box.");
    } catch (e) { if (campionati.isEmpty) _mostraErrore("Sei offline?"); }
  }

  void _mostraErrore(String msg) { if (mounted) setState(() { haErrore = true; messaggioErrore = msg; inCaricamento = false; }); }

  void _applicaFiltri() {
    setState(() {
      campionatiFiltrati = campionati.where((camp) {
        final nome = camp['nome'].toString().toLowerCase();
        final testo = _searchController.text.toLowerCase();
        final matchTesto = nome.contains(testo);
        bool matchPillola = true;
        if (_filtroAttivo == 'Formula 🏎️') matchPillola = nome.contains('formula') || nome.contains('f1') || nome.contains('indy');
        else if (_filtroAttivo == 'Moto 🏍️') matchPillola = nome.contains('moto') || nome.contains('superbike');
        else if (_filtroAttivo == 'Endurance ⏱️') matchPillola = nome.contains('wec') || nome.contains('imsa') || nome.contains('gt');
        else if (_filtroAttivo == 'Rally 🌲') matchPillola = nome.contains('rally') || nome.contains('wrc');
        return matchTesto && matchPillola;
      }).toList();
    });
  }

  Future<void> _sincronizza(String u, String n) async {
    final webcalUrl = Uri.parse('webcal://$baseUrl/calendari/genera?url=${Uri.encodeComponent(u)}&nome=${Uri.encodeComponent(n)}');
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 8.0),
          decoration: BoxDecoration(color: Theme.of(context).appBarTheme.backgroundColor, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20))),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (t) => _applicaFiltri(),
                onSubmitted: (t) { _salvaRicerca(t); },
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: "Cerca un campionato...",
                  hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFE53935)),
                  suffixIcon: _searchController.text.isNotEmpty 
                    ? IconButton(icon: Icon(Icons.clear, color: isDark ? Colors.white54 : Colors.black54), onPressed: () { HapticFeedback.selectionClick(); _searchController.clear(); _applicaFiltri(); })
                    : null,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
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
                        label: Text(cat, style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        selected: isSelected,
                        selectedColor: const Color(0xFFE53935),
                        backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onSelected: (sel) { if (sel) { HapticFeedback.lightImpact(); setState(() { _filtroAttivo = cat; _applicaFiltri(); }); } },
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (_searchController.text.isEmpty && _cronologiaRicerche.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Icon(Icons.history, size: 16, color: isDark ? Colors.white54 : Colors.black54),
                        const SizedBox(width: 8),
                        ..._cronologiaRicerche.map((ricerca) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: InkWell(
                            onTap: () { _searchController.text = ricerca; _applicaFiltri(); _salvaRicerca(ricerca); },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(border: Border.all(color: isDark ? Colors.white24 : Colors.black12), borderRadius: BorderRadius.circular(15)),
                              child: Text(ricerca, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                )
            ],
          ),
        ),
        
        Expanded(
          child: inCaricamento 
            ? ListView.builder(itemCount: 8, itemBuilder: (c, i) => const ShimmerCard())
            : haErrore 
              ? Center(child: Text(messaggioErrore))
              : campionatiFiltrati.isEmpty 
                ? const Center(child: Text("Nessun risultato"))
                : RefreshIndicator(
                    color: const Color(0xFFE53935),
                    onRefresh: _scaricaCatalogo,
                    child: AnimationLimiter(
                      child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 10, bottom: 20),
                          itemCount: campionatiFiltrati.length,
                          itemBuilder: (context, index) {
                            
                            final camp = campionatiFiltrati[index];
                            final nome = camp['nome'] ?? "Sconosciuto";
                            final coloreCamp = _parseColor(camp['colore']);
                            
                            // ORA CERCHIAMO IL NOME DEL FILE LOCALE!
                            final logoFile = camp['logo_file'] ?? "";
                            
                            Widget logoWidget;
                            if (logoFile.isNotEmpty) {
                              // LEGGE DALLA TUA CARTELLA LOCALE!
                              logoWidget = Image.asset(
                                'assets/logos/$logoFile',
                                width: 30, height: 30, fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.sports_score, color: coloreCamp);
                                },
                              );
                            } else {
                              logoWidget = Icon(Icons.sports_score, color: coloreCamp);
                            }
                            
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 375),
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    color: Theme.of(context).cardColor,
                                    clipBehavior: Clip.antiAlias,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    child: Container(
                                      decoration: BoxDecoration(border: Border(left: BorderSide(color: coloreCamp, width: 6))),
                                      child: ListTile(
                                        leading: Container(
                                          width: 50, height: 50,
                                          padding: const EdgeInsets.all(8),
                                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                          child: Center(child: logoWidget),
                                        ),
                                        title: Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text(camp['categoria'] ?? "Motorsport", style: const TextStyle(fontSize: 12)),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Consumer<FavoritesProvider>(
                                              builder: (c, favs, child) {
                                                final isFav = favs.isFavorite(camp);
                                                return IconButton(
                                                  icon: Icon(isFav ? Icons.star : Icons.star_border, color: isFav ? Colors.amber : Colors.grey),
                                                  onPressed: () { HapticFeedback.selectionClick(); favs.toggleFavorite(camp); },
                                                );
                                              },
                                            ),
                                            IconButton(icon: Icon(Icons.add_circle_outline, color: coloreCamp), onPressed: () { HapticFeedback.heavyImpact(); _sincronizza(camp['url_sorgente'], nome); }),
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
    );
  }
}