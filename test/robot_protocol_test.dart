import 'package:app_robot_sumo/screens/control_screen.dart';
import 'package:app_robot_sumo/services/bluetooth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('los comandos coinciden con comandoRC() del firmware', () {
    expect(robotCommandCodes, {
      RobotCommand.forward: 'F',
      RobotCommand.backward: 'B',
      RobotCommand.left: 'L',
      RobotCommand.right: 'R',
      RobotCommand.stop: 'S',
    });
  });

  test('la trama del joystick cabe en el buffer de 16 bytes del firmware', () {
    expect(joystickFrame(-100, -100), '<-100,-100>');
    expect(joystickFrame(-100, -100).length, lessThan(16));
  });

  group('joystickToXY', () {
    const max = 80.0;

    test('arriba en pantalla es avanzar', () {
      expect(joystickToXY(const Offset(0, -max), max), (0, 100));
    });

    test('abajo en pantalla es retroceder', () {
      expect(joystickToXY(const Offset(0, max), max), (0, -100));
    });

    test('derecha e izquierda son giros', () {
      expect(joystickToXY(const Offset(max, 0), max), (100, 0));
      expect(joystickToXY(const Offset(-max, 0), max), (-100, 0));
    });

    test('es proporcional', () {
      expect(joystickToXY(const Offset(max / 2, -max / 4), max), (50, 25));
    });
  });
}
