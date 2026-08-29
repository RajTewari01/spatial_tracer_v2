import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  final bool hasSeenOnboarding;
  const SplashScreen({super.key, required this.hasSeenOnboarding});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(
            builder: (context) => widget.hasSeenOnboarding
                ? const DashboardScreen()
                : const OnboardingScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Text(
                'Spatial Tracer',
                style: GoogleFonts.pacifico(
                  fontSize: 48,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Text(
                  'Alypion',
                  style: TextStyle(
                    fontSize: 16,
                    letterSpacing: 3.0,
                    fontWeight: FontWeight.w500,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
