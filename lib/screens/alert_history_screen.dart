import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather_alert.dart';
import '../services/enchanced_notification_service.dart';

class AlertHistoryScreen extends StatefulWidget {
  const AlertHistoryScreen({super.key});

  @override
  State<AlertHistoryScreen> createState() => _AlertHistoryScreenState();
}

class _AlertHistoryScreenState extends State<AlertHistoryScreen> {
  final EnhancedNotificationService _notificationService =
      EnhancedNotificationService();
  List<WeatherAlert> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlertHistory();
  }

  Future<void> _loadAlertHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final alerts = await _notificationService.getAlertHistory();
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading alert history: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlertHistory,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _alerts.isEmpty
              ? _buildEmptyState()
              : _buildAlertList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Weather Alerts Yet',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Weather alerts will appear here when they occur',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertList() {
    // Group alerts by date
    Map<String, List<WeatherAlert>> groupedAlerts = {};

    for (WeatherAlert alert in _alerts) {
      String dateKey = DateFormat('yyyy-MM-dd').format(alert.timestamp);
      if (!groupedAlerts.containsKey(dateKey)) {
        groupedAlerts[dateKey] = [];
      }
      groupedAlerts[dateKey]!.add(alert);
    }

    List<String> sortedDates =
        groupedAlerts.keys.toList()
          ..sort((a, b) => b.compareTo(a)); // Most recent first

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        String dateKey = sortedDates[index];
        List<WeatherAlert> dayAlerts = groupedAlerts[dateKey]!;
        DateTime date = DateTime.parse(dateKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _formatDateHeader(date),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),

            // Alerts for this date
            ...dayAlerts.map((alert) => _buildAlertCard(alert)),

            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildAlertCard(WeatherAlert alert) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: alert.severityColor,
          child: Text(
            alert.severityEmoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          '${alert.alertType} - ${alert.city}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alert.description),
            if (alert.additionalInfo != null) ...[
              const SizedBox(height: 4),
              Text(
                alert.additionalInfo!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(alert.timestamp),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: Chip(
          label: Text(
            alert.severityText,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          backgroundColor: alert.severityColor.withAlpha(60),
          side: BorderSide(color: alert.severityColor),
        ),
        isThreeLine: true,
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(const Duration(days: 1));
    DateTime alertDate = DateTime(date.year, date.month, date.day);

    if (alertDate == today) {
      return 'Today';
    } else if (alertDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, MMMM d').format(date);
    }
  }
}
