import 'package:flutter/material.dart';

class FullScreenModal extends StatelessWidget {
  final Widget child;
  final String title;

  const FullScreenModal({super.key, required this.child, this.title = ''});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: child,
    );
  }
}
