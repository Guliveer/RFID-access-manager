# RFID Access Control System - ESP32C3 + HTTPS

System kontroli dostępu RFID z bezpieczną komunikacją HTTPS, oparty na XIAO ESP32C3.

## 🎯 Funkcje

- ✅ Bezpieczna komunikacja HTTPS (port 443) z API
- ✅ WiFi wbudowany (nie potrzebny Ethernet Shield)
- ✅ Odczyt kart RFID (MFRC522)
- ✅ Sterowanie elektrozamkiem (solenoid)
- ✅ Debouncing kart (2s) - zapobiega podwójnemu odczytowi

## 🔧 Wymagane komponenty

### Hardware
- **XIAO ESP32C3** - główna płytka z WiFi
- **MFRC522** - czytnik RFID (13.56MHz)
- **Przekaźnik** - do sterowania solenoidem
- **Solenoid** - elektrozamek (12V/24V)
- **Breadboard + przewody** - do połączeń
- **Zasilacz zewnętrzny** - dla solenoidu

### Software
- **Arduino IDE** 2.0+
- **ESP32 Board Support** (Espressif)
- **Biblioteka MFRC522** (GithubCommunity)
- **WiFi** (wbudowana w ESP32)
- **WiFiClientSecure** (wbudowana w ESP32)

## 📦 Instalacja Arduino IDE

### 1. Dodaj obsługę ESP32

**File → Preferences → Additional Boards Manager URLs:**
```
https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
```

**Tools → Board → Boards Manager:**
- Wyszukaj: `esp32`
- Zainstaluj: **esp32 by Espressif Systems**

### 2. Zainstaluj bibliotekę MFRC522

**Sketch → Include Library → Manage Libraries:**
- Wyszukaj: `MFRC522`
- Zainstaluj: **MFRC522 by GithubCommunity**

### 3. Wybierz płytkę

**Tools → Board → ESP32 Arduino:**
- Wybierz: **XIAO_ESP32C3**

## 🔌 Schemat połączeń

### MFRC522 (czytnik RFID) → XIAO ESP32C3

| MFRC522 Pin | → | ESP32C3 Pin | GPIO |
|-------------|---|-------------|------|
| **SDA (SS)** | → | **D2** | GPIO4 |
| **RST** | → | **D1** | GPIO3 |
| **SCK** | → | **D8** | GPIO8 |
| **MISO** | → | **D9** | GPIO9 |
| **MOSI** | → | **D10** | GPIO10 |
| **VCC** | → | **3.3V** | - |
| **GND** | → | **GND** | - |

⚠️ **WAŻNE**: MFRC522 działa TYLKO na 3.3V! Nie podłączaj do 5V!

### Przekaźnik (Solenoid) → XIAO ESP32C3

| Przekaźnik Pin | → | ESP32C3 Pin | GPIO |
|----------------|---|-------------|------|
| **IN** | → | **D0** | GPIO2 |
| **VCC** | → | **5V/VUSB** | - |
| **GND** | → | **GND** | - |

### Solenoid
- Podłącz przez przekaźnik (NIE bezpośrednio!)
- Zasilanie: 12V lub 24V (zewnętrzne)
- Masa: wspólna z ESP32C3

## ⚙️ Konfiguracja

### 1. Otwórz plik Arduino.ino

### 2. Zmień dane WiFi (linie 6-7):
```cpp
const char* ssid = "TWOJA_SIEC_WIFI";
const char* password = "TWOJE_HASLO";
```

### 3. Zmień Scanner ID (linia 15):
```cpp
const char* scannerId = "TWOJ_SCANNER_ID";
```
(Pobierz z swojego panelu API)

### 4. Wgraj kod
- Podłącz ESP32C3 przez USB
- Kliknij **Upload** (Ctrl+U)

## 🚀 Użycie

### 1. Otwórz Serial Monitor
- **Tools → Serial Monitor**
- Ustaw baud rate: **9600**

### 2. Uruchomienie
```
=== RFID Access Control - HTTPS ===

Laczenie z WiFi... OK
IP: 192.168.1.xxx

System gotowy - przyloz karte RFID
```

### 3. Przyłóż kartę RFID
```
[KARTA] Token: ABCD1234
Sprawdzanie dostepu... OK
[DOSTEP] Przyznany!
Otwieranie drzwi...
Zamknieto
```

## 🔒 Bezpieczeństwo

### HTTPS
- Połączenie szyfrowane SSL/TLS
- Port 443
- API: `rfid-access-manager.vercel.app`

### Tryb SSL
Kod używa `client.setInsecure()` - nie weryfikuje certyfikatu serwera.

**Dla pełnej weryfikacji** dodaj certyfikat CA:
```cpp
const char* root_ca = "-----BEGIN CERTIFICATE-----\n"
"...\n"
"-----END CERTIFICATE-----\n";

client.setCACert(root_ca);
```

## 📡 API

**Endpoint:** `POST https://rfid-access-manager.vercel.app/api/v1/access`

**Request Body:**
```json
{
  "scanner": "7f3eeb72-5ca2-4e19-843c-dbedccaa3f00",
  "token": "ABCD1234"
}
```

**Response (dostęp przyznany):**
```json
{
  "granted": true,
  "message": "Access granted"
}
```

**Response (dostęp odmówiony):**
```json
{
  "granted": false,
  "message": "Access denied"
}
```

## 🐛 Rozwiązywanie problemów

### Czytnik RFID nie wykrywa kart
- Sprawdź czy MFRC522 jest zasilany **3.3V** (NIE 5V!)
- Sprawdź połączenia SPI (D8, D9, D10)
- Upewnij się że RST jest podłączony do D1
- Przyłóż kartę bliżej czytnika (1-2 cm)

### WiFi nie łączy się
- Sprawdź SSID i hasło w kodzie
- Upewnij się że WiFi jest 2.4 GHz (ESP32C3 nie obsługuje 5 GHz)
- Sprawdź czy router ma włączony DHCP

### Błąd połączenia z API
- Sprawdź połączenie internetowe
- Upewnij się że API działa (otwórz w przeglądarce)
- Sprawdź czy firewall nie blokuje port 443

### Solenoid nie otwiera się
- Sprawdź czy przekaźnik jest prawidłowo podłączony
- Upewnij się że solenoid ma odpowiednie zasilanie (12V/24V)
- Sprawdź czy masa jest wspólna dla wszystkich komponentów

## 📊 Specyfikacja techniczna

### XIAO ESP32C3
- **Procesor**: ESP32-C3 (RISC-V, 160 MHz)
- **Flash**: 4 MB
- **RAM**: 400 KB
- **WiFi**: 2.4 GHz 802.11 b/g/n
- **Rozmiar**: 21 x 17.5 mm

### Zużycie pamięci
- **Flash**: ~350 KB (~8.5%)
- **RAM**: ~30 KB podczas pracy

### Timing
- **Debouncing kart**: 2 sekundy
- **Timeout API**: 10 sekund
- **Czas otwarcia**: 3 sekundy

## 📝 Struktura kodu

```
arduino/
├── Arduino.ino  # Główny plik programu
└── README.md    # Ta dokumentacja
```

### Funkcje:
- `setup()` - Inicjalizacja systemu
- `loop()` - Główna pętla programu
- `getCardID()` - Odczyt ID karty RFID
- `checkAccess()` - Weryfikacja dostępu przez API
- `openDoor()` - Otwarcie elektrozamka

## 🔄 Changelog

### v1.0.0 (2025-11-30)
- ✅ Migracja z Arduino Uno na XIAO ESP32C3
- ✅ Zmiana z HTTP na HTTPS
- ✅ WiFi zamiast Ethernet Shield
- ✅ Optymalizacja kodu (usunięcie debug logów)
- ✅ Czysty, produkcyjny kod

## 📄 Licencja

Projekt open source - do celów edukacyjnych i komercyjnych.

## 🤝 Wsparcie

W razie problemów:
1. Sprawdź sekcję "Rozwiązywanie problemów"
2. Otwórz Serial Monitor i sprawdź komunikaty
3. Upewnij się że wszystkie połączenia są poprawne

## 🎓 Autor

System RFID Access Control z obsługą HTTPS dla ESP32C3.