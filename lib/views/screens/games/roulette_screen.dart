// lib/views/screens/games/roulette_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/wallet_provider.dart';
import 'dart:math';

class RouletteScreen extends StatefulWidget {
  const RouletteScreen({super.key});

  @override
  State<RouletteScreen> createState() => _RouletteScreenState();
}

class _RouletteScreenState extends State<RouletteScreen>
    with SingleTickerProviderStateMixin {
  static const int bet = 5;

  final List<int> redNumbers = [1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36];
  final List<int> blackNumbers = [2, 4, 6, 8, 10, 11, 13, 15, 17, 20, 22, 24, 26, 28, 29, 31, 33, 35];

  String selectedBet = '';
  bool spinning = false;
  int? result;
  String resultMessage = '';
  Color resultColor = Colors.transparent;

  int wins = 0, losses = 0, totalSpins = 0;

  late AnimationController _spinCtrl;
  late Animation<double> _spinAnim;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _spinAnim = Tween<double>(begin: 0, end: 8 * 2 * pi).animate(
      CurvedAnimation(parent: _spinCtrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (selectedBet.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a bet! 🎯'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final wallet = Provider.of<WalletProvider>(context, listen: false);
    if (wallet.balance < bet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough coins! 💰'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    wallet.spendCoins(bet);

    setState(() {
      spinning = true;
      result = null;
      resultMessage = '';
      totalSpins++;
    });

    await _spinCtrl.forward(from: 0);

    final rnd = Random();
    final winningNumber = rnd.nextInt(37); // 0-36

    setState(() {
      result = winningNumber;
      spinning = false;
    });

    _evaluateResult(winningNumber, wallet);
  }

  void _evaluateResult(int number, WalletProvider wallet) {
    bool won = false;
    int multiplier = 0;

    if (selectedBet == 'RED' && redNumbers.contains(number)) {
      won = true;
      multiplier = 2;
    } else if (selectedBet == 'BLACK' && blackNumbers.contains(number)) {
      won = true;
      multiplier = 2;
    } else if (selectedBet == 'EVEN' && number != 0 && number % 2 == 0) {
      won = true;
      multiplier = 2;
    } else if (selectedBet == 'ODD' && number != 0 && number % 2 == 1) {
      won = true;
      multiplier = 2;
    } else if (selectedBet == '1-18' && number >= 1 && number <= 18) {
      won = true;
      multiplier = 2;
    } else if (selectedBet == '19-36' && number >= 19 && number <= 36) {
      won = true;
      multiplier = 2;
    } else if (selectedBet == 'GREEN' && number == 0) {
      won = true;
      multiplier = 35;
    }

    if (won) {
      final winAmount = bet * multiplier;
      wallet.addCoins(winAmount);
      setState(() {
        resultMessage = '🎉 WIN! +${winAmount - bet} coins';
        resultColor = Colors.green;
        wins++;
      });
    } else {
      setState(() {
        resultMessage = '😔 LOSE';
        resultColor = Colors.red;
        losses++;
      });
    }
  }

  Color _getNumberColor(int number) {
    if (number == 0) return Colors.green;
    if (redNumbers.contains(number)) return Colors.red;
    return Colors.black;
  }

  Widget _betButton(String label, Color color, IconData icon) {
    final isSelected = selectedBet == label;

    return GestureDetector(
      onTap: () => setState(() => selectedBet = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.amber : color,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: color.withOpacity(0.6),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = Provider.of<WalletProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0d1a0d),
      appBar: AppBar(
        title: const Text('🎡 Roulette',
            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1a331a),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statBox('Spins', totalSpins, Colors.blue),
                _statBox('Wins', wins, Colors.green),
                _statBox('Losses', losses, Colors.red),
              ],
            ),
            const SizedBox(height: 24),

            // Roulette Wheel
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2d5a2d), Color(0xFF1a331a)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber, width: 3),
              ),
              child: Column(
                children: [
                  // Spinning Wheel
                  AnimatedBuilder(
                    animation: _spinAnim,
                    builder: (_, child) => Transform.rotate(
                      angle: _spinAnim.value,
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [
                              Colors.amber,
                              Color(0xFF8B4513),
                              Color(0xFF654321),
                            ],
                          ),
                          border: Border.all(color: Colors.amber, width: 8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.5),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: List.generate(
                            12,
                                (i) => Transform.rotate(
                              angle: (i * 2 * pi / 12),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Container(
                                  margin: const EdgeInsets.only(top: 10),
                                  width: 4,
                                  height: 100,
                                  color: i % 2 == 0
                                      ? Colors.red
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Result Display
                  if (result != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getNumberColor(result!),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber, width: 3),
                      ),
                      child: Text(
                        result.toString(),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                  if (resultMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: resultColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        resultMessage,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Betting Options
            const Text(
              'PLACE YOUR BET',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _betButton('RED', Colors.red[700]!, Icons.circle),
                _betButton('BLACK', Colors.black, Icons.circle),
                _betButton('EVEN', Colors.blue[700]!, Icons.filter_2),
                _betButton('ODD', Colors.orange[700]!, Icons.filter_1),
                _betButton('1-18', Colors.purple[700]!, Icons.looks_one),
                _betButton('19-36', Colors.teal[700]!, Icons.looks_two),
                _betButton('GREEN', Colors.green[700]!, Icons.star),
              ],
            ),

            const SizedBox(height: 24),

            // Spin Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: spinning ? null : _spin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 12,
                ),
                child: spinning
                    ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor:
                        AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'SPINNING...',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
                    : const Text(
                  'SPIN (5 coins)',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Text(
              'Red/Black/Even/Odd/1-18/19-36: ×2\nGreen (0): ×35',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, int value, Color color) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color, width: 2),
    ),
    child: Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    ),
  );
}