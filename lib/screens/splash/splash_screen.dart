import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../main.dart' show AuthGate;
import '../../services/store_settings.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Main slide: rider enters left, cruises, exits right
  late final AnimationController _slideCtrl;
  // ── Continuous looping: speed lines, road dashes scroll
  late final AnimationController _loopCtrl;
  // ── Bob / micro-vibration
  late final AnimationController _bobCtrl;
  // ── Lean ramp: goes from 0° to –8° as rider speeds up
  late final AnimationController _leanCtrl;
  // ── Particle trail controller
  late final AnimationController _particleCtrl;

  late final Animation<double> _slideAnim; // –0.35 → 1.30

  final List<_Particle> _particles = [];
  final math.Random _rng = math.Random(42);

  @override
  void initState() {
    super.initState();

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _slideAnim = Tween<double>(
      begin: -0.38,
      end: 1.32,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeIn));

    _loopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();

    _bobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..repeat(reverse: true);

    _leanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _particleCtrl =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 80),
          )
          ..addListener(_spawnParticles)
          ..repeat();

    _startSequence();
  }

  void _spawnParticles() {
    if (!mounted) return;
    // Only spawn when rider is actually on screen
    final t = _slideAnim.value;
    if (t < -0.10 || t > 0.90) return;
    // Spawn 1-2 particles per frame
    final count = _rng.nextInt(3);
    for (int i = 0; i < count; i++) {
      _particles.add(
        _Particle(
          progress: 0.0,
          yFrac: 0.60 + _rng.nextDouble() * 0.12, // near the bike
          speedX: -(_rng.nextDouble() * 0.018 + 0.012), // drift left
          speedY: (_rng.nextDouble() - 0.5) * 0.004,
          size: _rng.nextDouble() * 5 + 2,
          color: _rng.nextBool()
              ? Colors.white.withValues(alpha: 0.45)
              : const Color(0xFFFFAB40).withValues(alpha: 0.35),
        ),
      );
    }
    // Remove dead particles
    _particles.removeWhere((p) => p.progress >= 1.0);
    // Advance live ones
    for (final p in _particles) {
      p.progress += 0.055;
      p.xFrac += p.speedX;
      p.yFrac += p.speedY;
    }
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _leanCtrl.forward();
    await _slideCtrl.forward();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const AuthGate(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 550),
      ),
    );
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _loopCtrl.dispose();
    _bobCtrl.dispose();
    _leanCtrl.dispose();
    _particleCtrl
      ..removeListener(_spawnParticles)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFBF360C), Color(0xFFFF6D00), Color(0xFFFFAB40)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ── Decorative background circles ──
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _BackgroundPainter()),
              ),
            ),

            // ── Scrolling road + dashes ──
            _buildScrollingRoad(size),

            // ── Brand content (logo + tagline) ──
            _buildBrandContent(context),

            // ── Particle trails ──
            _buildParticles(size),

            // ── PNG Delivery Rider ──
            _buildPngRider(size),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Scrolling road with animated dashes
  // ─────────────────────────────────────────────
  Widget _buildScrollingRoad(Size size) {
    return AnimatedBuilder(
      animation: _loopCtrl,
      builder: (_, _) {
        return Positioned(
          bottom: size.height * 0.30,
          left: 0,
          right: 0,
          child: CustomPaint(
            size: Size(size.width, 30),
            painter: _RoadPainter(scroll: _loopCtrl.value),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // Brand content
  // ─────────────────────────────────────────────
  Widget _buildBrandContent(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 56),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: const Center(
              child: StoreBrandLogo(size: 56, color: Colors.white),
            ),
          ),
          const SizedBox(height: 18),
          const StoreBrandName(
            style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
              shadows: [
                Shadow(
                  color: Color(0x55000000),
                  offset: Offset(0, 3),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Fast  •  Fresh  •  Flavourful',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.4,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Particle exhaust trail
  // ─────────────────────────────────────────────
  Widget _buildParticles(Size size) {
    return AnimatedBuilder(
      animation: _particleCtrl,
      builder: (_, _) {
        return Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ParticlePainter(
                particles: List.from(_particles),
                screenSize: size,
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // PNG Rider with motion effects
  // ─────────────────────────────────────────────
  Widget _buildPngRider(Size size) {
    // Rider image dimensions on screen
    const riderW = 280.0;
    const riderH = 180.0;
    final riderTop = size.height * 0.48;

    return AnimatedBuilder(
      animation: Listenable.merge([_slideAnim, _bobCtrl, _leanCtrl]),
      builder: (context, _) {
        final xPos = _slideAnim.value * size.width;
        final bob = (_bobCtrl.value * 2 - 1) * 2.8; // ±2.8 px vertical
        final speedFactor = ((_slideAnim.value + 0.38) / 1.7).clamp(0.0, 1.0);
        // Lean forward as speed increases (–10° tilt)
        final leanAngle = -_leanCtrl.value * 0.14; // radians
        // Motion blur sigma based on speed
        final blurSigma = speedFactor * 4.0;

        return Positioned(
          left: xPos,
          top: riderTop + bob,
          child: Transform.rotate(
            angle: leanAngle,
            alignment: const Alignment(0.5, 0.8),
            child: Transform.scale(
              scale: 1.0 + speedFactor * 0.04,
              alignment: const Alignment(0.5, 0.8),
              child: SizedBox(
                width: riderW,
                height: riderH,
                child: Stack(
                  children: [
                    // ── Motion blur behind rider ──
                    if (blurSigma > 0.5)
                      Positioned.fill(
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: blurSigma * 2.5,
                            sigmaY: 0.3,
                            tileMode: TileMode.decal,
                          ),
                          child: Opacity(
                            opacity: speedFactor * 0.45,
                            child: Image.asset(
                              'assets/images/delivery_rider.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    // ── Sharp rider image ──
                    Positioned.fill(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                        child: Image.asset(
                          'assets/images/delivery_rider.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                    // ── Speed-glow overlay (orange radial bloom) ──
                    if (speedFactor > 0.15)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: const Alignment(-0.5, 0.2),
                                radius: 0.9,
                                colors: [
                                  const Color(
                                    0xFFFF6D00,
                                  ).withValues(alpha: speedFactor * 0.18),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════
// Animated road dashes (scrolling rightwards becomes leftwards)
// ══════════════════════════════════════════════
class _RoadPainter extends CustomPainter {
  final double scroll; // 0→1 looping

  const _RoadPainter({required this.scroll});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.20)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const dashW = 32.0;
    const gap = 20.0;
    const stride = dashW + gap;
    // Offset scrolls leftward
    final offset = scroll * stride;

    double x = -stride + offset;
    while (x < size.width + stride) {
      canvas.drawLine(Offset(x, 8), Offset(x + dashW, 8), paint);
      x += stride;
    }
  }

  @override
  bool shouldRepaint(_RoadPainter old) => old.scroll != scroll;
}

// ══════════════════════════════════════════════
// Particle trail painter
// ══════════════════════════════════════════════
class _Particle {
  double progress; // 0 → 1 (life)
  double xFrac;
  double yFrac;
  final double speedX;
  final double speedY;
  final double size;
  final Color color;

  _Particle({
    required this.progress,
    required this.yFrac,
    required this.speedX,
    required this.speedY,
    required this.size,
    required this.color,
  }) : xFrac = 0.0;
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Size screenSize;

  const _ParticlePainter({required this.particles, required this.screenSize});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final alpha = (1.0 - p.progress) * p.color.a;
      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha.clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(
        Offset(p.xFrac * size.width, p.yFrac * size.height),
        p.size * (1.0 - p.progress * 0.6),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

// ══════════════════════════════════════════════
// Background decorative circles
// ══════════════════════════════════════════════
class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;

    p.color = Colors.white.withValues(alpha: 0.06);
    canvas.drawCircle(Offset(size.width + 40, -60), 200, p);

    p.color = Colors.white.withValues(alpha: 0.05);
    canvas.drawCircle(Offset(-50, size.height + 30), 180, p);

    p.color = Colors.white.withValues(alpha: 0.08);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.35), 60, p);

    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.65),
      90,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_BackgroundPainter _) => false;
}
