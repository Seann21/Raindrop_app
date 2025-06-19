import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/enchanced_notification_service.dart';
import '../services/weather_alert_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _weatherAlertsEnabled = true;
  bool _generalNotificationsEnabled = true;
  bool _extremeWeatherOnly = false;
  bool _isLoading = false;

  final WeatherAlertService _alertService = WeatherAlertService();
  final EnhancedNotificationService _notificationService =
      EnhancedNotificationService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;

      setState(() {
        _weatherAlertsEnabled = prefs.getBool('weather_alerts_enabled') ?? true;
        _generalNotificationsEnabled =
            prefs.getBool('notification_general') ?? true;
        _extremeWeatherOnly = prefs.getBool('extreme_weather_only') ?? false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading settings: $e')));
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;

      await prefs.setBool('weather_alerts_enabled', _weatherAlertsEnabled);
      await prefs.setBool('notification_general', _generalNotificationsEnabled);
      await prefs.setBool('extreme_weather_only', _extremeWeatherOnly);

      // Update alert service
      if (_weatherAlertsEnabled) {
        await _alertService.startWeatherMonitoring();
      } else {
        _alertService.stopWeatherMonitoring();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving settings: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendTestNotification() async {
    if (!mounted) return;

    try {
      await _notificationService.showExtremeWeatherAlert(
        city: 'Test City',
        alertType: 'Test Alert',
        description: 'This is a test notification',
        additionalInfo: 'If you see this, notifications are working!',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test notification sent!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending test notification: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _clearAllNotifications() async {
    if (!mounted) return;

    try {
      await _notificationService.cancelAllNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications cleared!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing notifications: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Weather Alerts Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.warning_amber,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Weather Alerts',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Enable Weather Alerts'),
                            subtitle: const Text(
                              'Get notified about extreme weather conditions',
                            ),
                            value: _weatherAlertsEnabled,
                            onChanged: (value) {
                              setState(() {
                                _weatherAlertsEnabled = value;
                              });
                              _saveSettings();
                            },
                          ),
                          SwitchListTile(
                            title: const Text('Extreme Weather Only'),
                            subtitle: const Text(
                              'Only receive alerts for severe weather conditions',
                            ),
                            value: _extremeWeatherOnly,
                            onChanged:
                                _weatherAlertsEnabled
                                    ? (value) {
                                      setState(() {
                                        _extremeWeatherOnly = value;
                                      });
                                      _saveSettings();
                                    }
                                    : null,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // General Notifications Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.notifications,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'General Notifications',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('General Updates'),
                            subtitle: const Text(
                              'App updates and general weather information',
                            ),
                            value: _generalNotificationsEnabled,
                            onChanged: (value) {
                              setState(() {
                                _generalNotificationsEnabled = value;
                              });
                              _saveSettings();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Test Notification Button
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.bug_report,
                                color: Colors.purple,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Test Notifications',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _sendTestNotification,
                              icon: const Icon(Icons.send),
                              label: const Text('Send Test Alert'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Clear All Notifications Button
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _clearAllNotifications,
                          icon: const Icon(Icons.clear_all, color: Colors.red),
                          label: const Text('Clear All Notifications'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
