#include <Servo.h>

Servo myServo;
int currentAngle = 90;
int stepSize = 1;
const int analogPin = A6;
bool running = false;
const float Vcc_source = 3.30;
const float Vcc_adc = 4.914; //ADC reference voltage have measured with internal 1.1V reference
const float R_ref = 46700.0; // 47kΩ

// ── Tunable parameters ──────────────────────────────────────────
const float ANGULAR_VELOCITY_DEG_S = 90.0; // ← change this (degrees / second)

// SETTLE_MS is derived automatically — do not edit manually
// Formula: time per step (ms) = (stepSize / angular_velocity) * 1000
const int SETTLE_MS      = (int)(stepSize * 1000.0 / ANGULAR_VELOCITY_DEG_S);
const int BETWEEN_TRIALS = 70;  // ms pause between trials
// ────────────────────────────────────────────────────────────────


void setup() {
  Serial.begin(9600);
  myServo.attach(9);         // Servo motor 9 numaralı pine bağlı
  myServo.write(90);   // start at 90°
  //delay(500);          // let servo physically reach 90° before first trial
}

float readResistance() {
  int   sensorValue = analogRead(analogPin);
  float voltage     = sensorValue * (Vcc_adc / 1023.0);
  float R_tpu       = (voltage * R_ref) / (Vcc_source - voltage);
  return R_tpu;
}

void loop() {
  if (Serial.available()) {
    Serial.read();  // wait for trigger character

        // ── Print angular velocity once at the top ────────────────
    Serial.print("Angular velocity: ");
    Serial.print(ANGULAR_VELOCITY_DEG_S, 1);
    Serial.print(" deg/s  |  Step size: ");
    Serial.print(stepSize);
    Serial.print(" deg  |  Settle delay: ");
    Serial.print(SETTLE_MS);
    Serial.println(" ms/step");
    Serial.println("Trial Angle Resistance(Ohm)");
    // ─────────────────────────────────────────────────────────

     for (int j = 1; j <=700; j=j+1 ) {

      // ── Make sure servo is at 90° before bending starts ──────
      myServo.write(90);
      delay(70);  // give it time to physically reach 90°
      

      // ── BENDING: 90° → 0° (angle printed as 0→90) ───────────
      for (int i = 90; i >= 0; i -= stepSize) {
        myServo.write(i);
        delay(SETTLE_MS);          // FIX: wait BEFORE reading, same as release

        float R = readResistance();

        Serial.print(j);
        Serial.print(" ");
        Serial.print(90 - i);      // prints 0→90
        Serial.print(" ");
        Serial.println(R, 1);
      }

      delay(BETWEEN_TRIALS);


      // ── RELEASING: 0° → 90° (angle printed as 90→0) ─────────
      int printAngle = 90;
      for (int i = 0; i <= 90; i += stepSize) {
        myServo.write(i);
        delay(SETTLE_MS);          // same delay as bending

        float R = readResistance();

        Serial.print(j);
        Serial.print(" ");
        Serial.print(printAngle);  // prints 90→0
        Serial.print(" ");
        Serial.println(R, 1);

        printAngle--;
      }

      delay(BETWEEN_TRIALS);
    }

    Serial.println("DONE");
    while (true);  // stop after all trials
  }
}
     
