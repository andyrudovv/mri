import 'package:flutter/material.dart';

class MRIsummary extends StatelessWidget {
  final String? result;
  final Map<String, dynamic>? probabilities;

  const MRIsummary({super.key, this.result, this.probabilities});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      height: 600,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(13),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Predicted Class: ${result ?? 'No prediction yet'}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (probabilities != null && probabilities!.isNotEmpty)
              ...probabilities!.entries.map(
                (e) => Text(
                  "${e.key}: ${e.value.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
