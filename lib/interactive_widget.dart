import 'package:flutter/material.dart';
import 'dart:math' as math;

class InteractiveGridBackground extends StatefulWidget {
  final Widget child;

  const InteractiveGridBackground({super.key, required this.child});

  @override
  State<InteractiveGridBackground> createState() =>
      _InteractiveGridBackgroundState();
}

class _InteractiveGridBackgroundState extends State<InteractiveGridBackground>
    with SingleTickerProviderStateMixin {
  final List<DotRipple> ripples = [];
  late AnimationController _controller;
  late List<MovingDot> _dots;
  final int _numberOfDots = 120;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    // Initialize dots BEFORE the controller
    _dots = List.generate(_numberOfDots, (index) => MovingDot(_random));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = context.size ?? MediaQuery.of(context).size;
      setState(() {
        for (var dot in _dots) {
          dot.position = Offset(
            _random.nextDouble() * size.width,
            _random.nextDouble() * size.height,
          );
        }
      });
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addListener(() {
        setState(() {
          for (var dot in _dots) {
            dot.update(context.size ?? Size.zero);
          }
          ripples.removeWhere((ripple) => ripple.progress >= 1.0);
        });
      });

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      ripples.add(DotRipple(
        position: details.localPosition,
        startTime: DateTime.now().millisecondsSinceEpoch,
      ));
    });

    if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => _handleTapDown(details),
      child: CustomPaint(
        painter: DotsPainter(
          dots: _dots,
          ripples: ripples,
          animationValue: _controller.value,
        ),
        child: widget.child,
      ),
    );
  }
}

class MovingDot {
  Offset position;
  final double radius;
  final Color color;
  final double speed;
  final Offset direction;

  MovingDot(math.Random random)
      : radius = random.nextDouble() * 2 + 2,
        color = Colors.white.withOpacity(random.nextDouble() * 0.6 + 0.2),
        speed = random.nextDouble() * 0.5 + 0.1,
        position = Offset(
          random.nextDouble() * 1000,
          random.nextDouble() * 1000,
        ),
        direction = Offset(
          random.nextDouble() * 2 - 1,
          random.nextDouble() * 2 - 1,
        ).normalize();

  void update(Size size) {
    position = position + direction * speed;

    if (position.dx < -radius) {
      position = Offset(size.width + radius, position.dy);
    }
    if (position.dx > size.width + radius) {
      position = Offset(-radius, position.dy);
    }
    if (position.dy < -radius) {
      position = Offset(position.dx, size.height + radius);
    }
    if (position.dy > size.height + radius) {
      position = Offset(position.dx, -radius);
    }
  }
}

class DotRipple {
  final Offset position;
  final int startTime;
  double progress = 0.0;

  DotRipple({required this.position, required this.startTime});
}

class DotsPainter extends CustomPainter {
  final List<MovingDot> dots;
  final List<DotRipple> ripples;
  final double animationValue;
  static const double maxRippleRadius = 150.0;

  DotsPainter({
    required this.dots,
    required this.ripples,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now().millisecondsSinceEpoch;

    for (var ripple in ripples) {
      ripple.progress = (now - ripple.startTime) / 2000.0;
    }

    for (var dot in dots) {
      double currentRadius = dot.radius;
      Color currentColor = dot.color;

      for (var ripple in ripples) {
        if (ripple.progress < 1.0) {
          final distance = (dot.position - ripple.position).distance;
          final rippleRadius = ripple.progress * maxRippleRadius;

          if ((distance - rippleRadius).abs() < 50) {
            final intensity = 1.0 - (distance - rippleRadius).abs() / 50;
            final fadeOut = 1.0 - ripple.progress;

            currentRadius += intensity * fadeOut * 5;
            currentColor = currentColor.withOpacity(
                (currentColor.opacity + intensity * fadeOut * 0.5)
                    .clamp(0.2, 1.0));
          }
        }
      }

      final paint = Paint()..color = currentColor;
      canvas.drawCircle(dot.position, currentRadius.clamp(1.0, 10.0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant DotsPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.ripples.length != ripples.length;
  }
}

extension on Offset {
  Offset normalize() {
    final magnitude = distance;
    if (magnitude == 0) return Offset.zero;
    return Offset(dx / magnitude, dy / magnitude);
  }
}

// Public FuturisticRippleButton - now the only definition
class FuturisticRippleButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final bool isElevated;

  const FuturisticRippleButton({
    super.key,
    required this.onPressed,
    required this.child,
    required this.isElevated,
  });

  @override
  State<FuturisticRippleButton> createState() => _FuturisticRippleButtonState();
}

class _FuturisticRippleButtonState extends State<FuturisticRippleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse().then((_) {
      if (mounted) widget.onPressed();
    });
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    const Color primaryVariant = Color(0xFF89A4B8);
    const Color primaryLight = Color(0xFFD6E4EE);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple Effect
          AnimatedBuilder(
            animation: _rippleAnimation,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: _rippleAnimation.value * 2,
                    colors: [
                      primaryColor
                          .withOpacity(0.3 * (1 - _rippleAnimation.value)),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),

          // Button with Scale Animation
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: widget.isElevated
                        ? const LinearGradient(
                            colors: [primaryVariant, primaryLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(30),
                    border: widget.isElevated
                        ? null
                        : Border.all(
                            color: primaryColor,
                            width: 2,
                          ),
                    boxShadow: widget.isElevated
                        ? [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.4),
                              blurRadius: 15,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                    child: Center(
                      child: DefaultTextStyle.merge(
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              widget.isElevated ? Colors.black : primaryColor,
                          shadows: widget.isElevated
                              ? [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 2,
                                    offset: const Offset(1, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
