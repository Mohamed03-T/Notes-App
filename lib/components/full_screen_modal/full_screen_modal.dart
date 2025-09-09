import 'package:flutter/material.dart';

class FullScreenModal extends StatelessWidget {
  final Widget child;
  final String title;

  const FullScreenModal({Key? key, required this.child, this.title = ''}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: child,
    );
  }
}
