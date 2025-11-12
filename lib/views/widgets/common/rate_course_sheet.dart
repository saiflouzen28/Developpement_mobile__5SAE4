import 'package:flutter/material.dart';

class RateCourseSheet extends StatefulWidget {
  final String courseTitle;
  final void Function(int rating, String? comment) onSubmit;

  const RateCourseSheet({
    super.key,
    required this.courseTitle,
    required this.onSubmit,
  });

  @override
  State<RateCourseSheet> createState() => _RateCourseSheetState();
}

class _RateCourseSheetState extends State<RateCourseSheet> {
  int _rating = 0;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            runSpacing: 16,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Noter ce cours',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(widget.courseTitle, style: Theme.of(context).textTheme.bodyMedium),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final idx = i + 1;
                  final active = idx <= _rating;
                  return IconButton(
                    onPressed: () => setState(() => _rating = idx),
                    icon: Icon(active ? Icons.star : Icons.star_border,
                        color: Colors.amber, size: 32),
                  );
                }),
              ),

              TextField(
                controller: _ctrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Laisser un commentaire (facultatif)',
                ),
              ),

              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _rating == 0
                      ? null
                      : () {
                    widget.onSubmit(
                      _rating,
                      _ctrl.text.trim().isEmpty ? null : _ctrl.text.trim(),
                    );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Envoyer mon avis'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
