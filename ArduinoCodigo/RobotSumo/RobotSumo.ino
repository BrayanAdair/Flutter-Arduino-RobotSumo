int motB0 = 2; 
int motB1 = 3; //PWM
int motA1 = 4;
int motA0 = 5; //PWM

int lec0=A2;
int lec1=A1;

long cont1 = 0;

int sensorleft = A7;
int sensorcenter = A6;
int sensorright = A5;
 
int l1 = 0;
int l2 = 0;
int l3 = 0;


int f1 = 0;
int f2 = 0;
int f3 = 0;
 
int f4 = 0;
int f5 = 0;
int f6 = 0;


int buzzer = 6; //El pin al que se conecta el buzzer es el 6

int echo = 8;
int triger = 7;

int vel = 200;

int led= 13;

char valorBoton;
char penultimo = 'n';
char antepenultimo = 'm';
char vali = 'b';

void setup()
{
  Serial.begin(9600);
  pinMode(led, OUTPUT);
  pinMode(motA0, OUTPUT);
  pinMode(motA1, OUTPUT);
  pinMode(motB0, OUTPUT);
  pinMode(motB1, OUTPUT);
  pinMode(buzzer, OUTPUT); // Pin 6 declarado como salida
  pinMode(echo, INPUT);
  pinMode(triger, OUTPUT);
  digitalWrite(triger, LOW);
 
  digitalWrite(motA0, LOW);
  digitalWrite(motA1, LOW);
  digitalWrite(motB0, LOW);
  digitalWrite(motB1, LOW);
  

  pinMode(sensorright, INPUT);
  pinMode(sensorcenter, INPUT);
  pinMode(sensorleft, INPUT);
  pinMode(lec0,INPUT_PULLUP);
  pinMode(lec1,INPUT_PULLUP);

  delay(1500); // tarda 1.5s en iniciar cualquier programa

}

void loop()
{
l3=analogRead(sensorleft);
l2=analogRead(sensorcenter);
l1=analogRead(sensorright);

if(digitalRead(lec0)==0){
    if(digitalRead(lec1)==0){

      if ((l1 > 550 && l2 > 550 && l3 > 550 || l1 < 550 && l2 < 550 && l3 < 550 ) && cont1 > 0) //feedback when comes all sensor on white
      {
        l1 = f1;
        l2 = f2;
        l3 = f3;
        cont1=cont1-1;//decremento de ciclos para salir de la memoria
      }

      ////////////////////////////////////////////////////////////////////////////
      
      if (l1 > 550 && l2 < 550 && l3 < 550 || l1 > 550 && l2 > 550 && l3 < 550) //left turn
      {
        izquierda();
      }
      else if (l1 < 550 && l2 < 550 && l3 > 550 || l1 < 550 && l2 > 550 && l3 > 550) //right turn
      {
        derecha();
      }
      else if (l1 < 550 && l2 > 550 && l3 < 550) //go forward straight
      {
        adelante();
        cont1 = 20000; // Numero de ciclos para mantener la memoria
      }
      else
      { 
        if(l1 > 550 && l2 > 550 && l3 > 550 || l1 < 550 && l2 < 550 && l3 < 550)  //Detener en caso de 3 sensores en el mismo color
        {
          alto();
        }
      }
     
      ///////////////////////////////////////////////////////////////////
      f1 = l1;
      f2 = l2;
      f3 = l3;

    } else{
      //A1=0 A2=1 SUMO
      // Para volverlo sumo para fondo blanco cambiar los valores del if de la siguiente manera
      //l1 > 550 && l2 > 550  && l3 > 550
     if(distancia()<150){
if(l1 > 550 || l2 > 550 || l3 > 550)
{
alto();
delay(1000);
atras();
delay(1000);
derecha();
delay(700);
}
else{
adelanter();
}
}
else
{
if(l1 > 550 || l2 > 550 || l3 > 550)
{
alto();
delay(1000);
atras();
delay(1000);
derecha();
delay(700);
}
else{
derecha();
}
} 

      
    }

  }  else{
         if(digitalRead(lec1)==0){
        //A1=1 A2=0  Evasor

        if(distancia()<15){
        alto();
        delay(500);
        atras();
        delay(700);
        derecha();
        delay(500);
        adelanter();
        }

        else {
        adelanter();
        }

        } else{
        //A1=1 A2=1 RC

       
        if(Serial.available() > 0)
      { 
        valorBoton = Serial.read();
        //Penultimo = n neutral antepenultimo = m neutral
        //Donde se quiera una izquierda se debe poner derecha y al reves
        //3 señales o 3 botones al mismo tiempo
        if((antepenultimo == 'w' && penultimo == 'd' && valorBoton == 'h') 
                  || (antepenultimo == 'w' && penultimo == 'a' && valorBoton == 'f'))//wdh o waf
        {
          vali = 'i';
          adelante();
          penultimo = 'n';
          antepenultimo = 'm';
        } 
        else if((antepenultimo == 's' && penultimo == 'd' && valorBoton == 'h') 
                  || (antepenultimo == 's' && penultimo == 'a' && valorBoton == 'f'))//sdh o saf
        {
          vali = 'k';
          atras();
          penultimo = 'n';
          antepenultimo = 'm';
        } 
        else if((antepenultimo == 'a' && penultimo == 'w' && valorBoton == 't') 
                  || (antepenultimo == 'a' && penultimo == 's' && valorBoton == 'g'))//awt o asg
        {
          vali = 'j';
          derecha();
          penultimo = 'n';
          antepenultimo = 'm';
        } 
        else if((antepenultimo == 'd' && penultimo == 'w' && valorBoton == 't') 
                  || (antepenultimo == 'd' && penultimo == 's' && valorBoton == 'g'))//dwt o dsg
        {
          vali = 'l';
          izquierda();
          penultimo = 'n';
          antepenultimo = 'm';
        } 
        else if(vali == 'i')//Validacion no se suelta adelante
        {
          adelante();
          if(valorBoton == 't')
          {
            vali = 'b';
            alto();
          }
          else if(valorBoton == 'd') { //d
            izquierda();
          }
          else if(valorBoton == 'a') { //a
            derecha();
          }
        }
        else if(vali == 'k')//Validacion no se suelta atras
        {
          atras();
          if(valorBoton == 'g')
          {
            vali = 'b';
            alto();
          }
          else if(valorBoton == 'd') { //d
            atrasderecha();
          }
          else if(valorBoton == 'a') { //a
            atrasizquierda();
          }
        }
        else if(vali == 'j')//Validacion no se suelta izquierda
        {
          derecha();
          if(valorBoton == 'f')
          {
            vali = 'b';
            alto();
          }
          else if(valorBoton == 'w') { //w
            derecha();
          }
          else if(valorBoton == 'a') { //s
            atrasderecha();
          }
        }
        else if(vali == 'l')//Validacion no se suelta derecha
        {
          izquierda();
          if(valorBoton == 'h')
          {
            vali = 'b';
            alto();
          }
          else if(valorBoton == 'w') { //w
            izquierda();
          }
          else if(valorBoton == 'a') { //s
            atrasizquierda();
          }
        }
        
        //Combinaciones de dos botones:
        else if(valorBoton == 'w') { //w
          adelante();
        }
        else if(valorBoton == 's') { //s
          atras();
        }
        else if(penultimo != 's' && valorBoton == 'a') { //a
          derecha();
        }
        else if(penultimo != 's' && valorBoton == 'd') { //d
          izquierda();
        }
        else if(penultimo == 'w' && valorBoton == 'a') { //wa
          derecha();
        }
        else if(penultimo == 'w' && valorBoton == 'd') { //wd
          izquierda();
        }
        else if(penultimo == 'w' && valorBoton == 'f') { //wf
          adelante();
        }
        else if(penultimo == 'w' && valorBoton == 'h') { //wh
          adelante();
        }
        else if(penultimo == 't' && valorBoton == 'a') { //ta
          derecha();
        }
        else if(penultimo == 't' && valorBoton == 'd') { //td
          izquierda();
        }
        else if(penultimo == 's' && valorBoton == 'a') { //sa
          atrasizquierda();
        }
        else if(penultimo == 's' && valorBoton == 'd') { //sd
          atrasderecha();
        }
        else if(penultimo == 's' && valorBoton == 'f') { //sf
          atras();
        }
        else if(penultimo == 's' && valorBoton == 'h') { //sh
          atras();
        }
        else if(penultimo == 'g' && valorBoton == 'a') { //ga
          atrasderecha();
        }
        else if(penultimo == 'g' && valorBoton == 'd') { //gd
          atrasizquierda();
        }
        //Espejo
        else if(penultimo == 'a' && valorBoton == 'w') { //aw
          derecha();
        }
        else if(penultimo == 'd' && valorBoton == 'w') { //dw
          izquierda();
        }
        else if(penultimo == 'f' && valorBoton == 'w') { //fw
          adelante();
        }
        else if(penultimo == 'h' && valorBoton == 'w') { //hw
          adelante();
        }
        else if(penultimo == 'a' && valorBoton == 't') { //at
          derecha();
        }
        else if(penultimo == 'd' && valorBoton == 't') { //dt
          izquierda();
        }
        else if(penultimo == 'a' && valorBoton == 's') { //as
          atrasderecha();
        }
        else if(penultimo == 'd' && valorBoton == 's') { //ds
          atrasizquierda();
        }
        else if(penultimo == 'f' && valorBoton == 's') { //fs
          atras();
        }
        else if(penultimo == 'h' && valorBoton == 's') { //hs
          atras();
        }
        else if(penultimo == 'a' && valorBoton == 'g') { //ag
          atrasderecha();
        }
        else if(penultimo == 'd' && valorBoton == 'g') { //dg
          atrasizquierda();
        }
        
        else {
          //Si se presionan más de dos botones o no se presionan los adecuados
          alto();
          penultimo = 'n';
          antepenultimo = 'm';
          
        }
        //Actualizar la penultimo

        Serial.print(antepenultimo);
        Serial.print("  ");
        Serial.print(penultimo);
        Serial.print("  ");
        Serial.print(valorBoton);
        Serial.print("  ");
        Serial.print(vali);
        Serial.println("  ");
        
        
        antepenultimo = penultimo;
        penultimo = valorBoton;
        /*if(valorBoton != penultimo) {
          penultimo = valorBoton;*/
      
      }

        }

  }

}

long distancia()
{
  long t;
  long d;

  digitalWrite(triger, HIGH);
  delayMicroseconds(10);
  digitalWrite(triger, LOW);

  t = pulseIn(echo, HIGH);
  d = t / 59;
  if (d <= 1 || d >= 25)
  {
    d = 1000;
  }
  delay(10);
  return d;
}


void alto()
{
  digitalWrite(motA0, 0);
  analogWrite(motA1, 0);//PWM
  analogWrite(motB0, 0); //PWM
  digitalWrite(motB1, 0);
}

void atras()
{
  digitalWrite(motA0, 1);
  digitalWrite(motA1, 0); //PWM
  digitalWrite(motB1, 1); //PWM
  digitalWrite(motB0, 0);
}

void adelante()
{
  digitalWrite(motA1, 1);
  digitalWrite(motA0, 0);
  digitalWrite(motB0, 1);
  digitalWrite(motB1, 0);
}
void adelanter()
{
  digitalWrite(motA1, 1);
  digitalWrite(motA0, 0);  //PWM
  digitalWrite(motB0, 1); //PWM
  digitalWrite(motB1, 0);
}

void izquierda()
{
  digitalWrite(motA0, 0);
  analogWrite(motA1, 0); //PWM
  analogWrite(motB0, 200); //PWM
  digitalWrite(motB1, 0);
}

void derecha()
{
  digitalWrite(motA1,50);
  analogWrite(motA0, 1); //PWM
  analogWrite(motB0, 0); //PWM
  digitalWrite(motB1, 0);

}

void atrasderecha(){
  digitalWrite(motA0, 0);
  digitalWrite(motA1, 0); //PWM
  digitalWrite(motB0, 0); //PWM
  digitalWrite(motB1, 1);
}


void atrasizquierda(){
  digitalWrite(motA0, 1);
  digitalWrite(motA1, 0); //PWM
  digitalWrite(motB0, 0); //PWM
  digitalWrite(motB1, 0);
}