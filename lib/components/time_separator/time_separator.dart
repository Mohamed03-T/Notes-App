import 'package:flutter/material.dart';

class TimeSeparator extends StatelessWidget {
  final String label;

  const TimeSeparator({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(20)),
        child: Text(label),
      ),
    );
  }
}
