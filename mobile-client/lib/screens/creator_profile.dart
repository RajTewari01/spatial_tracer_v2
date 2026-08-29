import 'dart:ui';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class CreatorProfileScreen extends StatefulWidget {
  const CreatorProfileScreen({super.key});

  @override
  State<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  
  late AnimationController _parallaxController;
  late Animation<double> _horizontalOffset;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });

    _parallaxController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
    
    _horizontalOffset = Tween<double>(begin: 0.0, end: 1.0).animate(_parallaxController);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _parallaxController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not launch $urlString");
    }
  }

  Future<void> _openCV() async {
    try {
      final byteData = await rootBundle.load('assets/docs/CV.pdf');
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/Biswadeep_Tewari_CV.pdf');
      await tempFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
      await OpenFilex.open(tempFile.path);
    } catch (e) {
      debugPrint("Error opening CV: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    
    // Monochrome Dark / Green & Gold Light
    final bgDark = const Color(0xFF000000);
    final bgLight = const Color(0xFFF1F8E9); // Soft Green
    final accent = isDark ? const Color(0xFFEBEBEF) : const Color(0xFFD4AF37); // Frost or Gold

    return Material(
      type: MaterialType.transparency,
      child: Scaffold(
        backgroundColor: isDark ? bgDark : bgLight,
        body: Stack(
          children: [
            // Background 3-Layer Moving Mountains Parallax
            AnimatedBuilder(
              animation: _horizontalOffset,
              builder: (context, child) {
                return _buildMovingParallaxMountains(isDark, _horizontalOffset.value);
              }
            ),

            // Scrollable Content
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 400,
                  pinned: true,
                  stretch: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: IconThemeData(
                    color: isDark ? Colors.white : Colors.black87
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Floating Chinese Characters Parallax
                        Positioned(
                          top: 100 - (_scrollOffset * 0.4),
                          right: 40,
                          child: Text("禅", style: TextStyle(fontSize: 80, color: (isDark ? Colors.white : Colors.black).withOpacity(0.04), fontWeight: FontWeight.bold)),
                        ),
                        Positioned(
                          top: 220 - (_scrollOffset * 0.6),
                          left: 30,
                          child: Text("道", style: TextStyle(fontSize: 100, color: (isDark ? Colors.white : Colors.black).withOpacity(0.02), fontWeight: FontWeight.bold)),
                        ),

                        // Avatar & Name Container
                        Positioned(
                          bottom: 30,
                          left: 0, right: 0,
                          child: Column(
                            children: [
                              Hero(
                                tag: 'creator_avatar',
                                child: Container(
                                  width: 130, height: 130,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withOpacity(isDark ? 0.2 : 0.8), width: 3),
                                    image: const DecorationImage(
                                      image: AssetImage('assets/images/raj_profile.jpg'),
                                      fit: BoxFit.cover,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accent.withOpacity(isDark ? 0.1 : 0.3),
                                        blurRadius: 40, spreadRadius: 10
                                      )
                                    ]
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "Biswadeep Tewari",
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.0,
                                  color: isDark ? Colors.white : Colors.black87,
                                  shadows: [
                                    Shadow(color: isDark ? Colors.black54 : Colors.white70, blurRadius: 15)
                                  ]
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: accent.withOpacity(0.3))
                                ),
                                child: Text(
                                  "AI ARCHITECT & ENGINEER",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2.5,
                                    color: accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        
                        // CV Download Button
                        GestureDetector(
                          onTap: _openCV,
                          child: _buildIphoneGlassCard(
                            context: context,
                            isDark: isDark,
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CupertinoIcons.doc_text_viewfinder, color: accent, size: 24),
                                const SizedBox(width: 12),
                                Text(
                                  "View Professional CV",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(CupertinoIcons.chevron_forward, color: isDark ? Colors.white54 : Colors.black54, size: 16)
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Layer 1
                        _buildIphoneGlassCard(
                          context: context,
                          isDark: isDark,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader(context, "A Dialogue with Machines", Icons.auto_awesome_rounded, accent, isDark),
                              const SizedBox(height: 16),
                              Text(
                                "I am an architect of unseen threads, weaving human intention into the cold, beautiful logic of machines. By stripping away traditional interfaces, I invite a pure dialogue—where a quiet gesture speaks directly to the ether. This is not just an engine; it is an intimate dance between thought and digital reality.",
                                style: TextStyle(height: 1.6, fontSize: 15, color: isDark ? Colors.white70 : Colors.black87),
                              ),
                              const SizedBox(height: 24),
                              Wrap(
                                spacing: 10, runSpacing: 10,
                                children: ["Flutter", "Python / FastAPI", "LangChain", "MediaPipe", "Kotlin", "TensorFlow"].map((e) => _buildGlassChip(context, e, isDark, accent)).toList(),
                              )
                            ]
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        // Layer 2
                        _buildIphoneGlassCard(
                          context: context,
                          isDark: isDark,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader(context, "Invisible Mathematics", Icons.memory_rounded, accent, isDark),
                              const SizedBox(height: 16),
                              Text(
                                "Operating like a ghost within the system, this tracking heuristic requires no hardware, no gloves, and no tethers. It is simply mathematics in its most elegant, invisible form. Every movement is caught by pure geometric logic—a whisper of motion translated into instantaneous action.",
                                style: TextStyle(height: 1.6, fontSize: 15, color: isDark ? Colors.white70 : Colors.black87),
                              ),
                            ]
                          ),
                        ),

                        const SizedBox(height: 24),
                        // Layer 3
                        _buildIphoneGlassCard(
                          context: context,
                          isDark: isDark,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "悟",
                                style: TextStyle(fontSize: 48, color: accent.withOpacity(0.5)),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Where the mind wanders, the engine follows.",
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: isDark ? Colors.white60 : Colors.black54
                                ),
                              ),
                            ]
                          ),
                        ),

                        const SizedBox(height: 40),
                        
                        // Action Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildGlassIconButton(Icons.code_rounded, () => _launchURL("https://github.com/RajTewari01"), isDark, accent),
                            _buildGlassIconButton(Icons.email_rounded, () => _launchURL("mailto:tewari765@gmail.com"), isDark, accent),
                            _buildGlassIconButton(Icons.language_rounded, () => _launchURL("https://biswadeep.pythonanywhere.com"), isDark, accent),
                          ],
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // CUSTOM PREMIUM IPHONE GLASS UI COMPONENTS
  // -------------------------------------------------------------

  Widget _buildIphoneGlassCard({required BuildContext context, required bool isDark, required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          width: double.infinity,
          padding: padding ?? const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6),
              width: 1.5,
            ),
            boxShadow: isDark ? [] : [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, spreadRadius: -5)
            ]
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassChip(BuildContext context, String label, bool isDark, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08))
      ),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, Color accent, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: accent, size: 22),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: isDark ? Colors.white : Colors.black87)),
      ],
    );
  }
  
  Widget _buildGlassIconButton(IconData icon, VoidCallback onTap, bool isDark, Color accent) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 70, width: 70,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.5),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.white, width: 1.5),
              borderRadius: BorderRadius.circular(24)
            ),
            child: Icon(icon, size: 28, color: isDark ? Colors.white : Colors.black87),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // LIVING HORIZONTAL PARALLAX MIRROR MOUNTAINS
  // -------------------------------------------------------------
  Widget _buildMovingParallaxMountains(bool isDark, double timeOffset) {
    // Scroll offset moves mountains up/down. Time offset moves them left/right.
    double verticalScroll1 = _scrollOffset * -0.1;
    double verticalScroll2 = _scrollOffset * -0.25;
    double verticalScroll3 = _scrollOffset * -0.4;
    
    // Width mapping: the landscape needs to be wider than screen so it can pan.
    // 0.0 to 1.0 timeOffset covers the pan. We multiply by screen width to get pixel offset.
    final screenW = MediaQuery.of(context).size.width;
    
    final screenH = MediaQuery.of(context).size.height;
    
    // Different layers move at different horizontal speeds
    double hOffset1 = timeOffset * screenW * 0.2;
    double hOffset2 = timeOffset * screenW * 0.5;
    double hOffset3 = timeOffset * screenW * 1.0;
    
    // Birds move much faster to simulate flight across the sky
    double birdOffset = (timeOffset * screenW * 2.5) % screenW;
    
    final mountainColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFA5D6A7); // Slate for dark, pale green for light

    return SizedBox.expand(
      child: Stack(
        children: [
          // Sky / Birds Layer
          Positioned(
            top: 50 + verticalScroll1, left: -birdOffset, width: screenW * 2,
            height: 200,
            child: CustomPaint(painter: _BirdsPainter(color: isDark ? Colors.white24 : Colors.black26, timeOffset: timeOffset)),
          ),
          Positioned(
            top: 100 + verticalScroll2, left: -birdOffset + (screenW * 1.5), width: screenW * 2,
            height: 200,
            child: CustomPaint(painter: _BirdsPainter(color: isDark ? Colors.white24 : Colors.black26, timeOffset: timeOffset)),
          ),

          // Deepest Layer (Moves slowest horizontally)
          Positioned(
            top: 150 + verticalScroll1, left: -hOffset1, width: screenW * 2,
            height: 400,
            child: CustomPaint(painter: _MountainPainter(color: mountainColor.withOpacity(0.3))),
          ),
          Positioned(
            top: 150 + verticalScroll1, left: -hOffset1 + (screenW * 2), width: screenW * 2,
            height: 400,
            child: CustomPaint(painter: _MountainPainter(color: mountainColor.withOpacity(0.3))),
          ),

          // Middle Layer
          Positioned(
            top: 220 + verticalScroll2, left: -hOffset2, width: screenW * 2,
            height: 350,
            child: CustomPaint(painter: _MountainPainter(color: mountainColor.withOpacity(0.6))),
          ),
          Positioned(
            top: 220 + verticalScroll2, left: -hOffset2 + (screenW * 2), width: screenW * 2,
            height: 350,
            child: CustomPaint(painter: _MountainPainter(color: mountainColor.withOpacity(0.6))),
          ),

          // Foreground River & Reflection
          Positioned(
            top: 300 + verticalScroll3, left: -hOffset3, width: screenW * 2,
            bottom: 0,
            child: _buildMirroredRiver(mountainColor, isDark, timeOffset),
          ),
          Positioned(
            top: 300 + verticalScroll3, left: -hOffset3 + (screenW * 2), width: screenW * 2,
            bottom: 0,
            child: _buildMirroredRiver(mountainColor, isDark, timeOffset),
          ),
        ],
      ),
    );
  }

  Widget _buildMirroredRiver(Color mountainColor, bool isDark, double timeOffset) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(child: CustomPaint(painter: _MountainPainter(color: mountainColor))),
            // The mirror effect via reversed painter and blur
            Expanded(
              child: Opacity(
                opacity: 0.25,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationX(3.14159), // Flip Upside Down
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 10.0), // River flowing blur
                      child: CustomPaint(painter: _MountainPainter(color: mountainColor)),
                    ),
                  ),
                ),
              )
            )
          ],
        ),
        // Flowing River Tint
        Positioned.fill(
          top: 175, // approximate start of the reflection
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  (isDark ? const Color(0xFF003050) : const Color(0xFF81D4FA)).withOpacity(0.3)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            ),
          ),
        ),
        // Flowing River Waves
        Positioned.fill(
          top: 175,
          child: CustomPaint(painter: _RiverPainter(color: isDark ? Colors.white30 : Colors.white60, timeOffset: timeOffset)),
        )
      ]
    );
  }
}

class _RiverPainter extends CustomPainter {
  final Color color;
  final double timeOffset;
  _RiverPainter({required this.color, required this.timeOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Draw subtle flowing horizontal lines (sine waves)
    for (int i = 0; i < 8; i++) {
      final path = Path();
      double y = size.height * (0.2 + (i * 0.1));
      double waveOffset = timeOffset * 200 + (i * 10);
      path.moveTo(0, y);
      for (double x = 0; x <= size.width; x += 30) {
        path.lineTo(x, y + sin((x / 50) + waveOffset) * (3 + (i * 0.5)));
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _BirdsPainter extends CustomPainter {
  final Color color;
  final double timeOffset;
  _BirdsPainter({required this.color, required this.timeOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Birds flap rapidly
    double flap = sin(timeOffset * 800); 

    void drawBird(double x, double y, double scale) {
      final path = Path();
      double wingY = y - (5 * scale) + (flap * 6 * scale);
      path.moveTo(x - (10 * scale), wingY);
      path.quadraticBezierTo(x - (5 * scale), y + (2 * scale), x, y);
      path.quadraticBezierTo(x + (5 * scale), y + (2 * scale), x + (10 * scale), wingY);
      canvas.drawPath(path, paint);
    }
    
    // Flock 1
    drawBird(size.width * 0.2, size.height * 0.3, 1.2);
    drawBird(size.width * 0.23, size.height * 0.35, 1.0);
    drawBird(size.width * 0.17, size.height * 0.38, 0.9);
    drawBird(size.width * 0.26, size.height * 0.39, 0.8);
    drawBird(size.width * 0.15, size.height * 0.44, 0.7);
    
    // Flock 2 (Further away)
    drawBird(size.width * 0.6, size.height * 0.15, 0.6);
    drawBird(size.width * 0.62, size.height * 0.18, 0.5);
    drawBird(size.width * 0.58, size.height * 0.20, 0.55);
    
    // Flock 3
    drawBird(size.width * 0.85, size.height * 0.6, 0.9);
    drawBird(size.width * 0.88, size.height * 0.65, 0.8);
    drawBird(size.width * 0.82, size.height * 0.68, 0.7);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MountainPainter extends CustomPainter {
  final Color color;
  _MountainPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.5);
    
    // Draw mountain peaks spanning the width
    path.quadraticBezierTo(size.width * 0.1, size.height * 0.2, size.width * 0.25, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.4, size.height * 0.3, size.width * 0.6, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.8, size.height * 0.1, size.width, size.height * 0.8);
    
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
