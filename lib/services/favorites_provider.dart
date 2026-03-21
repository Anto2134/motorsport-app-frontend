import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FavoritesProvider extends ChangeNotifier {
  List<dynamic> _favoriteItems = [];

  List<dynamic> get favoriteItems => _favoriteItems;

  // Appena il cervello si accende, va a leggere la cassaforte
  FavoritesProvider() {
    _caricaPreferiti();
  }

  Future<void> _caricaPreferiti() async {
    final prefs = await SharedPreferences.getInstance();
    final stringaSalvata = prefs.getString('preferiti_salvati');
    
    if (stringaSalvata != null) {
      _favoriteItems = json.decode(stringaSalvata);
      notifyListeners(); // Avvisa l'app che i vecchi preferiti sono tornati!
    }
  }

  Future<void> _salvaPreferiti() async {
    final prefs = await SharedPreferences.getInstance();
    // Trasformiamo la lista in una stringa di testo per poterla salvare
    await prefs.setString('preferiti_salvati', json.encode(_favoriteItems));
  }

  void toggleFavorite(dynamic campionato) {
    // Cerchiamo se il campionato c'è già (controllando il nome, che è univoco)
    final index = _favoriteItems.indexWhere((item) => item['nome'] == campionato['nome']);
    
    if (index >= 0) {
      _favoriteItems.removeAt(index); // Se c'è, lo togliamo
    } else {
      _favoriteItems.add(campionato); // Se non c'è, lo aggiungiamo
    }
    
    _salvaPreferiti(); // Chiudiamo a chiave la cassaforte
    notifyListeners(); 
  }

  bool isFavorite(dynamic campionato) {
    return _favoriteItems.any((item) => item['nome'] == campionato['nome']);
  }
}