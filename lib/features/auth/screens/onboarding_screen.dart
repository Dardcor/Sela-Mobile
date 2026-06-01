import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/colors.dart';
import 'auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "title": "Tugas kelompok\nsering tidak merata?",
      "subtitle": "Kelola dan bagi tugas dengan lebih mudah bersama SELA.",
      "image": "assets/images/onboarding_1.svg"
    },
    {
      "title": "Bagikan tugas dengan\nbantuan AI",
      "subtitle": "AI membagi tugas secara otomatis agar lebih adil dan sesuai kemampuan setiap anggota.",
      "image": "assets/images/onboarding_2.svg"
    },
    {
      "title": "Pantau progres tim\nsecara real-time",
      "subtitle": "Pantau progres dan keaktifan tim secara transparan.",
      "image": "assets/images/onboarding_3.svg"
    },
    {
      "title": "Kerja tim tanpa drama\ndan lebih teratur",
      "subtitle": "Mulai kelola tugas kelompokmu dengan cara yang lebih adil, cepat, dan efisien.",
      "image": "assets/images/onboarding_4.svg"
    },
  ];

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataStr = prefs.getString('user_data');
    if (userDataStr != null) {
      final userData = jsonDecode(userDataStr);
      final email = userData['email'];
      await prefs.setBool('has_seen_onboarding_$email', true);
    }

    if (!mounted) return;
    
    // Redirect ke dashboard atau navbar lecturer
    final userData = jsonDecode(prefs.getString('user_data') ?? '{}');
    if (userData['role'] == 'lecturer') {
      Navigator.pushReplacementNamed(context, '/lecturer_navbar');
    } else {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_currentPage != onboardingData.length - 1)
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: Text(
                        "Lewati",
                        style: GoogleFonts.poppins(
                          color: AppColors.primaryTeal,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 48), // Alignment placeholder
                ],
              ),
            ),

            // Illustration and Text Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (value) {
                  setState(() {
                    _currentPage = value;
                  });
                },
                itemCount: onboardingData.length,
                itemBuilder: (context, index) {
                  return OnboardingContent(
                    title: onboardingData[index]["title"]!,
                    subtitle: onboardingData[index]["subtitle"]!,
                    image: onboardingData[index]["image"]!,
                  );
                },
              ),
            ),

            // Dot Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                onboardingData.length,
                (index) => buildDot(index: index),
              ),
            ),
            const SizedBox(height: 30),

            // Bottom Navigation Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: _currentPage == onboardingData.length - 1
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _finishOnboarding,
                        child: Text(
                          "Mulai Sekarang",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: _currentPage == 0
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentPage != 0)
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryTeal,
                              side: const BorderSide(
                                  color: AppColors.primaryTeal, width: 1.5),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.arrow_back_ios, size: 14),
                            label: Text(
                              "Kembali",
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.ease,
                              );
                            },
                          ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryTeal,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.ease,
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Selanjutnya",
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_ios,
                                  size: 14, color: Colors.white),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      height: 10,
      width: 10,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? AppColors.primaryTeal
            : Colors.transparent,
        border: Border.all(color: AppColors.primaryTeal, width: 1.5),
        shape: BoxShape.circle,
      ),
    );
  }
}

class OnboardingContent extends StatelessWidget {
  final String title;
  final String subtitle;
  final String image;

  const OnboardingContent({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.image,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // Gambar Ilustrasi
          SvgPicture.asset(
            image,
            height: 280,
            fit: BoxFit.contain,
          ),
          const Spacer(flex: 1),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryTeal,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.primaryTeal.withOpacity(0.9),
                  height: 1.5,
                ),
                children: _buildSubtitleTextSpans(subtitle),
              ),
            ),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  List<TextSpan> _buildSubtitleTextSpans(String text) {
    if (text.contains("SELA.")) {
      List<String> parts = text.split("SELA.");
      return [
        TextSpan(text: parts[0]),
        TextSpan(
          text: "SELA.",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        if (parts.length > 1) TextSpan(text: parts[1]),
      ];
    }
    return [TextSpan(text: text)];
  }
}
