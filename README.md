# Sistem Pencatatan Aset

> **Proyek Tugas Akhir - Agus Syuhada**

Aplikasi **Sistem Pencatatan Aset** adalah aplikasi multi-platform berbasis Flutter yang dirancang untuk mempermudah proses manajemen, pelacakan, dan siklus aset (Asset Cycle). Aplikasi ini mendukung fitur-fitur seperti pemindaian aset menggunakan OCR, statistik visual dengan grafik, dan manajemen pengguna.

## 🏗 Arsitektur

Aplikasi ini dibangun menggunakan **Clean Architecture** dengan pola desain **MVVM (Model-View-ViewModel)**. Pendekatan ini memastikan pemisahan tanggung jawab yang jelas (Separation of Concerns) agar kode mudah dirawat dan diuji.

*   **Model**: Mendefinisikan struktur data dan serialisasi JSON (di folder `data/models`).
*   **View (UI)**: Menangani tampilan antarmuka pengguna (di folder `ui`).
*   **ViewModel**: Menangani logika bisnis dan state management menggunakan `Provider`, menghubungkan View dengan Repository.
*   **Repository**: Bertindak sebagai sumber kebenaran tunggal (Single Source of Truth) yang mengelola data dari API (Remote) atau penyimpanan lokal.
*   **Service**: Menangani komunikasi langsung dengan API endpoint atau hardware device.

## 🛠 Tech Stack

*   **Framework:** Flutter (Dart SDK >=3.8.1)
*   **State Management:** Provider
*   **Networking:** Dio & HTTP
*   **Environment Management:** flutter_dotenv
*   **Local Storage:** Shared Preferences & Sqflite (Dependencies)
*   **Features:**
    *   **Camera & OCR:** Camera, Azure Vision (via API integration)
    *   **Charts:** fl_chart (untuk statistik aset)
    *   **Date Picker:** syncfusion_flutter_datepicker
    *   **Utilities:** intl (formatting), permission_handler

## 🚀 Quick Start

Ikuti langkah-langkah berikut untuk menjalankan proyek ini di lingkungan lokal Anda.

### 1. Clone Repository

Buka terminal dan jalankan perintah berikut untuk mengunduh source code:

```bash
git clone https://github.com/AgusSyuhada/frontend_sistem-pencatatan-aset.git
cd frontend_sistem_pencatatan_aset
```

### 2. Setup Environment (.env)

Aplikasi ini membutuhkan konfigurasi environment variable. Buat file baru bernama `.env` di **root directory** proyek (sejajar dengan `pubspec.yaml`).

Isi file `.env` dengan konfigurasi berikut (sesuaikan URL dengan API server Anda):

```env
BASE_URL=http://your-api-url.com/api/v1
```

> **Catatan:** Pastikan URL diakhiri tanpa slash jika API client menambahkannya, atau sesuaikan dengan konfigurasi di `lib/config/api_config.dart`.

### 3. Install Dependencies

Unduh semua library yang dibutuhkan oleh project:

```bash
flutter pub get
```

### 4. Jalankan Aplikasi

Pastikan emulator atau device fisik sudah terhubung, lalu jalankan perintah:

```bash
# Untuk menjalankan dalam mode debug
flutter run

# Untuk menjalankan dalam mode profile/release
flutter run --profile
flutter run --release
```

## 📂 Struktur Program

Berikut adalah gambaran umum struktur direktori proyek:

```text
lib/
├── config/                 # Konfigurasi global (Routes, Theme, API Config, Constants)
├── data/
│   ├── local/              # Penyimpanan lokal (Preferences)
│   ├── models/             # Model data (Request/Response)
│   ├── remote/             # Layanan API (Services & Exceptions)
│   └── repositories/       # Logika akses data (Repository Pattern)
├── di/                     # Dependency Injection (AppProviders)
├── ui/                     # User Interface (Screens & ViewModels)
│   ├── asset/              # Fitur terkait Aset (Cycle, Master)
│   ├── auth/               # Fitur Autentikasi (Login, Forgot Password)
│   ├── common/             # Widget umum yang digunakan ulang
│   ├── home/               # Dashboard utama
│   ├── ocr/                # Fitur Scan/OCR
│   ├── profile/            # Profil pengguna
│   ├── splash/             # Splash screen
│   ├── terms/              # Syarat & Ketentuan
│   └── user/               # Manajemen User
├── utils/                  # Fungsi bantuan (Helpers, Validators)
└── main.dart               # Entry point aplikasi
```
