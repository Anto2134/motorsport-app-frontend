import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/favorites_provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  Color _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return const Color(0xFFE53935);
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) hexColor = 'FF$hexColor'; 
    return Color(int.parse(hexColor, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FavoritesProvider>();
    final favorites = provider.favoriteItems;
    final isCloud = provider.isCloudSynced;

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: isCloud ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isCloud ? Icons.cloud_done : Icons.phone_android, size: 16, color: isCloud ? Colors.green : Colors.orangeAccent),
              const SizedBox(width: 8),
              Text(isCloud ? "Sincronizzato nel Cloud" : "Salvato solo su questo dispositivo", style: TextStyle(color: isCloud ? Colors.green : Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        if (favorites.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextButton.icon(
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  context.read<FavoritesProvider>().clearFavorites();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lista preferiti svuotata! 🗑️"), duration: Duration(seconds: 2)));
                },
                icon: const Icon(Icons.delete_sweep, color: Color(0xFFE53935)),
                label: const Text("Svuota tutto", style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        Expanded(
          child: favorites.isEmpty
              ? Semantics(
                  label: 'Nessun preferito.',
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star_border, size: 80, color: Colors.white24),
                        const SizedBox(height: 16),
                        const Text("Nessun preferito", style: TextStyle(fontSize: 20, color: Colors.white54, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(isCloud ? "Tocca la stellina nel catalogo\nper salvarli nel tuo account." : "Tocca la stellina nel catalogo.\nAccedi per non perderli mai.", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white38)),
                      ],
                    ),
                  ),
                )
              : Semantics(
                  label: 'Lista dei preferiti',
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 10, bottom: 20),
                    itemCount: favorites.length,
                    itemBuilder: (context, index) {
                      final camp = favorites[index];
                      final nome = camp['nome'] ?? "Sconosciuto";
                      final coloreCamp = _parseColor(camp['colore']);
                      
                      final logoFile = camp['logo_file'] ?? "";

                      Widget logoWidget;
                      if (logoFile.isNotEmpty) {
                        logoWidget = Image.asset(
                          'assets/logos/$logoFile',
                          width: 30, height: 30, fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.star, color: coloreCamp);
                          },
                        );
                      } else {
                        logoWidget = Icon(Icons.star, color: coloreCamp);
                      }

                      return Semantics(
                        label: 'Preferito: $nome',
                        child: Dismissible(
                          key: Key(nome),
                          direction: DismissDirection.endToStart,
                          onDismissed: (direction) { HapticFeedback.mediumImpact(); context.read<FavoritesProvider>().toggleFavorite(camp); },
                          background: Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(15)), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white, size: 30)),
                          child: Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            color: Theme.of(context).cardColor,
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            child: Container(
                              decoration: BoxDecoration(border: Border(left: BorderSide(color: coloreCamp, width: 6))),
                              child: ListTile(
                                leading: Container(width: 50, height: 50, padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Center(child: logoWidget)),
                                title: Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(camp['categoria'] ?? "Motorsport", style: const TextStyle(fontSize: 12)),
                                trailing: const Icon(Icons.swipe_left, color: Colors.grey),
                              ),
                            ),
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