import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:async';
import '../services/favorites_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final String baseUrl = "motorsport-hub1-0-1.onrender.com";
  Map<String, dynamic> _liveData = {};
  bool _isLoading = true;
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchLiveTimestamps();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() { _now = DateTime.now(); });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLiveTimestamps() async {
    try {
      final res = await http.get(Uri.parse('https://$baseUrl/api/campionati'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        Map<String, dynamic> mappedData = {};
        for (var camp in data['campionati']) { mappedData[camp['nome']] = camp; }
        if (mounted) setState(() { _liveData = mappedData; _isLoading = false; });
      } else {
        if (mounted) setState(() { _isLoading = false; });
      }
    } catch (e) { 
      if (mounted) setState(() { _isLoading = false; }); 
    }
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
    final webcalUrl = Uri.parse('webcal://$baseUrl/calendari/genera?url=${Uri.encodeComponent(u)}&nome=${Uri.encodeComponent(n)}');
    if (!await launchUrl(webcalUrl) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Impossibile aprire il calendario")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>().favoriteItems;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("La tua Plancia 🏁", style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true, elevation: 0),
      body: RefreshIndicator(
        color: const Color(0xFFE53935),
        onRefresh: _fetchLiveTimestamps,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (favorites.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text("Vai su Esplora e aggiungi campionati ai preferiti per vederli qui!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))),
                )
              else ...[
                const Padding(padding: EdgeInsets.only(left: 16, top: 16, bottom: 8), child: Text("I tuoi Campionati", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                SizedBox(
                  height: 250, 
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
                      
                      // LOGICA DI CONTROLLO HONESTA
                      String titoloGara = "Sorgente dati irraggiungibile ⚠️";
                      if (_isLoading) {
                        titoloGara = "Ricerca dati in corso...";
                      } else if (garaData != null) {
                        titoloGara = garaData['gara_titolo'] ?? "";
                        targetDate = DateTime.fromMillisecondsSinceEpoch(garaData['timestamp'].toInt());
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
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 6,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [Theme.of(context).cardColor, coloreCamp.withOpacity(0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
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
                                    Container(width: 50, height: 35, padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)), child: logoFile.isNotEmpty ? Image.asset('assets/logos/$logoFile', fit: BoxFit.contain, errorBuilder: (c,e,s) => Icon(Icons.flag, color: coloreCamp)) : Icon(Icons.flag, color: coloreCamp)),
                                    IconButton(
                                      icon: Icon(Icons.calendar_month, color: coloreCamp),
                                      onPressed: () { HapticFeedback.heavyImpact(); _sincronizza(liveCamp['url_sorgente'], campName); },
                                    )
                                  ],
                                ),
                                const Spacer(),
                                Text(campName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text(titoloGara, style: TextStyle(fontSize: 13, color: targetDate == null && !_isLoading ? Colors.redAccent : Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 12),
                                if (targetDate != null)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(color: isDark ? Colors.black26 : Colors.black12, borderRadius: BorderRadius.circular(10)),
                                    child: Text(_formatCountdown(targetDate), textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: coloreCamp)),
                                  )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              
              const Padding(padding: EdgeInsets.only(left: 16, top: 32, bottom: 16), child: Text("Ultime dal Paddock 📰", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.article)),
                    title: const Text("Notizia in arrivo"),
                    subtitle: const Text("Presto collegheremo le news..."),
                    trailing: const Icon(Icons.chevron_right),
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