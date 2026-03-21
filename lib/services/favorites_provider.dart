import 'package:flutter/material.dart';

// ChangeNotifier significa: "Se cambia qualcosa qui dentro, avvisa tutta l'app!"
class FavoritesProvider extends ChangeNotifier {
  // Questa è la nostra cassaforte privata dei preferiti
  final List<dynamic> _favoriteItems = [];

  // Questo è lo sportello per leggere cosa c'è nella cassaforte
  List<dynamic> get favoriteItems => _favoriteItems;

  // Questa funzione aggiunge o toglie un campionato dai preferiti
  void toggleFavorite(dynamic campionato) {
    if (_favoriteItems.contains(campionato)) {
      _favoriteItems.remove(campionato); // Se c'è già, lo togliamo
    } else {
      _favoriteItems.add(campionato); // Se non c'è, lo aggiungiamo
    }
    
    // LA VERA MAGIA: Questo comando urla all'app "EHI, AGGIORNATEVI TUTTI!"
    notifyListeners(); 
  }

  // Una comodità per sapere subito se un campionato è tra i preferiti (utile per colorare la stellina)
  bool isFavorite(dynamic campionato) {
    return _favoriteItems.contains(campionato);
  }
}