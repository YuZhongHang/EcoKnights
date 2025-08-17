// ESP32 MQ135 Air Quality Monitoring System
// Pin configuration
#define MQ135_PIN A0  // For ESP32-S3, use A0-A7 or GPIO 1-10 for ADC
#define BUZZER_PIN 2  // Optional: buzzer for alerts
#define LED_PIN 2     // Optional: LED indicator

// MQ135 sensor parameters
#define RL_VALUE 10.0          // Load resistance in kOhms
#define RO_CLEAN_AIR_FACTOR 3.6 // RO_CLEAR_AIR_FACTOR=(Sensor resistance in clean air)/RL
#define CALIBRATION_SAMPLE_TIMES 50
#define CALIBRATION_SAMPLE_INTERVAL 500
#define READ_SAMPLE_INTERVAL 50
#define READ_SAMPLE_TIMES 5

// Gas concentration curves (approximated values)
#define GAS_CO2 0
float CO2Curve[3] = {2.602, 0.053, -0.42}; // (x, y, slope)

float Ro = 10.0; // Sensor resistance in clean air

void setup() {
  Serial.begin(115200);
  pinMode(MQ135_PIN, INPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(LED_PIN, OUTPUT);
  
  Serial.println("ESP32 MQ135 Air Quality Monitor");
  Serial.println("Calibrating sensor...");
  
  // Calibrate the sensor
  Ro = MQCalibration(MQ135_PIN);
  Serial.print("Calibration completed. Ro = ");
  Serial.print(Ro);
  Serial.println(" kohm");
  Serial.println("Sensor ready!");
  Serial.println("Format: Raw Value | Voltage | Resistance | CO2 PPM | Air Quality");
  Serial.println("------------------------------------------------------------");
}

void loop() {
  // Read raw analog value
  int rawValue = analogRead(MQ135_PIN);
  
  // Convert to voltage (ESP32 ADC is 12-bit, 0-4095, with 3.3V reference)
  float voltage = (rawValue * 3.3) / 4095.0;
  
  // Calculate sensor resistance
  float resistance = MQGetGasPercentage(MQRead(MQ135_PIN) / Ro, GAS_CO2);
  
  // Get CO2 concentration in PPM
  float co2_ppm = MQGetGasPercentage(MQRead(MQ135_PIN) / Ro, GAS_CO2);
  
  // Determine air quality level
  String airQuality = getAirQualityLevel(co2_ppm);
  
  // Print readings
  Serial.print("Raw: ");
  Serial.print(rawValue);
  Serial.print(" | Voltage: ");
  Serial.print(voltage, 2);
  Serial.print("V | Resistance: ");
  Serial.print(MQRead(MQ135_PIN), 2);
  Serial.print(" kohm | CO2: ");
  Serial.print(co2_ppm, 0);
  Serial.print(" PPM | Quality: ");
  Serial.println(airQuality);
  
  // Alert system (optional)
  if (co2_ppm > 1000) {
    digitalWrite(LED_PIN, HIGH);
    tone(BUZZER_PIN, 1000, 200);
  } else {
    digitalWrite(LED_PIN, LOW);
  }
  
  delay(2000); // Read every 2 seconds
}

// Function to calibrate the sensor
float MQCalibration(int mq_pin) {
  float val = 0;
  
  for (int i = 0; i < CALIBRATION_SAMPLE_TIMES; i++) {
    val += MQResistanceCalculation(analogRead(mq_pin));
    delay(CALIBRATION_SAMPLE_INTERVAL);
  }
  val = val / CALIBRATION_SAMPLE_TIMES;
  val = val / RO_CLEAN_AIR_FACTOR;
  
  return val;
}

// Function to read sensor resistance
float MQRead(int mq_pin) {
  float rs = 0;
  
  for (int i = 0; i < READ_SAMPLE_TIMES; i++) {
    rs += MQResistanceCalculation(analogRead(mq_pin));
    delay(READ_SAMPLE_INTERVAL);
  }
  rs = rs / READ_SAMPLE_TIMES;
  
  return rs;
}

// Function to calculate sensor resistance
float MQResistanceCalculation(int raw_adc) {
  float voltage = (float)raw_adc * 3.3 / 4095.0;
  if (voltage == 0) return 0;
  return ((3.3 * RL_VALUE) / voltage) - RL_VALUE;
}

// Function to get gas concentration
float MQGetGasPercentage(float rs_ro_ratio, int gas_id) {
  if (gas_id == GAS_CO2) {
    return MQGetPercentage(rs_ro_ratio, CO2Curve);
  }
  return 0;
}

// Function to calculate percentage
float MQGetPercentage(float rs_ro_ratio, float *curve) {
  return (pow(10, (((log10(rs_ro_ratio) - curve[1]) / curve[2]) + curve[0])));
}

// Function to determine air quality level
String getAirQualityLevel(float co2_ppm) {
  if (co2_ppm < 400) {
    return "Excellent";
  } else if (co2_ppm < 600) {
    return "Good";
  } else if (co2_ppm < 1000) {
    return "Fair";
  } else if (co2_ppm < 1500) {
    return "Poor";
  } else {
    return "Very Poor";
  }
}

// Function to get detailed air quality information
void printAirQualityInfo() {
  Serial.println("\n=== Air Quality Reference ===");
  Serial.println("CO2 Levels (PPM):");
  Serial.println("< 400:     Excellent (Outdoor air)");
  Serial.println("400-600:   Good (Acceptable indoor)");
  Serial.println("600-1000:  Fair (Drowsiness possible)");
  Serial.println("1000-1500: Poor (Stuffy air)");
  Serial.println("> 1500:    Very Poor (Health effects)");
  Serial.println("=============================\n");
}