import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class ChampionshipDetailScreen extends StatefulWidget {
  final Map<String, dynamic> campionato;
  final List<dynamic> allNews;
  final String serverUrl;

  const ChampionshipDetailScreen({
    super.key,
    required this.campionato,
    required this.allNews,
    required this.serverUrl,
  });

  @override
  State<ChampionshipDetailScreen> createState() => _ChampionshipDetailScreenState();
}

class _ChampionshipDetailScreenState extends State<ChampionshipDetailScreen> {
  bool _showPiloti = true;
  String _selectedYear = DateTime.now().year.toString();
  bool _isLoadingHistory = false;
  
  bool _isRaceResultsExpanded = false;
  bool _isStandingsExpanded = false; 
  bool _isCalendarExpanded = false; 
  
  List<dynamic> _pilotiVisibili = [];
  List<dynamic> _costruttoriVisibili = [];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('it_IT', null);
    final classifiche = widget.campionato['classifiche'] ?? {};
    _pilotiVisibili = classifiche['piloti'] ?? [];
    _costruttoriVisibili = classifiche['costruttori'] ?? [];
  }

  Color _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return const Color(0xFFE53935);
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) hexColor = 'FF$hexColor';
    return Color(int.parse(hexColor, radix: 16));
  }

  Color _getTextColorForBackground(Color background) {
    return background.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
  }

  // ==========================================
  // FILTRO NOTIZIE CORRETTO (BYE BYE BUG "FE")
  // ==========================================
  List<dynamic> _getFilteredNews() {
    String nomeCamp = widget.campionato['nome'].toString().toLowerCase();
    String keyword = (widget.campionato['keyword'] ?? nomeCamp).toString().toLowerCase();

    return widget.allNews.where((news) {
      String title = (news['titolo'] ?? "").toString().toLowerCase();
      String source = (news['fonte'] ?? "").toString().toLowerCase();

      if (keyword == 'formula e' || nomeCamp.contains('formula e')) return title.contains('formula e') || title.contains('formula-e') || title.contains('abb fia');
      if (keyword == 'formula 2' || nomeCamp.contains('formula 2')) return title.contains('formula 2') || title.contains('f2');
      if (keyword == 'formula 3' || nomeCamp.contains('formula 3')) return title.contains('formula 3') || title.contains('f3');
      if (keyword == 'formula 1' || nomeCamp.contains('formula 1')) return title.contains('formula 1') || title.contains('f1');

      if (keyword.contains('wec')) return title.contains('wec') || title.contains('endurance');
      if (keyword.contains('wrc')) return title.contains('wrc') || title.contains('rally');
      if (keyword.contains('motogp')) return title.contains('motogp');
      if (keyword.contains('superbike')) return title.contains('wsbk') || title.contains('superbike');
      if (keyword.contains('indycar')) return title.contains('indycar');
      if (keyword.contains('nascar')) return title.contains('nascar');
      if (keyword.contains('imsa')) return title.contains('imsa');
      if (keyword.contains('dtm')) return title.contains('dtm');
      
      return title.contains(keyword) || source.contains(keyword); 
    }).toList();
  }

  Future<void> _fetchHistoricalStandings(String year) async {
    setState(() { _selectedYear = year; _isLoadingHistory = true; });
    try {
      final url = Uri.parse("${widget.serverUrl}/api/storico?campionato=${Uri.encodeComponent(widget.campionato['nome'])}&anno=$year");
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() { _pilotiVisibili = data['piloti'] ?? []; _costruttoriVisibili = data['costruttori'] ?? []; });
      }
    } catch (e) {
      debugPrint("Errore storico: $e");
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Widget _buildMedal(String pos, Color themeColor, bool isDark) {
    if (pos == "1") return const CircleAvatar(backgroundColor: Color(0xFFFFD700), radius: 14, child: Text("1", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)));
    if (pos == "2") return const CircleAvatar(backgroundColor: Color(0xFFC0C0C0), radius: 14, child: Text("2", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)));
    if (pos == "3") return const CircleAvatar(backgroundColor: Color(0xFFCD7F32), radius: 14, child: Text("3", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)));
    if (pos == "Rit" || pos == "DNF") return SizedBox(width: 28, height: 28, child: Center(child: Text("❌", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.redAccent : Colors.red))));
    return SizedBox(width: 28, height: 28, child: Center(child: Text(pos, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54))));
  }

  String _formatDate(double timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
    return DateFormat('d MMMM yyyy', 'it_IT').format(date);
  }

  String _formatWeekend(dynamic tInizio, dynamic tFine) {
    if (tInizio == null || tFine == null) return "-";
    DateTime dInizio = DateTime.fromMillisecondsSinceEpoch(tInizio.toInt());
    DateTime dFine = DateTime.fromMillisecondsSinceEpoch(tFine.toInt());

    if (dInizio.month == dFine.month && dInizio.day == dFine.day) {
      return DateFormat('d\nMMM', 'it_IT').format(dInizio);
    }
    if (dInizio.month == dFine.month) {
      return "${dInizio.day}-${dFine.day}\n${DateFormat('MMM', 'it_IT').format(dFine)}";
    } else {
      return "${dInizio.day} ${DateFormat('MMM', 'it_IT').format(dInizio)}\n${dFine.day} ${DateFormat('MMM', 'it_IT').format(dFine)}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final coloreCamp = _parseColor(widget.campionato['colore']);
    final coloreTestoDinamico = _getTextColorForBackground(coloreCamp); 
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoFile = widget.campionato['logo_file'] ?? "";
    
    final List<dynamic> listaAttiva = _showPiloti ? _pilotiVisibili : _costruttoriVisibili;
    final List<dynamic> calendario = widget.campionato['calendario_completo'] ?? [];
    final Map<String, dynamic>? ultimaGara = widget.campionato['ultima_gara'];
    final List<dynamic> risultatiUltimaGara = widget.campionato['risultati_ultima_gara'] ?? [];
    
    final String titoloSessione = widget.campionato['titolo_ultima_sessione'] ?? "";
    final String titoloMostrato = titoloSessione.isNotEmpty ? "Risultati: $titoloSessione" : "Ultimi Risultati in Pista";

    int currentYear = DateTime.now().year;
    List<String> years = List.generate(currentYear - 2019, (index) => (currentYear - index).toString());

    // ==========================================
    // LOGICA DI FALLBACK PER I CAMPIONATI MINORI
    // ==========================================
    List<dynamic> displayNews = _getFilteredNews();
    String newsSectionTitle = "Ultime Notizie";
    
    if (displayNews.isEmpty) {
      // Se è un campionato minore e non ha news specifiche, prendi le prime 5 dal pool globale!
      displayNews = widget.allNews.take(5).toList();
      newsSectionTitle = "Dal mondo Motorsport"; // Cambiamo il titolo per far capire all'utente
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: coloreCamp,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.campionato['nome'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [coloreCamp, isDark ? Colors.black : Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
                  if (logoFile.isNotEmpty) Center(child: Opacity(opacity: 0.15, child: Image.asset('assets/logos/$logoFile', width: 180, fit: BoxFit.contain, color: Colors.white))),
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  if (ultimaGara != null || risultatiUltimaGara.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: coloreCamp.withOpacity(0.3)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: coloreCamp.withOpacity(0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                            child: Row(
                              children: [
                                Icon(Icons.timer, color: coloreCamp),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(titoloMostrato, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      if (ultimaGara != null) Text(_formatDate(ultimaGara['timestamp']), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (risultatiUltimaGara.isNotEmpty) ...[
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _isRaceResultsExpanded ? risultatiUltimaGara.length : (risultatiUltimaGara.length > 5 ? 5 : risultatiUltimaGara.length),
                              separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                              itemBuilder: (context, index) {
                                var pilota = risultatiUltimaGara[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                  child: Row(
                                    children: [
                                      _buildMedal(pilota['pos'], coloreCamp, isDark),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text(pilota['nome'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                                      Text(pilota['info'], style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                    ],
                                  ),
                                );
                              }
                            ),
                            if (risultatiUltimaGara.length > 5)
                              InkWell(
                                onTap: () => setState(() => _isRaceResultsExpanded = !_isRaceResultsExpanded),
                                child: Container(
                                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12)), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))),
                                  child: Center(child: Text(_isRaceResultsExpanded ? "Comprimi classifica" : "Espandi classifica completa", style: TextStyle(color: coloreCamp, fontWeight: FontWeight.bold))),
                                ),
                              )
                          ] else ...[
                            const Padding(padding: EdgeInsets.all(16.0), child: Text("Risultati in fase di elaborazione...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)))
                          ]
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (_pilotiVisibili.isNotEmpty || _isLoadingHistory) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: coloreCamp.withOpacity(0.3)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: coloreCamp.withOpacity(0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.emoji_events, color: coloreCamp),
                                    const SizedBox(width: 8),
                                    const Text("Classifiche", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                  decoration: BoxDecoration(color: isDark ? Colors.black38 : Colors.white, borderRadius: BorderRadius.circular(20)),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedYear,
                                      icon: const Icon(Icons.history, size: 16),
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black),
                                      items: years.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null && newValue != _selectedYear) _fetchHistoricalStandings(newValue);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() { _showPiloti = true; _isStandingsExpanded = false; }),
                                      child: Container(decoration: BoxDecoration(color: _showPiloti ? coloreCamp : Colors.transparent, borderRadius: BorderRadius.circular(20)), child: Center(child: Text("Piloti", style: TextStyle(color: _showPiloti ? coloreTestoDinamico : Colors.grey.shade600, fontWeight: FontWeight.bold)))),
                                    ),
                                  ),
                                  if (_costruttoriVisibili.isNotEmpty || _isLoadingHistory)
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(() { _showPiloti = false; _isStandingsExpanded = false; }),
                                        child: Container(decoration: BoxDecoration(color: !_showPiloti ? coloreCamp : Colors.transparent, borderRadius: BorderRadius.circular(20)), child: Center(child: Text("Team", style: TextStyle(color: !_showPiloti ? coloreTestoDinamico : Colors.grey.shade600, fontWeight: FontWeight.bold)))),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          _isLoadingHistory 
                            ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
                            : Column(
                                children: [
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _isStandingsExpanded ? listaAttiva.length : (listaAttiva.length > 5 ? 5 : listaAttiva.length),
                                    separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                                    itemBuilder: (context, index) {
                                      var item = listaAttiva[index];
                                      bool isTop3 = index < 3;
                                      
                                      Color pillColor = isDark ? coloreCamp.withOpacity(0.2) : coloreCamp.withOpacity(0.1);
                                      Color textPillColor = coloreCamp;
                                      if (coloreCamp.computeLuminance() > 0.5 && !isDark) { pillColor = coloreCamp; textPillColor = Colors.black87; }

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                        child: Row(
                                          children: [
                                            SizedBox(width: 30, child: Center(child: Text(item['pos'], style: TextStyle(fontSize: isTop3 ? 18 : 15, fontWeight: isTop3 ? FontWeight.bold : FontWeight.w500, color: isDark ? Colors.white70 : Colors.black87)))),
                                            const SizedBox(width: 12),
                                            Expanded(child: Text(item['nome'], style: TextStyle(fontSize: 16, fontWeight: isTop3 ? FontWeight.bold : FontWeight.w500))),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
                                              decoration: BoxDecoration(color: pillColor, borderRadius: BorderRadius.circular(12)), 
                                              child: Text("${item['punti']} pt", style: TextStyle(color: textPillColor, fontWeight: FontWeight.bold, fontSize: 13))
                                            )
                                          ],
                                        ),
                                      );
                                    }
                                  ),
                                  if (listaAttiva.length > 5)
                                    InkWell(
                                      onTap: () => setState(() => _isStandingsExpanded = !_isStandingsExpanded),
                                      child: Container(
                                        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12)), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))),
                                        child: Center(child: Text(_isStandingsExpanded ? "Mostra solo i Top 5" : "Espandi classifica completa", style: TextStyle(color: coloreCamp, fontWeight: FontWeight.bold))),
                                      ),
                                    )
                                ],
                              )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (calendario.isNotEmpty) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: coloreCamp.withOpacity(0.3)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () => setState(() => _isCalendarExpanded = !_isCalendarExpanded),
                            borderRadius: _isCalendarExpanded ? const BorderRadius.vertical(top: Radius.circular(16)) : BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(color: coloreCamp.withOpacity(0.1), borderRadius: _isCalendarExpanded ? const BorderRadius.vertical(top: Radius.circular(16)) : BorderRadius.circular(16)),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_month, color: coloreCamp),
                                  const SizedBox(width: 12),
                                  const Expanded(child: Text("Calendario Stagione", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                                  Text("${calendario.length} Eventi", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Icon(_isCalendarExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                          if (_isCalendarExpanded) ...[
                            Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: calendario.length,
                              separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                              itemBuilder: (context, index) {
                                var gara = calendario[index];
                                bool isPassata = gara['stato'] == 'conclusa';
                                String rangeDate = _formatWeekend(gara['timestamp_inizio'] ?? gara['timestamp'], gara['timestamp_fine'] ?? gara['timestamp']);
                                
                                return ListTile(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Macchina del Tempo in arrivo per: ${gara['titolo']}!"), duration: const Duration(seconds: 2)),
                                    );
                                  },
                                  leading: Container(
                                    width: 65, height: 50,
                                    decoration: BoxDecoration(color: isPassata ? Colors.grey.withOpacity(0.2) : coloreCamp.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                    child: Center(child: Text(rangeDate, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isPassata ? Colors.grey : coloreCamp))),
                                  ),
                                  title: Text(gara['titolo'], style: TextStyle(fontWeight: isPassata ? FontWeight.normal : FontWeight.bold, color: isPassata ? Colors.grey : (isDark ? Colors.white : Colors.black))),
                                  subtitle: gara['luogo'] != "" ? Text(gara['luogo'], style: const TextStyle(fontSize: 12)) : null,
                                  trailing: isPassata ? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey) : const Icon(Icons.flag_outlined, color: Colors.grey),
                                );
                              }
                            ),
                          ]
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                  
                  // IL NUOVO TITOLO DINAMICO!
                  Text(newsSectionTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  ...displayNews.map((news) {
                    final String rawImgUrl = news['immagine'] ?? "";
                    final String proxyImgUrl = rawImgUrl.isNotEmpty ? "${widget.serverUrl}/api/image?url=${Uri.encodeComponent(rawImgUrl)}" : "";
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () async {
                          if (news['link'] != "") {
                            final url = Uri.parse(news['link']);
                            if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.inAppBrowserView);
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (proxyImgUrl.isNotEmpty)
                              Image.network(proxyImgUrl, height: 180, width: double.infinity, fit: BoxFit.cover,
                                errorBuilder: (c,e,s) => Container(height: 180, color: Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey))
                              ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(news['titolo'] ?? "", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(news['fonte'] ?? "", style: TextStyle(fontSize: 12, color: coloreCamp, fontWeight: FontWeight.bold)),
                                      Text(news['data'] ?? "", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}