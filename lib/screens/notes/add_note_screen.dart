import 'package:flutter/material.dart';

class AddNoteScreen extends StatelessWidget {
  const AddNoteScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('Add Note')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(controller: controller, maxLines: 8, decoration: const InputDecoration(border: OutlineInputBorder())),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () {}, child: const Text('Save'))
          ],
        ),
      ),
    );
  }
}
