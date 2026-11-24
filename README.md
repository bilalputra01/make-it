# Make it

Aplikasi daftar tugas sederhana yang dibuat dengan Flutter.

## Fitur

- Tambah tugas ke bagian Hari Ini, Mendatang, atau Kapan Saja.
- Tandai tugas selesai dan buka kembali dari bagian Selesai.
- Lihat persentase tugas Hari Ini yang sudah selesai.
- Tugas disimpan melalui Mock API JSON Server.

Tugas baru menggunakan label Umum, prioritas Medium, dan estimasi 25 menit.

## Menjalankan aplikasi

```shell
flutter pub get
flutter run
```

## Mock API JSON Server

Di Schema Builder, buat dua resource:

- **`tasks`**: `id` (`id_auto`, dibuat otomatis), `title` (String), `labelName` (String),
  `labelColorValue` (Number), `durationMinutes` (Number), `priority` (String),
  `isCompleted` (Boolean), `schedule` (String), `dueDate` (String, optional),
  dan `repeatDays` (Array of Number).
- **`labels`**: `id` (`id_auto`, dibuat otomatis), `name` (String), dan
  `colorValue` (Number).

Field `priority` berisi `high`, `medium`, atau `low`; `schedule` berisi
`today`, `upcoming`, atau `anytime`. `repeatDays` menggunakan angka 1–7.
JSON Server membuat `id` untuk label; untuk tugas aplikasi mengirim `id`
sendiri. Field label tugas sengaja datar agar tidak memerlukan tipe Object. Jangan
kirim nilai `id` saat membuat data; API akan memberi ID otomatis.

1. Install JSON Server:
   ```shell
   npm install -g json-server
   ```
2. Jalankan Mock API dari folder project:
   ```shell
   json-server --host 0.0.0.0 --port 3000 db.json
   ```
3. Pastikan project memiliki resource `/tasks` dan `/labels`. Base URL Studio
   pada contoh ini adalah `http://localhost:3000/api/make-it`.
4. Untuk Flutter Windows/web, gunakan:
   ```shell
   flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/make-it
   ```
5. Untuk Android Emulator gunakan:
   ```shell
   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/make-it
   ```
6. Untuk perangkat fisik gunakan alamat IP PC, misalnya:
   ```shell
   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000/api/make-it
   ```

Jalankan tes dan pemeriksaan kode dengan:

```shell
flutter test
flutter analyze
```
