import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  UserModel? _currentUser;
  bool _isLoading = false;

  AuthProvider(this._authService) {
    _init();
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  void _init() {
    _authService.authStateChanges.listen((AuthState state) async {
      if (state.session?.user != null) {
        await _loadUser();
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });

    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await _authService.getCurrentUserProfile();
      _currentUser = user;
    } catch (e) {
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reloadUser() async {
    await _loadUser();
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await _authService.signInWithEmail(email, password);
      _currentUser = user;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithStudentId(String studentId, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await _authService.signInWithStudentId(studentId, password);
      _currentUser = user;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String role = 'student',
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await _authService.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );
      _currentUser = user;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUpWithStudentId({
    required String studentId,
    required String password,
    required String fullName,
    String role = 'student',
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await _authService.signUpWithStudentId(
        studentId: studentId,
        password: password,
        fullName: fullName,
        role: role,
      );
      _currentUser = user;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  String getRedirectPath() {
    return _authService.getRedirectPathByRole(_currentUser?.role);
  }
}

