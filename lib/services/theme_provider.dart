import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark; // Il Dark Mode resta il nostro default!

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _caricaTema();
  }

  Future<void> _caricaTema() async {
    final prefs = await SharedPreferences.getInstance();
    final temaSalvato = prefs.getString('tema_app');
    
    if (temaSalvato == 'light') {
      _themeMode = ThemeMode.light;
    } else if (temaSalvato == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setTema(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    String valoreDaSalvare = 'system';
    if (mode == ThemeMode.light) valoreDaSalvare = 'light';
    if (mode == ThemeMode.dark) valoreDaSalvare = 'dark';
    
    await prefs.setString('tema_app', valoreDaSalvare);
  }
}