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
  _ControlMode _mode = _ControlMode.joystick;

  static const _repeatInterval = Duration(milliseconds: 150);

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
    _repeatTimer?.cancel();
    _connectionSub?.cancel();
    super.dispose();
  }

  /// Envia [command] repetidamente cada 150ms mientras siga activo.
  /// `null` detiene el envio periodico y manda un stop unico.
  void _setCommand(RobotCommand? command) {
    if (_activeCommand == command) return;
    _activeCommand = command;
    _repeatTimer?.cancel();

    if (command == null) {
      _bluetoothService.sendCommand(RobotCommand.stop);
      return;
    }

    _bluetoothService.sendCommand(command);
    _repeatTimer = Timer.periodic(_repeatInterval, (_) {
      _bluetoothService.sendCommand(command);
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
                    ? _Joystick(onCommandChanged: _setCommand)
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

/// Modo joystick: cuantiza la posicion del pulgar en una de las 4 direcciones
/// cardinales (la de mayor magnitud), con una zona muerta central para el
/// stop. Ver nota de diseno en el mensaje anterior: el firmware solo entiende
/// 'w'/'a'/'s'/'d', asi que no hay velocidad ni diagonales proporcionales.
class _Joystick extends StatefulWidget {
  const _Joystick({required this.onCommandChanged});

  final ValueChanged<RobotCommand?> onCommandChanged;

  @override
  State<_Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<_Joystick> {
  static const double _baseRadius = 100;
  static const double _knobRadius = 40;
  static const double _deadZone = 0.35;

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
      widget.onCommandChanged(null);
      return;
    }

    final command = delta.dx.abs() > delta.dy.abs()
        ? (delta.dx > 0 ? RobotCommand.right : RobotCommand.left)
        : (delta.dy > 0 ? RobotCommand.backward : RobotCommand.forward);
    widget.onCommandChanged(command);
  }

  void _reset() {
    setState(() => _knobOffset = Offset.zero);
    widget.onCommandChanged(null);
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
