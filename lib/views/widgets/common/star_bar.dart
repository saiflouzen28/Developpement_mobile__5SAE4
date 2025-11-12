import 'package:flutter/material.dart';

class StarBar extends StatelessWidget {
  final double value; // 0..5
  final int count;
  final double size;
  final Color? color;

  const StarBar({
    super.key,
    required this.value,
    this.count = 0,
    this.size = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Colors.amber;
    final full = value.floor();
    final hasHalf = (value - full) >= 0.5;
    const total = 5;

    final stars = <Widget>[
      for (int i = 0; i < full; i++) Icon(Icons.star, size: size, color: themeColor),
      if (hasHalf) Icon(Icons.star_half, size: size, color: themeColor),
      for (int i = (hasHalf ? full + 1 : full); i < total; i++)
        Icon(Icons.star_border, size: size, color: themeColor),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...stars,
        const SizedBox(width: 6),
        Text(value.toStringAsFixed(1), style: Theme.of(context).textTheme.bodySmall),
        if (count > 0) ...[
          const SizedBox(width: 4),
          Text('($count)', style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}
