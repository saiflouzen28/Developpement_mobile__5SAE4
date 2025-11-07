// lib/views/screens/games/components/animated_reel.dart
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';

class AnimatedReel extends StatefulWidget {
  final List<String> symbols;
  final int finalIndex;
  final Duration spinDuration;
  final VoidCallback onFinished;

  const AnimatedReel({
    super.key,
    required this.symbols,
    required this.finalIndex,
    required this.spinDuration,
    required this.onFinished,
  });

  @override
  State<AnimatedReel> createState() => _AnimatedReelState();
}

class _AnimatedReelState extends State<AnimatedReel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.spinDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onFinished();
      });

    final int cycles = 6 + Random().nextInt(3);
    final double end = (cycles * widget.symbols.length + widget.finalIndex).toDouble();

    _animation = Tween<double>(begin: 0.0, end: end)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) {
        final double value = _animation.value;
        final bool fast = _controller.velocity.abs() > 300;

        return Stack(
          children: [
            // 3 visible rows
            Column(
              children: List.generate(3, (i) {
                final int idx = (value ~/ 1 + i - 1) % widget.symbols.length;
                return Expanded(
                  child: _symbolBox(widget.symbols[idx], fast),
                );
              }),
            ),
            // Blur overlay
            if (fast)
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.white.withOpacity(0.1)),
              ),
          ],
        );
      },
    );
  }

  Widget _symbolBox(String s, bool blur) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6366F1), width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))
        ],
      ),
      child: Center(
        child: blur
            ? ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Text(s, style: const TextStyle(fontSize: 60)),
        )
            : Text(s, style: const TextStyle(fontSize: 60)),
      ),
    );
  }
}