import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class ResultDialog extends StatelessWidget {
  final String title;
  final String message;
  final int coinsWon;
  final bool isJackpot;

  const ResultDialog({
    super.key,
    required this.title,
    required this.message,
    required this.coinsWon,
    this.isJackpot = false,
  });

  @override
  Widget build(BuildContext context) {
    final confettiCtrl = ConfettiController(duration: const Duration(seconds: 3));

    if (isJackpot) confettiCtrl.play();

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 12),
              if (coinsWon > 0)
                Text('+$coinsWon coins',
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber)),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'))
          ],
        ),
        if (isJackpot)
          ConfettiWidget(
            confettiController: confettiCtrl,
            blastDirectionality: BlastDirectionality.explosive,
            colors: const [
              Colors.red,
              Colors.yellow,
              Colors.green,
              Colors.blue
            ],
          ),
      ],
    );
  }
}