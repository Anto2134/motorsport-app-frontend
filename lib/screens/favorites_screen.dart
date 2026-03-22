import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/favorites_provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Chiediamo al Provider la lista dei preferiti aggiornata!
    final favorites = context.watch<FavoritesProvider>().favoriteItems;

    // Rimosso lo Scaffold per evitare il problema delle "Doppie AppBar"
    return Column(
      children: [
        // Mostriamo il tasto "Svuota tutto" solo se ci sono campionati
        if (favorites.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextButton.icon(
                onPressed: () {
                  // Svuotiamo la lista tramite il Provider!
                  context.read<FavoritesProvider>().clearFavorites();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Lista preferiti svuotata! 🗑️"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.delete_sweep, color: Color(0xFFE53935)),
                label: const Text(
                  "Svuota tutto",
                  style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

        // Corpo della pagina (Lista o Messaggio Vuoto)
        Expanded(
          child: favorites.isEmpty
              ? Semantics(
                  label: 'Nessun preferito.',
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_border, size: 80, color: Colors.white24),
                        SizedBox(height: 16),
                        Text(
                          "Nessun preferito",
                          style: TextStyle(fontSize: 20, color: Colors.white54, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Vai nel catalogo e tocca la stellina\nper salvare qui i tuoi campionati.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38),
                        ),
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
                      return Semantics(
                        label: 'Preferito: ${camp['nome']}',
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          color: const Color(0xFF1E1E1E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: ListTile(
                            leading: const Icon(Icons.star, color: Colors.amber),
                            title: Text(
                              camp['nome'],
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.white54),
                              tooltip: 'Rimuovi dai preferiti',
                              onPressed: () {
                                context.read<FavoritesProvider>().toggleFavorite(camp);
                              },
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