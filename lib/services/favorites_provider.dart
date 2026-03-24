import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class FavoritesProvider extends ChangeNotifier {
  List<dynamic> _favoriteItems = [];
  bool isCloudSynced = false; // Sapere se stiamo usando il Cloud

  List<dynamic> get favoriteItems => _favoriteItems;

  FavoritesProvider() {
    // IL CERVELLO ASCOLTA: Appena cambia l'utente (login o logout), reagisce!
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        isCloudSynced = true;
        _caricaDaCloud(user.uid);
      } else {
        isCloudSynced = false;
        _caricaDaLocale();
      }
    });
  }

  // 1. Lettura/Scrittura Locale (Per gli ospiti)
  Future<void> _caricaDaLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final stringaSalvata = prefs.getString('preferiti_salvati');
    
    if (stringaSalvata != null) {
      _favoriteItems = json.decode(stringaSalvata);
    } else {
      _favoriteItems = [];
    }
    notifyListeners();
  }

  Future<void> _salvaInLocale() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferiti_salvati', json.encode(_favoriteItems));
  }

  // 2. Lettura/Scrittura Cloud (Per gli utenti VIP)
  Future<void> _caricaDaCloud(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      
      if (doc.exists && doc.data()!.containsKey('favorites')) {
        // L'utente aveva già dati nel cloud, li scarichiamo
        _favoriteItems = List<dynamic>.from(doc.data()!['favorites']);
      } else {
        // MAGIA: È il suo primo accesso! Prendiamo i preferiti che aveva salvato 
        // localmente (se ce ne sono) e li carichiamo nel cloud automaticamente.
        await _salvaNelCloud(uid); 
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Errore caricamento Cloud: $e");
    }
  }

  Future<void> _salvaNelCloud(String uid) async {
    // Usiamo merge: true per non cancellare eventuali altri dati dell'utente futuri
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'favorites': _favoriteItems
    }, SetOptions(merge: true));
  }

  // 3. Azioni Comuni
  void toggleFavorite(dynamic campionato) {
    final index = _favoriteItems.indexWhere((item) => item['nome'] == campionato['nome']);
    
    if (index >= 0) {
      _favoriteItems.removeAt(index);
    } else {
      _favoriteItems.add(campionato);
    }
    
    // Sceglie in automatico dove salvare
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _salvaNelCloud(user.uid);
    } else {
      _salvaInLocale();
    }
    
    notifyListeners(); 
  }

  void clearFavorites() {
    _favoriteItems.clear();
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _salvaNelCloud(user.uid);
    } else {
      _salvaInLocale();
    }
    
    notifyListeners();
  }

  bool isFavorite(dynamic campionato) {
    return _favoriteItems.any((item) => item['nome'] == campionato['nome']);
  }
}