import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/config.dart';
import 'order_detail_screen.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  final String userId;

  const NotificationScreen({super.key, required this.userId});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool isLoading = false;
  List<dynamic> notifications = [];
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http
          .get(
            Uri.parse(
              '${Config.BASE_URL}/get_notifications.php?user_id=${widget.userId}',
            ),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout:
                () =>
                    throw TimeoutException(
                      'Koneksi timeout, silakan coba lagi',
                    ),
          );

      // Log response untuk debugging
      print('Notification API Response Status: ${response.statusCode}');
      print('Notification API Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          setState(() {
            // Gunakan nilai default [] jika notifications null
            notifications = data['notifications'] ?? [];
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Gagal memuat notifikasi';
          });
        }
      } else {
        setState(() {
          errorMessage = 'Network error: ${response.statusCode}';
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.BASE_URL}/mark_notification_read.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'notification_id': notificationId,
          'user_id': widget.userId,
        }),
      );

      print('Mark as read response: ${response.statusCode}');
      print('Mark as read body: ${response.body}');

      // Update the notification locally to avoid unnecessary reload
      setState(() {
        for (var i = 0; i < notifications.length; i++) {
          if (notifications[i]['id'].toString() == notificationId) {
            notifications[i]['is_read'] = '1';
            break;
          }
        }
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  void _handleNotificationTap(dynamic notification) {
    if (notification == null) return;

    // Debugging
    print('Handling notification tap: $notification');

    // Mark as read if not already read
    final notificationId = notification['id']?.toString();
    if (notificationId != null) {
      final bool isRead =
          notification['is_read'] == 1 ||
          notification['is_read'] == '1' ||
          notification['status'] == 'read';

      if (!isRead) {
        _markAsRead(notificationId);
      }
    }

    // Get the type and reference
    final String type = notification['type']?.toString() ?? 'general';
    final String refId = notification['reference_id']?.toString() ?? '';

    print('Notification type: $type, refId: $refId');

    // Handle different notification types
    if (refId.isNotEmpty) {
      switch (type) {
        case 'order_created':
        case 'order_cancelled':
        case 'order_paid':
        case 'order_shipped':
        case 'order_delivered':
          // All order-related notifications navigate to order detail
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      OrderDetailScreen(orderId: refId, userId: widget.userId),
            ),
          ).then((_) => _loadNotifications()); // Refresh after returning
          break;

        // Add more cases for other notification types as needed
        default:
          print('Unhandled notification type: $type');
      }
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'order_created':
        return Colors.blue;
      case 'order_cancelled':
        return Colors.red;
      case 'order_shipped':
        return Colors.orange;
      case 'order_delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'order_created':
        return Icons.add_shopping_cart;
      case 'order_cancelled':
        return Icons.cancel;
      case 'order_shipped':
        return Icons.local_shipping;
      case 'order_delivered':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.green),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : notifications.isEmpty
              ? const Center(child: Text('Tidak ada notifikasi'))
              : ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  // Improved null safety and data type handling
                  final bool isRead =
                      notification['is_read'] == 1 ||
                      notification['is_read'] == '1';
                  final String type =
                      notification['type']?.toString() ?? 'general';
                  final Color typeColor = _getNotificationColor(type);
                  final IconData typeIcon = _getNotificationIcon(type);

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    elevation: isRead ? 1 : 3,
                    color: isRead ? Colors.white : Colors.grey.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color:
                            isRead
                                ? Colors.transparent
                                : typeColor.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        backgroundColor: typeColor.withOpacity(0.2),
                        child: Icon(typeIcon, color: typeColor),
                      ),
                      title: Text(
                        notification['title'] ?? 'Notifikasi',
                        style: TextStyle(
                          fontWeight:
                              isRead ? FontWeight.normal : FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            notification['message'] ?? '',
                            style: TextStyle(color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDate(notification['created_at']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _handleNotificationTap(notification),
                    ),
                  );
                },
              ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy HH:mm').format(dateTime);
    } catch (e) {
      return dateStr;
    }
  }
}
