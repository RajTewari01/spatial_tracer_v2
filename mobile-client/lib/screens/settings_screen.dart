import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import 'creator_profile.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _useHandTracking = true;
  bool _useFaceTracking = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _useHandTracking = prefs.getBool('use_hand_tracking') ?? true;
      _useFaceTracking = prefs.getBool('use_face_tracking') ?? false;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, bottom: 8, top: 24),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildCustomTile({
    required Widget icon,
    required Color iconBackgroundColor,
    required String title,
    required Widget trailing,
    required bool isBottom,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border(
            bottom: isBottom ? BorderSide.none : BorderSide(color: borderColor, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: icon,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children, required Color borderColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required Widget icon,
    required Color iconBackgroundColor,
    required String title,
    required String subtitle,
    required bool isBottom,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(
          bottom: isBottom ? BorderSide.none : BorderSide(color: borderColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: icon,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: textColor.withOpacity(0.5),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final theme = CupertinoTheme.of(context);
    
    // Theme aware colors for custom cards
    final cardColor = isDark ? CupertinoColors.white.withOpacity(0.05) : CupertinoColors.black.withOpacity(0.03);
    final borderColor = isDark ? CupertinoColors.white.withOpacity(0.1) : CupertinoColors.black.withOpacity(0.05);
    final textColor = isDark ? CupertinoColors.white : const Color(0xFF051911);

    return CupertinoPageScaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false, // Fixes interpolation crash with GoogleFonts
        middle: Text("Settings", style: GoogleFonts.pacifico(fontSize: 24, fontWeight: FontWeight.w400)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("Engine configuration", textColor),
              _buildCard(
                borderColor: borderColor,
                children: [
                  _buildCustomTile(
                    icon: const Icon(CupertinoIcons.hand_draw, color: CupertinoColors.white, size: 20),
                    iconBackgroundColor: CupertinoColors.activeBlue,
                    title: "Hand tracking",
                    trailing: CupertinoSwitch(
                      value: _useHandTracking,
                      onChanged: (val) {
                        setState(() => _useHandTracking = val);
                        _savePreference('use_hand_tracking', val);
                      },
                    ),
                    isBottom: false,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                  ),
                  _buildCustomTile(
                    icon: const Icon(CupertinoIcons.person_crop_square, color: CupertinoColors.white, size: 20),
                    iconBackgroundColor: CupertinoColors.activeGreen,
                    title: "Face tracking",
                    trailing: CupertinoSwitch(
                      value: _useFaceTracking,
                      onChanged: (val) {
                        setState(() => _useFaceTracking = val);
                        _savePreference('use_face_tracking', val);
                      },
                    ),
                    isBottom: true,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                  ),
                ]
              ),

              _buildSectionHeader("How to control", textColor),
              _buildCard(
                borderColor: borderColor,
                children: [
                  _buildInfoTile(
                    icon: const Icon(CupertinoIcons.hand_draw, color: CupertinoColors.white, size: 20),
                    iconBackgroundColor: CupertinoColors.systemOrange,
                    title: "Pinch index & thumb",
                    subtitle: "Click or select items",
                    isBottom: false,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                  ),
                  _buildInfoTile(
                    icon: const Icon(CupertinoIcons.hand_point_right, color: CupertinoColors.white, size: 20),
                    iconBackgroundColor: CupertinoColors.systemPurple,
                    title: "Flick open hand",
                    subtitle: "Scroll up, down, left, right",
                    isBottom: false,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                  ),
                  _buildInfoTile(
                    icon: const Icon(CupertinoIcons.arrow_uturn_left, color: CupertinoColors.white, size: 20),
                    iconBackgroundColor: CupertinoColors.systemRed,
                    title: "Make a fist",
                    subtitle: "Go back or exit menu",
                    isBottom: false,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                  ),
                  _buildInfoTile(
                    icon: const Icon(CupertinoIcons.square_on_square, color: CupertinoColors.white, size: 20),
                    iconBackgroundColor: CupertinoColors.systemBlue,
                    title: "Peace sign",
                    subtitle: "Open recent apps",
                    isBottom: false,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                  ),
                  _buildCustomTile(
                    icon: const Icon(CupertinoIcons.play_circle_fill, color: CupertinoColors.white, size: 20),
                    iconBackgroundColor: CupertinoColors.systemGreen,
                    title: "Interactive tutorial",
                    trailing: Icon(CupertinoIcons.chevron_forward, color: textColor.withOpacity(0.5), size: 20),
                    isBottom: true,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                    onTap: () {
                      Navigator.push(context, CupertinoPageRoute(
                        builder: (_) => OnboardingScreen(isFromSettings: true)
                      ));
                    },
                  ),
                ]
              ),

              _buildSectionHeader("Appearance", textColor),
              _buildCard(
                borderColor: borderColor,
                children: [
                  _buildCustomTile(
                    icon: const Icon(CupertinoIcons.moon_fill, color: CupertinoColors.white, size: 20),
                    iconBackgroundColor: const Color(0xFF1A1A1A),
                    title: "Dark mode",
                    trailing: CupertinoSwitch(
                      value: isDark,
                      onChanged: (val) {
                        themeProvider.toggleTheme(val);
                      },
                    ),
                    isBottom: true,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                  ),
                ]
              ),

              _buildSectionHeader("About", textColor),
              _buildCard(
                borderColor: borderColor,
                children: [
                  _buildCustomTile(
                    icon: const Icon(CupertinoIcons.star_fill, color: CupertinoColors.white, size: 20),
                    iconBackgroundColor: const Color(0xFFD4AF37),
                    title: "Creator info",
                    trailing: Icon(CupertinoIcons.chevron_forward, color: textColor.withOpacity(0.5), size: 20),
                    isBottom: true,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                    onTap: () {
                      Navigator.push(context, CupertinoPageRoute(builder: (_) => const CreatorProfileScreen()));
                    },
                  ),
                ]
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
