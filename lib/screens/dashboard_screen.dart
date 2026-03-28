import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../services/favorites_provider.dart';
import 'championship_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ===============================================
  // CONFIGURAZIONE AMBIENTE
  // ===============================================
  //final String serverUrl = "http://127.0.0.1:5000"; // TEST LOCALE
   final String serverUrl = "https://motorsport-hub1-0-1.onrender.com"; // PRODUZIONE

  Map<String, dynamic> _liveData = {};
  List<dynamic> _newsList = [];
  bool _isLoading = true;
  bool _isLoadingNews = true;
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('it_IT', null);
    _fetchLiveTimestamps();
    _fetchNews();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLiveTimestamps() async {
    try {
      final res = await http.get(Uri.parse('$serverUrl/api/campionati'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        Map<String, dynamic> mappedData = {};
        for (var camp in data['campionati']) {
          mappedData[camp['nome']] = camp;
        }
        if (mounted) {
          setState(() {
            _liveData = mappedData;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() { _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _fetchNews() async {
    if (mounted) setState(() => _isLoadingNews = true);
    try {
      final res = await http.get(Uri.parse('$serverUrl/api/news'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (mounted) {
          setState(() {
            _newsList = data['news'];
            _isLoadingNews = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingNews = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingNews = false);
    }
  }

  Future<void> _refreshAll() async {
    await _fetchLiveTimestamps();
    await _fetchNews();
  }

  Color _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return const Color(0xFFE53935);
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) hexColor = 'FF$hexColor';
    return Color(int.parse(hexColor, radix: 16));
  }

  String _formatCountdown(DateTime target) {
    Duration diff = target.difference(_now);
    if (diff.isNegative) return "🔴 In Corso / Conclusa";
    int days = diff.inDays;
    int hours = diff.inHours % 24;
    int minutes = diff.inMinutes % 60;
    int seconds = diff.inSeconds % 60;
    if (days > 0) return "${days}g ${hours}h ${minutes}m ${seconds}s";
    return "${hours}h ${minutes}m ${seconds}s";
  }

  Future<void> _sincronizza(String u, String n) async {
    final domain = serverUrl.replaceAll("https://", "").replaceAll("http://", "");
    final webcalUrl = Uri.parse('webcal://$domain/calendari/genera?url=${Uri.encodeComponent(u)}&nome=${Uri.encodeComponent(n)}');
    if (!await launchUrl(webcalUrl) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Impossibile aprire il calendario")));
    }
  }

  // ==========================================
  // FILTRO NOTIZIE (Solo dai tuoi preferiti!)
  // ==========================================
  List<dynamic> _getPersonalizedNews(List<dynamic> favs) {
    if (favs.isEmpty) return _newsList.take(10).toList();

    return _newsList.where((news) {
      String title = (news['titolo'] ?? "").toString().toLowerCase();
      String source = (news['fonte'] ?? "").toString().toLowerCase();
      
      for (var camp in favs) {
        String keyword = (camp['keyword'] ?? camp['nome']).toString().toLowerCase();
        if (title.contains(keyword) || source.contains(keyword)) return true;
        if (keyword.contains('formula 1') && title.contains('f1')) return true;
        if (keyword.contains('wrc') && title.contains('rally')) return true;
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rawFavorites = context.watch<FavoritesProvider>().favoriteItems;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Ordina i preferiti per data della prossima gara (la più vicina prima)
    List<dynamic> favorites = List.from(rawFavorites);
    favorites.sort((a, b) {
      final liveA = _liveData[a['nome']] ?? a;
      final liveB = _liveData[b['nome']] ?? b;
      final timeA = liveA['prossima_gara'] != null ? liveA['prossima_gara']['timestamp'] : double.infinity;
      final timeB = liveB['prossima_gara'] != null ? liveB['prossima_gara']['timestamp'] : double.infinity;
      return timeA.compareTo(timeB);
    });

    final personalizedNews = _getPersonalizedNews(favorites);

    return Scaffold(
      appBar: AppBar(
        title: const Text("La tua Plancia 🏁", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: const Color(0xFFE53935),
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (favorites.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      "Vai su Esplora e aggiungi campionati ai preferiti per vederli qui!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else ...[
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                  child: Text("I tuoi Campionati", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  height: 290, 
                  child: PageView.builder(
                    controller: PageController(viewportFraction: 0.9),
                    physics: const BouncingScrollPhysics(),
                    itemCount: favorites.length,
                    itemBuilder: (context, index) {
                      final campName = favorites[index]['nome'];
                      final liveCamp = _liveData[campName] ?? favorites[index];
                      final coloreCamp = _parseColor(liveCamp['colore']);
                      final logoFile = liveCamp['logo_file'] ?? "";

                      final garaData = liveCamp['prossima_gara'];
                      DateTime? targetDate;
                      String titoloGara = "Ricerca dati in corso...";
                      List<dynamic>? meteoWeekend;

                      if (!_isLoading && garaData == null) {
                        titoloGara = "Sorgente dati irraggiungibile ⚠️";
                      } else if (garaData != null) {
                        titoloGara = garaData['gara_titolo'] ?? "";
                        targetDate = DateTime.fromMillisecondsSinceEpoch(garaData['timestamp'].toInt());
                        meteoWeekend = garaData['meteo_weekend'];
                      }

                      return Dismissible(
                        key: Key(campName),
                        direction: DismissDirection.up,
                        onDismissed: (direction) {
                          HapticFeedback.mediumImpact();
                          context.read<FavoritesProvider>().toggleFavorite(liveCamp);
                        },
                        background: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
                          alignment: Alignment.bottomCenter,
                          padding: const EdgeInsets.only(bottom: 20),
                          child: const Icon(Icons.delete, color: Colors.white, size: 30),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChampionshipDetailScreen(
                                  campionato: liveCamp,
                                  allNews: _newsList,
                                  serverUrl: serverUrl,
                                ),
                              ),
                            );
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 6,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Theme.of(context).cardColor, coloreCamp.withOpacity(0.05)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border(top: BorderSide(color: coloreCamp, width: 4)),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        width: 50, height: 35,
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                                        child: logoFile.isNotEmpty
                                            ? Image.asset('assets/logos/$logoFile', fit: BoxFit.contain, errorBuilder: (c, e, s) => Icon(Icons.flag, color: coloreCamp))
                                            : Icon(Icons.flag, color: coloreCamp),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.calendar_month, color: coloreCamp),
                                        onPressed: () {
                                          HapticFeedback.heavyImpact();
                                          _sincronizza(liveCamp['url_sorgente'], campName);
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(campName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text(titoloGara, style: TextStyle(fontSize: 13, color: targetDate == null && !_isLoading ? Colors.redAccent : Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 12),
                                  
                                  if (targetDate != null)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(color: isDark ? Colors.black26 : Colors.black12, borderRadius: BorderRadius.circular(10)),
                                      child: Text(
                                        _formatCountdown(targetDate),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 20, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: coloreCamp),
                                      ),
                                    ),

                                  const Spacer(),

                                  if (meteoWeekend != null && meteoWeekend.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.black38 : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: meteoWeekend.map((giorno) {
                                          return Column(
                                            children: [
                                              Text(giorno['giorno'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                              const SizedBox(height: 4),
                                              Text(giorno['icona'], style: const TextStyle(fontSize: 18)),
                                              const SizedBox(height: 4),
                                              Text("${giorno['max']}° / ${giorno['min']}°", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              const Padding(
                padding: EdgeInsets.only(left: 16, top: 32, bottom: 16),
                child: Text("Esplora il Paddock 📸", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),

              if (_isLoadingNews)
                const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
              else if (personalizedNews.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Nessuna notizia rilevante trovata in questo momento.", style: TextStyle(color: Colors.grey)),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: personalizedNews.length,
                  itemBuilder: (context, index) {
                    final news = personalizedNews[index];
                    final String rawImgUrl = news['immagine'] ?? "";
                    final String fonte = news['fonte'] ?? "Motorsport Hub";

                    final String proxyImgUrl = rawImgUrl.isNotEmpty
                        ? "$serverUrl/api/image?url=${Uri.encodeComponent(rawImgUrl)}"
                        : "";

                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFFE53935).withOpacity(0.1),
                                  child: const Icon(Icons.sports_motorsports, color: Color(0xFFE53935), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Text(fonte, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                const Spacer(),
                                const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                              ],
                            ),
                          ),

                          GestureDetector(
                            onTap: () async {
                              if (news['link'] == "") return;
                              HapticFeedback.selectionClick();
                              final url = Uri.parse(news['link']);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.inAppBrowserView);
                              }
                            },
                            child: proxyImgUrl.isNotEmpty
                                ? Image.network(
                                    proxyImgUrl,
                                    width: double.infinity,
                                    height: 250,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 250,
                                        color: isDark ? Colors.black12 : Colors.grey.withOpacity(0.1),
                                        child: const Center(child: CircularProgressIndicator(color: Colors.red)),
                                      );
                                    },
                                    errorBuilder: (c, e, s) {
                                      return Container(
                                        height: 250, width: double.infinity,
                                        color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
                                        child: const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                                            SizedBox(height: 8),
                                            Text("Immagine non disponibile", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                          ],
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    height: 250, width: double.infinity,
                                    color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
                                    child: const Center(child: Icon(Icons.article, size: 60, color: Colors.grey)),
                                  ),
                          ),

                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Icon(Icons.favorite_border, size: 28),
                                SizedBox(width: 16),
                                Icon(Icons.mode_comment_outlined, size: 28),
                                SizedBox(width: 16),
                                Icon(Icons.send_outlined, size: 28),
                                Spacer(),
                                Icon(Icons.bookmark_border, size: 28),
                              ],
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: RichText(
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15, height: 1.3),
                                children: [
                                  TextSpan(text: "$fonte ", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: news['titolo'] ?? ""),
                                ],
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 6, bottom: 8),
                            child: Text(news['data'] ?? "", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}