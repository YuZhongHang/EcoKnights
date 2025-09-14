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
#include "BluetoothSerial.h"

// ----------------- Firebase Setup -----------------
#define API_KEY "AIzaSyACHWHcfV0sQ36EzGFc88Np2JD7NT60BFU"
#define FIREBASE_PROJECT_ID "my-iot-project-g01-43"

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

// ---------- Time variables Initialization ----------
unsigned long lastUpdate = 0;
const long interval = 1000; // update every 1 second

unsigned long lastDustRead = 0; 
float dust_density = 0;
unsigned long lastDHTRead = 0;
float humidity = 0, temperature = 0;

// Timing rules:
// - Main loop refresh: every 1s
// - Dust sensor: every 2s
// - DHT22: every 2s
// - MQ-135: every 1s

// ----------------- Bluetooth Setup -----------------
BluetoothSerial SerialBT;  // Create Bluetooth object
String btName;

// ----------------- Setup -----------------
void setup() {
  Serial.begin(115200);
  pinMode(MQ135_PIN, INPUT);
  pinMode(DUST_PIN, INPUT);
  pinMode(DUST_LED_PIN, OUTPUT);

  dht.begin();

  // OLED init
  Wire.begin(25, 26); // SDA, SCL
  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println(F("SSD1306 allocation failed"));
    for(;;);
  }
  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);

  Serial.println("Ecoknight Air Quality + Dust + Temp/Humidity Monitor");
  Serial.println("Calibrating MQ-135 sensor...");
  
  // Calibrate MQ-135
  Ro = MQCalibration(MQ135_PIN);
  Serial.print("Calibration completed. Ro = ");
  Serial.print(Ro);
  Serial.println(" kohm");
  Serial.println("Sensor ready!");
  display.println("Sensor ready!");
  display.display();

  // ---- Generate Unique ID from ESP32 MAC ----
  uint64_t chipid = ESP.getEfuseMac();  // Get unique MAC address
  char uniqueID[13];                   // 12 hex chars + null terminator
  sprintf(uniqueID, "%04X%08X", (uint16_t)(chipid >> 32), (uint32_t)chipid);

  // ---- Create Bluetooth name using ID ----
  btName = "EcoKnights_" + String(uniqueID);
  SerialBT.begin(btName);  // Start Bluetooth with unique name

  Serial.println("Bluetooth Started with name: " + btName);
  display.println("Bluetooth Started with name: " + btName);
  display.display();
  
  
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.println("Waiting for Wifi...");
    display.clearDisplay();
    display.println("Waiting for Wifi...");
    display.display();
  }
  Serial.print(ssid);
  Serial.println("WiFi connected");
  display.clearDisplay();
  display.println("WiFi connected");
  display.display();

  // init and get the time
  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);

  if (obtainTime()) {
    Serial.println("Time synced successfully!");
  } else {
    Serial.println("Failed to obtain time");
  }
}

bool obtainTime() {
  struct tm timeinfo;
  int retry = 0;
  const int maxRetries = 300; // ~300s max
  while (!getLocalTime(&timeinfo) && retry < maxRetries) {
    Serial.println("Waiting for NTP time sync...");
    delay(1000);
    retry++;
  }
  return retry < maxRetries;
}

// ----------------- Loop -----------------
void loop() {
  // send a test message over Bluetooth
  if (SerialBT.hasClient()) {
    SerialBT.println("Hello from " + String("EcoKnights device!"));
    display.clearDisplay();
    display.print("Hello from " + String("EcoKnights device!"));
    display.display();
  }

  if (millis() - lastUpdate >= interval) {
    lastUpdate = millis();

    struct tm timeinfo;
    // ----- Timestamp Read -----
    if (!getLocalTime(&timeinfo)) {
      // set default "0000-00-00 00:00:00"
      timeinfo.tm_year = 0;
      timeinfo.tm_mon  = 0;
      timeinfo.tm_mday = 0;
      timeinfo.tm_hour = 0;
      timeinfo.tm_min  = 0;
      timeinfo.tm_sec  = 0;
    }

    // ----- MQ-135 Read -----
    int mq_raw = analogRead(MQ135_PIN);
    float mq_resistance = MQRead(MQ135_PIN);
    float co2_ppm = MQGetGasPercentage(mq_resistance / Ro, GAS_CO2);
    String airQuality = getAirQualityLevel(co2_ppm);

    // ----- Dust Sensor Read (only every 2 sec) -----
    if (millis() - lastDustRead > 2000) {
      digitalWrite(DUST_LED_PIN, HIGH); 
      delayMicroseconds(280);
      int dust_raw = analogRead(DUST_PIN);
      digitalWrite(DUST_LED_PIN, LOW); 
      delayMicroseconds(9680); 

      float voltage = dust_raw * (3.3 / 4095.0);
      dust_density = 0.17 * voltage * 5.0 * 1000 - 0.1 * 1000;
      if (dust_density < 0) dust_density = 0;

      lastDustRead = millis();  // update timer
    }

    // ----- DHT22 Read (only every 2 sec) -----
    if (millis() - lastDHTRead > 2000) {
      humidity = dht.readHumidity();
      temperature = dht.readTemperature();
      if (isnan(humidity) || isnan(temperature)) {
        Serial.println("Failed to read DHT22!");
        humidity = 0;
        temperature = 0;
      }
      lastDHTRead = millis();
    }

    // ----- Serial Output -----
    Serial.print(btName + ": –> ");
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
    display.setTextSize(1);

    // Draw sensor boxes
    display.drawRect(0, 0, 64, 26, SSD1306_WHITE);    // CO2
    display.drawRect(64, 0, 64, 26, SSD1306_WHITE);   // Temp
    display.drawRect(0, 26, 64, 26, SSD1306_WHITE);   // Humi
    display.drawRect(64, 26, 64, 26, SSD1306_WHITE);  // Dust

    // ---- CO2 ----
    display.setCursor(5, 2);
    display.print("CO2");
    char co2Str[10];
    sprintf(co2Str, "%d ppm", (int)co2_ppm);
    int16_t x1, y1; uint16_t w, h;
    display.getTextBounds(co2Str, 0, 0, &x1, &y1, &w, &h);
    int16_t cx = (64 - w) / 2;
    display.setCursor(cx, 12);
    display.print(co2Str);

    // ---- Temp ----
    display.setCursor(70, 2);
    display.print("Temp");
    char tempStr[10];
    sprintf(tempStr, "%d C", (int)temperature);
    display.getTextBounds(tempStr, 0, 0, &x1, &y1, &w, &h);
    cx = 64 + (64 - w) / 2;
    display.setCursor(cx, 12);
    display.print(tempStr);

    // ---- Humi ----
    display.setCursor(5, 28);
    display.print("Humi");
    char humiStr[10];
    sprintf(humiStr, "%d %%", (int)humidity);
    display.getTextBounds(humiStr, 0, 0, &x1, &y1, &w, &h);
    cx = (64 - w) / 2;
    display.setCursor(cx, 38);
    display.print(humiStr);

    // ---- Dust ----
    display.setCursor(70, 28);
    display.print("Dust");
    char dustStr[12];
    sprintf(dustStr, "%d mg", (int)dust_density);
    display.getTextBounds(dustStr, 0, 0, &x1, &y1, &w, &h);
    cx = 64 + (64 - w) / 2;
    display.setCursor(cx, 38);
    display.print(dustStr);

    // ---- Timestamp ----
    char timeString[25];
    strftime(timeString, sizeof(timeString), "%Y-%m-%d %H:%M:%S", &timeinfo);
    display.getTextBounds(timeString, 0, 0, &x1, &y1, &w, &h);
    cx = (SCREEN_WIDTH - w) / 2;
    display.setCursor(cx, 56);
    display.print(timeString);

    display.display();
  }
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