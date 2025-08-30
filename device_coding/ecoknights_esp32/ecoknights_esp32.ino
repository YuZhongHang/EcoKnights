// Port "ESP32 Dev Module" - COM9
// ----------------- Integration -----------------
// ----------------- ESP32 Setup -----------------
// VIN->'+'Rail(Red), GND->'-'Rail(Black)

// ----------------- OLED Setup ------------------
// GND(Black), VCC(Red), SCL->D26(Yellow), SDA->D25(Yellow)

// ----------------- MQ-135 Setup ----------------
// VCC(Red), GND(Black), AO->D34(Orange)

// ----------------- DHT22 Setup -----------------
// +->'+'Rail(Red), out->D27(Dark Cho), -->'-'Rail(Black)
// Red->'+'Rail, Black->'-'Rail, Green->'+'Rail, Blue->'-'Rail, Yellow->D32, White->D33


#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include "DHT.h"
#include <WiFi.h>
#include "time.h"

// ----------------- OLED Setup -----------------
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET    -1
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// ----------------- MQ-135 Setup ----------------
#define MQ135_PIN 34  // Analog pin for MQ135
#define RL_VALUE 10.0          
#define RO_CLEAN_AIR_FACTOR 3.6 
#define CALIBRATION_SAMPLE_TIMES 50
#define CALIBRATION_SAMPLE_INTERVAL 500
#define READ_SAMPLE_INTERVAL 50
#define READ_SAMPLE_TIMES 5
#define GAS_CO2 0
float CO2Curve[3] = {2.602, 0.053, -0.42}; 
float Ro = 10.0;

// ----------------- DHT22 Setup -----------------
#define DHT_PIN 27     // DATA pin for DHT22
#define DHT_TYPE DHT22
DHT dht(DHT_PIN, DHT_TYPE);

// --------------- Dust Sensor Setup ---------------
#define DUST_PIN 32   // Analog pin for GP2Y1010AU0F
#define DUST_LED_PIN 33 // Control pin for dust sensor LED


// --------------- Wifi Setup ---------------
const char* ssid     = "OPPO Mr Fish"; //Wifi_SSID
const char* password = "mrfishmrfish"; // Wifi_Password

// NTP server and timezone
const char* ntpServer = "pool.ntp.org";
const long  gmtOffset_sec = 8 * 3600; // GMT+8 for Malaysia
const int   daylightOffset_sec = 0;

// ----------------- Setup -----------------
void setup() {
  Serial.begin(115200);
  pinMode(MQ135_PIN, INPUT);
  pinMode(DUST_PIN, INPUT);
  pinMode(DUST_LED_PIN, OUTPUT);

  dht.begin(); // Initialize DHT22

  // OLED init
  Wire.begin(25, 26); // SDA, SCL
  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println(F("SSD1306 allocation failed"));
    for(;;);
  }
  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);

  Serial.println("ESP32 Air Quality + Dust + Temp/Humidity Monitor");
  Serial.println("Calibrating MQ-135 sensor...");
  
  // Calibrate MQ-135
  Ro = MQCalibration(MQ135_PIN);
  Serial.print("Calibration completed. Ro = ");
  Serial.print(Ro);
  Serial.println(" kohm");
  Serial.println("Sensor ready!");

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.print(ssid);
  Serial.println(" WiFi connected");

  // init and get the time
  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
}

// ----------------- Loop -----------------
void loop() {
  // ----- Timestamp Read -----
  struct tm timeinfo;
  if(!getLocalTime(&timeinfo)){
    Serial.println("Failed to obtain time");
    return;
  }

  // ----- MQ-135 Read -----
  int mq_raw = analogRead(MQ135_PIN);
  float mq_resistance = MQRead(MQ135_PIN);
  float co2_ppm = MQGetGasPercentage(mq_resistance / Ro, GAS_CO2);
  String airQuality = getAirQualityLevel(co2_ppm);

  // ----- Dust Sensor Read -----
  digitalWrite(DUST_LED_PIN, HIGH); // Turn on IR LED
  delayMicroseconds(280);
  int dust_raw = analogRead(DUST_PIN); // Read ADC
  digitalWrite(DUST_LED_PIN, LOW); // Turn off IR LED
  delayMicroseconds(9680); // Wait for next cycle

  float voltage = dust_raw * (3.3 / 4095.0);
  float dust_density = 0.17 * voltage * 5.0 * 1000 - 0.1 * 1000; // Adjust for 5V VCC
  if(dust_density < 0) dust_density = 0;

  // ----- DHT22 Read -----
  float humidity = dht.readHumidity();
  float temperature = dht.readTemperature();
  if (isnan(humidity) || isnan(temperature)) {
    Serial.println("Failed to read DHT22!");
    humidity = 0;
    temperature = 0;
  }

  // ----- Serial Output -----
  Serial.print("CO2: "); Serial.print((int)co2_ppm); 
  Serial.print(" PPM | Quality: "); Serial.print(airQuality);
  Serial.print(" | Temp: "); Serial.print(temperature); 
  Serial.print(" C | Humidity: "); Serial.print(humidity);
  Serial.print(" % | Dust: "); Serial.print(dust_density); Serial.println(" mg/m³");

  // ---- Timestamp Output ----
  Serial.printf("%04d-%02d-%02d %02d:%02d:%02d\n",
                timeinfo.tm_year + 1900,
                timeinfo.tm_mon + 1,
                timeinfo.tm_mday,
                timeinfo.tm_hour,
                timeinfo.tm_min,
                timeinfo.tm_sec);

  // ----- OLED Output -----
  display.clearDisplay();
  display.setCursor(0,0);
  display.setTextSize(1);

  display.print("CO2: "); display.print((int)co2_ppm);
  display.println(" PPM");

  display.print("Quality: "); display.println(airQuality);

  display.print("Temp: "); display.print(temperature); display.println(" C");
  display.print("Humidity: "); display.print(humidity); display.println(" %");

  display.print("Dust: "); display.print((int)dust_density);
  display.println(" mg/m3");

  char timeString[25];
  strftime(timeString, sizeof(timeString), "%Y-%m-%d %H:%M:%S", &timeinfo);
  display.println(timeString);
                
  display.display();

  delay(1000);
}

// ----------------- MQ-135 Functions -----------------
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

float MQRead(int mq_pin) {
  float rs = 0;
  for (int i = 0; i < READ_SAMPLE_TIMES; i++) {
    rs += MQResistanceCalculation(analogRead(mq_pin));
    delay(READ_SAMPLE_INTERVAL);
  }
  return rs / READ_SAMPLE_TIMES;
}

float MQResistanceCalculation(int raw_adc) {
  float voltage = (float)raw_adc * 3.3 / 4095.0;
  if (voltage == 0) return 0;
  return ((3.3 * RL_VALUE) / voltage) - RL_VALUE;
}

float MQGetGasPercentage(float rs_ro_ratio, int gas_id) {
  if (gas_id == GAS_CO2) return MQGetPercentage(rs_ro_ratio, CO2Curve);
  return 0;
}

float MQGetPercentage(float rs_ro_ratio, float *curve) {
  return pow(10, (((log10(rs_ro_ratio) - curve[1]) / curve[2]) + curve[0]));
}

String getAirQualityLevel(float co2_ppm) {
  if (co2_ppm < 400) return "Excellent";
  else if (co2_ppm < 600) return "Good";
  else if (co2_ppm < 1000) return "Fair";
  else if (co2_ppm < 1500) return "Poor";
  else return "Very Poor";
}