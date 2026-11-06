#include <SoftwareSerial.h>

// ===== Pines (según diagrama) =====
const int ENA = 5;   // PWM Motor A
const int IN1 = 7;
const int IN2 = 8;
const int ENB = 6;   // PWM Motor B
const int IN3 = 9;
const int IN4 = 12;

// HC-06: TXD -> pin 10 | RXD <- pin 11 (con divisor 1k/2k)
SoftwareSerial bt(10, 11);

// ===== Ajustes =====
const unsigned long TIMEOUT_MS = 500; // sin comandos -> se detiene
const int VEL_MIN = 80;               // PWM mínimo para que los motores giren
const int ZONA_MUERTA = 10;           // % del joystick que se ignora
const int GIRO_SUAVE = 30;            // % de la rueda interior en diagonales

int velMax = 255;                     // ajustable desde la app (0-9, q)
unsigned long ultimoCmd = 0;

// Buffer para tramas analógicas <x,y>
char buf[16];
byte idx = 0;
bool leyendo = false;

void setup()
{
  pinMode(ENA, OUTPUT); pinMode(IN1, OUTPUT); pinMode(IN2, OUTPUT);
  pinMode(ENB, OUTPUT); pinMode(IN3, OUTPUT); pinMode(IN4, OUTPUT);

  Serial.begin(9600);  // monitor serie (depuración)
  bt.begin(9600);      // velocidad por defecto del HC-06
  alto();
}

void loop()
{
  while (bt.available())
  {
    procesar(bt.read());
  }

  // Failsafe: si se pierde la señal, se detiene
  if (millis() - ultimoCmd > TIMEOUT_MS)
  {
    alto();
  }
}

// ===== Recepción =====
void procesar(char c)
{
  // Joystick analógico: <x,y>  con x,y de -100 a 100
  if (c == '<') { idx = 0; leyendo = true; return; }

  if (leyendo)
  {
    if (c == '>')
    {
      buf[idx] = '\0';
      leyendo = false;
      leerXY();
    }
    else if (idx < sizeof(buf) - 1)
    {
      buf[idx++] = c;
    }
    else
    {
      leyendo = false; // trama inválida
    }
    return;
  }

  // Joystick digital (app "Arduino Bluetooth RC Car" y similares)
  comandoRC(c);
}

void leerXY()
{
  char* coma = strchr(buf, ',');
  if (!coma) return;
  *coma = '\0';

  int x = constrain(atoi(buf), -100, 100);
  int y = constrain(atoi(coma + 1), -100, 100);

  if (abs(x) < ZONA_MUERTA) x = 0;
  if (abs(y) < ZONA_MUERTA) y = 0;

  // Mezcla tipo arcade: y = avance, x = giro
  int izq = constrain(y + x, -100, 100);
  int der = constrain(y - x, -100, 100);

  mover(izq, der);
  ultimoCmd = millis();
}

void comandoRC(char c)
{
  switch (c)
  {
    case 'F': mover( 100,  100); break;              // adelante
    case 'B': mover(-100, -100); break;              // atrás
    case 'L': mover(-100,  100); break;              // izquierda (sobre su eje)
    case 'R': mover( 100, -100); break;              // derecha (sobre su eje)
    case 'G': mover( GIRO_SUAVE,  100); break;       // adelante-izquierda
    case 'I': mover( 100,  GIRO_SUAVE); break;       // adelante-derecha
    case 'H': mover(-GIRO_SUAVE, -100); break;       // atrás-izquierda
    case 'J': mover(-100, -GIRO_SUAVE); break;       // atrás-derecha
    case 'S': alto(); break;                         // stop

    case 'q': velMax = 255; return;                  // velocidad 100%
    default:
      if (c >= '0' && c <= '9')                      // velocidad 0%-90%
      {
        velMax = map(c - '0', 0, 10, VEL_MIN, 255);
      }
      return; // otros caracteres (luces, claxon) se ignoran
  }
  ultimoCmd = millis();
}

// ===== Motores =====
// izq / der: -100 (atrás) a 100 (adelante)
// Si los giros salen invertidos, intercambia Motor A y B aquí.
void mover(int izq, int der)
{
  motor(ENA, IN1, IN2, izq); // Motor A = izquierdo
  motor(ENB, IN3, IN4, der); // Motor B = derecho
}

void motor(int en, int a, int b, int v)
{
  if (v == 0)
  {
    digitalWrite(a, LOW);
    digitalWrite(b, LOW);
    analogWrite(en, 0);
    return;
  }
  digitalWrite(a, v > 0 ? HIGH : LOW);
  digitalWrite(b, v < 0 ? HIGH : LOW);
  analogWrite(en, map(abs(v), 1, 100, VEL_MIN, velMax));
}

void alto()
{
  motor(ENA, IN1, IN2, 0);
  motor(ENB, IN3, IN4, 0);
}
