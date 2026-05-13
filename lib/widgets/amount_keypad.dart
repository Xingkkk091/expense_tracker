import 'package:flutter/material.dart';

/// 自訂 numpad 風格金額輸入鍵盤
class AmountKeypad extends StatelessWidget {
  final ValueChanged<String> onKeyTap;
  final VoidCallback onBackspace;
  final VoidCallback? onDone;

  const AmountKeypad({
    super.key,
    required this.onKeyTap,
    required this.onBackspace,
    this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final keys = [
      '1', '2', '3',
      '4', '5', '6',
      '7', '8', '9',
      '.', '0', '⌫',
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 2.4,
      ),
      itemCount: keys.length,
      itemBuilder: (context, i) {
        final k = keys[i];
        final theme = Theme.of(context);
        return Material(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              if (k == '⌫') {
                onBackspace();
              } else {
                onKeyTap(k);
              }
            },
            child: Center(
              child: k == '⌫'
                  ? const Icon(Icons.backspace_outlined, size: 22)
                  : Text(k,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w600)),
            ),
          ),
        );
      },
    );
  }
}
