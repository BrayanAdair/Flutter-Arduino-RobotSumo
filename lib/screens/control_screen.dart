import 'dart:async';

import 'package:flutter/material.dart';

import '../services/bluetooth_service.dart';

enum _ControlMode { classic, joystick }

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  final _bluetoothService = RobotBluetoothService.instance;

  StreamSubscription<bool>? _connectionSub;
  Timer? _repeatTimer;
  RobotCommand? _activeCommand;
  int _joystickX = 0;
  int _joystickY = 0;
  _ControlMode _mode = _ControlMode.joystick;

  // Debe ser bastante menor que TIMEOUT_MS del firmware (500 ms): si no llegan
  // comandos durante ese tiempo, el robot se detiene por seguridad.
  static const _repeatInterval = Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();
    _connectionSub = _bluetoothService.connectionState.listen((connected) {
      if (!connected && mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Se perdio la conexion con el robot')),
        );
      }
    });
  }

  @override
  void dispose() {
    _stop();
    _connectionSub?.cancel();
    super.dispose();
  }

  /// Corta el envio periodico y manda un stop unico.
  void _stop() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
    _activeCommand = null;
    _bluetoothService.sendCommand(RobotCommand.stop);
  }

  /// Envia [command] repetidamente mientras siga activo; `null` equivale a stop.
  void _setCommand(RobotCommand? command) {
    if (command == null) {
      _stop();
      return;
    }
    if (_activeCommand == command) return;
    _activeCommand = command;
    _repeatTimer?.cancel();

    _bluetoothService.sendCommand(command);
    _repeatTimer = Timer.periodic(_repeatInterval, (_) {
      _bluetoothService.sendCommand(command);
    });
  }

  /// Actualiza la posicion del joystick. Los arrastres llegan mucho mas rapido
  /// de lo que transmite el enlace a 9600 baudios, asi que solo se guarda el
  /// ultimo valor y el temporizador lo envia a ritmo fijo.
  void _setJoystick(int x, int y) {
    _joystickX = x;
    _joystickY = y;

    if (x == 0 && y == 0) {
      if (_repeatTimer != null) _stop();
      return;
    }
    if (_repeatTimer != null) return;

    _bluetoothService.sendJoystick(x, y);
    _repeatTimer = Timer.periodic(_repeatInterval, (_) {
      _bluetoothService.sendJoystick(_joystickX, _joystickY);
    });
  }

  void _toggleMode() {
    // Se corta cualquier movimiento activo al cambiar de modo, para no dejar
    // un comando "pegado" enviandose desde un widget que ya no esta visible.
    _setCommand(null);
    setState(() {
      _mode = _mode == _ControlMode.joystick
          ? _ControlMode.classic
          : _ControlMode.joystick;
    });
  }

  Future<void> _disconnect() async {
    // Salida manual: el listener no debe avisar de perdida de conexion ni
    // hacer un segundo pop que dejaria la app sin pantallas.
    await _connectionSub?.cancel();
    _stop();
    await _bluetoothService.disconnect();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final device = _bluetoothService.connectedDevice;
    final deviceLabel = device?.name ?? device?.address ?? 'Robot';
    final isJoystick = _mode == _ControlMode.joystick;

    return Scaffold(
      appBar: AppBar(
        title: Text('Control - $deviceLabel'),
        actions: [
          IconButton(
            icon: Icon(isJoystick ? Icons.gamepad : Icons.control_camera),
            tooltip: isJoystick ? 'Modo clasico (botones)' : 'Modo joystick',
            onPressed: _toggleMode,
          ),
          IconButton(
            icon: const Icon(Icons.bluetooth_disabled),
            tooltip: 'Desconectar',
            onPressed: _disconnect,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                isJoystick
                    ? 'Arrastra el joystick para mover. Al soltar, el robot se detiene.'
                    : 'Manten presionado un boton para mover. Al soltar, el robot se detiene.',
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Center(
                child: isJoystick
                    ? _Joystick(onChanged: _setJoystick)
                    : _DPad(onCommandChanged: _setCommand),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  onPressed: () => _setCommand(null),
                  child: const Text(
                    'STOP',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modo clasico: D-Pad de 4 botones. Mantener presionado repite el comando
/// cada 150ms (via [onCommandChanged]); al soltar se manda `null` (stop).
class _DPad extends StatelessWidget {
  const _DPad({required this.onCommandChanged});

  final ValueChanged<RobotCommand?> onCommandChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DPadButton(
          icon: Icons.keyboard_arrow_up,
          onPressStart: () => onCommandChanged(RobotCommand.forward),
          onPressEnd: () => onCommandChanged(null),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DPadButton(
              icon: Icons.keyboard_arrow_left,
              onPressStart: () => onCommandChanged(RobotCommand.left),
              onPressEnd: () => onCommandChanged(null),
            ),
            const SizedBox(width: 12),
            _StopButton(onTap: () => onCommandChanged(null)),
            const SizedBox(width: 12),
            _DPadButton(
              icon: Icons.keyboard_arrow_right,
              onPressStart: () => onCommandChanged(RobotCommand.right),
              onPressEnd: () => onCommandChanged(null),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DPadButton(
          icon: Icons.keyboard_arrow_down,
          onPressStart: () => onCommandChanged(RobotCommand.backward),
          onPressEnd: () => onCommandChanged(null),
        ),
      ],
    );
  }
}

class _DPadButton extends StatelessWidget {
  const _DPadButton({
    required this.icon,
    required this.onPressStart,
    required this.onPressEnd,
  });

  final IconData icon;
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onPressStart(),
      onTapUp: (_) => onPressEnd(),
      onTapCancel: onPressEnd,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.blueGrey[700],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 36),
      ),
    );
  }
}

class _StopButton extends StatelessWidget {
  const _StopButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.stop, color: Colors.white, size: 36),
      ),
    );
  }
}

/// Convierte el desplazamiento del pulgar en pantalla (y crece hacia abajo) a
/// los valores de la trama `<x,y>`: x positivo = derecha, y positivo = adelante.
@visibleForTesting
(int, int) joystickToXY(Offset delta, double maxDistance) {
  int scale(double value) => (value / maxDistance * 100).round().clamp(-100, 100);
  return (scale(delta.dx), scale(-delta.dy));
}

/// Modo joystick: control proporcional de velocidad y giro. El firmware mezcla
/// x e y para calcular la velocidad de cada rueda.
class _Joystick extends StatefulWidget {
  const _Joystick({required this.onChanged});

  final void Function(int x, int y) onChanged;

  @override
  State<_Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<_Joystick> {
  static const double _baseRadius = 100;
  static const double _knobRadius = 40;
  static const double _deadZone = 0.10;

  Offset _knobOffset = Offset.zero;

  void _updateFromLocalPosition(Offset localPosition) {
    final center = Offset(_baseRadius, _baseRadius);
    var delta = localPosition - center;
    final maxDistance = _baseRadius - _knobRadius / 2;
    final distance = delta.distance;
    if (distance > maxDistance) {
      delta = delta / distance * maxDistance;
    }

    setState(() => _knobOffset = delta);

    final magnitude = delta.distance / maxDistance;
    if (magnitude < _deadZone) {
      widget.onChanged(0, 0);
      return;
    }

    final (x, y) = joystickToXY(delta, maxDistance);
    widget.onChanged(x, y);
  }

  void _reset() {
    setState(() => _knobOffset = Offset.zero);
    widget.onChanged(0, 0);
  }

  @override
  Widget build(BuildContext context) {
    final size = _baseRadius * 2;
    return GestureDetector(
      onPanStart: (details) => _updateFromLocalPosition(details.localPosition),
      onPanUpdate: (details) => _updateFromLocalPosition(details.localPosition),
      onPanEnd: (_) => _reset(),
      onPanCancel: _reset,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blueGrey[900],
          border: Border.all(color: Colors.blueGrey[700]!, width: 2),
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            transform: Matrix4.translationValues(_knobOffset.dx, _knobOffset.dy, 0),
            width: _knobRadius * 2,
            height: _knobRadius * 2,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blueAccent,
              boxShadow: [
                BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
