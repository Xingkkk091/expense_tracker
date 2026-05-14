import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// 啟動時的 PIN/生物辨識鎖定畫面
class AppLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const AppLockScreen({super.key, required this.onUnlocked});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final _auth = AuthService();
  final List<String> _entered = [];
  String? _error;
  bool _tryingBiometric = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    final enabled = await _auth.isBiometricEnabled();
    if (!enabled) return;
    if (!await _auth.canCheckBiometric()) return;
    setState(() => _tryingBiometric = true);
    final ok = await _auth.authenticateBiometric();
    setState(() => _tryingBiometric = false);
    if (ok && mounted) widget.onUnlocked();
  }

  Future<void> _onKey(String k) async {
    if (k == '⌫') {
      if (_entered.isNotEmpty) setState(() => _entered.removeLast());
      return;
    }
    if (_entered.length >= 4) return;
    setState(() => _entered.add(k));
    if (_entered.length == 4) {
      final pin = _entered.join();
      final ok = await _auth.verifyPin(pin);
      if (ok && mounted) {
        widget.onUnlocked();
      } else {
        setState(() {
          _error = 'PIN 錯誤';
          _entered.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Icon(Icons.lock_outline,
                size: 56, color: theme.colorScheme.onPrimary),
            const SizedBox(height: 16),
            Text('請輸入 PIN 解鎖',
                style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < _entered.length;
                return Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled
                        ? theme.colorScheme.onPrimary
                        : Colors.transparent,
                    border: Border.all(
                        color: theme.colorScheme.onPrimary, width: 1.5),
                  ),
                );
              }),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: TextStyle(
                      color: theme.colorScheme.errorContainer, fontSize: 13)),
            ],
            const Spacer(),
            _PinPad(onKey: _onKey, onBiometric: _tryBiometric),
            const SizedBox(height: 24),
            if (_tryingBiometric)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: CircularProgressIndicator(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}

class _PinPad extends StatelessWidget {
  final ValueChanged<String> onKey;
  final VoidCallback onBiometric;
  const _PinPad({required this.onKey, required this.onBiometric});

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '👆', '0', '⌫'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.4,
        ),
        itemCount: keys.length,
        itemBuilder: (context, i) {
          final k = keys[i];
          if (k == '👆') {
            return InkResponse(
              onTap: onBiometric,
              radius: 36,
              child: const Center(
                child: Icon(Icons.fingerprint,
                    color: Colors.white70, size: 32),
              ),
            );
          }
          return InkResponse(
            onTap: () => onKey(k),
            radius: 36,
            child: Center(
              child: k == '⌫'
                  ? const Icon(Icons.backspace_outlined,
                      color: Colors.white, size: 24)
                  : Text(k,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w500)),
            ),
          );
        },
      ),
    );
  }
}
