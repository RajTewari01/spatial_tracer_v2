import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'db_helper.dart';
import 'screens/creator_profile.dart';
import 'screens/splash_screen.dart';
import 'screens/settings_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: CupertinoColors.transparent),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: SpatialTracerApp(hasSeenOnboarding: hasSeenOnboarding),
    ),
  );
}

class SpatialTracerApp extends StatelessWidget {
  final bool hasSeenOnboarding;
  const SpatialTracerApp({super.key, required this.hasSeenOnboarding});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return CupertinoApp(
      title: 'Spatial Tracer',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: themeProvider.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: SplashScreen(hasSeenOnboarding: hasSeenOnboarding),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  INTERACTIVE ONBOARDING SCREEN
// ═══════════════════════════════════════════════════════════════
class OnboardingScreen extends StatefulWidget {
  final bool isFromSettings;
  const OnboardingScreen({super.key, this.isFromSettings = false});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const _methodChannel = MethodChannel('com.rajtewari/hand_tracker');
  static const _eventChannel = EventChannel('com.rajtewari/gesture_stream');
  StreamSubscription? _gestureSubscription;
  bool _isSuccessAnim = false;

  final List<Map<String, dynamic>> _pages = [
    {
      'icon': CupertinoIcons.hand_draw,
      'title': 'Pinch to click',
      'subtitle': 'Touch your index finger and thumb together.',
      'requiredGesture': 'PINCH',
      'color': CupertinoColors.systemOrange,
    },
    {
      'icon': CupertinoIcons.hand_point_right,
      'title': 'Swipe to scroll',
      'subtitle': 'Flick your open hand horizontally in mid-air.',
      'requiredGesture': 'SWIPE',
      'color': CupertinoColors.systemPurple,
    },
    {
      'icon': CupertinoIcons.hand_raised,
      'title': 'Open hand',
      'subtitle': 'Hold your palm flat to pause or return home.',
      'requiredGesture': 'OPEN_HAND',
      'color': CupertinoColors.systemRed,
    },
  ];

  @override
  void initState() {
    super.initState();
    _startTrackerForOnboarding();
  }

  Future<void> _startTrackerForOnboarding() async {
    try {
      final status = await Permission.camera.request();
      if (status.isGranted) {
        await _methodChannel.invokeMethod('startService', {
          'useHand': true,
          'useFace': false,
        });
        _gestureSubscription = _eventChannel.receiveBroadcastStream().listen((gesture) {
          _handleLiveGesture(gesture.toString());
        });
      }
    } catch (e) {
      debugPrint("Onboarding Tracker Error: $e");
    }
  }

  void _handleLiveGesture(String gesture) {
    if (_isSuccessAnim) return;
    final requiredGesture = _pages[_currentPage]['requiredGesture'];
    if (gesture == requiredGesture) {
      _triggerSuccessAndAdvance();
    }
  }

  Future<void> _triggerSuccessAndAdvance() async {
    setState(() => _isSuccessAnim = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    
    if (_currentPage == _pages.length - 1) {
      _completeOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 800),
        curve: Curves.fastOutSlowIn,
      );
      setState(() => _isSuccessAnim = false);
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (!mounted) return;
    if (widget.isFromSettings) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

  @override
  void dispose() {
    _gestureSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.scaffoldBackgroundColor,
                    isDark ? const Color(0xFF000000) : const Color(0xFFE8F5E9)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Top Navigation Row
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      GestureDetector(
                        onTap: () {
                          if (_currentPage > 0) {
                            _pageController.previousPage(duration: const Duration(milliseconds: 600), curve: Curves.fastOutSlowIn);
                          } else if (widget.isFromSettings) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: (_currentPage == 0 && !widget.isFromSettings) ? 0.0 : 1.0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(CupertinoIcons.chevron_back, color: isDark ? Colors.white : Colors.black87, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      (_currentPage == 0 && widget.isFromSettings) ? "Close" : "Back",
                                      style: TextStyle(
                                        color: isDark ? Colors.white : Colors.black87,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Skip Button
                      GestureDetector(
                        onTap: _completeOnboarding,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
                              ),
                              child: Text(
                                "Skip",
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (idx) => setState(() => _currentPage = idx),
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOutBack,
                              padding: const EdgeInsets.all(10),
                              child: Icon(
                                _isSuccessAnim ? CupertinoIcons.check_mark : page['icon'], 
                                size: 140, 
                                color: _isSuccessAnim ? CupertinoColors.activeGreen : (isDark ? Colors.white : Colors.black87),
                              ),
                            ),
                            const SizedBox(height: 60),
                            Text(
                              _isSuccessAnim ? "Perfect." : page['title'],
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 48, 
                                fontWeight: FontWeight.w200,
                                letterSpacing: -1.5,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _isSuccessAnim ? "Gesture recognized seamlessly." : page['subtitle'],
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                color: isDark ? Colors.white60 : Colors.black54,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 60),
                            if (!_isSuccessAnim) 
                              const CupertinoActivityIndicator(radius: 14),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                // Minimalist Next / Done Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: GestureDetector(
                    onTap: () {
                      if (_currentPage == _pages.length - 1) {
                        _completeOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.fastOutSlowIn,
                        );
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      decoration: BoxDecoration(
                        color: _currentPage == _pages.length - 1 
                            ? (isDark ? Colors.white : Colors.black)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: _currentPage == _pages.length - 1 
                              ? Colors.transparent
                              : (isDark ? Colors.white30 : Colors.black26),
                          width: 1,
                        )
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentPage == _pages.length - 1 ? "Get Started" : "Next step",
                            style: TextStyle(
                              color: _currentPage == _pages.length - 1 
                                  ? (isDark ? Colors.black : Colors.white)
                                  : (isDark ? Colors.white : Colors.black87),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentPage == _pages.length - 1 ? CupertinoIcons.check_mark : CupertinoIcons.arrow_right,
                            color: _currentPage == _pages.length - 1 
                                ? (isDark ? Colors.black : Colors.white)
                                : (isDark ? Colors.white : Colors.black87),
                            size: 16,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  DASHBOARD SCREEN (PINTEREST APPLE AESTHETICS)
// ═══════════════════════════════════════════════════════════════
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _methodChannel = MethodChannel('com.rajtewari/hand_tracker');
  bool _isActive = false;
  bool _useHandTracking = true;
  bool _useFaceTracking = false;
  
  Timer? _uptimeTimer;
  Timer? _clockTimer;
  
  int _uptimeSeconds = 0;
  String _currentTimeString = "";
  
  int? _currentSessionId;
  DateTime? _sessionStartTime;
  DateTime? _lastEndTime;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadDatabaseInfo();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateClock();
    });
  }

  void _updateClock() {
    if (mounted) {
      setState(() {
        _currentTimeString = DateFormat('hh:mm:ss a').format(DateTime.now());
      });
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _useHandTracking = prefs.getBool('use_hand_tracking') ?? true;
        _useFaceTracking = prefs.getBool('use_face_tracking') ?? false;
      });
    }
  }
  
  Future<void> _loadDatabaseInfo() async {
    final activeSession = await DatabaseHelper.instance.getActiveSession();
    if (activeSession != null) {
      if (mounted) {
        setState(() {
          _isActive = true;
          _currentSessionId = activeSession['id'] as int;
          _sessionStartTime = DateTime.parse(activeSession['start_time'] as String);
          _uptimeSeconds = DateTime.now().difference(_sessionStartTime!).inSeconds;
          
          _uptimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            setState(() {
              _uptimeSeconds++;
            });
          });
        });
      }
    }

    final lastSession = await DatabaseHelper.instance.getLastCompletedSession();
    if (lastSession != null && lastSession['end_time'] != null) {
      if (mounted) {
        setState(() {
          _lastEndTime = DateTime.parse(lastSession['end_time'] as String);
        });
      }
    }
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  void dispose() {
    _uptimeTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  String _formatUptime(int totalSeconds) {
    int h = totalSeconds ~/ 3600;
    int m = (totalSeconds % 3600) ~/ 60;
    int s = totalSeconds % 60;
    if (h > 0) {
      return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    }
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  Future<void> _toggleService() async {
    try {
      if (_isActive) {
        await _methodChannel.invokeMethod('stopService');
        
        // Save End Time to SQLite
        final endTime = DateTime.now();
        if (_currentSessionId != null) {
          await DatabaseHelper.instance.endSession(_currentSessionId!, endTime);
        }
        
        setState(() {
          _isActive = false;
          _uptimeTimer?.cancel();
          _lastEndTime = endTime;
          _sessionStartTime = null;
        });
      } else {
        final cameraStatus = await Permission.camera.request();
        if (!cameraStatus.isGranted) return;

        await _methodChannel.invokeMethod('startService', {
          'useHand': _useHandTracking,
          'useFace': _useFaceTracking,
        });
        
        // Save Start Time to SQLite
        final startTime = DateTime.now();
        final sessionId = await DatabaseHelper.instance.startSession(startTime);
        
        setState(() {
          _isActive = true;
          _currentSessionId = sessionId;
          _sessionStartTime = startTime;
          _uptimeSeconds = 0;
          _uptimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            setState(() {
              _uptimeSeconds++;
            });
          });
        });
      }
    } on PlatformException catch (e) {
      debugPrint("ERR: Start failed - \${e.message}");
    }
  }

  void _openAccessibilitySettings() {
    _methodChannel.invokeMethod('openAccessibilitySettings');
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final textColor = theme.textTheme.textStyle.color;

    return CupertinoPageScaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Stack(
        children: [
          // Background Gradient to add depth
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.scaffoldBackgroundColor,
                    isDark ? const Color(0xFF000000) : const Color(0xFFE8F5E9)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Custom Floating Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: _openAccessibilitySettings,
                        child: _buildGlassIcon(CupertinoIcons.person_crop_circle, isDark),
                      ),
                      Text(
                        "spatial tracer", 
                        style: GoogleFonts.pacifico(
                          fontSize: 24, 
                          color: isDark ? Colors.white : const Color(0xFF051911),
                        )
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, CupertinoPageRoute(builder: (_) => const SettingsScreen()));
                        },
                        child: _buildGlassIcon(CupertinoIcons.settings, isDark),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Massive Typography: The Timer
                Text(
                  _isActive ? _formatUptime(_uptimeSeconds) : "00:00:00",
                  style: GoogleFonts.inter(
                    fontSize: 72,
                    fontWeight: FontWeight.w200,
                    letterSpacing: -2.0,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Humanized Status Text
                Text(
                  _isActive ? "Recording" : "Ready",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 2.0,
                    color: _isActive 
                        ? (isDark ? Colors.white70 : Colors.black54) 
                        : (isDark ? Colors.white30 : Colors.black38),
                  ),
                ),

                const SizedBox(height: 60),

                // Apple-style Control Toggle
                GestureDetector(
                  onTap: _toggleService,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    width: _isActive ? 160 : 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: _isActive 
                          ? CupertinoColors.destructiveRed.withOpacity(isDark ? 0.8 : 0.9)
                          : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
                      borderRadius: BorderRadius.circular(45),
                      border: Border.all(
                        color: _isActive 
                            ? CupertinoColors.destructiveRed 
                            : (isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1)),
                        width: 1.5,
                      )
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isActive ? CupertinoIcons.square_fill : CupertinoIcons.play_fill,
                            size: 28,
                            color: _isActive ? Colors.white : (isDark ? Colors.white : Colors.black87),
                          ),
                          if (_isActive) ...[
                            const SizedBox(width: 8),
                            Text(
                              "Stop",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          ]
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(),
                
                // Minimalist iOS Widget for Telemetry
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildInfoColumn("Start Time", _sessionStartTime != null 
                                ? DateFormat('h:mm a').format(_sessionStartTime!) 
                                : "--:--", isDark),
                            Container(width: 1, height: 40, color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
                            _buildInfoColumn("Last Session", _lastEndTime != null 
                                ? DateFormat('h:mm a').format(_lastEndTime!) 
                                : "--:--", isDark),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGlassIcon(IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Icon(icon, color: isDark ? Colors.white : Colors.black87, size: 28),
    );
  }

  Widget _buildInfoColumn(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}
