#include <WiFi.h> // Connect ESP32 to the WiFi
#include <WebServer.h> // Create small HTTP server on the ESP32 to handle network communication
#include "DHT.h" // Library for DHT temperature & humidity sensor
#include <math.h> // For math functions like pow() that used in CO2 calculations

// ======== WiFi Settings ========
// ESP32 connect to WiFi when it starts
// Choosed WiFi but not bluetooth cuz Flutter Bluetooth requires extra setup & permissions, WiFi easier
const char* ssid = "WIFI_NAME"; // Change to user's wifi name (SSID)
const char* password = "WIFI_PASSWORD"; // Change to user's wifi password

// ======== DHT22 Settings ========
#define DHTPIN  // DHT22 signal pin connected to GPIO 4 (the pin on ESP32 where DHT22's data wire is connected)
#define DHTTYPE DHT22 // Specify sensor model
DHT dht(DHTPIN, DHTTYPE); // Create object dht so we can call dht.functionName() 

// ======== Dust Sensor (GP2Y1014AU0F) ========
// GP2Y1014 uses an LED to shine light on dujst particles, and a photodiode detects scattered light
#define LED_PIN 25 // Controls the LED inside dust sensor
#define DUST_ANALOG_PIN 34 // Read analog voltage output from the sensor

// ======== MQ135 Settings ========
#define MQ135_PIN 35 // The analog pin connected to MQ135 output
#define RLOAD 10.0 // Fixed resistor value in the circuit (in kΩ)
#define RZERO 76.63 // Calibration constants for converting resistance → CO₂ PPM
#define PARA 116.6020682 // Calibration constants for converting resistance → CO₂ PPM
#define PARB 2.769034857 // Calibration constants for converting resistance → CO₂ PPM

WebServer server(80); // Creates a server that listens on port 80 (default for HTTP)

// ======== MQ135 Functions ========
float mq135_getResistance(int raw_adc) { // Turn raw ADC reading into resistance
  float v = raw_adc * (3.3 / 4095.0); // Convert ADC value to voltage
  return ((3.3 * RLOAD / v) - RLOAD); // Apply formula for sensor resistance
}

float mq135_getPPM(float resistance) { // Converts resistance into approximate CO2 concentration (PPM)
  return PARA * pow((resistance / RZERO), -PARB);
}

String aqiCategory(float ppm) { // Converts PPM into air quality category
  // If Statement to decide the category
  if (ppm <= 400) return "Good";
  else if (ppm <= 1000) return "Moderate";
  else if (ppm <= 2000) return "Unhealthy for Sensitive Groups";
  else if (ppm <= 5000) return "Unhealthy";
  else return "Hazardous";
}

// ======== Handle API Request ========
void handleSensorData() {
  float temperature = dht.readTemperature();
  float humidity = dht.readHumidity();

  // Dust
  digitalWrite(LED_PIN, LOW);
  delayMicroseconds(280);
  int dustRaw = analogRead(DUST_ANALOG_PIN);
  delayMicroseconds(40);
  digitalWrite(LED_PIN, HIGH);
  delayMicroseconds(9680);
  float dustVoltage = dustRaw * (3.3 / 4095.0);
  float dustDensity = (dustVoltage - 0.9) / 0.5;

  // MQ135
  int mq135Raw = analogRead(MQ135_PIN);
  float mq135Res = mq135_getResistance(mq135Raw);
  float co2ppm = mq135_getPPM(mq135Res);
  String airQuality = aqiCategory(co2ppm);

  String json = "{";
  json += "\"temperature\":" + String(temperature, 1) + ",";
  json += "\"humidity\":" + String(humidity, 1) + ",";
  json += "\"dust_density\":" + String(dustDensity, 2) + ",";
  json += "\"co2_ppm\":" + String(co2ppm, 1) + ",";
  json += "\"aqi_category\":\"" + airQuality + "\"";
  json += "}";

  server.send(200, "application/json", json);
}

void setup() {
  Serial.begin(115200);

  dht.begin();
  pinMode(LED_PIN, OUTPUT);

  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nConnected!");
  Serial.print("ESP32 IP Address: ");
  Serial.println(WiFi.localIP());

  server.on("/sensor", handleSensorData);
  server.begin();
}

void loop() {
  server.handleClient();
}