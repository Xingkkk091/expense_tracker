import 'package:flutter/material.dart';

/// 自訂 numpad 風格金額輸入鍵盤
/// onQuickAdd 為 +10/+100/+1000 等快速加值
class AmountKeypad extends StatelessWidget {
  final ValueChanged<String> onKeyTap;
  final VoidCallback onBackspace;
  final ValueChanged<int>? onQuickAdd;

  const AmountKeypad({
    super.key,
    required this.onKeyTap,
    required this.onBackspace,
    this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context) {
    final keys = [
      '1', '2', '3',
      '4', '5', '6',
      '7', '8', '9',
      '.', '0', '⌫',
    ];
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onQuickAdd != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                for (final v in const [10, 50, 100, 500, 1000])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: BorderSide(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.4)),
                        ),
                        onPressed: () => onQuickAdd!(v),
                        child: Text(
                          '+$v',
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        GridView.builder(
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
        ),
      ],
    );
  }
}
