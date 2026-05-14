import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 計算機式金額輸入鍵盤（算盤）
/// - 可輸入 + − × ÷ 連續算式
/// - 上方顯示算式，按 = 收斂為結果
/// - 每次變動透過 onChanged 回傳目前計算結果
class CalculatorKeypad extends StatefulWidget {
  final double initialValue;
  final ValueChanged<double> onChanged;

  const CalculatorKeypad({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<CalculatorKeypad> createState() => _CalculatorKeypadState();
}

class _CalculatorKeypadState extends State<CalculatorKeypad> {
  late String _expr;

  static const _ops = '+−×÷';

  @override
  void initState() {
    super.initState();
    _expr = widget.initialValue > 0
        ? _trimNum(widget.initialValue)
        : '';
  }

  static String _trimNum(double v) {
    if (v == v.truncateToDouble()) return v.toStringAsFixed(0);
    return v.toString();
  }

  bool get _endsWithOp => _expr.isNotEmpty && _ops.contains(_expr[_expr.length - 1]);

  /// 目前算式的計算結果（容錯：忽略結尾運算子）
  double get _result {
    var e = _expr;
    while (e.isNotEmpty && _ops.contains(e[e.length - 1])) {
      e = e.substring(0, e.length - 1);
    }
    return _evaluate(e) ?? 0;
  }

  void _emit() => widget.onChanged(_result);

  void _input(String k) {
    setState(() {
      switch (k) {
        case 'AC':
          _expr = '';
          break;
        case '⌫':
          if (_expr.isNotEmpty) {
            _expr = _expr.substring(0, _expr.length - 1);
          }
          break;
        case '=':
          final r = _result;
          _expr = _trimNum(r);
          break;
        case '+':
        case '−':
        case '×':
        case '÷':
          if (_expr.isEmpty) {
            // 算式不以運算子開頭（除非接續上一結果，這裡直接忽略）
            return;
          }
          if (_endsWithOp) {
            // 取代結尾運算子
            _expr = _expr.substring(0, _expr.length - 1) + k;
          } else {
            _expr += k;
          }
          break;
        case '.':
          // 找出目前數字段是否已有小數點
          final seg = _currentSegment();
          if (!seg.contains('.')) {
            _expr += seg.isEmpty ? '0.' : '.';
          }
          break;
        case '00':
          if (_expr.isEmpty || _endsWithOp) {
            _expr += '0';
          } else {
            _expr += '00';
          }
          break;
        default: // 0-9
          _expr += k;
      }
    });
    _emit();
  }

  String _currentSegment() {
    var i = _expr.length - 1;
    while (i >= 0 && !_ops.contains(_expr[i])) {
      i--;
    }
    return _expr.substring(i + 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fmt = NumberFormat('#,##0.##');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 算式顯示條
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: scheme.outline),
          ),
          child: Row(
            children: [
              Icon(Icons.calculate_outlined,
                  size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _expr.isEmpty ? '輸入金額…' : _expr,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    color: _expr.isEmpty
                        ? scheme.onSurfaceVariant
                        : scheme.onSurface,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (_expr.contains(RegExp(r'[+−×÷]'))) ...[
                const SizedBox(width: 8),
                Text(
                  '= ${fmt.format(_result)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        // 按鍵
        _buildKeys(theme),
      ],
    );
  }

  Widget _buildKeys(ThemeData theme) {
    const layout = [
      ['AC', '⌫', '÷', '×'],
      ['7', '8', '9', '−'],
      ['4', '5', '6', '+'],
      ['1', '2', '3', '='],
      ['0', '00', '.', '='],
    ];
    return Column(
      children: [
        for (final row in layout)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                for (final k in row)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _KeyButton(
                        label: k,
                        kind: _kindOf(k),
                        onTap: () => _input(k),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  _KeyKind _kindOf(String k) {
    if (k == 'AC' || k == '⌫') return _KeyKind.control;
    if (_ops.contains(k)) return _KeyKind.operator;
    if (k == '=') return _KeyKind.equals;
    return _KeyKind.number;
  }

  // ===== 算式求值（shunting-yard） =====
  static double? _evaluate(String expr) {
    if (expr.isEmpty) return null;
    final tokens = <String>[];
    final buf = StringBuffer();
    for (var i = 0; i < expr.length; i++) {
      final c = expr[i];
      if ('0123456789.'.contains(c)) {
        buf.write(c);
      } else if ('+−×÷'.contains(c)) {
        if (buf.isNotEmpty) {
          tokens.add(buf.toString());
          buf.clear();
        }
        tokens.add(c);
      }
    }
    if (buf.isNotEmpty) tokens.add(buf.toString());
    if (tokens.isEmpty) return null;

    int prec(String o) => (o == '×' || o == '÷') ? 2 : 1;
    final output = <String>[];
    final ops = <String>[];
    for (final t in tokens) {
      if (double.tryParse(t) != null) {
        output.add(t);
      } else {
        while (ops.isNotEmpty && prec(ops.last) >= prec(t)) {
          output.add(ops.removeLast());
        }
        ops.add(t);
      }
    }
    while (ops.isNotEmpty) {
      output.add(ops.removeLast());
    }

    final stack = <double>[];
    for (final t in output) {
      final n = double.tryParse(t);
      if (n != null) {
        stack.add(n);
      } else {
        if (stack.length < 2) return null;
        final b = stack.removeLast();
        final a = stack.removeLast();
        switch (t) {
          case '+':
            stack.add(a + b);
            break;
          case '−':
            stack.add(a - b);
            break;
          case '×':
            stack.add(a * b);
            break;
          case '÷':
            stack.add(b == 0 ? 0 : a / b);
            break;
        }
      }
    }
    if (stack.length != 1) return null;
    final r = stack.first;
    return r < 0 ? 0 : r; // 金額不為負
  }
}

enum _KeyKind { number, operator, control, equals }

class _KeyButton extends StatelessWidget {
  final String label;
  final _KeyKind kind;
  final VoidCallback onTap;

  const _KeyButton({
    required this.label,
    required this.kind,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color bg;
    Color fg;
    switch (kind) {
      case _KeyKind.number:
        bg = scheme.surface;
        fg = scheme.onSurface;
        break;
      case _KeyKind.operator:
        bg = scheme.surfaceContainerHighest;
        fg = scheme.primary;
        break;
      case _KeyKind.control:
        bg = scheme.surfaceContainerHighest;
        fg = scheme.onSurfaceVariant;
        break;
      case _KeyKind.equals:
        bg = scheme.primary;
        fg = scheme.onPrimary;
        break;
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: scheme.outline),
          ),
          child: label == '⌫'
              ? Icon(Icons.backspace_outlined, size: 20, color: fg)
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: kind == _KeyKind.number ? 20 : 18,
                    fontWeight: kind == _KeyKind.number
                        ? FontWeight.w400
                        : FontWeight.w600,
                    color: fg,
                  ),
                ),
        ),
      ),
    );
  }
}
