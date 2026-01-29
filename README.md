# Smart Transit Kiosk (RFID & Facial Recognition)

A comprehensive, production-ready smart ticketing system. This project integrates **IoT (ESP32)**, **Computer Vision (Face API)**, and **Mobile (Flutter)** into a seamless transit payment solution.

---

## 🏗️ Architecture & Tech Stack

The system consists of three interconnected nodes:
1.  **Hardware Node (ESP32)**: Handles physical inputs (RFID cards, Touch buttons, IR proximity) and communicates via WebSockets.
2.  **Kiosk Dashboard (Web)**: The user-facing display. It processes Facial Recognition and handles the business logic (ticketing, logging) via Firebase.
3.  **Companion App (Mobile)**: Allows users to manage their smart cards, view travel history, and recharge wallets.

**Technologies Used:**
*   **IoT**: ESP32, C++, MFRC522 (RFID), WebSockets.
*   **Web**: HTML5, CSS3, JavaScript, `face-api.js`.
*   **Mobile**: Flutter (Dart), Android/iOS.
*   **Backend**: Firebase Firestore (Database), Firebase Authentication.

---

## 🛠️ Prerequisites

Before starting, ensure you have:
*   **Hardware**: ESP32 Dev Board, MFRC522 RFID Reader, SSD1306 OLED Display, 3x Touch Sensors, IR Sensor, Buzzer, LEDs.
*   **Software**: VS Code, Arduino IDE, Flutter SDK, Node.js (optional, for local serving).

---

## 📝 Step-by-Step Implementation Guide

Follow these steps strictly in order.

### Step 1: Firebase Setup (The Backbone)

1.  **Create Project**: Go to [console.firebase.google.com](https://console.firebase.google.com/) and create a project named `Smart-Transit`.
2.  **Enable Firestore**: Create a Firestore Database in **test mode** (for development).
3.  **Database Structure**: You must manually create these collections or let the app create them dynamically. The structure **MUST** be exact:

#### **Collection: `cards`**
*   **Document ID**: `<UID of the RFID Card>` (e.g., `d3a2c4b1`)
*   **Fields**:
    *   `name` (string): "John Doe"
    *   `wallet` (number): `150`
    *   `institution` (string): "CET" (Required for concession)
    *   `blacklist` (boolean): `false`
    *   `from_clg` (string): "East Fort" (Default return stop)

#### **Sub-Collection: `cards/{UID}/logs`**
*   **Document ID**: `<LogNumber>` (e.g., `1`, `2`)
*   **Fields**:
    *   `logNumber` (number): `1`
    *   `date_time` (string): "1/29/2026, 10:00:00 AM"
    *   `destination` (string): "Thampanoor"
    *   `boarding` (string): "Paravankunnu"
    *   `ticket_no` (number): `84920`
    *   `type` (string): "Regular" OR "Concession"
    *   `amount` (number): `12` (Only for Regular)

#### **Collection: `pins`**
*   **Document ID**: `<4-digit PIN>` (e.g., `1234`)
*   **Fields**:
    *   `card` (string): "d3a2c4b1" (Matches the RFID UID above)

#### **Collection: `clg_status`**
*   **Document ID**: `<Institution Name>` (e.g., `CET`)
*   **Fields**:
    *   `status` (boolean): `true` (College is Open)

4.  **Get Credentials**:
    *   Go to **Project Settings** > **General**.
    *   **Web App**: Register a web app to get the **config object** (apiKey, appId, etc.).
    *   **Android App**: Register an Android app (com.example.smart_ticket) and download `google-services.json`.

---

### Step 2: Hardware Setup (ESP32)

1.  **Wiring**: Connect the components to the ESP32 pins:
    *   **Touch 1 (Concession)**: GPIO 4
    *   **Touch 2 (Regular)**: GPIO 15
    *   **Touch 3 (Back)**: GPIO 13
    *   **RFID**: SDA(17), RST(16), SCK(18), MISO(19), MOSI(23)
    *   **IR Sensor**: GPIO 33
    *   **Buzzer**: GPIO 32
    *   **Emergency Button**: GPIO 26
    *   **LED**: GPIO 25
    *   **OLED**: I2C Pins (SDA 21, SCL 22 on most boards)

2.  **Flashing Code**:
    *   Open `Docs/esp32_code.txt` in Arduino IDE.
    *   Install Libraries: `WebSockets` (Markus Sattler), `MFRC522`, `Adafruit GFX`, `Adafruit SSD1306`.
    *   **Edit Config**: Update `ssid` and `password` with your WiFi details.
    *   Upload to ESP32.
    *   *Verification*: Open Serial Monitor (115200 baud). Ensure it connects to WiFi and displays an IP address.

---

### Step 3: Web Kiosk Setup

1.  **Navigate**: Go to the `Web App (Kisosk)` folder.
2.  **Config**:
    *   Rename `config.example.js` to `config.js`.
    *   Paste your **Web App credentials** from Step 1 inside.
3.  **Facial Recognition Data**:
    *   Go to `Web App (Kisosk)/images/`.
    *   Create folders named after your users (e.g., `Rahul VH`).
    *   Add 1-10 photos of the person inside (`1.jpg`, `2.jpg`, etc.).
    *   **Update Code**: In `index.html`, find `loadLabeledFaces` and update the array:
        ```javascript
        const labels = ['Rahul VH', 'Another User'];
        ```
4.  **Run**:
    *   You need a local web server (Facial API security requirement).
    *   If using VS Code, right-click `index.html` -> **Open with Live Server**.
    *   **Network Check**: The Web App connects to the ESP32 via WebSocket (`ws://esp32system.local:81`). Ensure both devices are on the *same WiFi*.

---

### Step 4: Mobile App Deployment

1.  **Navigate**: Go to `Mobile APP (companion)/smart_ticket`.
2.  **Credentials**:
    *   Copy the `google-services.json` (from Step 1) into `android/app/`.
3.  **Build**:
    *   Run `flutter pub get`.
    *   Run `flutter run` on a connected Android/iOS device.
4.  **Usage**:
    *   Login with the UserID (UID) and PIN configured in Firebase.
    *   View logs and recharge wallet.

---

## 🔄 System Workflow (How to Test)

1.  **Start**: Power on ESP32. Open Web Kiosk page.
2.  **Idle**: System waits. IR Sensor detects user -> Wakes up Kiosk.
3.  **Selection**: User presses "Concession" or "Regular" on ESP32 touch pad.
4.  **Auth**:
    *   **RFID**: Tap card on reader.
    *   **OR PIN**: Enter PIN on Kiosk screen.
5.  **Verification**:
    *   Web Kiosk shows **"Show Face"**.
    *   Camera activates -> Scans face -> Matches with `images/` folder.
6.  **Ticket**:
    *   If Match Success -> Fare deducted (if Regular) -> Ticket Logged to Firestore.
    *   Mobile App updates instantly with new log.

---

## ❓ Troubleshooting

*   **Camera not opening?** Ensure you are using `localhost` or `HTTPS`. Chrome blocks camera on unsecure HTTP IPs.
*   **Generic WebSocket Error?** Check if ESP32 and PC are on the same WiFi. Try accessing the ESP32 IP in a browser to check connectivity.
*   **Face not recognized?** Ensure images are `.jpg` and face is clearly visible. Adding more angles helps.

---

---

## 📜 License

## 📜 License & Attribution

**Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)**

### ⚠️ READ CAREFULLY

This project is open-source for **educational and personal use only**. By using this code, you agree to the following terms:

1.  **NO COMMERCIAL USE**: You cannot use this code for any commercial purpose, product, or service.
2.  **MANDATORY ATTRIBUTION**: You **MUST** credit the original author (**Rahul VH**) in any presentation, demo, publication, or media appearance where this project is shown.
3.  **NO MISREPRESENTATION**: You cannot claim this work as your own. If you use this for a college project, you must explicitly declare that it is an open-source project adaptation.

*   ✅ **Allowed**: Using it to learn, building it for a hobby, showing it while saying "I adapted this from Rahul VH's project".
*   ❌ **Forbidden**: Presenting it to media/examiners saying "I built this entire system myself from scratch".

For commercial inquiries, please contact the author.



