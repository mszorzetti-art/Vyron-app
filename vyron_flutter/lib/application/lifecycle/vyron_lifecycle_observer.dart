import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/vyron_access_notifier.dart';

/// Observador global de ciclo de vida Android/iOS e atividade do usuário:
/// - Registra toques na interface (throttle de 10s no VyronAccessNotifier).
/// - Verifica expiração de sessão e tempo de ociosidade a cada 15s.
/// - Reavalia imediatamente ao retornar para primeiro plano (`AppLifecycleState.resumed`).
class VyronLifecycleObserver extends ConsumerStatefulWidget {
  const VyronLifecycleObserver({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<VyronLifecycleObserver> createState() =>
      _VyronLifecycleObserverState();
}

class _VyronLifecycleObserverState extends ConsumerState<VyronLifecycleObserver>
    with WidgetsBindingObserver {
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _idleTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) {
        if (!mounted) return;
        ref.read(vyronAccessProvider.notifier).checkInactivityAndExpiry();
      },
    );
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(vyronAccessProvider.notifier).onAppLifecycleStateChanged(state);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        ref.read(vyronAccessProvider.notifier).recordUserActivity();
      },
      child: widget.child,
    );
  }
}
