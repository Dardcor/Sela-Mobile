import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../core/constants/colors.dart';
import '../widgets/notification_widgets.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/services/api_client.dart';

import '../../../core/services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = true;
  List<dynamic> _notifications = [];
  StreamSubscription<RemoteMessage>? _messageSubscription;

  bool _isSelectionMode = false;
  Set<String> _selectedNotificationIds = {};
  final Set<Completer<bool>> _pendingDeletes = {};

  Future<void> _forceExecutePendingDeletes() async {
    if (_pendingDeletes.isEmpty) return;
    for (var completer in _pendingDeletes) {
      if (!completer.isCompleted) completer.complete(false);
    }
    _pendingDeletes.clear();
    ScaffoldMessenger.of(context).clearSnackBars();
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  void initState() {
    super.initState();
    _fetchNotifications();

    _messageSubscription = FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) {
      if (!mounted) return;

      // Optimistically prepend from FCM payload for instant UI update
      final notification = message.notification;
      final data = message.data;
      if (notification != null) {
        final optimistic = {
          'id': data['notification_id'] ?? message.hashCode.toString(),
          'title': notification.title ?? 'Sela',
          'message': notification.body ?? '',
          'type': data['type'] ?? 'system',
          'related_id': data['related_id'],
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        };

        setState(() {
          // Avoid duplicate if already present
          final exists = _notifications.any(
            (n) => n['id'].toString() == optimistic['id'].toString(),
          );
          if (!exists) {
            _notifications.insert(0, optimistic);
          }
        });
      }

      // Background sync to get authoritative data from server
      _fetchNotifications();
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedNotificationIds.clear();
    });
  }

  void _cancelSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedNotificationIds.clear();
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedNotificationIds.length == _notifications.length) {
        _selectedNotificationIds.clear();
      } else {
        _selectedNotificationIds = _notifications
            .map((n) => n['id'].toString())
            .toSet();
      }
    });
  }

  Future<void> _deleteSelected() async {
    final selectedIds = _selectedNotificationIds.toList();
    _cancelSelection();

    // Backup data
    final backup = _notifications
        .where((n) => selectedIds.contains(n['id'].toString()))
        .toList();

    setState(() {
      _notifications.removeWhere(
        (n) => selectedIds.contains(n['id'].toString()),
      );
    });

    bool isUndone = false;
    final completer = Completer<bool>();
    _pendingDeletes.add(completer);

    if (mounted) {
      showUndoSnackBar(context, '${selectedIds.length} notifikasi dihapus', () {
        isUndone = true;
        if (!completer.isCompleted) completer.complete(true);
        if (mounted) {
          setState(() {
            _notifications.insertAll(0, backup);
            // Assuming we still have created_at from backend.
            _notifications.sort(
              (a, b) => DateTime.parse(
                b['created_at'],
              ).compareTo(DateTime.parse(a['created_at'])),
            );
          });
        }
      });
    }

    final earlyResult = await Future.any([
      Future.delayed(const Duration(seconds: 3), () => false),
      completer.future,
    ]);

    _pendingDeletes.remove(completer);
    if (isUndone || earlyResult) return;

    try {
      await ApiClient().dio.post(
        '/notifications/delete-multiple',
        data: {'ids': selectedIds},
      );
    } catch (e) {
      debugPrint('Err Delete Selected: $e');
      if (mounted) _fetchNotifications();
    }
  }

  Future<void> _markReadSelected() async {
    final selectedIds = _selectedNotificationIds.toList();
    _cancelSelection();

    setState(() {
      for (var n in _notifications) {
        if (selectedIds.contains(n['id'].toString())) {
          n['is_read'] = true;
        }
      }
    });

    try {
      await ApiClient().dio.put(
        '/notifications/mark-read-multiple',
        data: {'ids': selectedIds},
      );
    } catch (e) {
      debugPrint('Err Mark Read Selected: $e');
    }
  }

  Future<void> _fetchNotifications() async {
    await _forceExecutePendingDeletes();
    try {
      final response = await ApiClient().dio.get('/notifications');

      if (mounted) {
        setState(() {
          _notifications = response.data['notifications'] ?? [];
          _isLoading = false;
        });
        // Tandai semua sebagai dibaca setelah data dimuat
        _markAllAsRead();
      }
    } catch (e) {
      debugPrint('Err Notifications: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleJoinRequest(
    String reqId,
    String notifId,
    bool isAccept,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryTeal),
        ),
      );

      final action = isAccept ? 'accept' : 'reject';
      await ApiClient().dio.post('/group-join-requests/$reqId/$action');

      // Delete the notification so it doesn't stay there
      await ApiClient().dio.delete('/notifications/$notifId');

      if (mounted) {
        Navigator.pop(context); // close dialog
        setState(() {
          _notifications.removeWhere((n) => n['id'].toString() == notifId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAccept
                  ? 'Permintaan bergabung diterima'
                  : 'Permintaan bergabung ditolak',
            ),
            backgroundColor: isAccept ? AppColors.primaryTeal : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses permintaan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await ApiClient().dio.put('/notifications/mark-all-read');
      await NotificationService.cancelAllNotifications();
    } catch (e) {
      debugPrint('Err Mark All As Read: $e');
    }
  }

  Future<void> _deleteSingleNotification(String notificationId) async {
    // Backup data untuk fitur URUNGKAN (Undo)
    final indexToRestore = _notifications.indexWhere(
      (n) => n['id'].toString() == notificationId,
    );
    if (indexToRestore == -1) return;

    final backupData = _notifications[indexToRestore];

    // Hapus sementara dari layar (Optimistic UI)
    setState(() {
      _notifications.removeAt(indexToRestore);
    });

    bool isUndone = false;
    final completer = Completer<bool>();
    _pendingDeletes.add(completer);

    if (mounted) {
      showUndoSnackBar(context, '1 notifikasi dihapus', () {
        isUndone = true;
        if (!completer.isCompleted) completer.complete(true);
        if (mounted) {
          setState(() {
            _notifications.insert(indexToRestore, backupData);
          });
        }
      });
    }

    final earlyResult = await Future.any([
      Future.delayed(const Duration(seconds: 3), () => false),
      completer.future,
    ]);

    _pendingDeletes.remove(completer);
    if (isUndone || earlyResult) return;

    try {
      // Menjalankan API asli di belakang layar setelah jeda Undo berakhir
      await ApiClient().dio.post(
        '/notifications/delete-multiple',
        data: {
          'ids': [notificationId],
        },
      );
    } catch (e) {
      debugPrint('Err Delete Single: $e');
      if (mounted) _fetchNotifications();
    }
  }

  Future<void> _markSingleAsRead(String notificationId) async {
    try {
      await ApiClient().dio.put(
        '/notifications/$notificationId',
        data: {'is_read': true},
      );
      await NotificationService.cancelAllNotifications();
    } catch (e) {
      debugPrint('Err Mark Single As Read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: RefreshIndicator(
        onRefresh: _fetchNotifications,
        color: AppColors.primaryTeal,
        edgeOffset: MediaQuery.of(context).padding.top + 10,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header - Now part of scroll view to allow pull-to-refresh from top
            SliverToBoxAdapter(
              child: NotificationHeader(
                onBack: () => Navigator.pop(context),
                isSelectionMode: _isSelectionMode,
                selectedCount: _selectedNotificationIds.length,
                totalCount: _notifications.length,
                onCancelSelection: _cancelSelection,
                onSelectAll: _selectAll,
                onDeleteSelected: _deleteSelected,
                onMarkReadSelected: _markReadSelected,
                onEnterSelectionMode: _enterSelectionMode,
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(25, 10, 25, 30),
              sliver: _isLoading
                  ? const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    )
                  : _notifications.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada notifikasi',
                              style: GoogleFonts.outfit(
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final notif = _notifications[index];
                        return NotificationCard(
                          notification: notif,
                          isSelectionMode: _isSelectionMode,
                          isSelected: _selectedNotificationIds.contains(
                            notif['id'].toString(),
                          ),
                          onAccept: () {
                            _handleJoinRequest(
                              notif['related_id'].toString(),
                              notif['id'].toString(),
                              true,
                            );
                          },
                          onReject: () {
                            _handleJoinRequest(
                              notif['related_id'].toString(),
                              notif['id'].toString(),
                              false,
                            );
                          },
                          onLongPress: () {
                            if (!_isSelectionMode) {
                              _enterSelectionMode();
                              setState(() {
                                _selectedNotificationIds.add(
                                  notif['id'].toString(),
                                );
                              });
                            }
                          },
                          onTap: () {
                            if (_isSelectionMode) {
                              setState(() {
                                final id = notif['id'].toString();
                                if (_selectedNotificationIds.contains(id)) {
                                  _selectedNotificationIds.remove(id);
                                } else {
                                  _selectedNotificationIds.add(id);
                                }
                              });
                            }
                          },
                          onDismissed: () {
                            _deleteSingleNotification(notif['id'].toString());
                          },
                        );
                      }, childCount: _notifications.length),
                    ),
            ),
            // Bottom spacing similar to dashboard
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }
}
