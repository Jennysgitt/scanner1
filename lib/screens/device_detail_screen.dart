import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../services/supabase_service.dart';

class DeviceDetailScreen extends StatefulWidget {
  final String deviceId;

  const DeviceDetailScreen({super.key, required this.deviceId});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  Map<String, dynamic>? _deviceData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceDetail();
  }

  Future<void> _loadDeviceDetail() async {
    setState(() => _isLoading = true);
    try {
      final supabaseService = Provider.of<SupabaseService>(context, listen: false);
      final data = await supabaseService.getDeviceDetailWithOwner(widget.deviceId);
      
      if (mounted) {
        setState(() {
          _deviceData = data;
          _isLoading = false;
        });
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_deviceData == null) {
      return const Scaffold(body: Center(child: Text('Device not found')));
    }

    final user = _deviceData!['users'] as Map<String, dynamic>?;
    final studentIdData = user?['student_ids'];
    String? studentId;
    if (studentIdData is List && studentIdData.isNotEmpty) {
      studentId = studentIdData[0]['student_id'] as String?;
    } else if (studentIdData is Map) {
      studentId = studentIdData['student_id'] as String?;
    }
    final String studentIdDisplay = studentId ?? 'N/A';
    final logs = _deviceData!['verification_logs'] as List? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.primaryGradient)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDeviceSection(),
            const SizedBox(height: 24),
            _buildOwnerSection(user, studentIdDisplay),
            const SizedBox(height: 24),
            _buildRecentLogsSection(logs),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceSection() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppTheme.lightGradient,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.laptop, color: AppTheme.primaryBlue, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_deviceData!['brand']} ${_deviceData!['model']}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'SN: ${_deviceData!['serial_number']}',
                      style: const TextStyle(color: AppTheme.textMedium),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(_deviceData!['status'] as String? ?? 'pending'),
            ],
          ),
          if (_deviceData!['image_url'] != null) ...[
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                _deviceData!['image_url'],
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOwnerSection(Map<String, dynamic>? user, String studentId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Owner Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                child: Text(
                  (user?['full_name'] as String? ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?['full_name'] as String? ?? 'Unknown User',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    Text('Student ID: $studentId', style: const TextStyle(color: AppTheme.primaryBlue)),
                    Text(user?['email'] as String? ?? 'No email available', style: const TextStyle(color: AppTheme.textMedium)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentLogsSection(List logs) {
    if (logs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        const SizedBox(height: 12),
        ...logs.take(5).map((log) {
          final isEntry = (log['entry_type'] as String? ?? 'entry') == 'entry';
          final createdAt = DateTime.parse(log['created_at'] as String);
          return GlassCard(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  isEntry ? Icons.login : Icons.logout,
                  color: isEntry ? Colors.blue : Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isEntry ? 'Entry Logged' : 'Exit Logged', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(DateFormat('MMM d, y • HH:mm').format(createdAt), style: const TextStyle(fontSize: 12, color: AppTheme.textMedium)),
                    ],
                  ),
                ),
                if (log['latitude'] != null)
                  IconButton(
                    icon: const Icon(Icons.map, color: AppTheme.primaryBlue),
                    onPressed: () {
                      final url = 'https://www.google.com/maps/search/?api=1&query=${log['latitude']},${log['longitude']}';
                      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    },
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppTheme.successGreen;
    if (status == 'stolen') color = AppTheme.errorRed;
    if (status == 'pending') color = AppTheme.warningOrange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }
}
