import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AuthProvider with ChangeNotifier {
  final SharedPreferences prefs;
  String? _token;
  String? _userName;

  AuthProvider(this.prefs) {
    _token = prefs.getString('jwt_token');
    _userName = prefs.getString('user_name');
  }

  bool get isAuthenticated => _token != null;
  String? get token => _token;
  String? get userName => _userName;

  // Utilisation de l'IP locale pour que le téléphone puisse se connecter au backend du PC
  static const String baseUrl = 'http://192.168.1.5:3000/api/auth';

  Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _userName = data['user']['name'];
        await prefs.setString('jwt_token', _token!);
        if (_userName != null) {
          await prefs.setString('user_name', _userName!);
        }
        notifyListeners();
        return null; // success
      } else {
        final errorData = jsonDecode(response.body);
        return errorData['errorMessage'] ?? 'Erreur de connexion';
      }
    } catch (e) {
      return 'Erreur réseau : $e';
    }
  }

  Future<String?> register(String email, String password, String name) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'name': name}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _userName = data['user']['name'];
        await prefs.setString('jwt_token', _token!);
        await prefs.setString('user_name', _userName!);
        notifyListeners();
        return null; // success
      } else {
        final errorData = jsonDecode(response.body);
        return errorData['errorMessage'] ?? 'Erreur d\'inscription';
      }
    } catch (e) {
      return 'Erreur réseau : $e';
    }
  }

  Future<void> logout() async {
    _token = null;
    _userName = null;
    await prefs.remove('jwt_token');
    await prefs.remove('user_name');
    notifyListeners();
  }
}
