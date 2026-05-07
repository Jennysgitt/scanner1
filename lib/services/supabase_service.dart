import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/device_model.dart';

class SupabaseService {
  SupabaseClient get _client => Supabase.instance.client;
  SupabaseClient get client => _client;

  // Auth Methods
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // User Methods
  Future<UserModel?> getUserRole(String userId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  Future<UserModel?> getUserByStudentId(String studentId) async {
    final studentIdUpper = studentId.toUpperCase().trim();
    
    final studentIdResponse = await _client
        .from('student_ids')
        .select('user_id, student_id')
        .eq('student_id', studentIdUpper)
        .maybeSingle();

    if (studentIdResponse == null) return null;

    final userResponse = await _client
        .from('users')
        .select()
        .eq('id', studentIdResponse['user_id'] as String)
        .maybeSingle();

    if (userResponse == null) return null;
    return UserModel.fromJson(userResponse);
  }

  // Device Methods
  Future<List<DeviceModel>> getDevices({String? userId}) async {
    var query = _client.from('devices').select();
    
    if (userId != null) {
      query = query.eq('user_id', userId);
    }
    
    final response = await query.order('created_at', ascending: false);
    return (response as List)
        .map((json) => DeviceModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<DeviceModel> createDevice({
    required String userId,
    required String brand,
    required String model,
    required String serialNumber,
    required String imageUrl,
    String? deviceId,
    List<double>? features,
  }) async {
    final response = await _client.from('devices').insert({
      'user_id': userId,
      'brand': brand,
      'model': model,
      'serial_number': serialNumber,
      'image_url': imageUrl,
      'device_id': deviceId,
      'ai_features': features,
      'status': 'pending',
    }).select().single();

    return DeviceModel.fromJson(response);
  }

  Future<void> updateDeviceQrCode(
    String deviceId,
    String qrCodeUrl,
    String qrCodeHash,
  ) async {
    await _client.from('devices').update({
      'qr_code_url': qrCodeUrl,
      'qr_code_hash': qrCodeHash,
    }).eq('id', deviceId);
  }

  Future<void> reportDeviceStolen(String deviceId, {String? location}) async {
    await _client.from('devices').update({
      'status': 'stolen',
      'location': location,
    }).eq('id', deviceId);
  }

  // Storage Methods
  Future<String> uploadImage(String path, List<int> fileBytes, {String bucket = 'device-images'}) async {
    print('SupabaseService: Uploading image to bucket: $bucket, path: $path');
    final uint8List = Uint8List.fromList(fileBytes);
    await _client.storage
        .from(bucket)
        .uploadBinary(path, uint8List);

    final publicUrl = _client.storage
        .from(bucket)
        .getPublicUrl(path);
    
    print('SupabaseService: Image uploaded, public URL: $publicUrl');
    return publicUrl;
  }

  // User Profile Methods
  Future<void> updateUserProfile({
    required String userId,
    String? email,
    String? profilePictureUrl,
    String? fullName,
    String? role,
  }) async {
    print('SupabaseService: Updating user profile for $userId');
    final updateData = <String, dynamic>{
      'id': userId, // Required for upsert
    };
    
    if (email != null) {
      updateData['email'] = email;
    }
    
    if (profilePictureUrl != null) {
      updateData['profile_picture_url'] = profilePictureUrl;
      print('SupabaseService: Setting profile_picture_url');
    }
    
    if (fullName != null) {
      updateData['full_name'] = fullName;
    }

    if (role != null) {
      updateData['role'] = role;
    }

    if (updateData.isNotEmpty) {
      print('SupabaseService: Sending update data: $updateData');
      await _client
          .from('users')
          .upsert(updateData) // Use upsert instead of update
          .eq('id', userId);
      print('SupabaseService: Update successful');
    }
  }

  Future<List<Map<String, dynamic>>> getEnrichedVerificationLogs({
    int limit = 100,
  }) async {
    final response = await _client
        .from('verification_logs')
        .select('*, devices(*, users(*, student_ids(student_id)))')
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getDeviceDetailWithOwner(String deviceId) async {
    final response = await _client
        .from('devices')
        .select('*, users(*, student_ids(student_id)), verification_logs(*)')
        .eq('id', deviceId)
        .maybeSingle();

    return response;
  }

  Future<void> createVerificationLog({
    required String deviceId,
    String? officerId,
    required String status,
    double? aiScore,
    double? imageMatchScore,
    bool? qrValidity,
    String entryType = 'entry',
    double? latitude,
    double? longitude,
  }) async {
    await _client.from('verification_logs').insert({
      'device_id': deviceId,
      'officer_id': officerId,
      'status': status,
      'ai_score': aiScore,
      'image_match_score': imageMatchScore,
      'qr_validity': qrValidity,
      'entry_type': entryType,
      'latitude': latitude,
      'longitude': longitude,
    });
  }
}

