// Prueba de motores sin Bluetooth ni app, con los pines del diagrama original.
// Repite: Motor A, Motor B y ambos, siempre hacia adelante.
// El LED L parpadea 1, 2 o 3 veces para indicar el paso, y queda encendido
// mientras los motores tienen orden de avanzar.

const int ENA = 5;   // Motor A
const int IN1 = 7;
const int IN2 = 8;
const int ENB = 6;   // Motor B
const int IN3 = 9;
const int IN4 = 12;
const int LED = 13;

const unsigned long TIEMPO_MOTOR_MS = 3000;
const unsigned long PAUSA_MS = 1000;

void setup()
{
  pinMode(ENA, OUTPUT); pinMode(IN1, OUTPUT); pinMode(IN2, OUTPUT);
  pinMode(ENB, OUTPUT); pinMode(IN3, OUTPUT); pinMode(IN4, OUTPUT);
  pinMode(LED, OUTPUT);

  // Los motores se controlan con IN1-IN4; ENA y ENB quedan siempre activos.
  detener();
  digitalWrite(ENA, HIGH);
  digitalWrite(ENB, HIGH);

  delay(3000);
}

void loop()
{
  paso(1, true, false);  // solo Motor A
  paso(2, false, true);  // solo Motor B
  paso(3, true, true);   // ambos
}

void paso(int numero, bool motorA, bool motorB)
{
  for (int i = 0; i < numero; i++)
  {
    digitalWrite(LED, HIGH);
    delay(200);
    digitalWrite(LED, LOW);
    delay(300);
  }

  digitalWrite(IN1, motorA ? HIGH : LOW);
  digitalWrite(IN3, motorB ? HIGH : LOW);
  digitalWrite(LED, HIGH);
  delay(TIEMPO_MOTOR_MS);

  detener();
  digitalWrite(LED, LOW);
  delay(PAUSA_MS);
}

void detener()
{
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, LOW);
}
