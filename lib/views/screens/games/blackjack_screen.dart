// lib/views/screens/games/blackjack_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/wallet_provider.dart';
import 'dart:math';

class BlackjackScreen extends StatefulWidget {
  const BlackjackScreen({super.key});

  @override
  State<BlackjackScreen> createState() => _BlackjackScreenState();
}

class _BlackjackScreenState extends State<BlackjackScreen>
    with TickerProviderStateMixin {
  static const int bet = 10;
  final List<String> deck = [];
  List<String> playerHand = [];
  List<String> dealerHand = [];

  bool gameActive = false;
  bool dealerTurn = false;
  String resultMessage = '';
  Color resultColor = Colors.transparent;

  int wins = 0, losses = 0, draws = 0;

  late AnimationController _dealCtrl;
  late Animation<double> _dealAnim;

  @override
  void initState() {
    super.initState();
    _dealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _dealAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _dealCtrl, curve: Curves.easeOut),
    );
    _initDeck();
  }

  @override
  void dispose() {
    _dealCtrl.dispose();
    super.dispose();
  }

  void _initDeck() {
    deck.clear();
    final suits = ['♠️', '♥️', '♣️', '♦️'];
    final ranks = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];

    for (var suit in suits) {
      for (var rank in ranks) {
        deck.add('$rank$suit');
      }
    }
    deck.shuffle(Random());
  }

  int _cardValue(String card) {
    final rank = card.substring(0, card.length - 2);
    if (rank == 'A') return 11;
    if (['J', 'Q', 'K'].contains(rank)) return 10;
    return int.parse(rank);
  }

  int _calculateHand(List<String> hand) {
    int value = 0;
    int aces = 0;

    for (var card in hand) {
      final v = _cardValue(card);
      value += v;
      if (v == 11) aces++;
    }

    while (value > 21 && aces > 0) {
      value -= 10;
      aces--;
    }

    return value;
  }

  Future<void> _startGame() async {
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
      _initDeck();
      playerHand = [deck.removeLast(), deck.removeLast()];
      dealerHand = [deck.removeLast(), deck.removeLast()];
      gameActive = true;
      dealerTurn = false;
      resultMessage = '';
      resultColor = Colors.transparent;
    });

    await _dealCtrl.forward();
    await _dealCtrl.reverse();

    if (_calculateHand(playerHand) == 21) {
      _endGame();
    }
  }

  Future<void> _hit() async {
    if (!gameActive || dealerTurn) return;

    setState(() {
      playerHand.add(deck.removeLast());
    });

    await _dealCtrl.forward();
    await _dealCtrl.reverse();

    if (_calculateHand(playerHand) >= 21) {
      _endGame();
    }
  }

  Future<void> _stand() async {
    if (!gameActive) return;

    setState(() {
      dealerTurn = true;
    });

    while (_calculateHand(dealerHand) < 17) {
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() {
        dealerHand.add(deck.removeLast());
      });

      await _dealCtrl.forward();
      await _dealCtrl.reverse();
    }

    _endGame();
  }

  void _endGame() {
    final playerScore = _calculateHand(playerHand);
    final dealerScore = _calculateHand(dealerHand);
    final wallet = Provider.of<WalletProvider>(context, listen: false);

    String msg;
    Color col;
    int winnings = 0;

    if (playerScore > 21) {
      msg = 'BUST! 💥 Dealer Wins';
      col = Colors.red;
      losses++;
    } else if (dealerScore > 21) {
      msg = 'DEALER BUST! 🎉 You Win!';
      col = Colors.green;
      winnings = bet * 2;
      wins++;
    } else if (playerScore > dealerScore) {
      msg = 'YOU WIN! 🎊';
      col = Colors.green;
      winnings = bet * 2;
      wins++;
    } else if (dealerScore > playerScore) {
      msg = 'DEALER WINS 😔';
      col = Colors.red;
      losses++;
    } else {
      msg = 'PUSH! 🤝 Tie';
      col = Colors.orange;
      winnings = bet;
      draws++;
    }

    if (winnings > 0) {
      wallet.addCoins(winnings);
    }

    setState(() {
      gameActive = false;
      resultMessage = msg;
      resultColor = col;
    });
  }

  Widget _buildCard(String card, {bool hidden = false}) {
    final isRed = card.contains('♥️') || card.contains('♦️');

    return Container(
      width: 60,
      height: 90,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: hidden ? Colors.blue[900] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: hidden
          ? Center(
        child: Icon(Icons.question_mark,
            color: Colors.amber, size: 40),
      )
          : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isRed ? Colors.red : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHand(String label, List<String> hand, int score,
      {bool hideFirst = false}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.amber,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber, width: 2),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    hand.length,
                        (i) => _buildCard(
                      hand[i],
                      hidden: hideFirst && i == 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hideFirst ? '?' : 'Score: $score',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = Provider.of<WalletProvider>(context);
    final playerScore = _calculateHand(playerHand);
    final dealerScore = _calculateHand(dealerHand);

    return Scaffold(
      backgroundColor: const Color(0xFF0d4d0d),
      appBar: AppBar(
        title: const Text('🃏 Blackjack',
            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1a5c1a),
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
                _statBox('Wins', wins, Colors.green),
                _statBox('Losses', losses, Colors.red),
                _statBox('Draws', draws, Colors.orange),
              ],
            ),
            const SizedBox(height: 24),

            // Dealer Hand
            _buildHand(
              'DEALER',
              dealerHand,
              dealerScore,
              hideFirst: gameActive && !dealerTurn,
            ),

            const SizedBox(height: 32),

            // Result Message
            if (resultMessage.isNotEmpty)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: resultColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  resultMessage,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // Player Hand
            _buildHand('PLAYER', playerHand, playerScore),

            const SizedBox(height: 32),

            // Action Buttons
            if (!gameActive)
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'DEAL (10 coins)',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (!dealerTurn)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _hit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'HIT',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _stand,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'STAND',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
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
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    ),
  );
}