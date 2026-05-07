import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/outline_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/glass_card.dart';
import '../services/supabase_service.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class RegisterDeviceScreen extends StatefulWidget {
  const RegisterDeviceScreen({super.key});

  @override
  State<RegisterDeviceScreen> createState() => _RegisterDeviceScreenState();
}

class _RegisterDeviceScreenState extends State<RegisterDeviceScreen> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialNumberController = TextEditingController();
  
  int _currentStep = 0;
  Uint8List? _selectedImage;
  bool _isLoading = false;
  String? _qrCodeUrl;

  @override
  void dispose() {
    _pageController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _serialNumberController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentStep = 1);
      }
    } else if (_currentStep == 1) {
      if (_selectedImage != null) {
        _handleRegister();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a device image'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep = _currentStep - 1);
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await showModalBottomSheet<XFile>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppTheme.primaryBlue),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  final image = await picker.pickImage(source: ImageSource.gallery);
                  Navigator.pop(context, image);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppTheme.primaryBlue),
                title: const Text('Take a Photo'),
                onTap: () async {
                  final image = await picker.pickImage(source: ImageSource.camera);
                  Navigator.pop(context, image);
                },
              ),
            ],
          ),
        ),
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        if (mounted) {
          setState(() {
            _selectedImage = bytes;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _handleRegister() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a device image'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final supabaseService = Provider.of<SupabaseService>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);

      if (authProvider.currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Step 1: Upload image to Supabase Storage
      final imageBytes = _selectedImage!;
      final fileName = '${authProvider.currentUser!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imageUrl = await supabaseService.uploadImage(fileName, imageBytes);

      // Step 2: Register device with AI backend
      final aiResponse = await apiService.registerDeviceWithAI(
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        serialNumber: _serialNumberController.text.trim(),
        imageUrl: imageUrl,
      );

      final deviceId = aiResponse['device_id'] as String?;
      final features = (aiResponse['features'] as List?)?.map((e) => (e as num).toDouble()).toList();

      // Step 3: Create device in database
      final device = await supabaseService.createDevice(
        userId: authProvider.currentUser!.id,
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        serialNumber: _serialNumberController.text.trim(),
        imageUrl: imageUrl,
        deviceId: deviceId,
        features: features,
      );

      // Step 4: Generate QR code data and hash
      final qrData = jsonEncode({
        'device_id': device.id,
        'user_id': device.userId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      final qrHash = sha256.convert(utf8.encode(qrData)).toString();
      
      // Generate QR code URL (using a QR code service or local generation)
      final qrCodeData = '$qrHash|${device.id}';
      _qrCodeUrl = qrCodeData;

      // Step 5: Update device with QR code info
      await supabaseService.updateDeviceQrCode(
        device.id,
        qrCodeData,
        qrHash,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentStep = 2;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        
        String errorMessage = 'Error registering device: ${e.toString()}';
        if (e.toString().contains('duplicate key value') || e.toString().contains('23505')) {
          errorMessage = 'A device with this Serial Number is already registered in the system.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header removed - Progress Indicator remains
              const SizedBox(height: 10),
              // Progress Indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: List.generate(3, (index) {
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(
                          right: index < 2 ? 8 : 0,
                        ),
                        height: 4,
                        decoration: BoxDecoration(
                          color: index <= _currentStep
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),
              // Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                  ],
                ),
              ),
              // Navigation Buttons
              if (_currentStep < 2)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlineButton(
                            text: 'Back',
                            icon: Icons.arrow_back,
                            onPressed: _previousStep,
                          ),
                        ),
                      if (_currentStep > 0) const SizedBox(width: 16),
                      Expanded(
                        flex: _currentStep > 0 ? 1 : 1,
                        child: GradientButton(
                          text: _currentStep == 0 ? 'Continue' : 'Register',
                          icon: _currentStep == 0
                              ? Icons.arrow_forward
                              : Icons.check,
                          isLoading: _isLoading,
                          onPressed: _nextStep,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Device Information',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your device details',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textMedium,
                ),
              ),
              const SizedBox(height: 32),
              CustomTextField(
                label: 'Brand',
                hint: 'e.g., Apple, Samsung',
                controller: _brandController,
                prefixIcon: const Icon(
                  Icons.branding_watermark,
                  color: AppTheme.primaryBlue,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter device brand';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Model',
                hint: 'e.g., iPhone 14, Galaxy S23',
                controller: _modelController,
                prefixIcon: const Icon(
                  Icons.phone_android,
                  color: AppTheme.primaryBlue,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter device model';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Serial Number',
                hint: 'Enter device serial number',
                controller: _serialNumberController,
                prefixIcon: const Icon(
                  Icons.confirmation_number,
                  color: AppTheme.primaryBlue,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter serial number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Device Image',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload a clear photo of your device',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textMedium,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  gradient: _selectedImage != null
                      ? null
                      : AppTheme.lightGradient,
                  color: _selectedImage != null ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.dividerGray,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.memory(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_photo_alternate,
                              size: 40,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Tap to Upload Image',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gallery or Camera',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textMedium,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (_selectedImage != null) ...[
              const SizedBox(height: 16),
              OutlineButton(
                text: 'Remove Image',
                icon: Icons.delete_outline,
                onPressed: () {
                  setState(() => _selectedImage = null);
                },
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Success Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.successGreen,
                    AppTheme.successGreen.withOpacity(0.7),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Device Registered!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your device has been successfully registered',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textMedium,
              ),
            ),
            const SizedBox(height: 40),
            // QR Code
            if (_qrCodeUrl != null)
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'Your QR Code',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(
                        data: _qrCodeUrl!,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 40),
            GradientButton(
              text: 'View My Devices',
              icon: Icons.devices,
              onPressed: () => context.go('/my-devices'),
            ),
            const SizedBox(height: 16),
            OutlineButton(
              text: 'Register Another Device',
              icon: Icons.add,
              onPressed: () {
                // Reset form
                _brandController.clear();
                _modelController.clear();
                _serialNumberController.clear();
                _selectedImage = null;
                _qrCodeUrl = null;
                _currentStep = 0;
                _pageController.jumpToPage(0);
                setState(() {});
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
