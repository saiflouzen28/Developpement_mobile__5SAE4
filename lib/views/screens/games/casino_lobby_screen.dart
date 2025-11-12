// lib/views/screens/games/casino_lobby_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../core/constant/app_theme.dart';
import 'components/game_card.dart';
import 'slot_machine_screen.dart';
import 'blackjack_screen.dart';
import 'roulette_screen.dart';

class CasinoLobbyScreen extends StatelessWidget {
  const CasinoLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = Provider.of<WalletProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0d0d1a),
      appBar: AppBar(
        title: const Text(
          '🎰 CASINO',
          style: TextStyle(
            color: Colors.amber,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: const Color(0xFF1a1a2e),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.amber, Colors.orange],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.white, size: 24),
                const SizedBox(width: 6),
                Text(
                  '${wallet.balance}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1a1a2e),
              const Color(0xFF0d0d1a),
              Colors.purple.shade900.withOpacity(0.3),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Welcome Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6366F1),
                    Color(0xFF8B5CF6),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    '🎲 WELCOME TO THE CASINO 🎲',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your Balance: ${wallet.balance} Coins',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.amber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Play smart, win big! 💰',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'CHOOSE YOUR GAME',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Slot Machine Card
            GameCard(
              title: '🎰 Slot Machine',
              description: '5 coins per spin – Win up to ×20!\nMatch 3 emojis to win big! 🍒🍋💎',
              icon: Icons.casino_rounded,
              color: Colors.red[700]!,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SlotMachineScreen()),
              ),
            ),

            const SizedBox(height: 12),

            // Blackjack Card
            GameCard(
              title: '🃏 Blackjack',
              description: '10 coins per hand – Classic 21!\nBeat the dealer without busting!',
              icon: Icons.style,
              color: Colors.green[700]!,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BlackjackScreen()),
              ),
            ),

            const SizedBox(height: 12),

            // Roulette Card
            GameCard(
              title: '🎡 Roulette',
              description: '5 coins per spin – Spin to win!\nRed, Black, Even, Odd, or Green!',
              icon: Icons.trip_origin,
              color: Colors.orange[700]!,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RouletteScreen()),
              ),
            ),

            const SizedBox(height: 32),

            // Bottom Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: const Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Game Rules:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Slot Machine: Match 3 symbols to win\n'
                        '• Blackjack: Get 21 or closer than dealer\n'
                        '• Roulette: Bet on colors, numbers, or ranges',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/profile'),
        label: const Text(
          'Charge Wallet',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add_card),
        backgroundColor: AppTheme.secondaryColor,
        elevation: 8,
      ),
    );
  }
}