import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// GET STARTED SCREEN
// Shown ONLY the very first time the app is opened.
// Swiping the button marks first-launch as done and takes the
// user straight to the Login screen.
// ============================================================

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  // =========================================================
  // COLORS
  // =========================================================

  static const Color green = Color(0xFF65B83D);
  static const Color darkGreen = Color(0xFF4C8F27);
  static const Color dark = Color(0xFF252525);

  // =========================================================
  // SWIPE STATE
  // =========================================================

  double _dragPosition = 0;
  bool _completed = false;

  // =========================================================
  // COMPLETE GET STARTED
  // =========================================================

  Future<void> _completeGetStarted() async {
    if (_completed) {
      return;
    }

    _completed = true;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_get_started', true);
    } catch (e) {
      debugPrint('FRUTGO GET STARTED PREF ERROR: $e');
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacementNamed('/login');
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // =================================================
            // TOP LOGO ROW
            // =================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: green,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.eco,
                            color: Colors.white,
                            size: 18,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 9),
                  const Text(
                    'Frutgo',
                    style: TextStyle(
                      color: green,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            // =================================================
            // CENTER BRAND ART
            // =================================================

            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8ED),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.eco,
                              color: green,
                              size: 42,
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'Fresh',
                      style: TextStyle(
                        fontSize: 54,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: dark,
                        height: 1,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Frut ',
                          style: TextStyle(
                            fontSize: 25,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                            color: dark,
                          ),
                        ),
                        Text(
                          'go',
                          style: TextStyle(
                            fontSize: 25,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: dark,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Text(
                        'DELIVERED IN MINUTES',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // =================================================
            // SWIPE TO GET STARTED
            // =================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 34),
              child: _buildSwipeButton(),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // SWIPE BUTTON
  // =========================================================

  Widget _buildSwipeButton() {
    const double thumbSize = 52;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double trackWidth = constraints.maxWidth;
        final double maxDrag = trackWidth - thumbSize - 8;

        return Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [green, darkGreen],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: green.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Center(
                child: Text(
                  'Swipe to Get Started',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),

              AnimatedPositioned(
                duration: _completed
                    ? const Duration(milliseconds: 250)
                    : Duration.zero,
                curve: Curves.easeOut,
                left: 4 + _dragPosition,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _dragPosition =
                          (_dragPosition + details.delta.dx)
                              .clamp(0, maxDrag);
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_dragPosition > maxDrag * 0.65) {
                      setState(() {
                        _dragPosition = maxDrag;
                      });

                      _completeGetStarted();
                    } else {
                      setState(() {
                        _dragPosition = 0;
                      });
                    }
                  },
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: green,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}