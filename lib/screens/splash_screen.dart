import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({required this.onComplete, super.key});

  final VoidCallback onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _logoScale;
  late final Animation<Offset> _riseIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addStatusListener(_handleAnimationStatus);
    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.12, 0.72, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.78, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.72, curve: Curves.easeOutBack),
      ),
    );
    _riseIn = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.12, 0.8, curve: Curves.easeOutCubic),
          ),
        );
    _controller.forward();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleAnimationStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F4),
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Opacity(
              opacity: _fadeIn.value,
              child: SlideTransition(
                position: _riseIn,
                child: ScaleTransition(scale: _logoScale, child: child),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2EB982), Color(0xFF137453)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x3016875F),
                        blurRadius: 28,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'MINTLY',
                  style: TextStyle(
                    color: Color(0xFF18271F),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'MONEY, MADE EASY',
                  style: TextStyle(
                    color: Color(0xFF839089),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 34),
                SizedBox(
                  width: 48,
                  child: LinearProgressIndicator(
                    value: _controller.value,
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(4),
                    backgroundColor: const Color(0xFFDDE8E1),
                    color: const Color(0xFF16865F),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
