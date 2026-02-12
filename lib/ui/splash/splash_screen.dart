import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'splash_viewmodel.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SplashViewModel>().checkSessionAndNavigate(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.blue,
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(),

              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // const FlutterLogo(size: 120),
                    Image.asset('assets/app_icon.png', width: 120, height: 120),
                    const SizedBox(height: 16),
                    const Text(
                      "SIPA",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
              const Text(
                "©2026",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Text(
                "v1.0.0",
                style: TextStyle(color: Colors.white54, fontSize: 10),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
