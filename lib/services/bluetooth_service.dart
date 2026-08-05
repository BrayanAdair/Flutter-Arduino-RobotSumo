import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

/// Comandos que entiende el firmware del robot sumo (HC-06).
/// El modo RC del Arduino compara caracteres en minuscula estilo WASD
/// ('w','a','s','d'); cualquier caracter no reconocido (como 'S' mayuscula)
/// cae en su rama por defecto y llama a alto(), por lo que sirve como stop.
enum RobotCommand { forward, backward, left, right, stop }

const Map<RobotCommand, String> robotCommandCodes = {
  RobotCommand.forward: 'w',
  RobotCommand.backward: 's',
  RobotCommand.left: 'a',
  RobotCommand.right: 'd',
  RobotCommand.stop: 'S',
};

/// Encapsula toda la logica de conexion Bluetooth SPP y envio de comandos.
/// Las pantallas solo deben hablar con esta clase, nunca con el plugin directamente.
class RobotBluetoothService {
  RobotBluetoothService._internal();

  static final RobotBluetoothService instance = RobotBluetoothService._internal();

  BluetoothConnection? _connection;
  BluetoothDevice? _connectedDevice;
  StreamSubscription<Uint8List>? _inputSubscription;

  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();

  /// Emite `true` al conectar y `false` al desconectar (manual o por perdida de senal).
  Stream<bool> get connectionState => _connectionStateController.stream;

  bool get isConnected => _connection != null && _connection!.isConnected;

  BluetoothDevice? get connectedDevice => _connectedDevice;

  /// Pide los permisos de Bluetooth/ubicacion requeridos por Android.
  Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
    ].request();

    return statuses.values.every(
      (status) => status.isGranted || status.isLimited,
    );
  }

  Future<bool> isBluetoothEnabled() async {
    return await FlutterBluetoothSerial.instance.isEnabled ?? false;
  }

  Future<bool> requestEnableBluetooth() async {
    return await FlutterBluetoothSerial.instance.requestEnable() ?? false;
  }

  Future<List<BluetoothDevice>> getBondedDevices() async {
    return await FlutterBluetoothSerial.instance.getBondedDevices();
  }

  /// Conecta al dispositivo indicado. Lanza una excepcion si falla.
  Future<void> connect(BluetoothDevice device) async {
    await disconnect();

    final connection = await BluetoothConnection.toAddress(device.address);
    _connection = connection;
    _connectedDevice = device;

    _inputSubscription = connection.input!.listen((_) {});
    _inputSubscription!.onDone(_handleRemoteDisconnection);

    _connectionStateController.add(true);
  }

  /// Desconecta manualmente (por ejemplo, al presionar el boton de desconectar).
  Future<void> disconnect() async {
    if (_connection == null) return;

    try {
      await _inputSubscription?.cancel();
      await _connection!.finish();
    } catch (_) {
      // Se ignora: la conexion puede ya estar cerrada.
    }

    _connection = null;
    _connectedDevice = null;
    _connectionStateController.add(false);
  }

  void _handleRemoteDisconnection() {
    _connection = null;
    _connectedDevice = null;
    _connectionStateController.add(false);
  }

  /// Envia un unico byte/caracter asociado al comando.
  void sendCommand(RobotCommand command) {
    if (!isConnected) return;
    final code = robotCommandCodes[command]!;
    _connection!.output.add(Uint8List.fromList(utf8.encode(code)));
  }
}
