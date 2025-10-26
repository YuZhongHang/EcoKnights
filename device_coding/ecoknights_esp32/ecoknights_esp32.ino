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

// ----------------- Firebase Setup -----------------
#include <FirebaseESP32.h>
#include <addons/TokenHelper.h>
#define API_KEY "AIzaSyACHWHcfV0sQ36EzGFc88Np2JD7NT60BFU"
#define FIREBASE_PROJECT_ID "my-iot-project-g01-43"
String FIREBASE_DEVICE_ID = "44:1D:64:F6:19:6E";
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

#define DATABASE_URL "https://my-iot-project-g01-43-default-rtdb.asia-southeast1.firebasedatabase.app/"
#define DATABASE_SECRET "t8HrQIQWklk5oJePbSAnqPkYt2b6NzVgTcUaoM7Q"

// ----------------- OLED Setup -----------------
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET    -1
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// ----------------- MQ-135 Setup ----------------
#define MQ135_PIN 34
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
#define DHT_PIN 27
#define DHT_TYPE DHT22
DHT dht(DHT_PIN, DHT_TYPE);

// --------------- Dust Sensor Setup ---------------
#define DUST_PIN 32
#define DUST_LED_PIN 33

// NTP server and timezone
#include "time.h"
const char* ntpServer = "pool.ntp.org";
const long  gmtOffset_sec = 8 * 3600; // GMT+8 for Malaysia
const int   daylightOffset_sec = 0;

// ---------- Time variables Initialization ----------
unsigned long lastUpdate = 0;
const long interval = 1000; // update display every 1 second

unsigned long lastDustRead = 0; 
float dust_density = 0;
unsigned long lastDHTRead = 0;
float humidity = 0, temperature = 0;

// ----------------- Bluetooth Setup -----------------
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <BLE2902.h>
BLEServer *pServer;
BLEService *pService;
BLECharacteristic *pCharacteristic;
BLEAdvertising *pAdvertising;
String btName;

#define SERVICE_UUID        "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
#define CHARACTERISTIC_UUID "6e400002-b5a3-f393-e0a9-e50e24dcca9e"

// ----------------- Wifi Setup -----------------
#include <WiFi.h>
bool wifiConnected = false;
String wifiSSID = "";
String wifiPASS = "";

// ----------------- OLED Display Setup Msg -----------------
void oledPrint(String msg) {
  delay(2000);
  display.clearDisplay();
  display.setCursor(0, 0);
  display.println(msg);
  display.display();
}

// Callback to restart advertising after disconnect
class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) override {
    Serial.println("BLE Client Connected");
  }

  void onDisconnect(BLEServer* pServer) override {
    Serial.println("BLE Client Disconnected. Restarting advertising...");
    pServer->startAdvertising();
  }
};

bool success = false;
bool connected = false;

// ----------------- Reading Wifi Credential From App -----------------
class WifiCredentialsCallback: public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    String value = pCharacteristic->getValue();

    if (value.length() > 0) {
      Serial.println("Received over BLE: " + value);

      int delimiter = value.indexOf('|');
      if (delimiter != -1) {
        wifiSSID = value.substring(0, delimiter);
        wifiPASS = value.substring(delimiter + 1);

        Serial.println("Parsed SSID: " + wifiSSID);
        Serial.println("Parsed Password: " + wifiPASS);

        WiFi.begin(wifiSSID.c_str(), wifiPASS.c_str());
        oledPrint("Connecting WiFi...");

        unsigned long startAttempt = millis();
        while (millis() - startAttempt < 15000) {
          if (WiFi.status() == WL_CONNECTED) {
            success = true;
            break;
          }
          delay(500);
          Serial.print(".");
        }
        Serial.println();
      }
    }
  }
};

String generateDeviceID() {
  uint64_t chipid = ESP.getEfuseMac();
  char uniqueID[13];
  sprintf(uniqueID, "%04X%08X", (uint16_t)(chipid >> 32), (uint32_t)chipid);
  String deviceID = "EcoKnights_" + String(uniqueID);
  return deviceID;
}

// ----------------- Setup -----------------
void setup() {
  Serial.begin(921600);
  pinMode(MQ135_PIN, INPUT);
  pinMode(DUST_PIN, INPUT);
  pinMode(DUST_LED_PIN, OUTPUT);

  dht.begin();

  delay(3000);
  Wire.begin(25, 26);
  while(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println("SSD1306 allocation failed, retrying...");
    delay(500);
  }

  Serial.println("\nOLED initialized successfully!");
  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);

  Serial.println("Ecoknight Air Quality + Dust + Temp/Humidity Monitor");
  Serial.println("Sensor ready!\n");
  oledPrint("Sensor ready!");

  btName = generateDeviceID();

  BLEDevice::init(btName);
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  pService = pServer->createService(SERVICE_UUID);

  pCharacteristic = pService->createCharacteristic(
      CHARACTERISTIC_UUID,
      BLECharacteristic::PROPERTY_READ   |
      BLECharacteristic::PROPERTY_WRITE  |
      BLECharacteristic::PROPERTY_NOTIFY
  );

  pCharacteristic->setCallbacks(new WifiCredentialsCallback());
  pCharacteristic->setValue("Ready");
  pService->start();

  pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setMinInterval(32);
  pAdvertising->setMaxInterval(48);
  pAdvertising->start();

  obtainWifi();
  delay(3000);
}

bool obtainWifi() {
  Serial.print("Bluetooth: " + btName + "\nWaiting WiFi via BLE");
  oledPrint("Bluetooth: " + btName + "\nWaiting WiFi via BLE");
  while (!(WiFi.status() == WL_CONNECTED)) {
    Serial.print(".");
    display.print(".");
    delay(1500);
  }
  return true;
}

bool obtainTime() {
  struct tm timeinfo;
  int retry = 0;
  const int maxRetries = 300;
  oledPrint("Waiting for NTP time sync.");
  Serial.print("Waiting for NTP time sync");
  while (!getLocalTime(&timeinfo) && retry < maxRetries) {
    display.print(".");
    Serial.print(".");
    delay(1000);
    retry++;
  }
  Serial.print("\n");
  return retry < maxRetries;
}

// ----------------- Loop -----------------
void loop() {
  if(!connected){
    if (success) {
      wifiConnected = true;
      pCharacteristic->setValue("OK");
      pCharacteristic->notify();
      Serial.println("WiFi connected!");
      oledPrint("WiFi connected!");
      connected = true;
      config.api_key = API_KEY;
      config.database_url = DATABASE_URL;
      config.signer.tokens.legacy_token = DATABASE_SECRET;
      auth.token.uid = "";
      Firebase.begin(&config, &auth);
      Firebase.reconnectWiFi(true);
    } else {
      wifiConnected = false;
      pCharacteristic->setValue("FAIL");
      pCharacteristic->notify();
      Serial.println("WiFi connect FAIL");
      oledPrint("WiFi FAIL, retry via BLE");
      obtainWifi();
    }
  } 

  static bool ntpDone = false;
  if (!ntpDone) {
    configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
    if (obtainTime()) {
      Serial.println("Time synced successfully!");
      oledPrint("Time synced successfully!");
    } else {
      Serial.println("Failed to obtain time");
      oledPrint("NTP sync failed");
    }
    ntpDone = true;
  }

  if (millis() - lastUpdate >= interval) {
    lastUpdate = millis();

    struct tm timeinfo;
    if (!getLocalTime(&timeinfo)) {
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
    String airQuality;

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
      airQuality = getAirQualityLevel(dust_density);
      lastDustRead = millis();
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
    Serial.print(" % | Dust: "); Serial.print(dust_density); Serial.println(" µg/m³");

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

    display.drawRect(0, 0, 64, 26, SSD1306_WHITE);
    display.drawRect(64, 0, 64, 26, SSD1306_WHITE);
    display.drawRect(0, 26, 64, 26, SSD1306_WHITE);
    display.drawRect(64, 26, 64, 26, SSD1306_WHITE);

    display.setCursor(5, 2);
    display.print("CO2");
    char co2Str[10];
    sprintf(co2Str, "%d ppm", (int)co2_ppm);
    int16_t x1, y1; uint16_t w, h;
    display.getTextBounds(co2Str, 0, 0, &x1, &y1, &w, &h);
    int16_t cx = (64 - w) / 2;
    display.setCursor(cx, 12);
    display.print(co2Str);

    display.setCursor(70, 2);
    display.print("Temp");
    char tempStr[10];
    sprintf(tempStr, "%d C", (int)temperature);
    display.getTextBounds(tempStr, 0, 0, &x1, &y1, &w, &h);
    cx = 64 + (64 - w) / 2;
    display.setCursor(cx, 12);
    display.print(tempStr);

    display.setCursor(5, 28);
    display.print("Humi");
    char humiStr[10];
    sprintf(humiStr, "%d %%", (int)humidity);
    display.getTextBounds(humiStr, 0, 0, &x1, &y1, &w, &h);
    cx = (64 - w) / 2;
    display.setCursor(cx, 38);
    display.print(humiStr);

    display.setCursor(70, 28);
    display.print("Dust");
    char dustStr[12];
    sprintf(dustStr, "%d µg", (int)dust_density);
    display.getTextBounds(dustStr, 0, 0, &x1, &y1, &w, &h);
    cx = 64 + (64 - w) / 2;
    display.setCursor(cx, 38);
    display.print(dustStr);

    char timeString[25];
    strftime(timeString, sizeof(timeString), "%Y-%m-%d %H:%M:%S", &timeinfo);
    display.getTextBounds(timeString, 0, 0, &x1, &y1, &w, &h);
    cx = (SCREEN_WIDTH - w) / 2;
    display.setCursor(cx, 56);
    display.print(timeString);

    display.display();
    
    // --------------- Push Data To Real-Time Firebase ---------------
    if (Firebase.ready() && WiFi.status() == WL_CONNECTED) {
      String path = "/devices/" + btName + "/readings";

      FirebaseJson json;
      json.set("co2", (int)co2_ppm);
      json.set("temperature", temperature);
      json.set("humidity", humidity);
      json.set("dust", dust_density);
      json.set("airQuality", airQuality);

      char timeString[25];
      strftime(timeString, sizeof(timeString), "%Y-%m-%d %H:%M:%S", &timeinfo);
      json.set("timestamp", timeString);

      // Update "latest" every second
      if (Firebase.setJSON(fbdo, path + "/latest", json)) {
        Serial.println("Latest data updated!");
      } else {
        Serial.println("Failed to send latest:");
        Serial.println(fbdo.errorReason());
      }

      // Push to history ONLY at :00 or :30 seconds (with slot tracking)
      int currentSecond = timeinfo.tm_sec;
      
      if (currentSecond == 0 || currentSecond == 30) {
        // Create unique slot: "HHMM_SS"
        char currentSlot[10];
        sprintf(currentSlot, "%02d%02d_%02d", 
                timeinfo.tm_hour, 
                timeinfo.tm_min, 
                currentSecond);
        
        static char lastSlot[10] = "XXXX_XX";
        
        if (strcmp(currentSlot, lastSlot) != 0) {
          if (Firebase.pushJSON(fbdo, path + "/history", json)) {
            Serial.printf("History: %02d:%02d:%02d (Slot: %s)\n", 
                         timeinfo.tm_hour, timeinfo.tm_min, currentSecond, currentSlot);
            strcpy(lastSlot, currentSlot);
          } else {
            Serial.println("❌ History failed:");
            Serial.println(fbdo.errorReason());
          }
        }
      }
    }
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

String getAirQualityLevel(float dust_density) {
  if (dust_density <= 100) return "Excellent";
  else if (dust_density <= 150) return "Fair";
  else if (dust_density <= 250) return "Poor";
  else return "Very Poor";
}