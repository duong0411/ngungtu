import 'package:flutter/foundation.dart';

import 'auth_service.dart';
import 'models/user_model.dart';
import 'node_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();
  final NodeService _nodes = NodeService();

  UserModel? user;
  bool booting = true;
  bool busy = false;
  String? error;
  String? nodeId;
  String? nodeName;

  bool get isLoggedIn => user != null;

  Future<void> bootstrap() async {
    booting = true;
    notifyListeners();
    try {
      user = await _auth.loadSavedUser();
      if (user != null) {
        await _ensureDevice();
      }
    } catch (e) {
      error = e.toString();
    }
    booting = false;
    notifyListeners();
  }

  Future<void> _ensureDevice() async {
    final node = await _nodes.ensureCondenserNode();
    nodeId = node?['_id']?.toString() ?? node?['id']?.toString();
    nodeName = node?['name']?.toString() ?? 'Máy Ngưng Tụ STEM';
  }

  Future<bool> login(String email, String password) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      user = await _auth.login(email.trim(), password);
      await _ensureDevice();
      busy = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      busy = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String phone, String password) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      user = await _auth.register(name.trim(), email.trim(), phone.trim(), password);
      await _ensureDevice();
      busy = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      busy = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    user = null;
    nodeId = null;
    nodeName = null;
    notifyListeners();
  }

  DateTime? _lastSync;

  Future<void> syncTelemetry(Map<String, dynamic> state) async {
    if (nodeId == null) return;
    final now = DateTime.now();
    if (_lastSync != null && now.difference(_lastSync!) < const Duration(seconds: 20)) {
      return;
    }
    _lastSync = now;
    await _nodes.updateState(nodeId!, state);
  }
}
