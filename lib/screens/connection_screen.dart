import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import '../services/bluetooth_service.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final _bluetoothService = RobotBluetoothService.instance;

  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _connectingDevice;
  bool _loading = true;
  bool _bluetoothEnabled = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final granted = await _bluetoothService.requestPermissions();
    if (!granted) {
      setState(() {
        _loading = false;
        _errorMessage =
            'Se requieren permisos de Bluetooth y ubicacion para continuar.';
      });
      return;
    }

    final enabled = await _bluetoothService.isBluetoothEnabled();
    if (!enabled) {
      setState(() {
        _loading = false;
        _bluetoothEnabled = false;
      });
      return;
    }

    try {
      final devices = await _bluetoothService.getBondedDevices();
      setState(() {
        _devices = devices;
        _bluetoothEnabled = true;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Error al obtener dispositivos emparejados: $e';
      });
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    setState(() => _connectingDevice = device);

    try {
      await _bluetoothService.connect(device);
      if (!mounted) return;

      await Navigator.of(context).pushNamed('/control');

      // Al regresar de la pantalla de control (desconexion), refresca el estado.
      if (mounted) _init();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('No se pudo conectar con ${device.name ?? device.address}'),
        ),
      );
    } finally {
      if (mounted) setState(() => _connectingDevice = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Robot Sumo - Conexion Bluetooth')),
      body: RefreshIndicator(
        onRefresh: _init,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_bluetoothEnabled) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'El Bluetooth esta apagado. Activalo e intenta de nuevo.',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: () async {
                await _bluetoothService.requestEnableBluetooth();
                _init();
              },
              child: const Text('Activar Bluetooth'),
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(_errorMessage!, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(onPressed: _init, child: const Text('Reintentar')),
          ),
        ],
      );
    }

    if (_devices.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'No hay dispositivos Bluetooth emparejados.\n'
              'Empareja tu modulo HC-06 desde los ajustes de Android primero.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        final isConnecting = _connectingDevice?.address == device.address;

        return ListTile(
          leading: const Icon(Icons.bluetooth),
          title: Text(device.name ?? 'Dispositivo desconocido'),
          subtitle: Text(device.address),
          trailing: isConnecting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : ElevatedButton(
                  onPressed: () => _connect(device),
                  child: const Text('Conectar'),
                ),
        );
      },
    );
  }
}
