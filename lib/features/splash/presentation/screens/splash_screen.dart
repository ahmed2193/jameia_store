import 'package:flutter/material.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// KeeTa-style brand splash: full yellow with the wordmark, then routes to the
/// main shell. (Dummy data is already loaded in setupServiceLocator.)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.shell);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delivery_dining_rounded, size: 72, color: AppColors.black),
            SizedBox(height: 12),
            Text('KeeTa',
                style: TextStyle(
                  fontFamily: 'KeeTa',
                  fontSize: 42,
                  fontWeight: AppTextStyles.bold,
                  color: AppColors.black,
                  letterSpacing: 1,
                )),
          ],
        ),
      ),
    );
  }
}
