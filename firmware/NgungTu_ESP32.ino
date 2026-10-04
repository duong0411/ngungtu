/*
 * ╔══════════════════════════════════════════════════════════════╗
 * ║     NGƯNG TỤ HƠI NƯỚC ESP32 — ĐIỀU KHIỂN + MQTT APP         ║
 * ╠══════════════════════════════════════════════════════════════╣
 * ║  ✅ PI control sò nóng lạnh (TEC) theo điểm sương           ║
 * ║  ✅ DHT11 + DS18B20 + OLED SSD1306                          ║
 * ║  ✅ WiFi Portal AP tĩnh 192.168.4.1 (lưu tối đa 5 mạng)    ║
 * ║  ✅ MQTT qua WebSockets SSL (WSS Port 443 Cloudflare)       ║
 * ║  ✅ Gửi nhiệt độ / độ ẩm / điểm sương / mặt lạnh lên App    ║
 * ╚══════════════════════════════════════════════════════════════╝
 *
 * THƯ VIỆN CẦN CÓ:
 * 1. WebSockets by Markus Sattler
 * 2. MQTTPubSubClient by Hideaki Tai
 * 3. DHT sensor library by Adafruit
 * 4. Adafruit SSD1306 + Adafruit GFX
 * 5. OneWire + DallasTemperature
 *
 * APP MOBILE: thêm Node chipId = 789, template = kitchen_living
 * (hoặc để ESP tự publish — app nhận tele/+/status)
 */

#include <WiFi.h>
#include <WebServer.h>
#include <DNSServer.h>
#include <EEPROM.h>
#include <WebSocketsClient.h>
#include <MQTTPubSubClient.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <DHT.h>
#include <esp_system.h>
#include "soc/soc.h"
#include "soc/rtc_cntl_reg.h"

// ─────────────────────────────────────────────────────────────
//  CHÂN PHẦN CỨNG NGƯNG TỤ
// ─────────────────────────────────────────────────────────────
#define PIN_DS18B20   4
#define PIN_DHT       15
#define PIN_TEC       25   // MOS sò nóng lạnh
#define PIN_FAN       26   // MOS quạt
#define PIN_BOOT_BTN  0
#define BOOT_HOLD_MS  3000

// ─────────────────────────────────────────────────────────────
//  PWM
// ─────────────────────────────────────────────────────────────
#define PWM_FREQ      5000
#define PWM_RES       8
#define TEC_MAX_PWM   204   // 80%

// ─────────────────────────────────────────────────────────────
//  THÔNG SỐ ĐIỀU KHIỂN
// ─────────────────────────────────────────────────────────────
#define DEW_OFFSET        2.0f
#define COLD_MIN_SET      2.0f
#define COLD_HARD_LIMIT   0.5f
#define MIN_RH_START      35.0f
#define MIN_DEW_START     4.0f
#define COLD_OVERHEAT     45.0f
#define NO_COOL_TIME_MS   90000UL
#define FAN_COOLDOWN_MS   60000UL

float Kp = 25.0f;
float Ki = 0.4f;

// ─────────────────────────────────────────────────────────────
//  WIFI PORTAL
// ─────────────────────────────────────────────────────────────
#define AP_SSID       "NgungTu"
#define AP_PASSWORD   ""
IPAddress apIP(192, 168, 4, 1);
const byte DNS_PORT = 53;

// ─────────────────────────────────────────────────────────────
//  MQTT (giống SmartHome — Cloudflare Tunnel WSS)
// ─────────────────────────────────────────────────────────────
#define MQTT_HOST     "mqtt.duynguyen.io.vn"
#define MQTT_PORT     443
#define MQTT_PATH     "/mqtt"
#define CHIP_ID       "789"

// Topic khớp app (kitchen_living): nhiệt độ / độ ẩm / quạt
#define DEV_TEMP      "789_temp_livingroom"
#define DEV_HUMI      "789_humi_living_room"
#define DEV_FAN       "789_fan_livingroom"
// Topic thêm cho máy ngưng tụ
#define DEV_DEW       "789_dew_point"
#define DEV_COLD      "789_cold_plate"
#define DEV_SETPOINT  "789_setpoint"
#define DEV_TEC       "789_tec"
#define DEV_STATUS    "789_status"
#define DEV_POWER     "789_power"   // ON/OFF bật tắt hệ thống từ app

#define EEPROM_SIZE   512
#define MAX_WIFI      5
#define TELEMETRY_MS  5000
#define HEARTBEAT_MS  30000
#define RECONNECT_MS  10000

struct WifiEntry {
  char ssid[32];
  char pass[32];
};
WifiEntry wifiList[MAX_WIFI];
int wifiCount = 0;

// ─────────────────────────────────────────────────────────────
//  ĐỐI TƯỢNG
// ─────────────────────────────────────────────────────────────
Adafruit_SSD1306 oled(128, 64, &Wire, -1);
OneWire oneWire(PIN_DS18B20);
DallasTemperature ds(&oneWire);
DHT dht(PIN_DHT, DHT11);
WebServer webServer(80);
DNSServer dnsServer;
WebSocketsClient wsClient;
MQTTPubSubClient mqttClient;

// ─────────────────────────────────────────────────────────────
//  BIẾN NGƯNG TỤ
// ─────────────────────────────────────────────────────────────
float airT = NAN, airRH = NAN, dewP = NAN;
float coldT = NAN, setpoint = 0;
bool  running = false, fault = false;
bool  systemEnabled = true;   // tắt bằng MQTT thì không chạy TEC
float integral = 0;
int   tecPwm = 0, fanPwm = 0;
unsigned long tDHT = 0, tDS = 0, tCtl = 0, tOff = 0, tOn = 0;
const char* statusMsg = "Khoi dong";

// ─────────────────────────────────────────────────────────────
//  BIẾN WIFI / MQTT
// ─────────────────────────────────────────────────────────────
bool portalActive = false;
unsigned long lastTelemetry = 0;
unsigned long lastHeartbeat = 0;
unsigned long lastReconnect = 0;
unsigned long lastMqttRetry = 0;
unsigned long lastOled = 0;
bool wssReady = false;
bool mqttLoggedOk = false;
int wifiRetries = 0;

unsigned long bootPressStart = 0;
bool bootWasPressed = false;

#define DOUBLE_RESET_MAGIC 0x12345678
RTC_DATA_ATTR uint32_t rtcMagic = 0;
bool isDoubleReset = false;

// ─────────────────────────────────────────────────────────────
//  PWM tương thích core 2.x / 3.x
// ─────────────────────────────────────────────────────────────
void pwmInit(int pin, int ch) {
#if defined(ESP_ARDUINO_VERSION_MAJOR) && (ESP_ARDUINO_VERSION_MAJOR >= 3)
  ledcAttach(pin, PWM_FREQ, PWM_RES);
  (void)ch;
#else
  ledcSetup(ch, PWM_FREQ, PWM_RES);
  ledcAttachPin(pin, ch);
#endif
}

void pwmWrite(int pin, int ch, int duty) {
#if defined(ESP_ARDUINO_VERSION_MAJOR) && (ESP_ARDUINO_VERSION_MAJOR >= 3)
  ledcWrite(pin, duty);
  (void)ch;
#else
  ledcWrite(ch, duty);
#endif
}

void setTEC(int d) {
  tecPwm = constrain(d, 0, TEC_MAX_PWM);
  pwmWrite(PIN_TEC, 0, tecPwm);
}

void setFAN(int d) {
  fanPwm = constrain(d, 0, 255);
  pwmWrite(PIN_FAN, 1, fanPwm);
}

// ─────────────────────────────────────────────────────────────
//  ĐIỂM SƯƠNG (Magnus)
// ─────────────────────────────────────────────────────────────
float calcDewPoint(float T, float RH) {
  const float a = 17.62f, b = 243.12f;
  float g = log(RH / 100.0f) + (a * T) / (b + T);
  return (b * g) / (a - g);
}

void shutdownAll(const char* msg) {
  setTEC(0);
  integral = 0;
  if (running) {
    running = false;
    tOff = millis();
  }
  statusMsg = msg;
}

void latchFault(const char* msg) {
  setTEC(0);
  integral = 0;
  fault = true;
  running = false;
  tOff = millis();
  statusMsg = msg;
  Serial.printf("!!! KHOA SO: %s\n", msg);
}

// ─────────────────────────────────────────────────────────────
//  CẢM BIẾN + ĐIỀU KHIỂN
// ─────────────────────────────────────────────────────────────
void readSensors() {
  if (millis() - tDHT >= 2000) {
    tDHT = millis();
    float h = dht.readHumidity();
    float t = dht.readTemperature();
    if (!isnan(h) && !isnan(t) && h > 0) {
      airRH = h;
      airT = t;
      dewP = calcDewPoint(airT, airRH);
    }
  }

  if (millis() - tDS >= 800) {
    float c = ds.getTempCByIndex(0);
    coldT = (c == DEVICE_DISCONNECTED_C) ? NAN : c;
    ds.requestTemperatures();
    tDS = millis();
  }
}

void control() {
  if (millis() - tCtl < 1000) return;
  tCtl = millis();

  if (fault) {
    setTEC(0);
    return;
  }

  if (!systemEnabled) {
    shutdownAll("Tat tu App");
    return;
  }

  if (isnan(coldT)) {
    shutdownAll("Loi DS18B20");
    return;
  }
  if (isnan(airT) || isnan(dewP)) {
    shutdownAll("Loi DHT11");
    return;
  }

  if (coldT > COLD_OVERHEAT) {
    latchFault("QUA NHIET-KT QUAT");
    return;
  }
  if (coldT < COLD_HARD_LIMIT) {
    shutdownAll("Chong dong bang");
    return;
  }

  bool canRun;
  if (!running) canRun = (airRH >= MIN_RH_START && dewP >= MIN_DEW_START);
  else          canRun = (airRH >= MIN_RH_START - 5 && dewP >= MIN_DEW_START - 1);
  if (!canRun) {
    shutdownAll("Khong khi qua kho");
    return;
  }

  if (!running) {
    running = true;
    integral = 0;
    tOn = millis();
  }
  statusMsg = "Dang ngung tu";

  if (tecPwm > 60 && millis() - tOn > NO_COOL_TIME_MS && coldT > airT + 1.0f) {
    latchFault("SO KHONG LANH");
    return;
  }

  setpoint = max(dewP - DEW_OFFSET, COLD_MIN_SET);
  float err = coldT - setpoint;
  integral += err;
  integral = constrain(integral, 0, (float)TEC_MAX_PWM / Ki);
  setTEC((int)(Kp * err + Ki * integral));
}

void updateFan() {
  bool cooldown = (tOff != 0 && millis() - tOff < FAN_COOLDOWN_MS);
  if (fault || running || cooldown) setFAN(255);
  else setFAN(0);
}

void drawOLED() {
  if (millis() - lastOled < 400) return;
  lastOled = millis();

  oled.clearDisplay();
  oled.setTextSize(1);
  oled.setTextColor(SSD1306_WHITE);

  if (portalActive) {
    oled.setCursor(0, 0);  oled.println("CAU HINH WIFI");
    oled.setCursor(0, 14); oled.println("Ket noi AP: NgungTu");
    oled.setCursor(0, 28); oled.println("Mo: 192.168.4.1");
    oled.setCursor(0, 48); oled.printf("WiFi luu: %d", wifiCount);
    oled.display();
    return;
  }

  oled.setCursor(0, 0);   oled.printf("KK: %.1fC  %.0f%%", airT, airRH);
  oled.setCursor(0, 11);  oled.printf("Diem suong: %.1fC", dewP);
  oled.setCursor(0, 22);  oled.printf("Mat lanh: %.1fC", coldT);
  oled.setCursor(0, 33);  oled.printf("Muc tieu: %.1fC", running ? setpoint : 0.0f);
  oled.setCursor(0, 44);  oled.printf("So:%d%% Quat:%d%%", tecPwm * 100 / 255, fanPwm * 100 / 255);
  oled.setCursor(0, 55);
  if (WiFi.status() == WL_CONNECTED) {
    oled.printf("%s %s", mqttClient.isConnected() ? "MQTT" : "WiFi", statusMsg);
  } else {
    oled.print(statusMsg);
  }
  oled.display();
}

// ─────────────────────────────────────────────────────────────
//  EEPROM WIFI
// ─────────────────────────────────────────────────────────────
void saveWifiList() {
  EEPROM.begin(EEPROM_SIZE);
  EEPROM.put(0, wifiCount);
  int addr = sizeof(wifiCount);
  for (int i = 0; i < MAX_WIFI; i++) {
    EEPROM.put(addr, wifiList[i]);
    addr += sizeof(WifiEntry);
  }
  EEPROM.commit();
  EEPROM.end();
}

void loadWifiList() {
  EEPROM.begin(EEPROM_SIZE);
  EEPROM.get(0, wifiCount);
  if (wifiCount < 0 || wifiCount > MAX_WIFI) wifiCount = 0;
  int addr = sizeof(wifiCount);
  for (int i = 0; i < MAX_WIFI; i++) {
    EEPROM.get(addr, wifiList[i]);
    addr += sizeof(WifiEntry);
  }
  EEPROM.end();
}

void addOrUpdateWifi(String ssid, String pass) {
  for (int i = 0; i < wifiCount; i++) {
    if (String(wifiList[i].ssid) == ssid) {
      pass.toCharArray(wifiList[i].pass, 32);
      saveWifiList();
      return;
    }
  }
  if (wifiCount >= MAX_WIFI) {
    for (int i = 0; i < MAX_WIFI - 1; i++) wifiList[i] = wifiList[i + 1];
    wifiCount = MAX_WIFI - 1;
  }
  ssid.toCharArray(wifiList[wifiCount].ssid, 32);
  pass.toCharArray(wifiList[wifiCount].pass, 32);
  wifiCount++;
  saveWifiList();
}

bool connectBestWifi() {
  Serial.println("\nQuet mang WiFi da luu...");
  WiFi.mode(WIFI_STA);
  WiFi.disconnect();
  delay(100);

  if (wifiCount == 0) {
    Serial.println("Chua co mang WiFi nao trong bo nho!");
    return false;
  }

  int n = WiFi.scanNetworks();
  int bestIdx = -1;
  int bestRSSI = -999;

  if (n > 0) {
    for (int i = 0; i < n; i++) {
      String scannedSSID = WiFi.SSID(i);
      int rssi = WiFi.RSSI(i);
      for (int w = 0; w < wifiCount; w++) {
        if (String(wifiList[w].ssid) == scannedSSID && rssi > bestRSSI) {
          bestRSSI = rssi;
          bestIdx = w;
        }
      }
    }
    WiFi.scanDelete();
  }

  if (bestIdx < 0) bestIdx = wifiCount - 1;
  else Serial.printf("Mang tot nhat: %s (%ddBm)\n", wifiList[bestIdx].ssid, bestRSSI);

  Serial.printf("Dang ket noi: %s\n", wifiList[bestIdx].ssid);
  WiFi.begin(wifiList[bestIdx].ssid, wifiList[bestIdx].pass);

  for (int i = 0; i < 30 && WiFi.status() != WL_CONNECTED; i++) {
    delay(500);
    Serial.print(".");
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi OK! IP: " + WiFi.localIP().toString());
    return true;
  }
  Serial.println("\nKet noi WiFi that bai!");
  return false;
}

// ─────────────────────────────────────────────────────────────
//  MQTT
// ─────────────────────────────────────────────────────────────
// retain=true: app subscribe xong nhận ngay giá trị cuối (tránh mãi --)
void mqttPub(const char* device, const String& payload, bool retain = true) {
  if (!mqttClient.isConnected()) return;
  String topic = "tele/" + String(device) + "/status";
  mqttClient.publish(topic, payload, retain, 0);
}

void pubOnline() { mqttPub(CHIP_ID, "online", true); }

void pubTemp(float t) {
  if (isnan(t)) return;
  mqttPub(DEV_TEMP, "{\"value\":" + String(t, 1) + "}", true);
}

void pubHumi(float h) {
  if (isnan(h)) return;
  mqttPub(DEV_HUMI, "{\"value\":" + String(h, 1) + "}", true);
}

void pubDew(float d) {
  if (isnan(d)) return;
  mqttPub(DEV_DEW, "{\"value\":" + String(d, 1) + "}", true);
}

void pubCold(float c) {
  if (isnan(c)) return;
  mqttPub(DEV_COLD, "{\"value\":" + String(c, 1) + "}", true);
}

void pubSetpoint(float s) {
  mqttPub(DEV_SETPOINT, "{\"value\":" + String(s, 1) + "}", true);
}

void pubTec() {
  int pct = tecPwm * 100 / 255;
  mqttPub(DEV_TEC, "{\"value\":" + String(pct) + "}", true);
}

void pubFan() {
  mqttPub(DEV_FAN, fanPwm > 0 ? "{\"value\":\"ON\"}" : "{\"value\":\"OFF\"}", true);
}

void pubStatus() {
  // JSON string value — app parse được
  String safe = String(statusMsg);
  safe.replace("\"", "'");
  mqttPub(DEV_STATUS, "{\"value\":\"" + safe + "\"}", true);
}

void pubPower() {
  mqttPub(DEV_POWER, systemEnabled ? "{\"value\":\"ON\"}" : "{\"value\":\"OFF\"}", true);
}

void publishTelemetry() {
  pubTemp(airT);
  wsClient.loop();
  pubHumi(airRH);
  wsClient.loop();
  pubDew(dewP);
  wsClient.loop();
  pubCold(coldT);
  wsClient.loop();
  pubSetpoint(running ? setpoint : 0.0f);
  wsClient.loop();
  pubTec();
  wsClient.loop();
  pubFan();
  wsClient.loop();
  pubStatus();
  wsClient.loop();
  pubPower();
}

void mqttCallback(const String& topicStr, const String& payload, const size_t size) {
  (void)size;
  String topic = topicStr;
  String cmd = payload;
  cmd.trim();
  cmd.toUpperCase();

  Serial.printf("Nhan lenh [%s]: %s\n", topic.c_str(), cmd.c_str());

  // Bật / tắt hệ thống ngưng tụ từ app
  if (topic.indexOf(DEV_POWER) >= 0 || topic.indexOf(DEV_FAN) >= 0) {
    // POWER: bật/tắt toàn bộ; FAN topic dùng như công tắc hệ thống cho dễ gắn app sẵn
    if (cmd == "ON" || cmd == "1") {
      systemEnabled = true;
      if (topic.indexOf(DEV_POWER) >= 0) statusMsg = "Bat tu App";
    } else if (cmd == "OFF" || cmd == "0") {
      systemEnabled = false;
      shutdownAll("Tat tu App");
    }
    pubPower();
    pubFan();
    pubStatus();
  }
}

void reconnectMQTT() {
  if (mqttClient.isConnected()) return;

  if (!wsClient.isConnected()) {
    Serial.println("[MQTT] Cho WebSocket SSL...");
    return;
  }
  wssReady = true;

  uint32_t chipId = (uint32_t)ESP.getEfuseMac();
  String clientId = "ESP32-NT-" + String(chipId, HEX);
  String lwtTopic = "tele/" + String(CHIP_ID) + "/status";

  Serial.printf("[MQTT] CONNECT %s ...\n", clientId.c_str());
  mqttClient.setWill(lwtTopic, "offline", true, 1);

  if (mqttClient.connect(clientId, "", "")) {
    mqttLoggedOk = true;
    Serial.println("[MQTT] CONNECTED!");
    pubOnline();
    wsClient.loop();
    delay(50);

    mqttClient.subscribe("cmnd/" + String(DEV_POWER) + "/POWER", [](const char* payload, unsigned int size) {
      String cmd = "";
      for (unsigned int i = 0; i < size; i++) cmd += payload[i];
      mqttCallback("cmnd/" + String(DEV_POWER) + "/POWER", cmd, size);
    });
    wsClient.loop();
    delay(50);

    // Dùng nút Quạt trên app living room để bật/tắt hệ thống
    mqttClient.subscribe("cmnd/" + String(DEV_FAN) + "/POWER", [](const char* payload, unsigned int size) {
      String cmd = "";
      for (unsigned int i = 0; i < size; i++) cmd += payload[i];
      mqttCallback("cmnd/" + String(DEV_FAN) + "/POWER", cmd, size);
    });
    wsClient.loop();
    delay(50);

    publishTelemetry();
  } else {
    mqttLoggedOk = false;
    Serial.println("[MQTT] CONNECT FAIL");
  }
}

// ─────────────────────────────────────────────────────────────
//  WEB PORTAL
// ─────────────────────────────────────────────────────────────
const char PORTAL_HTML[] PROGMEM = R"rawhtml(
<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>NgungTu Setup</title>
<style>body{font-family:sans-serif;background:#0a0e1a;color:#e2e8f0;display:flex;justify-content:center;padding:20px}
.c{max-width:400px;width:100%;} input{width:100%;padding:10px;margin-bottom:10px;border-radius:5px;border:none} button{padding:10px;width:100%;background:#0ea5e9;color:#fff;border:none;border-radius:5px;cursor:pointer;font-weight:bold}
#st{margin-top:15px;text-align:center;font-weight:bold;padding:10px;border-radius:5px;display:none;}</style>
</head><body><div class="c"><h2>May Ngung Tu WiFi</h2>
<button onclick="scan()" style="margin-bottom:10px;background:#6366f1;">Quet mang xung quanh</button><div id="w" style="margin-bottom:10px;line-height:1.8;cursor:pointer;"></div>
<input id="s" placeholder="Ten WiFi"><input type="password" id="p" placeholder="Mat khau">
<button onclick="conn()">Ket noi</button><div id="st"></div></div>
<script>
function scan() {
  document.getElementById('w').innerHTML = 'Dang quet...';
  fetch('/scan').then(r => r.json()).then(l => {
    document.getElementById('w').innerHTML = l.map(n =>
      `<div style="padding:5px; background:#1e293b; margin-top:5px; border-radius:5px;" onclick="document.getElementById('s').value='${n.ssid}'">${n.ssid} (${n.rssi}dBm)</div>`
    ).join('');
  }).catch(e => { document.getElementById('w').innerHTML = 'Loi quet mang'; });
}
function conn() {
  const s = document.getElementById('s').value;
  const p = document.getElementById('p').value;
  if (!s) { alert('Nhap ten WiFi!'); return; }
  const st = document.getElementById('st');
  st.style.display = 'block';
  st.innerHTML = 'Dang ket noi...';
  st.style.background = '#334155';
  fetch('/connect', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: 'ssid=' + encodeURIComponent(s) + '&pass=' + encodeURIComponent(p)
  }).then(r => r.json()).then(d => {
    if (d.ok) {
      st.style.background = '#22c55e';
      st.innerHTML = 'Thanh cong! Dang restart...';
    } else {
      st.style.background = '#ef4444';
      st.innerHTML = 'Loi: ' + (d.message || 'That bai');
    }
  }).catch(e => {
    st.style.background = '#ef4444';
    st.innerHTML = 'Loi mang!';
  });
}
</script></body></html>
)rawhtml";

void handleNotFound() {
  webServer.sendHeader("Location", "http://192.168.4.1/", true);
  webServer.send(302, "text/plain", "");
}

void handleRoot() { webServer.send_P(200, "text/html", PORTAL_HTML); }

void handleScan() {
  int n = WiFi.scanNetworks(false, false);
  if (n < 0) {
    webServer.send(200, "application/json", "[]");
    return;
  }
  String json = "[";
  for (int i = 0; i < n; i++) {
    if (i) json += ",";
    String ssid = WiFi.SSID(i);
    ssid.replace("\\", "\\\\");
    ssid.replace("\"", "\\\"");
    json += "{\"ssid\":\"" + ssid + "\",\"rssi\":" + String(WiFi.RSSI(i)) + "}";
  }
  json += "]";
  WiFi.scanDelete();
  webServer.send(200, "application/json", json);
}

void handleConnect() {
  String ssid = webServer.arg("ssid");
  String pass = webServer.arg("pass");
  if (ssid.length() > 0) {
    WiFi.begin(ssid.c_str(), pass.c_str());
    for (int i = 0; i < 30 && WiFi.status() != WL_CONNECTED; i++) delay(500);
    if (WiFi.status() == WL_CONNECTED) {
      addOrUpdateWifi(ssid, pass);
      webServer.send(200, "application/json", "{\"ok\":true}");
      delay(1000);
      ESP.restart();
    } else {
      WiFi.disconnect();
      webServer.send(200, "application/json", "{\"ok\":false,\"message\":\"Sai mat khau hoac WiFi yeu.\"}");
    }
  } else {
    webServer.send(200, "application/json", "{\"ok\":false,\"message\":\"Chua nhap ten WiFi!\"}");
  }
}

void startPortal() {
  portalActive = true;
  setTEC(0);
  setFAN(0);
  Serial.println("\nKhoi tao AP Portal...");
  WiFi.mode(WIFI_AP_STA);
  WiFi.softAPConfig(apIP, apIP, IPAddress(255, 255, 255, 0));
  WiFi.softAP(AP_SSID, AP_PASSWORD);
  dnsServer.start(DNS_PORT, "*", apIP);
  webServer.on("/", HTTP_GET, handleRoot);
  webServer.on("/scan", HTTP_GET, handleScan);
  webServer.on("/connect", HTTP_POST, handleConnect);
  webServer.onNotFound(handleNotFound);
  webServer.begin();
  Serial.println("Portal OK — ket noi WiFi: NgungTu → http://192.168.4.1");
  statusMsg = "Cau hinh WiFi";
}

void checkBootButtonForPortal() {
  bool pressed = (digitalRead(PIN_BOOT_BTN) == LOW);
  if (pressed) {
    if (!bootWasPressed) {
      bootWasPressed = true;
      bootPressStart = millis();
    } else if (millis() - bootPressStart >= BOOT_HOLD_MS) {
      wifiCount = 0;
      memset(wifiList, 0, sizeof(wifiList));
      saveWifiList();
      WiFi.disconnect(true);
      startPortal();
      bootWasPressed = false;
    }
  } else {
    bootWasPressed = false;
  }
}

void checkDoubleReset() {
  if (rtcMagic == DOUBLE_RESET_MAGIC) {
    isDoubleReset = true;
    rtcMagic = 0;
    wifiCount = 0;
    saveWifiList();
    Serial.println("DOUBLE RESET — xoa WiFi, mo Portal");
  } else {
    isDoubleReset = false;
    rtcMagic = DOUBLE_RESET_MAGIC;
  }
}

void clearDoubleResetFlag() {
  if (rtcMagic == DOUBLE_RESET_MAGIC) rtcMagic = 0;
}

// ─────────────────────────────────────────────────────────────
//  SETUP
// ─────────────────────────────────────────────────────────────
void setup() {
  WRITE_PERI_REG(RTC_CNTL_BROWN_OUT_REG, 0);
  Serial.begin(115200);
  delay(300);
  Serial.println("\n=== NGUNG TU ESP32 + MQTT ===");
  Serial.printf("Ly do reset: %d (9 = brownout)\n", (int)esp_reset_reason());

  pinMode(PIN_BOOT_BTN, INPUT_PULLUP);

  pwmInit(PIN_TEC, 0);
  pwmInit(PIN_FAN, 1);
  setTEC(0);
  setFAN(0);

  Wire.begin(21, 22);
  if (!oled.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println("Khong tim thay OLED");
  }

  oled.clearDisplay();
  oled.setTextSize(1);
  oled.setTextColor(SSD1306_WHITE);
  oled.setCursor(0, 20);
  oled.println("TEST QUAT 3 giay...");
  oled.println("Quat phai quay!");
  oled.display();
  setFAN(255);
  delay(3000);
  setFAN(0);

  dht.begin();
  ds.begin();
  ds.setWaitForConversion(false);
  Serial.printf("So DS18B20: %d\n", ds.getDeviceCount());
  ds.requestTemperatures();
  delay(800);
  tDS = millis();

  Serial.printf("[WSS] beginSSL %s:%d%s\n", MQTT_HOST, MQTT_PORT, MQTT_PATH);
  wsClient.beginSSL(MQTT_HOST, MQTT_PORT, MQTT_PATH);
  wsClient.setExtraHeaders("Sec-WebSocket-Protocol: mqtt");
  wsClient.setReconnectInterval(5000);
  wsClient.onEvent([](WStype_t type, uint8_t* payload, size_t length) {
    (void)length;
    switch (type) {
      case WStype_DISCONNECTED:
        wssReady = false;
        mqttLoggedOk = false;
        Serial.println("[WSS] DISCONNECTED");
        break;
      case WStype_CONNECTED:
        wssReady = true;
        Serial.printf("[WSS] CONNECTED → %s\n", payload ? (const char*)payload : MQTT_HOST);
        lastMqttRetry = 0;
        break;
      case WStype_ERROR:
        wssReady = false;
        Serial.println("[WSS] ERROR");
        break;
      default:
        break;
    }
  });

  mqttClient.begin(wsClient);
  mqttClient.setTimeout(8000);

  loadWifiList();
  checkDoubleReset();

  if (isDoubleReset) {
    startPortal();
  } else if (!(wifiCount > 0 && connectBestWifi())) {
    startPortal();
  }

  statusMsg = "San sang";
}

// ─────────────────────────────────────────────────────────────
//  LOOP
// ─────────────────────────────────────────────────────────────
void loop() {
  if (millis() > 3000 && rtcMagic == DOUBLE_RESET_MAGIC) {
    clearDoubleResetFlag();
  }

  if (!portalActive) checkBootButtonForPortal();

  // Luôn đọc cảm biến / điều khiển / OLED (kể cả lúc portal)
  readSensors();
  if (!portalActive) {
    control();
    updateFan();
  }
  drawOLED();

  if (portalActive) {
    dnsServer.processNextRequest();
    webServer.handleClient();
    delay(10);
    return;
  }

  unsigned long now = millis();

  if (WiFi.status() != WL_CONNECTED) {
    if (now - lastReconnect >= RECONNECT_MS) {
      lastReconnect = now;
      if (connectBestWifi()) {
        wifiRetries = 0;
      } else {
        wifiRetries++;
        if (wifiRetries >= 3) {
          startPortal();
          wifiRetries = 0;
        }
      }
    }
    delay(50);
    return;
  }
  wifiRetries = 0;

  wsClient.loop();
  mqttClient.update();

  if (!mqttClient.isConnected()) {
    if (now - lastMqttRetry >= 5000) {
      lastMqttRetry = now;
      if (wsClient.isConnected()) wssReady = true;
      Serial.printf("[DEBUG] wifi=%d ws=%d mqtt=%d\n",
                    WiFi.status() == WL_CONNECTED,
                    wsClient.isConnected(),
                    mqttClient.isConnected());
      reconnectMQTT();
    }
  } else if (!mqttLoggedOk) {
    mqttLoggedOk = true;
  }

  if (now - lastHeartbeat >= HEARTBEAT_MS) {
    lastHeartbeat = now;
    pubOnline();
  }

  if (now - lastTelemetry >= TELEMETRY_MS) {
    lastTelemetry = now;
    publishTelemetry();
    Serial.printf("Air %.1fC %.0f%% | Dew %.1f | Cold %.1f | Set %.1f | TEC %d | FAN %d | %s | MQTT=%d\n",
                  airT, airRH, dewP, coldT, setpoint, tecPwm, fanPwm, statusMsg,
                  mqttClient.isConnected());
  }

  delay(50);
}
