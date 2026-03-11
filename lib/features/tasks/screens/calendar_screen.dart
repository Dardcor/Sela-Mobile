import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/shared_widgets/app_bottom_nav_bar.dart';
import '../widgets/calendar_widgets.dart';

/// CalendarScreen — Kerangka layar kalender.
///
/// File ini hanya berisi susunan komponen dan logika navigasi.
/// Semua widget UI didelegasikan ke [calendar_widgets.dart] untuk:
/// - Keterbacaan yang lebih baik (file lebih pendek & bersih)
/// - Isolasi rebuild: jika kalender berubah, layar lain tidak ikut di-render ulang
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  // Data jadwal statis (sementara — dapat diganti dengan data dari Supabase)
  static const _schedules = [
    {'title': 'Ecomerse AWS', 'subtitle': 'Workshop Aplikasi dan Komputasi Awan', 'isGroup': true},
    {'title': 'Ecomerse AWS', 'subtitle': 'Workshop Aplikasi dan Komputasi Awan', 'isGroup': false},
    {'title': 'Ecomerse AWS', 'subtitle': 'Workshop Aplikasi dan Komputasi Awan', 'isGroup': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F9),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ✅ Header navigasi diisolasi — rebuild terpisah dari konten kalender
              const SliverToBoxAdapter(child: CalendarTopBar()),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              // ✅ Judul + filter bulan diisolasi
              const SliverToBoxAdapter(child: CalendarTitleSection()),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              // ✅ Kalender utama diisolasi — rebuild hanya saat tanggal berubah
              const SliverToBoxAdapter(child: CalendarCard()),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
              // ✅ Header list jadwal diisolasi
              const SliverToBoxAdapter(child: CalendarScheduleHeader()),
              const SliverToBoxAdapter(child: SizedBox(height: 15)),
              // ✅ Setiap item jadwal adalah widget terpisah — rebuild terisolasi per item
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final s = _schedules[index];
                      return ScheduleItem(
                        title: s['title'] as String,
                        subtitle: s['subtitle'] as String,
                        isGroup: s['isGroup'] as bool,
                      );
                    },
                    childCount: _schedules.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          const AppBottomNavBar(currentIndex: 1),
        ],
      ),
    );
  }
}
