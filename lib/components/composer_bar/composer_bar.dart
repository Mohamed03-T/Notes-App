import 'package:flutter/material.dart';

class ComposerBar extends StatelessWidget {
  final void Function(String)? onSend;

  const ComposerBar({Key? key, this.onSend}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        color: Colors.white,
        child: Row(
          children: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.photo)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.mic)),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration.collapsed(hintText: 'Write a note...'),
              ),
            ),
            IconButton(
                onPressed: () {
                  if (onSend != null) onSend!(controller.text);
                  controller.clear();
                },
                icon: const Icon(Icons.send)),
          ],
        ),
      ),
    );
  }
}
