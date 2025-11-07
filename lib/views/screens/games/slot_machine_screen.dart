// lib/views/screens/games/slot_machine_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/wallet_provider.dart';
import 'components/animated_reel.dart';
import 'dart:math';

class SlotMachineScreen extends StatefulWidget {
  const SlotMachineScreen({super.key});

  @override
  State<SlotMachineScreen> createState() => _SlotMachineScreenState();
}

class _SlotMachineScreenState extends State<SlotMachineScreen>
    with TickerProviderStateMixin {
  // ───── SETTINGS ─────
  static const int bet = 5;
  static const List<String> symbols = [
    '🍒', '🍋', '🍊', '🍉', '⭐', '💎', '🔔', '7️⃣', '🍇', '🍓'
  ];

  // ───── STATE ─────
  final Random _rnd = Random();
  late List<int> _finalIndices;
  bool _spinning = false;
  int _reelsDone = 0;

  // Lever animation
  late AnimationController _leverCtrl;
  late Animation<double> _leverAnim;

  // Result animation
  late AnimationController _resultCtrl;
  late Animation<double> _resultScale;
  late Animation<double> _resultOpacity;

  // Result banner
  String _resultText = '';
  Color _resultColor = Colors.transparent;

  // Stats
  int _spins = 0, _wagered = 0, _won = 0;

  @override
  void initState() {
    super.initState();
    _finalIndices = List.generate(3, (_) => _rnd.nextInt(symbols.length));

    // Lever animation
    _leverCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _leverAnim = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _leverCtrl, curve: Curves.easeOut),
    );

    // Result pop animation
    _resultCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _resultScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _resultCtrl, curve: Curves.elasticOut),
    );
    _resultOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _resultCtrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _leverCtrl.dispose();
    _resultCtrl.dispose();
    super.dispose();
  }

  // ───── BIASED RNG (≈15% win rate) ─────
  List<int> _generateResult() {
    final r = _rnd.nextDouble();
    if (r < 0.05) {
      // 5% Jackpot (3 same)
      final i = _rnd.nextInt(symbols.length);
      return [i, i, i];
    } else if (r < 0.15) {
      // 10% Two-match
      final a = _rnd.nextInt(symbols.length);
      final b = _rnd.nextInt(symbols.length);
      return _rnd.nextBool() ? [a, a, b] : [a, b, a];
    } else {
      // 85% No match
      final set = <int>{};
      while (set.length < 3) set.add(_rnd.nextInt(symbols.length));
      return set.toList();
    }
  }

  // ───── SPIN ─────
  Future<void> _spin() async {
    final wallet = Provider.of<WalletProvider>(context, listen: false);
    if (wallet.balance < bet) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough coins! 💰'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    wallet.spendCoins(bet);
    setState(() {
      _spins++;
      _wagered += bet;
      _spinning = true;
      _reelsDone = 0;
      _finalIndices = _generateResult();
      _resultText = '';
      _resultColor = Colors.transparent;
    });

    // Animate lever
    await _leverCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    await _leverCtrl.reverse();
  }

  void _reelStopped() {
    setState(() => _reelsDone++);
    if (_reelsDone == 3) {
      setState(() => _spinning = false);
      _evaluateResult();
    }
  }

  // ───── PAYOUT & RESULT ─────
  void _evaluateResult() async {
    final wallet = Provider.of<WalletProvider>(context, listen: false);
    final a = _finalIndices[0], b = _finalIndices[1], c = _finalIndices[2];

    int mult = 0;
    bool jackpot = false;
    String msg = 'Try Again! 😔';
    Color col = Colors.grey;

    if (a == b && b == c) {
      mult = 20;
      jackpot = true;
      msg = '🎉 JACKPOT! 🎉';
      col = Colors.amber;
    } else if (a == b || b == c || a == c) {
      mult = 3;
      msg = '🎊 WIN! 🎊';
      col = Colors.green;
    }

    final win = bet * mult;
    if (win > 0) {
      _won += win;
      wallet.addCoins(win);
    }

    setState(() {
      _resultText = msg;
      _resultColor = col;
    });

    // Animate result banner
    await _resultCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 2000));
    await _resultCtrl.reverse();
  }

  // ───── UI HELPERS ─────
  Widget _stat(String label, String value, IconData icon) => Column(
    children: [
      Icon(icon, color: Colors.amber, size: 20),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(
          color: Colors.amber,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
        ),
      ),
    ],
  );

  // ───── BUILD ─────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final reelW = size.width * 0.24;

    final wallet = Provider.of<WalletProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1a0033),
      appBar: AppBar(
        title: const Text('🎰 Slot Machine',
            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2d0052),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 26),
                const SizedBox(width: 6),
                Text(
                  '${wallet.balance}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // STATS
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.withOpacity(0.3),
                          Colors.deepPurple.withOpacity(0.3)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber, width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _stat('Spins', _spins.toString(), Icons.sync),
                        Container(
                          width: 2,
                          height: 50,
                          color: Colors.amber.withOpacity(0.3),
                        ),
                        _stat('Won', _won.toString(), Icons.stars),
                        Container(
                          width: 2,
                          height: 50,
                          color: Colors.amber.withOpacity(0.3),
                        ),
                        _stat(
                          'Net',
                          (_won - _wagered).toString(),
                          Icons.trending_up,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SLOT MACHINE
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4a0080), Color(0xFF2d0052)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.amber, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                        const BoxShadow(
                          color: Colors.black87,
                          blurRadius: 25,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Title
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '🎰 MEGA SLOTS 🎰',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // REELS (3×3)
                        Container(
                          height: size.width * 0.8,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.amber, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              3,
                                  (i) => Padding(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                                child: SizedBox(
                                  width: reelW,
                                  child: _spinning
                                      ? AnimatedReel(
                                    symbols: symbols,
                                    finalIndex: _finalIndices[i],
                                    spinDuration: Duration(
                                        milliseconds: 1800 + i * 400),
                                    onFinished: _reelStopped,
                                  )
                                      : _staticReel(symbols[_finalIndices[i]]),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // LEVER
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              children: [
                                const Text(
                                  'PULL',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onVerticalDragUpdate: (d) {
                                    if (d.delta.dy > 15 && !_spinning) _spin();
                                  },
                                  child: AnimatedBuilder(
                                    animation: _leverAnim,
                                    builder: (_, __) => Transform.rotate(
                                      angle: _leverAnim.value * 3.14159,
                                      origin: const Offset(14, -55),
                                      child: Container(
                                        width: 32,
                                        height: 110,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFff1744),
                                              Color(0xFFc62828)
                                            ],
                                          ),
                                          borderRadius:
                                          BorderRadius.circular(16),
                                          border: Border.all(
                                              color: Colors.amber, width: 2),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black54,
                                              blurRadius: 10,
                                              offset: Offset(0, 5),
                                            )
                                          ],
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.arrow_downward,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // SPIN BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _spinning ? null : _spin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 12,
                        shadowColor: Colors.amber,
                      ),
                      child: _spinning
                          ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation(
                                  Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'SPINNING...',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      )
                          : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.casino_rounded, size: 32),
                          SizedBox(width: 12),
                          Text(
                            'SPIN',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Bet: 5 coins | Max Win: ×20 🎰',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // RESULT BANNER (Floating)
          if (_resultText.isNotEmpty)
            Positioned(
              top: 120,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _resultCtrl,
                builder: (context, child) => Opacity(
                  opacity: _resultOpacity.value,
                  child: Transform.scale(
                    scale: _resultScale.value,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: _resultColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: _resultColor.withOpacity(0.6),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Text(
                        _resultText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 4,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _staticReel(String emoji) => Container(
    width: double.infinity,
    height: double.infinity,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Colors.white, Color(0xFFfff9c4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFFFD700), width: 3),
      boxShadow: const [
        BoxShadow(
          color: Colors.black38,
          blurRadius: 8,
          offset: Offset(0, 4),
        )
      ],
    ),
    child: Text(
      emoji,
      style: const TextStyle(fontSize: 70),
    ),
  );
}