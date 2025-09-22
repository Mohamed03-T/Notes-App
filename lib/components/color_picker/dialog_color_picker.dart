import 'package:flutter/material.dart';

Future<int?> showColorPickerDialog(BuildContext context, {int? initialColor}) async {
  final colors = [
    Colors.white.value,
    0xFFFFCDD2,
    0xFFFFE0B2,
    0xFFFFF9C4,
    0xFFC8E6C9,
    0xFFBBDEFB,
    0xFFD1C4E9,
    0xFFFFF3E0,
    0xFFE0F7FA,
    0xFFF3E5F5,
  ];

  int? selected = initialColor;

  return showDialog<int?>(
    context: context,
    builder: (ctx) {
      final controller = TextEditingController(text: initialColor != null ? initialColor.toRadixString(16).toUpperCase() : '');
      return AlertDialog(
        title: const Text('Select color'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: colors.map((c) {
                  final col = Color(c);
                  return GestureDetector(
                    onTap: () => selected = c,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: col,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.grey.shade300, width: selected == c ? 3 : 1),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Hex (ARGB or RGB)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              // try parse hex
              final txt = controller.text.trim();
              if (txt.isNotEmpty) {
                try {
                  final parsed = int.parse(txt, radix: 16);
                  // if length == 6 assume RGB => add FF alpha
                  int value = parsed;
                  if (txt.length == 6) value = 0xFF000000 | parsed;
                  selected = value;
                } catch (_) {}
              }
              Navigator.pop(ctx, selected);
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
