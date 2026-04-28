# Sela Mobile Apps

Aplikasi mobile cerdas untuk Sela Project Management Platform, dibangun menggunakan **Flutter**. Aplikasi ini membantu individu maupun tim dalam mengelola tugas (Task Management), merekam progres, dan memanfaatkan kecerdasan buatan (Gemini AI) untuk otomatisasi pembagian kerja.

Aplikasi ini terhubung secara langsung dengan `sela-backend` (Laravel Sanctum & Supabase).

## 🚀 Fitur Utama

- **Autentikasi Terintegrasi:** Mendukung login standar (Email/Password) dan login akademik terintegrasi via **ETHOL PENS**.
- **Manajemen Tugas Lengkap:** Pisahkan pekerjaan Anda ke dalam *Independent Task* (Pribadi) dan *Group Task* (Tim).
- **AI Task Automation:** Membagi dan menyusun subtask secara otomatis berdasarkan *deskripsi, link, file dokumen (PDF), dan abilities (kemampuan)* pengguna menggunakan integrasi **Google Gemini AI**.
- **Pelacakan Progres:** Pantau status penyelesaian subtask secara *real-time* dengan indikator visual.
- **Manajemen File & Link:** Lampirkan referensi secara mudah di dalam tugas.
- **Notifikasi Pintar & Kalender:** Lihat tenggat waktu dan notifikasi pembaruan secara langsung di menu.

## 🛠️ Teknologi yang Digunakan

- **Framework:** Flutter (Dart)
- **State/API Handling:** Dio (HTTP Client)
- **AI Integration:** `google_generative_ai` (Gemini 2.5 Flash)
- **Environment:** `flutter_dotenv` (DotEnv config)
- **Offline & Connectivity:** `connectivity_plus`

---

## 💻 Panduan Instalasi (Local Setup)

Untuk menjalankan Sela Mobile secara lokal, pastikan Anda telah menginstal **Flutter SDK** dan mengatur environment untuk Android / iOS.

### 1. Prasyarat System
- Flutter SDK (Versi stabil terbaru)
- Android Studio / Xcode (untuk emulator)
- [Sela Backend](https://github.com/Dardcor/Sela-Website) harus berjalan secara lokal atau menggunakan URL production.

### 2. Clone & Install Dependencies
Buka terminal dan jalankan perintah berikut:

```bash
git clone https://github.com/Dardcor/sela-mobile.git
cd sela-mobile
flutter pub get
```

### 3. Konfigurasi Environment (`.env`)
Aplikasi ini membutuhkan file environment untuk endpoint API backend dan kunci akses Gemini AI.

Buat file bernama `.env` di root folder proyek Anda (sejajar dengan pubspec.yaml):

```env
# Sesuaikan BASE_URL API Laravel Anda (contoh jika lokal jalan di IP 10.0.2.2 via emulator android, atau IP Network Anda)
API_BASE_URL=http://<YOUR-DOMAIN/YOUR-API>:8000/api 

# Akses API Gemini untuk fitur Divide Task/Subtask Automation
GEMINI_API_KEY=api_key_gemini
```

### 4. Menjalankan Aplikasi
Pilih device/emulator yang tersedia, lalu build aplikasi:

```bash
flutter run
```

Atau jika ingin menjalankan dalam mode rilis (release):
```bash
flutter run --release
```

---

## 🧪 Testing

Aplikasi ini dilengkapi dengan serangkaian *Automated Tests* untuk memastikan keandalan berbagai logic (seperti pemetaan error Autentikasi dan pengecekan GUI). 

Untuk menjalankan serangkaian tes, jalankan:
```bash
flutter test
```

## 📂 Struktur Folder (Ringkasan)

```text
lib/
 ├── core/              # Komponen inti, widget global (navbar, dll), dan API client
 ├── features/          # Berisi modul-modul utama secara modular
 │   ├── auth/          # Layar login & fungsi autentikasi
 │   ├── groups/        # Layar dan logika untuk Group Task
 │   ├── home/          # Dashboard pintar dan Profile
 │   ├── notifications/ # Modul Notifikasi
 │   └── tasks/         # Layar Kalender dan Independent Task 
 ├── model/             # Class model dan Logika Gemini AI (automatic.dart)
 ├── main.dart          # Entry point aplikasi Flutter
```
