import 'package:flutter/material.dart';
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

  List<dynamic> _getFilteredNews() {
    String nome = widget.campionato['nome'].toString().toLowerCase();
    String keyword = (widget.campionato['keyword'] ?? nome).toString().toLowerCase();

    return widget.allNews.where((news) {
      String title = (news['titolo'] ?? "").toString().toLowerCase();
      if (keyword.contains('formula 1') && (title.contains('formula 1') || title.contains('f1'))) return true;
      if (keyword.contains('wrc') && (title.contains('wrc') || title.contains('rally'))) return true;
      return title.contains(keyword) || title.contains(nome.split(' ')[0]);
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

  @override
  Widget build(BuildContext context) {
    final coloreCamp = _parseColor(widget.campionato['colore']);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredNews = _getFilteredNews();
    final logoFile = widget.campionato['logo_file'] ?? "";
    
    final List<dynamic> listaAttiva = _showPiloti ? _pilotiVisibili : _costruttoriVisibili;
    final List<dynamic> calendario = widget.campionato['calendario_completo'] ?? [];
    final Map<String, dynamic>? ultimaGara = widget.campionato['ultima_gara'];
    final List<dynamic> risultatiUltimaGara = widget.campionato['risultati_ultima_gara'] ?? [];
    
    int currentYear = DateTime.now().year;
    List<String> years = List.generate(currentYear - 2019, (index) => (currentYear - index).toString());

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: coloreCamp,
            iconTheme: const IconThemeData(color: Colors.white), // Fissato al Bianco
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.campionato['nome'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), // Fissato al Bianco
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
                  
                  if (ultimaGara != null) ...[
                    const Text("Ultima Gara Corsa", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
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
                            decoration: BoxDecoration(
                              color: coloreCamp.withOpacity(0.1),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.sports_score, color: coloreCamp),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(ultimaGara['gara_titolo'] ?? "", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      Text(_formatDate(ultimaGara['timestamp']), style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
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
                    const SizedBox(height: 32),
                  ],

                  if (_pilotiVisibili.isNotEmpty || _isLoadingHistory) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Standings", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          decoration: BoxDecoration(color: isDark ? Colors.black38 : Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedYear,
                              icon: const Icon(Icons.history, size: 18),
                              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                              items: years.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null && newValue != _selectedYear) _fetchHistoricalStandings(newValue);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _showPiloti = true),
                              child: Container(decoration: BoxDecoration(color: _showPiloti ? coloreCamp : Colors.transparent, borderRadius: BorderRadius.circular(20)), child: Center(child: Text("Piloti", style: TextStyle(color: _showPiloti ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold)))),
                            ),
                          ),
                          if (_costruttoriVisibili.isNotEmpty || _isLoadingHistory)
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _showPiloti = false),
                                child: Container(decoration: BoxDecoration(color: !_showPiloti ? coloreCamp : Colors.transparent, borderRadius: BorderRadius.circular(20)), child: Center(child: Text("Team", style: TextStyle(color: !_showPiloti ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold)))),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
                      ),
                      child: _isLoadingHistory 
                        ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: listaAttiva.length,
                            separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                            itemBuilder: (context, index) {
                              var item = listaAttiva[index];
                              bool isTop3 = index < 3;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                child: Row(
                                  children: [
                                    SizedBox(width: 30, child: Center(child: Text(item['pos'], style: TextStyle(fontSize: isTop3 ? 18 : 15, fontWeight: isTop3 ? FontWeight.bold : FontWeight.w500, color: isDark ? Colors.white70 : Colors.black87)))),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(item['nome'], style: TextStyle(fontSize: 16, fontWeight: isTop3 ? FontWeight.bold : FontWeight.w500))),
                                    // COLORE BADGE SICURO!
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
                                      decoration: BoxDecoration(
                                        color: isDark ? coloreCamp.withOpacity(0.4) : coloreCamp.withOpacity(0.15), 
                                        borderRadius: BorderRadius.circular(12)
                                      ), 
                                      child: Text("${item['punti']} pt", style: TextStyle(
                                        color: isDark ? Colors.white : coloreCamp, 
                                        fontWeight: FontWeight.bold
                                      ))
                                    )
                                  ],
                                ),
                              );
                            }
                          ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  if (calendario.isNotEmpty) ...[
                    const Text("Calendario Stagione", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: calendario.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                        itemBuilder: (context, index) {
                          var gara = calendario[index];
                          bool isPassata = gara['stato'] == 'conclusa';
                          
                          return ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isPassata ? Colors.grey.withOpacity(0.2) : coloreCamp.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12)
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(DateFormat('d', 'it_IT').format(DateTime.fromMillisecondsSinceEpoch(gara['timestamp'].toInt())), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isPassata ? Colors.grey : coloreCamp)),
                                  Text(DateFormat('MMM', 'it_IT').format(DateTime.fromMillisecondsSinceEpoch(gara['timestamp'].toInt())), style: TextStyle(fontSize: 10, color: isPassata ? Colors.grey : coloreCamp)),
                                ],
                              ),
                            ),
                            title: Text(gara['titolo'], style: TextStyle(fontWeight: isPassata ? FontWeight.normal : FontWeight.bold, color: isPassata ? Colors.grey : (isDark ? Colors.white : Colors.black))),
                            subtitle: gara['luogo'] != "" ? Text(gara['luogo'], style: const TextStyle(fontSize: 12)) : null,
                            trailing: isPassata ? const Icon(Icons.check_circle, color: Colors.green) : const Icon(Icons.flag_outlined, color: Colors.grey),
                          );
                        }
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                  
                  const Text("Ultime Notizie", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  if (filteredNews.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text("Nessuna notizia recente.", style: TextStyle(color: Colors.grey))))
                  else
                    ...filteredNews.map((news) {
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