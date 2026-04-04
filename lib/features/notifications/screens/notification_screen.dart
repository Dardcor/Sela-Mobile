import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/colors.dart';
import '../widgets/notification_widgets.dart';

import '../../../core/services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<dynamic> _notifications = [];
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _setupRealtimeListener();
    NotificationService.setupGlobalListener(); // Extra insurance
  }

  void _setupRealtimeListener() {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    _realtimeChannel = supabase.channel('notification-screen-${user.id}');

    _realtimeChannel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: user.id,
      ),
      callback: (payload) {
        debugPrint('Realtime: New notification received!');
        if (mounted) {
          setState(() {
            // Sisipkan notifikasi baru di paling atas
            _notifications.insert(0, payload.newRecord);
          });
          // Tandai langsung sebagai dibaca karena layar sedang terbuka
          _markSingleAsRead(payload.newRecord['id']);
        }
      },
    );

    _realtimeChannel!.subscribe((status, [error]) {
      debugPrint('Notification Screen Realtime: $status');
      if (error != null) debugPrint('Notification Screen Realtime Error: $error');
    });
  }

  @override
  void dispose() {
    if (_realtimeChannel != null) {
      supabase.removeChannel(_realtimeChannel!);
    }
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _notifications = data as List;
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
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Err Mark All As Read: $e');
    }
  }

  Future<void> _markSingleAsRead(String notificationId) async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
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
              child: NotificationHeader(onBack: () => Navigator.pop(context)),
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
