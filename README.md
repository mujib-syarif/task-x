# Task X

**Task X by mujib_syarif** — pemantau sistem dan pengelola aplikasi Android (gabungan Task Manager + System Monitor).

Flutter + Kotlin native. Tanpa akun, tanpa server, tanpa izin internet.

## Versi 1.1.0 (build 2)

### Fitur selesai
- **Beranda**: kartu perangkat, RAM, CPU, penyimpanan, baterai, jaringan, uptime + jumlah aplikasi; tarik ke bawah untuk memuat ulang; nilai yang tidak terbaca tampil "N/A"; banner peringatan suhu baterai.
- **Performance Monitor**: tab CPU / RAM / Penyimpanan / Baterai / Jaringan. Grafik riwayat pendek (30–300 titik, hanya di memori). Interval 1/2/3/5/10 dtk (bawaan 2 dtk).
- **Hemat baterai**: timer metrik hanya berjalan saat Beranda atau Performance Monitor benar-benar tampil dan aplikasi di latar depan; berhenti saat pindah tab, tertutup halaman lain, atau aplikasi ke latar belakang.
- **Baterai & suhu**: level, status pengisian, tegangan, suhu baterai. Peringatan suhu dapat diatur (bawaan 40 °C hangat, +5 °C panas). Ini suhu **baterai**, bukan suhu CPU. Tidak ada klaim kesehatan/kapasitas/estimasi waktu pengisian.
- **Jaringan**: Wi-Fi/seluler, validasi internet, status VPN (bukan jaminan aman), lalu lintas "sesi ini" (sejak Task X dibuka) dan "sejak boot", keduanya seluruh sistem, bukan per aplikasi.
- **Storage Analyzer**: kapasitas total/terpakai/tersedia, pemindaian folder via Storage Access Framework (tanpa akses semua file), pintasan ke pengaturan penyimpanan Android.
- **Sensor Lab**: pembacaan real-time akselerometer, giroskop, cahaya, jarak, magnetometer, barometer, dll. (sensor tanpa izin khusus) + daftar semua sensor. Listener dilepas saat halaman ditutup atau aplikasi ke latar belakang.
- **Laporan sistem**: TXT dan JSON dengan timestamp, versi aplikasi, perangkat, RAM, storage, baterai, jaringan, sensor; simpan lewat dialog "Simpan sebagai" Android, salin, bagikan. Tanpa daftar aplikasi, SSID, IP, atau ID perangkat.
- **Aplikasi / Proses / System Inspector / Pengaturan**: tetap seperti v1.0 (ikon asli, versi, ukuran APK, buka, Info aplikasi, uninstall lewat konfirmasi Android; proses Task X + aplikasi terpakai 24 jam via Akses penggunaan).
- Format uptime Indonesia konsisten: `1 hari 9 jam 11 menit`.

### Batasan Android 11 yang masih berlaku
- CPU total/per-core: `/proc/stat` dibatasi di Android 8+; ditampilkan "Dibatasi Android" bila tidak terbaca (tidak ada angka karangan).
- CPU/RAM/PID/jaringan per aplikasi lain tidak tersedia; tidak ada "RAM Booster" atau task killer.
- Suhu: hanya suhu baterai. Sensor langkah/detak jantung tidak ditampilkan (butuh izin).
- Ukuran aplikasi = ukuran berkas APK, bukan total data/cache.
- Peringatan suhu hanya di dalam aplikasi (tanpa notifikasi latar belakang, tanpa izin tambahan).

### Izin
`ACCESS_NETWORK_STATE`, `QUERY_ALL_PACKAGES` (daftar aplikasi), `PACKAGE_USAGE_STATS` (opsional, diberikan pengguna). Tanpa izin internet, tanpa server.

### Status pengujian
- `flutter analyze` bersih, `flutter test` lulus, `flutter build apk --release` berhasil di GitHub Actions (lihat tab Actions untuk run terbaru).
- Belum diuji manual di perangkat fisik (Infinix Hot 11s NFC): tampilan, Sensor Lab, dan ekspor berkas perlu dicoba langsung.

## Build APK (tanpa komputer)
1. **Otomatis**: setiap push ke `main` menjalankan build.
2. **Manual dari HP**: GitHub → Actions → **Build Android APK** → **Run workflow** (branch `main`).
3. Setelah hijau, buka run tersebut → bagian **Artifacts** → unduh **TaskX-apk** (zip berisi `TaskX-v1.1.0-<nomor>.apk`), ekstrak, lalu instal (izinkan "sumber tidak dikenal").
4. **Release resmi**: buat tag `v1.1.0` (GitHub → Releases → Draft new release); workflow melampirkan APK ke Release.

APK ditandatangani kunci debug (cukup untuk sideload pribadi). Build: arm + arm64.

## Ikon
`mujib_logo.png` (root) adalah sumber logo. `python3 tools/generate_icons.py` membuat ulang ikon launcher adaptive/legacy dan menyalin logo ke `assets/images/`.
