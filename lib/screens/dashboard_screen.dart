import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../services/supabase_service.dart';
import '../models/device_model.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<DeviceModel> _recentDevices = [];
  List<Map<String, dynamic>> _recentVerifications = [];
  Map<String, int> _stats = {
    'totalDevices': 0,
    'verifiedToday': 0,
    'activeAlerts': 0,
    'blocked': 0,
    'stolenDevices': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final supabaseService = Provider.of<SupabaseService>(context, listen: false);
      
      // Load all devices
      final allDevices = await supabaseService.getDevices();
      
      // Load enriched verification logs
      final verificationLogs = await supabaseService.getEnrichedVerificationLogs(limit: 50);
      
      // Calculate stats
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      
      final verifiedToday = verificationLogs.where((log) {
        final createdAt = DateTime.parse(log['created_at'] as String);
        return createdAt.isAfter(todayStart) && log['status'] == 'verified';
      }).length;
      
      final activeAlerts = verificationLogs.where((log) {
        return log['status'] == 'suspicious' || log['status'] == 'blocked';
      }).length;
      
      final blocked = verificationLogs.where((log) {
        return log['status'] == 'blocked';
      }).length;
      
      final stolenDevices = allDevices.where((d) => d.status == 'stolen').length;

      if (mounted) {
        setState(() {
          _stats = {
            'totalDevices': allDevices.length,
            'verifiedToday': verifiedToday,
            'activeAlerts': activeAlerts,
            'blocked': blocked,
            'stolenDevices': stolenDevices,
          };
          _recentDevices = allDevices.take(5).toList();
          _recentVerifications = verificationLogs.take(10).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading dashboard: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              const Text(
                                'Overview',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 20),
                              // KPI Cards
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildKPICard(
                                      'Total Devices',
                                      _stats['totalDevices'].toString(),
                                      Icons.devices,
                                      AppTheme.primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildKPICard(
                                      'Verified Today',
                                      _stats['verifiedToday'].toString(),
                                      Icons.verified,
                                      AppTheme.successGreen,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildKPICard(
                                      'Stolen Devices',
                                      _stats['stolenDevices'].toString(),
                                      Icons.report_problem,
                                      AppTheme.errorRed,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildKPICard(
                                      'Active Alerts',
                                      _stats['activeAlerts'].toString(),
                                      Icons.warning,
                                      AppTheme.warningOrange,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildKPICard(
                                      'Total Blocked',
                                      _stats['blocked'].toString(),
                                      Icons.block,
                                      AppTheme.errorRed,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              const Text(
                                'Recent Devices',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildRecentDevicesList(),
                              const SizedBox(height: 24),
                              const Text(
                                'Recent Verifications',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildRecentVerificationsList(),
                              const SizedBox(height: 20),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textMedium,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDevicesList() {
    if (_recentDevices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'No devices yet',
          style: TextStyle(color: AppTheme.textMedium),
        ),
      );
    }

    return Column(
      children: _recentDevices.map((device) {
        return GlassCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.lightGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.phone_android,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${device.brand} ${device.model}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device.qrCodeUrl != null ? 'Verified' : 'Pending',
                      style: TextStyle(
                        fontSize: 12,
                        color: device.qrCodeUrl != null
                            ? AppTheme.successGreen
                            : AppTheme.warningOrange,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textLight,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentVerificationsList() {
    if (_recentVerifications.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.history, color: AppTheme.textLight, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Audit Trail Empty',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textMedium,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Waiting for security scans to be performed...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textLight,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _recentVerifications.map<Widget>((verification) {
        final status = verification['status'] as String;
        final entryType = verification['entry_type'] as String? ?? 'entry';
        final isEntry = entryType.toLowerCase() == 'entry';
        
        final device = verification['devices'] as Map<String, dynamic>?;
        final user = device?['users'] as Map<String, dynamic>?;
        
        final studentIdData = user?['student_ids'];
        String? studentId;
        if (studentIdData is List && studentIdData.isNotEmpty) {
          studentId = studentIdData[0]['student_id'] as String?;
        } else if (studentIdData is Map) {
          studentId = studentIdData['student_id'] as String?;
        }
        
        final studentName = user?['full_name'] as String? ?? 'Unknown Student';

        Color statusColor;
        IconData statusIcon;

        switch (status) {
          case 'verified':
            statusColor = AppTheme.successGreen;
            statusIcon = Icons.verified_user;
            break;
          case 'suspicious':
            statusColor = AppTheme.warningOrange;
            statusIcon = Icons.gpp_maybe;
            break;
          case 'blocked':
          case 'stolen':
            statusColor = AppTheme.errorRed;
            statusIcon = Icons.gpp_bad;
            break;
          default:
            statusColor = AppTheme.textMedium;
            statusIcon = Icons.help_outline;
        }

        final createdAt = DateTime.parse(verification['created_at'] as String);
        final timeDisplay = DateFormat('HH:mm').format(createdAt);
        final dateDisplay = _getTimeAgo(createdAt);

        return GlassCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          onTap: () {
            if (device != null) {
              context.push('/device-detail/${device['id']}');
            }
          },
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Status Indicator
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                
                // Device and Student Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              studentName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Entry/Exit Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isEntry ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isEntry ? 'ENTRY' : 'EXIT',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isEntry ? Colors.blue : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (studentId != null)
                            Text(
                              'ID: $studentId',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (studentId != null)
                            const Text(' • ', style: TextStyle(color: AppTheme.textLight)),
                          Text(
                            '${device?['brand'] ?? ''} ${device?['model'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$dateDisplay at $timeDisplay',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Vertical Divider
                const VerticalDivider(width: 20, thickness: 1, indent: 4, endIndent: 4),
                
                // Action Buttons (Map Check)
                if (verification['latitude'] != null && verification['longitude'] != null)
                  IconButton(
                    icon: const Icon(Icons.map_outlined, color: AppTheme.primaryBlue, size: 22),
                    tooltip: 'Check Map Location',
                    onPressed: () {
                      final url = 'https://www.google.com/maps/search/?api=1&query=${verification['latitude']},${verification['longitude']}';
                      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    },
                  )
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.location_off_outlined, color: AppTheme.textLight, size: 18),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('MMM d, HH:mm').format(dateTime);
  }
}
