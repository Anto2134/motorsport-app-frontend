import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/favorites_provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>().favoriteItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestisci Preferiti", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: favorites.isEmpty
          ? const Center(
              child: Text("Non hai ancora salvato nessun campionato.", style: TextStyle(color: Colors.grey, fontSize: 16)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final camp = favorites[index];
                final logoFile = camp['logo_file'] ?? "";
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    leading: Container(
                      width: 40, height: 40,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: logoFile.isNotEmpty 
                          ? Image.asset('assets/logos/$logoFile', fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.flag, color: Colors.black))
                          : const Icon(Icons.sports_score, color: Colors.black),
                    ),
                    title: Text(camp['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(camp['categoria'] ?? "Motorsport"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: "Rimuovi dai preferiti",
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        context.read<FavoritesProvider>().toggleFavorite(camp);
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}