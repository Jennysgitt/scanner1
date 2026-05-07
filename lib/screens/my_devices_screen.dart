import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../services/supabase_service.dart';
import '../models/device_model.dart';
import '../providers/auth_provider.dart';

class MyDevicesScreen extends StatefulWidget {
  const MyDevicesScreen({super.key});

  @override
  State<MyDevicesScreen> createState() => _MyDevicesScreenState();
}

class _MyDevicesScreenState extends State<MyDevicesScreen> {
  List<DeviceModel> _devices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final supabaseService = Provider.of<SupabaseService>(context, listen: false);
      
      if (authProvider.currentUser != null) {
        final devices = await supabaseService.getDevices(
          userId: authProvider.currentUser!.id,
        );
        if (mounted) {
          setState(() {
            _devices = devices;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading devices: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _reportStolen(DeviceModel device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Device Stolen?'),
        content: Text('Are you sure you want to report your ${device.brand} ${device.model} as stolen? This will alert all security personnel.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Report Stolen'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        setState(() => _isLoading = true);
        final supabaseService = Provider.of<SupabaseService>(context, listen: false);
        await supabaseService.reportDeviceStolen(device.id);
        await _loadDevices();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Device reported as stolen successfully.'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
          );
        }
      }
    }
  }

  Future<void> _refreshDevices() async {
    await _loadDevices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header removed - pull to refresh is available
              const SizedBox(height: 10),
              // Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: AppTheme.backgroundWhite,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _devices.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _refreshDevices,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                itemCount: _devices.length,
                                itemBuilder: (context, index) {
                                  return _buildDeviceCard(_devices[index]);
                                },
                              ),
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/register-device'),
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Register Device',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppTheme.lightGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.devices_outlined,
                  size: 60,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'No Devices Yet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Register your first device to get started with SecureGate AI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textMedium,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              GradientButton(
                text: 'Register Your First Device',
                icon: Icons.add_circle_outline,
                onPressed: () => context.go('/register-device'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceCard(DeviceModel device) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      onTap: () {
        context.push('/device-detail/${device.id}');
      },
      child: Row(
        children: [
          // Device Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppTheme.lightGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: device.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      device.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.phone_android,
                          size: 40,
                          color: AppTheme.primaryBlue,
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.phone_android,
                    size: 40,
                    color: AppTheme.primaryBlue,
                  ),
          ),
          const SizedBox(width: 16),
          // Device Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${device.brand} ${device.model}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SN: ${device.serialNumber}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMedium,
                  ),
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 8),
                _buildStatusBadge(device),
              ],
            ),
          ),
          if (device.status != 'stolen')
            IconButton(
              icon: const Icon(Icons.report_problem_outlined, color: AppTheme.errorRed),
              tooltip: 'Report Stolen',
              onPressed: () => _reportStolen(device),
            ),
          const Icon(
            Icons.chevron_right,
            color: AppTheme.textLight,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(DeviceModel device) {
    Color color;
    String label;
    IconData icon;

    if (device.status == 'stolen') {
      color = AppTheme.errorRed;
      label = 'STOLEN';
      icon = Icons.warning;
    } else if (device.qrCodeUrl == null) {
      color = AppTheme.warningOrange;
      label = 'Pending';
      icon = Icons.hourglass_empty;
    } else {
      color = AppTheme.successGreen;
      label = 'Verified';
      icon = Icons.verified;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
