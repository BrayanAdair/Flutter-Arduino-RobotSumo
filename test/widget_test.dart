import 'package:flutter_test/flutter_test.dart';

import 'package:app_robot_sumo/main.dart';

void main() {
  testWidgets('App arranca en la pantalla de conexion', (WidgetTester tester) async {
    await tester.pumpWidget(const RobotSumoApp());

    expect(find.text('Robot Sumo - Conexion Bluetooth'), findsOneWidget);
  });
}
