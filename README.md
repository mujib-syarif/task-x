# Task X

**Task X by mujib_syarif** — pemantau sistem dan pengelola aplikasi Android (gabungan Task Manager + System Monitor).

Flutter + Kotlin native. Tanpa akun, tanpa server, tanpa izin internet.

## Fitur
- **Beranda**: RAM, CPU (jika diizinkan Android), penyimpanan, baterai, jaringan, uptime, jumlah aplikasi.
- **Performance Monitor**: tab CPU / RAM / Penyimpanan / Baterai / Jaringan dengan riwayat grafik selama aplikasi aktif.
- **Proses**: proses Task X sendiri + aplikasi yang dipakai 24 jam terakhir (opsional, via Akses penggunaan). Android 11 tidak mengizinkan membaca proses aplikasi lain.
- **Aplikasi**: ikon asli, versi, ukuran APK, buka, Info aplikasi, uninstall lewat alur resmi Android.
- **Alat**: System Inspector, Storage Analyzer (Storage Access Framework), sensor, ekspor/salin laporan, bersihkan cache Task X.
- **Pengaturan**: tema, interval pembaruan, riwayat, modul Beranda.

## Batasan Android (sengaja tidak dipalsukan)
- CPU total/per-core: `/proc/stat` dibatasi di Android 8+; ditampilkan "Dibatasi Android" bila tidak terbaca.
- CPU/RAM/PID aplikasi lain tidak tersedia; tidak ada "RAM Booster" atau task killer.
- Suhu: hanya suhu baterai.
- Ukuran aplikasi = ukuran berkas APK, bukan total data/cache.

## Build APK (tanpa komputer)
1. Push ke `main` atau jalankan **Actions → Build Android APK → Run workflow** dari HP.
2. Setelah hijau, buka run tersebut → **Artifacts → TaskX-apk** → unduh.
3. Untuk Release resmi: buat tag `v1.0.0` (mis. lewat GitHub → Releases → Draft new release).

APK ditandatangani kunci debug (cukup untuk sideload pribadi).

## Ikon
`mujib_logo.png` (root) adalah sumber logo. `python3 tools/generate_icons.py` membuat ulang ikon launcher adaptive/legacy dan menyalin logo ke `assets/images/`.
