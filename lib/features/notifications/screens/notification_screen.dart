import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  }

  @override
  void dispose() {
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
        _selectedNotificationIds = _notifications.map((n) => n['id'].toString()).toSet();
      }
    });
  }

  Future<void> _deleteSelected() async {
    final selectedIds = _selectedNotificationIds.toList();
    _cancelSelection();
    
    // Backup data
    final backup = _notifications.where((n) => selectedIds.contains(n['id'].toString())).toList();
    
    setState(() {
      _notifications.removeWhere((n) => selectedIds.contains(n['id'].toString()));
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
            _notifications.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
          });
        }
      });
    }

    final earlyResult = await Future.any([
      Future.delayed(const Duration(seconds: 10), () => false),
      completer.future,
    ]);
    
    _pendingDeletes.remove(completer);
    if (isUndone || earlyResult) return;

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    try {
      await ApiClient().dio.post('/notifications/delete-multiple', data: {'ids': selectedIds});
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
      await ApiClient().dio.put('/notifications/mark-read-multiple', data: {'ids': selectedIds});
    } catch (e) {
      debugPrint('Err Mark Read Selected: $e');
    }
  }

  Future<void> _deleteSingle(String id) async {
    final backupIndex = _notifications.indexWhere((n) => n['id'].toString() == id);
    if (backupIndex == -1) return;
    
    final backup = _notifications[backupIndex];
    
    setState(() {
      _notifications.removeAt(backupIndex);
    });
    
    bool isUndone = false;
    final completer = Completer<bool>();
    _pendingDeletes.add(completer);

    if (mounted) {
      showUndoSnackBar(context, 'Notifikasi dihapus', () {
        isUndone = true;
        if (!completer.isCompleted) completer.complete(true);
        if (mounted) {
          setState(() {
            _notifications.insert(backupIndex, backup);
          });
        }
      });
    }

    final earlyResult = await Future.any([
      Future.delayed(const Duration(seconds: 10), () => false),
      completer.future,
    ]);
    
    _pendingDeletes.remove(completer);
    if (isUndone || earlyResult) return;

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    try {
      await ApiClient().dio.delete('/notifications/$id');
    } catch (e) {
      debugPrint('Err Delete Single: $e');
      if (mounted) _fetchNotifications();
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

  Future<void> _markAllAsRead() async {
    try {
      await ApiClient().dio.put('/notifications/mark-all-read');
      await NotificationService.cancelAllNotifications();
    } catch (e) {
      debugPrint('Err Mark All As Read: $e');
    }
  }

  Future<void> _markSingleAsRead(String notificationId) async {
    try {
      await ApiClient().dio.put('/notifications/$notificationId', data: {'is_read': true});
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
                      child: Center(child: CircularProgressIndicator(color: AppColors.primaryTeal)),
                    )
                  : _notifications.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                  'No notifications yet',
                                  style: GoogleFonts.outfit(color: Colors.grey[400]),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => NotificationCard(
                              notification: _notifications[index],
                              isSelectionMode: _isSelectionMode,
                              isSelected: _selectedNotificationIds.contains(_notifications[index]['id'].toString()),
                              onLongPress: () {
                                if (!_isSelectionMode) {
                                  _enterSelectionMode();
                                  setState(() {
                                    _selectedNotificationIds.add(_notifications[index]['id'].toString());
                                  });
                                }
                              },
                              onTap: () {
                                if (_isSelectionMode) {
                                  setState(() {
                                    final id = _notifications[index]['id'].toString();
                                    if (_selectedNotificationIds.contains(id)) {
                                      _selectedNotificationIds.remove(id);
                                    } else {
                                      _selectedNotificationIds.add(id);
                                    }
                                  });
                                }
                              },
                              confirmDismiss: (direction) async {
                                _deleteSingle(_notifications[index]['id'].toString());
                                return true;
                              },
                            ),
                            childCount: _notifications.length,
                          ),
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
