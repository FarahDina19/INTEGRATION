# README — Apl Interaktif Unit 3 Integration

Oct 25, 2026 · @Miss

DUM10092 Engineering Mathematics · Institut Kemahiran MARA

## Apa itu apl ini

Satu apl web interaktif yang mengajar keseluruhan Unit 3 Integration kepada pelajar diploma TVET yang lemah matematik. Pelajar menaip ekspresi matematik sebenar, bukan memilih jawapan MCQ.

Apl ini dibina mengikut pendekatan CVSA (Concrete, Visual, Symbol, Abstract) dan menyediakan jalan kerja penuh untuk setiap soalan. Ia berjalan terus dalam pelayar tanpa pemasangan, pada telefon Android mahupun komputer riba.

## Pautan dan fail

Dua apl diterbitkan. Apl utama sudah mengandungi semua 3.1 hingga 3.4; apl 3.3 kekal berasingan untuk kelas yang mahu fokus pada teknik sahaja.

| Apl | Skop | Fail | Pautan |
| --- | --- | --- | --- |
| Unit 3 lengkap | 3.1, 3.2, 3.3, 3.4 | `integrasi-unit3.html` (138 KB) | [Buka](https://claude.ai/artifact/5NRpGbYNhVm69rihwcHQNo) |
| Technique Toolbox | 3.3 sahaja | `integrasi-33-teknik.html` (62 KB) | [Buka](https://claude.ai/artifact/4QqcvCYxgyQSocCkHHP4js) |

Rekaan visual kedua-duanya diambil daripada kanvas [Unit 3 Integration — Apps](https://claude.ai/artifact/1JEs96CQ1mrVoZn87spe3A).

## Struktur kandungan

Empat apl dalam satu hub. Turutan pengajaran yang disyorkan ialah A, B, D, kemudian C — pelajar perlu faham idea luas sebelum teknik.

| Apl | Subtopik | Nama | Kandungan utama |
| --- | --- | --- | --- |
| A | 3.1 | Undo Machine | Motosikal v = 2t, keluarga lengkung x² + C, power rule, cari F(x) |
| B | 3.2 | Rule Cards | Empat keluarga rule (power, trig, exponential, 1/x), tiga Aras setiap satu |
| D | 3.4 | Area Hunter | Tangki air, segi empat Riemann n = 4 hingga 200, F(b) − F(a) |
| C | 3.3 | Technique Toolbox | Substitution, by parts, partial fraction, pilih teknik, cari silap |

App C terkunci sehingga App D mencapai 80%, dengan butang buka awal untuk kegunaan guru.

App C sendiri ada lima tab: Mula, Subst., By parts, Pecahan, Nilai. Setiap teknik ada tiga Aras dengan penjana soalan rawak.

## Pendekatan CVSA dalam UI

App A dan App D bergerak melalui empat peringkat yang ditunjukkan sebagai strip di bahagian atas skrin. Pelajar nampak di mana mereka berada dan apa yang sudah selesai.

| Peringkat | App A (3.1) | App D (3.4) |
| --- | --- | --- |
| Konkrit | Motosikal makin laju, slider masa, luas berlorek | Tangki air pada kadar tetap, kemudian kadar berubah |
| Visual | Keluarga lengkung x² + C dengan slider C, tangen pada x = 1 | Segi empat Riemann, n = 4, 10, 50, 200 menumpu ke 6 |
| Simbol | Isi kotak kosong dalam template power rule | Isi F(3), F(0), kemudian hasil tolak |
| Abstrak | Soalan rawak tanpa bantuan graf | Definite integral rawak, jawapan berangka |

App B dan App C tidak mengikut strip empat peringkat kerana pelajar sudah berada di peringkat simbol dan abstrak. App C menggantikannya dengan tab Mula yang memberi konteks konkrit: tukar duit asing untuk substitution, dua orang mengecat bilik untuk by parts, satu bil dipecahkan untuk partial fraction.

## Input formula dan semakan jawapan

Inilah ciri yang membezakan apl ini daripada kuiz MCQ biasa. Pelajar menaip jawapan penuh, dan sistem menerima semua bentuk yang setara secara matematik.

Cara menaip:

1. Kuasa guna tanda `^` — contoh `x^3`
2. Pecahan guna `/` — contoh `x^3/3`
3. Darab boleh rapat — `2x` sama dengan `2*x`
4. Fungsi boleh tanpa kurungan — `sin 2x` dibaca sebagai `sin(2x)`
5. Nilai mutlak guna palang — `ln|x+1|`
6. Huruf `u` dan `t` diterima sebagai pemboleh ubah untuk langkah perantaraan

Semua yang berikut diterima sebagai jawapan betul untuk ∫ x² dx:

```markdown
x^3/3 + C
(1/3)x^3 + C
0.33333x^3 + C
x*x*x/3 + C
```

Cara sistem menyemak: ia menghurai ekspresi pelajar menjadi pokok sintaks, menilainya pada lima nilai x, dan membandingkan dengan antiderivative rujukan. Jika bezanya pemalar, jawapan betul. Kaedah ini menerima apa-apa bentuk setara tanpa perlu senarai jawapan yang panjang.

Tertinggal + C dikesan berasingan dan diberi mesej khusus — "Hampir! Bahagian x sudah betul, tapi tertinggal + C" — bukan ditanda salah terus.

## Penyelesai langkah demi langkah

Dalam App C, setiap soalan dipecahkan kepada lima langkah bergerbang. Satu langkah mesti betul sebelum langkah berikutnya terbuka, jadi pelajar tidak boleh terus meneka jawapan akhir.

Contoh untuk substitution:

1. Pilih u (soalan pilihan, dengan sebab untuk setiap pilihan salah)
2. Cari du/dx (taip jawapan)
3. Tukar integral kepada bentuk u (soalan pilihan)
4. Integrate dalam bentuk u (taip, guna huruf u)
5. Tukar balik kepada x dan tambah + C (taip)

Setiap langkah ada tiga tahap hint yang makin jelas, dan butang tunjuk jawapan langkah ini jika pelajar benar-benar buntu. Langkah yang sudah betul kekal di skrin sebagai ringkasan hijau, dan jejak kemajuan menunjukkan kedudukan semasa.

Sembilan penyelesai semuanya — tiga teknik darab tiga Aras. Selepas penyelesai berpandu, ada Latihan Bebas dengan satu kotak jawapan sahaja, jalan kerja penuh boleh dibuka bila-bila masa.

## Cara guna dalam kelas

Cadangan pembahagian mengikut waktu kuliah:

| Waktu | Apl | Aktiviti |
| --- | --- | --- |
| 1 | App A | Guru tayang peringkat Konkrit dan Visual di hadapan kelas, pelajar buat Simbol dan Abstrak sendiri |
| 2 | App B | Pelajar pilih keluarga rule, mula Aras 1, naik ke Aras 2 bila sudah lancar |
| 3 | App D | Riemann sebagai demo kelas, kemudian Simbol dan Abstrak berpasangan |
| 4–5 | App C | Satu teknik satu waktu, penyelesai berpandu dahulu, latihan bebas sebagai kerja rumah |
| 6 | App C tab Nilai | Pilih teknik dan cari silap sebagai aktiviti perbincangan kumpulan |

Tab Nilai sesuai dijadikan aktiviti berkumpulan: pelajar berbincang di mana silapnya sebelum menekan jawapan. Kad Formula boleh dicetak dan ditampal dalam buku nota.

Tiada had masa dan tiada markah tolak. Pelajar boleh cuba berulang kali tanpa penalti.

## Spesifikasi teknikal

| Perkara | Butiran |
| --- | --- |
| Format | Satu fail HTML, semua CSS dan JavaScript di dalam |
| Pergantungan luar | Hanya Google Fonts (Baloo 2 dan Nunito), ada fallback |
| Peranti | Telefon Android, iPhone, tablet, komputer riba |
| Lebar reka bentuk | Mula 390 px, kandungan maksimum 640 px di skrin besar |
| Simpanan progres | localStorage pelayar, per peranti, tiada akaun diperlukan |
| Mod gelap | Ikut tetapan sistem pengguna |
| Print | Kad Formula sahaja, susun atur mesra cetak |
| Capaian | Butang sebenar, label aria, sasaran sentuh sekurang-kurangnya 44 px |

Progres disimpan pada peranti pelajar sahaja. Tiada data dihantar ke mana-mana pelayan, jadi tiada isu privasi pelajar. Butang set semula ada di skrin Progres.

Fail boleh dimuat naik ke LMS institusi, dihantar sebagai lampiran, atau dibuka terus daripada pautan yang diberi di atas.

## Padanan silibus DUM10092

| Subtopik silibus | Objektif kognitif | Dilindungi oleh |
| --- | --- | --- |
| 3.1 Integration as reverse of differentiation | C2 | App A, keempat-empat peringkat |
| 3.2 Indefinite integral of function | C3 | App B, empat keluarga rule, tiga Aras |
| 3.3 Techniques of integration | C3 | App C tab Subst., By parts, Pecahan |
| 3.4 Definite integral | C3 | App D, peringkat Simbol dan Abstrak |
| CLO2 penilaian | C5 | App C tab Nilai, aktiviti Cari Silap |

Aktiviti Cari Silap memenuhi aras C5 kerana pelajar menilai penyelesaian orang lain dan mengenal pasti langkah yang salah, bukan sekadar mengira. Enam item meliputi silap yang paling kerap berlaku: lupa bahagi pekali selepas dx = du/3, pilih u bertentangan LIATE, guna tambah dalam uv − ∫v du, tertinggal tanda negatif dalam kaedah tutup, tertinggal + C, dan lupa darab du = dx/x dalam kes ln.

## Had semasa dan langkah seterusnya

Had yang diketahui:

- Penghurai ekspresi membaca `sin x cos x` sebagai `sin(x cos x)`. Pelajar perlu guna kurungan untuk kes begini.
- Progres tidak merentas peranti. Pelajar yang tukar telefon mula semula dari kosong.
- Partial fraction hanya meliputi dua faktor linear berbeza. Faktor berulang dan faktor kuadratik belum ada.
- By parts hanya satu pusingan. Kes yang perlu dua pusingan, seperti ∫ x² eˣ dx, belum ada.
- Tiada laporan untuk guru. Skor hanya kelihatan pada peranti pelajar sendiri.

Cadangan penambahbaikan:

- [ ] Tambah faktor berulang (x + a)² dalam partial fraction
- [ ] Tambah by parts dua pusingan sebagai Aras 4
- [ ] Kumpul data penggunaan untuk kajian tindakan — soalan mana paling kerap salah
- [ ] Rakam video demo pendek untuk pertandingan inovasi
- [ ] Uji dengan satu kelas sebenar dan kutip maklum balas pelajar
