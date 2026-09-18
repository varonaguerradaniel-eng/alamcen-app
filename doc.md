# 📦 Warehouse Elite — B2B Envanter Yönetim Sistemi

## Proje Dokümantasyonu

---

## 1. Genel Bakış

**Warehouse Elite**, Flutter ile geliştirilmiş bir **barkod tabanlı depo/envanter yönetim sistemi**dir. Uygulama, ürünlerin barkod okutularak sisteme kaydedilmesini, stok giriş/çıkış hareketlerinin takip edilmesini ve envanter durumunun anlık olarak izlenmesini sağlar.

| Bilgi | Değer |
|---|---|
| **Proje Adı** | `b2b_system` |
| **Uygulama Adı** | Warehouse Elite |
| **Platform** | Flutter (Cross-platform: Android, iOS, Windows, Linux, macOS, Web) |
| **Dart SDK** | `^3.11.0` |
| **Versiyon** | `1.0.0+1` |
| **Veritabanı** | SQLite (sqflite) |
| **Dil** | Türkçe (UI tamamen Türkçe lokalize) |

---

## 2. Mimari Yapı (Architecture)

Proje, klasik **katmanlı mimari (Layered Architecture)** kullanmaktadır:

```
lib/
├── main.dart                    # Uygulama giriş noktası
├── models/                      # Veri modelleri
│   ├── product.dart             # Ürün modeli
│   └── stock_movement.dart      # Stok hareket modeli
├── screens/                     # Ekranlar (UI)
│   ├── splash_screen.dart       # Açılış/yükleme ekranı
│   ├── dashboard_screen.dart    # Ana panel (Dashboard)
│   ├── barcode_scanner_screen.dart  # Barkod tarama ekranı
│   ├── action_selection_screen.dart # İşlem seçim ekranı
│   ├── add_product_screen.dart  # Ürün ekleme ekranı
│   ├── product_detail_screen.dart   # Ürün detay/düzenleme ekranı
│   └── product_list_screen.dart # Ürün listesi ekranı
├── services/                    # İş mantığı ve veri katmanı
│   ├── database_helper.dart     # SQLite veritabanı yöneticisi
│   └── xlsx_import_service.dart # Excel dosyası içe aktarma servisi
├── theme/                       # Tasarım sistemi
│   ├── app_colors.dart          # Renk paleti tanımları
│   └── app_theme.dart           # Material 3 tema konfigürasyonu
└── widgets/                     # Yeniden kullanılabilir bileşenler
    └── bottom_nav_bar.dart      # Alt navigasyon çubuğu
```

### Katmanlar

| Katman | Dizin | Sorumluluk |
|---|---|---|
| **Presentation** | `screens/`, `widgets/` | UI ekranları, kullanıcı etkileşimi |
| **Business Logic** | `services/` | Veritabanı işlemleri, veri akışı, dosya işlemleri |
| **Data** | `models/` | Veri modelleri, serileştirme (Map ↔ Object) |
| **Theme** | `theme/` | Renk, tipografi ve tema yönetimi |

---

## 3. Bağımlılıklar (Dependencies)

### Production Paketleri

| Paket | Versiyon | Kullanım Amacı |
|---|---|---|
| `cupertino_icons` | ^1.0.8 | iOS tarzı ikonlar |
| `sqflite` | ^2.4.2 | SQLite veritabanı (mobil) |
| `sqflite_common_ffi` | ^2.3.4+4 | SQLite FFI (masaüstü desteği) |
| `path_provider` | ^2.1.5 | Dosya sistemi yol erişimi |
| `path` | ^1.9.1 | Platform bağımsız yol oluşturma |
| `mobile_scanner` | ^6.0.5 | Kamera ile barkod/QR kod tarama |
| `excel` | ^4.0.6 | Excel (.xlsx) dosya okuma/yazma |
| `file_picker` | ^8.1.7 | Dosya seçme diyaloğu |
| `google_fonts` | ^6.2.1 | Google Fonts entegrasyonu (Inter font) |
| `provider` | ^6.1.5 | State management (henüz aktif kullanılmıyor) |
| `intl` | ^0.20.2 | Sayı/tarih formatlaması (Türk formatı) |

### Dev Paketleri

| Paket | Versiyon |
|---|---|
| `flutter_test` | SDK |
| `flutter_lints` | ^6.0.0 |

---

## 4. Veritabanı Şeması

Uygulama **SQLite** veritabanı kullanmaktadır. Masaüstü platformlarda `sqflite_common_ffi` ile FFI modu aktif edilir.

**Veritabanı dosyası:** `warehouse_elite.db`
**Versiyon:** `1`

### 4.1 `products` Tablosu

Ürün bilgilerini saklar.

| Sütun | Tip | Kısıtlama | Açıklama |
|---|---|---|---|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Benzersiz ID |
| `barcode` | TEXT | NOT NULL, UNIQUE | Barkod numarası |
| `name` | TEXT | NOT NULL | Ürün adı |
| `category` | TEXT | NOT NULL | Kategori |
| `cost_price` | REAL | NOT NULL, DEFAULT 0 | Geliş/maliyet fiyatı (₺) |
| `sale_price` | REAL | NOT NULL, DEFAULT 0 | Satış fiyatı (₺) |
| `quantity` | INTEGER | NOT NULL, DEFAULT 0 | Mevcut stok miktarı |
| `location` | TEXT | NOT NULL, DEFAULT '' | Depo konumu (Bölge/Raf) |
| `weight` | REAL | Nullable | Ağırlık (kg) |
| `created_at` | TEXT | NOT NULL | Oluşturulma tarihi (ISO 8601) |
| `updated_at` | TEXT | NOT NULL | Son güncelleme tarihi (ISO 8601) |

**İndeksler:**
- `idx_products_barcode` → `barcode` sütununda (hızlı barkod sorgusu)

### 4.2 `stock_movements` Tablosu

Stok hareketlerini (giriş, çıkış, sayım, fire/iade) saklar.

| Sütun | Tip | Kısıtlama | Açıklama |
|---|---|---|---|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Benzersiz ID |
| `product_id` | INTEGER | NOT NULL, FK → products(id) | İlişkili ürün |
| `type` | TEXT | NOT NULL | Hareket tipi |
| `quantity` | INTEGER | NOT NULL | İşlem miktarı |
| `note` | TEXT | Nullable | İsteğe bağlı not |
| `created_at` | TEXT | NOT NULL | Hareket tarihi (ISO 8601) |

**İndeksler:**
- `idx_movements_product` → `product_id` sütununda
- `idx_movements_created` → `created_at` sütununda

### 4.3 Stok Hareket Tipleri

| Tip Kodu | Türkçe Etiket | Davranış | Açıklama |
|---|---|---|---|
| `mal_kabul` | Stok Girişi | `quantity += miktar` | Gelen malı depoya kaydetme |
| `sevkiyat` | Sevkiyat | `quantity -= miktar` | Ürün gönderimi/çıkış |
| `sayim` | Sayım | `quantity = miktar` | Mevcut raf sayımını doğrulama (direkt set) |
| `fire_iade` | Fire/İade | `quantity -= miktar` | Hasarlı ürün veya müşteri iadesi |

> **Not:** Stok işlemleri `DatabaseHelper.processStockMovement()` metodu içinde **transaction** olarak çalışır. Hem `stock_movements` tablosuna kayıt eklenir, hem de `products` tablosundaki `quantity` güncellenir.

---

## 5. Veri Modelleri

### 5.1 Product (Ürün)

**Dosya:** `lib/models/product.dart`

```dart
class Product {
  int? id;
  String barcode;         // Benzersiz barkod
  String name;            // Ürün adı
  String category;        // Kategori
  double costPrice;       // Geliş fiyatı (₺)
  double salePrice;       // Satış fiyatı (₺)
  int quantity;           // Mevcut stok
  String location;        // Depo konumu
  double? weight;         // Ağırlık (kg), opsiyonel
  DateTime createdAt;     // Oluşturulma tarihi
  DateTime updatedAt;     // Son güncelleme
}
```

**Hesaplanan Alanlar (Computed Properties):**
- `profit` → `salePrice - costPrice` (Birim net kar)
- `profitMargin` → `(profit / costPrice) * 100` (Kar oranı %)

**Metotlar:**
- `toMap()` → SQLite'a yazmak için Map'e dönüştürme
- `Product.fromMap()` → SQLite'dan okumak için Map'ten oluşturma
- `copyWith()` → Immutable güncelleme deseni

### 5.2 StockMovement (Stok Hareketi)

**Dosya:** `lib/models/stock_movement.dart`

```dart
class StockMovement {
  int? id;
  int productId;           // İlişkili ürün ID
  String type;             // Hareket tipi (mal_kabul, sevkiyat, sayim, fire_iade)
  int quantity;            // İşlem miktarı
  String? note;            // Opsiyonel not
  DateTime createdAt;      // İşlem tarihi
  
  // Join ile gelen alanlar (DB'de saklanmaz)
  String? productName;     // Ürün adı (listeleme için)
  String? productBarcode;  // Ürün barkodu (listeleme için)
}
```

**Hesaplanan Alanlar:**
- `typeLabel` → Türkçe etiket (örn: "Stok Girişi", "Sevkiyat")
- `typeIcon` → Material Design ikon adı
- `isInbound` → Giriş hareketi mi? (`mal_kabul`)
- `isOutbound` → Çıkış hareketi mi? (`sevkiyat` veya `fire_iade`)

---

## 6. Servisler (Business Logic)

### 6.1 DatabaseHelper

**Dosya:** `lib/services/database_helper.dart`
**Desen:** Singleton

SQLite veritabanı üzerinde tüm CRUD işlemlerini yöneten merkezi servis.

#### Ürün İşlemleri (Product CRUD)

| Metot | Parametre | Dönüş | Açıklama |
|---|---|---|---|
| `insertProduct()` | `Product` | `int` (id) | Yeni ürün ekler |
| `getProductByBarcode()` | `String barcode` | `Product?` | Barkoda göre ürün bulur |
| `getProductById()` | `int id` | `Product?` | ID'ye göre ürün bulur |
| `getAllProducts()` | — | `List<Product>` | Tüm ürünleri çeker (`updated_at DESC`) |
| `updateProduct()` | `Product` | `int` (affected rows) | Ürün bilgilerini günceller |
| `deleteProduct()` | `int id` | `int` (affected rows) | Ürünü siler |
| `getLowStockProducts()` | `int threshold = 25` | `List<Product>` | Düşük stokluları çeker |

#### Stok Hareket İşlemleri

| Metot | Parametre | Dönüş | Açıklama |
|---|---|---|---|
| `insertStockMovement()` | `StockMovement` | `int` (id) | Hareket kaydı ekler |
| `getRecentMovements()` | `int limit = 20` | `List<StockMovement>` | Son hareketleri çeker (JOIN ile) |
| `getMovementsByProduct()` | `int productId` | `List<StockMovement>` | Ürüne ait hareketleri çeker |

#### Birleşik İşlemler

| Metot | Açıklama |
|---|---|
| `processStockMovement()` | **Transaction** içinde hem hareketi kaydeder, hem stok miktarını günceller |
| `getTodayStats()` | Bugünün girişleri, çıkışları ve düşük stoğu sayar |
| `bulkInsertProducts()` | Toplu ürün ekleme (Excel import için), `ConflictAlgorithm.ignore` |
| `close()` | Veritabanı bağlantısını kapatır |

### 6.2 XlsxImportService

**Dosya:** `lib/services/xlsx_import_service.dart`

Excel dosyalarından toplu ürün aktarma servisi.

#### Beklenen Excel Sütun Yapısı

| Sütun Index | Başlık | Zorunlu | Tip |
|---|---|---|---|
| 0 | Barkod | ✅ | Text |
| 1 | Ürün Adı | ✅ | Text |
| 2 | Kategori | ❌ (Varsayılan: "Genel") | Text |
| 3 | Miktar | ❌ (Varsayılan: 0) | Integer |
| 4 | Geliş Fiyatı | ❌ (Varsayılan: 0.0) | Double |
| 5 | Satış Fiyatı | ❌ (Varsayılan: 0.0) | Double |
| 6 | Konum | ❌ (Varsayılan: "") | Text |
| 7 | Ağırlık (kg) | ❌ (Varsayılan: null) | Double |

> **İlk satır** başlık satırı olarak kabul edilir ve atlanır.

#### Metotlar

| Metot | Açıklama |
|---|---|
| `importFromFile()` | Dosya seçiciyi açar, .xlsx dosyayı parse eder, `bulkInsertProducts()` ile DB'ye yazar |
| `generateTemplate()` | Örnek verili şablon Excel dosyası oluşturur (Windows'da `Downloads` klasörüne kaydeder) |

#### XlsxImportResult

| Alan | Tip | Açıklama |
|---|---|---|
| `success` | `bool` | İşlem başarılı mı |
| `message` | `String` | Kullanıcıya gösterilecek mesaj |
| `importedCount` | `int` | Başarılı eklenen ürün sayısı |
| `totalFound` | `int?` | Dosyada bulunan toplam geçerli ürün sayısı |

---

## 7. Ekranlar (Screens)

### 7.1 Splash Screen (Açılış Ekranı)

**Dosya:** `lib/screens/splash_screen.dart`

- Lacivert gradient arka plan (`navyDark → navyDeep`)
- Glassmorphic kalkan+QR ikon animasyonu
- Fade-in + Scale animasyonu (1500ms)
- "PRECISION INVENTORY MANAGEMENT" alt başlık
- `LinearProgressIndicator` yükleme çubuğu
- 3 saniye sonra `DashboardScreen`'e otomatik geçiş (FadeTransition)
- Dekoratif barcode çizgileri (dikey gradient çubuklar)

### 7.2 Dashboard Screen (Ana Panel)

**Dosya:** `lib/screens/dashboard_screen.dart`

Ana ekran olup şu bileşenlerden oluşur:

**İstatistik Kartları (Tıklanabilir):**
- **Bugünkü Girişler** → Mal kabul toplam miktarı → Tıklayınca filtrelenmiş ürün listesine gider
- **Bugünkü Çıkışlar** → Sevkiyat + Fire/İade toplam miktarı → Tıklayınca filtrelenmiş listeye gider
- **Düşük Stok Uyarıları** → Stok miktarı ≤ 25 olan ürün sayısı → Tıklayınca düşük stok listesine gider

**Hızlı İşlem Merkezi:**
- Büyük gradient dairesel buton ile barkod tarayıcıyı açar
- Dekoratif daire arka planlar

**Son Hareketler:**
- Son 10 stok hareketini kronolojik sırada listeler
- Her hareket için: ürün adı, hareket tipi, miktar (+/-), saat

**Pull-to-Refresh:** Aşağı çekerek verileri yenileyebilme

**Navigasyon:**
- `BottomNavBar` ile 5 sekme (Ana Sayfa, Depo, Tara, Geçmiş, Ürünler)
- Sekme 0: Dashboard (varsayılan)
- Sekme 1: `AddProductScreen` → Yeni ürün ekleme
- Sekme 2: `BarcodeScannerScreen` → Barkod tarama
- Sekme 3: Henüz implement edilmemiş
- Sekme 4: `ProductListScreen` → Ürün listesi

### 7.3 Barcode Scanner Screen (Barkod Tarama)

**Dosya:** `lib/screens/barcode_scanner_screen.dart`

- **Kamera modu:** `MobileScanner` ile gerçek zamanlı barkod okuma
- **Vizör (Viewfinder):** Köşe çerçeveli, tarama çizgili hedefleme alanı
- **Fener kontrolü:** Kamera fenerini açma/kapama
- **Manuel giriş:** Barkod numarasını elle yazma diyaloğu
- **Tetik butonu:** Büyük gradient QR ikon butonu
- **Kamera yoksa:** Gradient arka plan + "Kamera kullanılamıyor" mesajı

**İki Mod:**
1. **Normal mod** (`returnBarcodeOnly = false`): Barkod algılayınca → DB'den ürün sorgulaması yapar → `ActionSelectionScreen`'e yönlendirir
2. **Sadece barkod modu** (`returnBarcodeOnly = true`): Barkodu okuyup string olarak geri döner (Ürün ekleme ekranından çağrılır)

### 7.4 Action Selection Screen (İşlem Seçimi)

**Dosya:** `lib/screens/action_selection_screen.dart`

Barkod tarandıktan sonra açılan işlem merkezi ekranı.

**Üst Bölüm:**
- Taranan barkod numarası (büyük font)
- Bulunan ürün bilgisi veya "ürün bulunamadı" uyarısı

**İşlem Kartları:**

| Kart | Renk | İkon | İşlem |
|---|---|---|---|
| Mal Kabul | `secondaryContainer` | downloading | Stok girişi modal'ı açar |
| Sevkiyat | `primaryContainer` | local_shipping | Stok çıkışı modal'ı açar |
| Sayım | Beyaz (kenarlıklı) | calculate | Sayım modal'ı açar |
| Fire/İade | `tertiaryContainer` (yatay kart) | recycling | Fire/İade modal'ı açar |
| Anlık Stok Görüntüle | `inverseSurface` (koyu) | visibility | `ProductDetailScreen`'e gider (stock tab) |
| Fiyat Görüntüle | Yeşil | sell | `ProductDetailScreen`'e gider (price tab) |

**İşlem Modal'ı (BottomSheet):**
- Miktar girişi (büyük sayı input)
- Not alanı (opsiyonel)
- Mevcut stok bilgisi
- "İşlemi Kaydet" butonu → `processStockMovement()` çağırır

**Ürün bulunamadı durumu:**
- SnackBar ile uyarı gösterir
- "ÜRÜN EKLE" aksiyonu ile `AddProductScreen`'e yönlendirir

### 7.5 Add Product Screen (Ürün Ekleme)

**Dosya:** `lib/screens/add_product_screen.dart`

**Form Alanları:**

| Alan | Tip | Zorunlu | Validasyon |
|---|---|---|---|
| Ürün Adı | Text | ✅ | Boş olamaz |
| Kategori | Dropdown | ✅ | Sabit liste |
| Barkod/SKU | Text + Tarayıcı | ✅ | Boş olamaz, UNIQUE kontrolü |
| Başlangıç Miktarı | Number | ❌ | Tam sayı, ≥ 0, kesirli olamaz |
| Geliş Fiyatı (₺) | Decimal | ❌ | — |
| Satış Fiyatı (₺) | Decimal | ❌ | — |
| Ağırlık (kg) | Decimal | ❌ | Opsiyonel |
| Depo Konumu | Text | ❌ | — |

**Önceden Tanımlı Kategoriler:**
`Genel`, `Elektronik`, `Donanım`, `Ham Madde`, `Güvenlik Ekipmanı`, `Gıda`, `Tekstil`, `Diğer`

**Barkod Tarama Entegrasyonu:**
- Barkod alanının sağında QR ikon butonu
- Tıklayınca `BarcodeScannerScreen(returnBarcodeOnly: true)` açılır
- Tarama sonucu barkod alanına otomatik yazılır

**"0" değerli alanlar:** Dokunulunca tüm metin seçilir (`_onTapSelectAll`)

**Toplu Ürün Ekleme Bölümü:**
- "XLSX İçe Aktar" butonu → `XlsxImportService.importFromFile()`
- "Excel Şablonunu İndir" linki → `XlsxImportService.generateTemplate()`

**Hata Yönetimi:**
- `UNIQUE` constraint ihlali → "Barkod Zaten Kayıtlı" custom dialog
- Diğer hatalar → Genel hata dialog'u

### 7.6 Product Detail Screen (Ürün Detayı)

**Dosya:** `lib/screens/product_detail_screen.dart`

Bir ürünün tam detay ve düzenleme ekranı.

**Bölümler:**

1. **Başlık:** SKU-{id}, ürün adı, konum, stok durumu badge'i
2. **Ürün Bilgi Kartı:** Barkod, kategori, ağırlık
3. **Fiyat Modülü:**
   - Geliş fiyatı (düzenlenebilir)
   - Satış fiyatı (düzenlenebilir)
   - **Kar Durum Analizi kartı:** Net kar (₺) + Kar oranı (%) - yeşil gradient tasarım
   - "Kar Durumunu Yeniden Hesapla" butonu
4. **Stok Ayarla Paneli:**
   - Hero number (büyük stok gösterimi)
   - Stepper (+/- butonları)
   - Manuel sayı girişi
   - Preset butonlar: +10, +50, Maks (9999)
   - "Envanteri Güncelle" kaydetme butonu

**Fiyat Format:** Türk formatı (`#,##0.00` / `tr_TR`) - `NumberFormat` ile

### 7.7 Product List Screen (Ürün Listesi)

**Dosya:** `lib/screens/product_list_screen.dart`

Tüm ürünlerin listelendiği, filtrelenip sıralanabildiği ekran.

**Özellikleri:**

- **Arama:** Ürün adı, barkod veya kategoriye göre anında arama
- **Sıralama:** Ada göre, stoğa göre, son güncellemeye göre (PopupMenu)
- **Filtre destekleri:**
  - `lowStock` → Stok ≤ 25 olan ürünler
  - `inbound` → Giriş yapılan ürünler (tümü gösterilir)
  - `outbound` → Çıkış yapılan ürünler (stok > 0 olanlar)

**Mini İstatistikler (Üst kısım):**
- Toplam Ürün sayısı
- Düşük Stok sayısı (≤ 25)
- Stok Yok sayısı (== 0)

**Ürün Kartı İçeriği:**
- Ürün ikonu, adı, kategorisi, barkodu (kısaltılmış)
- Stok miktarı + durum badge'i (STOKTA / DÜŞÜK STOK / STOK YOK)
- Satış fiyatı

**Stok Durumu Renk Kodlaması:**

| Durum | Koşul | Renk |
|---|---|---|
| STOK YOK | `quantity == 0` | Kırmızı (`error`) |
| DÜŞÜK STOK | `quantity ≤ 25` | Turuncu (`#e65100`) |
| STOKTA | `quantity > 25` | Koyu mavi (`onSecondaryContainer`) |

**Boş Durum:** "Henüz ürün yok" mesajı + "Ürün Ekle" butonu

**FAB (Floating Action Button):** Gradient "Yeni Ürün" butonu → `AddProductScreen`

---

## 8. Tema ve Tasarım Sistemi

### 8.1 Renk Paleti

**Dosya:** `lib/theme/app_colors.dart`

Uygulama **Material 3** renk şemasını tamamen özelleştirilmiş renk paletiyle kullanır:

| Grubu | Ana Renk | Hex |
|---|---|---|
| Primary | Mor-Lacivert | `#4d56b0` |
| Secondary | Gri-Mor | `#5c5d72` |
| Tertiary | Mor-Lila | `#72547b` |
| Error | Kırmızı | `#a8364b` |
| Surface | Beyaz-Gri | `#FBF9F9` |
| Navy Dark | Lacivert | `#1A237E` |
| Profit Green | Yeşil | `#2e7d32` |

### 8.2 Tema Konfigürasyonu

**Dosya:** `lib/theme/app_theme.dart`

| Ayar | Değer |
|---|---|
| Material Design | M3 (`useMaterial3: true`) |
| Font | **Inter** (Google Fonts) |
| AppBar | Şeffaf (elevation: 0), lacivert başlık |
| InputDecoration | Filled, yuvarlatılmış (8px), border yok |
| ElevatedButton | Primary renk, yuvarlatılmış (12px), kalın metin |

---

## 9. Widget'lar

### 9.1 BottomNavBar

**Dosya:** `lib/widgets/bottom_nav_bar.dart`

Özelleştirilmiş alt navigasyon çubuğu:

- 5 sekme: Ana Sayfa, Depo, Tara, Geçmiş, Ürünler
- **Glassmorphic** tasarım (yarı-saydam beyaz, gölge)
- Aktif sekme: mavi arka plan, koyu ikon
- Pasif sekme: gri ikon
- Animasyonlu geçiş (200ms)
- Büyük harfli etiketler (9px, bold)

| Index | İkon | Etiket |
|---|---|---|
| 0 | dashboard | ANA SAYFA |
| 1 | inventory_2 | DEPO |
| 2 | qr_code_scanner | TARA |
| 3 | history | GEÇMİŞ |
| 4 | view_list | ÜRÜNLER |

---

## 10. Uygulama Akışları

### 10.1 Uygulama Başlatılması

```
main.dart
  ├── WidgetsFlutterBinding.ensureInitialized()
  ├── Platform kontrolü (Windows/Linux/macOS ise FFI init)
  ├── DatabaseHelper.instance.database (DB oluşturma/açma)
  └── runApp(WarehouseEliteApp)
       └── MaterialApp → SplashScreen → (3sn) → DashboardScreen
```

### 10.2 Barkod Tarama → İşlem Akışı

```
DashboardScreen
  └── "Hızlı Barkod Tara" veya BottomNav[2]
       └── BarcodeScannerScreen
            ├── Kamera ile otomatik barkod algılama
            └── Manuel giriş dialog
                 └── Barkod algılandı
                      ├── DB'de ürün var → ActionSelectionScreen(product: ürün)
                      └── DB'de ürün yok → ActionSelectionScreen(product: null)
                           └── "ÜRÜN EKLE" SnackBar → AddProductScreen
```

### 10.3 Stok İşlemi Akışı

```
ActionSelectionScreen
  └── İşlem Kartı Tıkla (örn: "Mal Kabul")
       └── BottomSheet Modal açılır
            ├── Miktar gir
            ├── Not ekle (opsiyonel)
            └── "İşlemi Kaydet"
                 └── DatabaseHelper.processStockMovement()
                      ├── stock_movements tablosuna kayıt
                      └── products.quantity güncelleme
                           └── SnackBar: "İşlem başarıyla kaydedildi"
```

### 10.4 Excel İçe Aktarma Akışı

```
AddProductScreen → "Toplu Ürün Ekle" bölümü
  ├── "XLSX İçe Aktar" → FilePicker → .xlsx seçimi
  │    └── XlsxImportService.importFromFile()
  │         ├── Excel parse (ilk satır header, geri kalan veri)
  │         ├── Her satır → Product modeline dönüştürme
  │         └── bulkInsertProducts() → DB'ye toplu ekleme
  │              └── ConflictAlgorithm.ignore (Duplicate barkod atlanır)
  │
  └── "Excel Şablonunu İndir" → XlsxImportService.generateTemplate()
       └── Windows: %USERPROFILE%\Downloads\urun_sablonu.xlsx
```

---

## 11. Platformlar Arası Destek

| Platform | Veritabanı | Kamera | Dosya Seçici |
|---|---|---|---|
| **Android** | sqflite (native) | ✅ MobileScanner | ✅ FilePicker |
| **iOS** | sqflite (native) | ✅ MobileScanner | ✅ FilePicker |
| **Windows** | sqflite_common_ffi | ⚠️ Kamera kullanılamayabilir | ✅ FilePicker |
| **Linux** | sqflite_common_ffi | ⚠️ Kamera kullanılamayabilir | ✅ FilePicker |
| **macOS** | sqflite_common_ffi | ⚠️ Kamera kullanılamayabilir | ✅ FilePicker |
| **Web** | ❌ Desteklenmez | — | — |

> **Masaüstünde kamera yoksa:** Gradient arka plan gösterilir, manuel barkod girişi kullanılabilir.

---

## 12. Tasarım Prensipleri

### UI/UX Kararları

1. **Türkçe Arayüz:** Tüm etiketler, mesajlar ve SnackBar'lar Türkçe
2. **Material 3:** M3 renk şeması ve bileşenleri kullanılır
3. **Glassmorphic Tasarım:** BottomNavBar ve splash ekranı
4. **Gradient Butonlar:** Birincil aksiyonlar gradient ile vurgulanır
5. **Tipografi Hiyerarşisi:** Büyük başlıklar (32px w900), alt etiketler (12px w700, letter-spacing)
6. **Animasyonlar:** Splash'ta fade-in/scale, nav bar'da geçiş animasyonu
7. **Pull-to-Refresh:** Dashboard'da aşağı çekerek yenileme
8. **Responsive:** `CustomScrollView` + `SliverAppBar` ile kaydırma deneyimi

### Kodlama Standartları

1. **Singleton Pattern:** `DatabaseHelper.instance` ile tek DB bağlantısı
2. **Static Methods:** `XlsxImportService` tamamen static
3. **Transaction Kullanımı:** Stok hareketlerinde atomik işlemler
4. **ISO 8601 Tarih Formatı:** DB'de tarihler string olarak saklanır
5. **CopyWith Pattern:** Product modelinde immutable güncelleme
6. **Mounted Check:** Her async işlem sonrası `if (mounted)` kontrolü

---

## 13. Bilinen Sınırlamalar ve Geliştirme Alanları

### Mevcut Sınırlamalar

| Durum | Açıklama |
|---|---|
| ⚠️ State Management | `provider` paketi yüklü ama kullanılmıyor. Her ekran kendi state'ini `setState` ile yönetiyor |
| ⚠️ Geçmiş Sekmesi | BottomNavBar'da index 3 (Geçmiş) henüz bir ekrana yönlendirilmiyor |
| ⚠️ "Tümünü Gör" | Dashboard'daki "Tümünü Gör" butonu henüz fonksiyonel değil |
| ⚠️ Hamburger Menü | AppBar'daki menü ikonu (`Icons.menu`) henüz bir drawer açmıyor |
| ⚠️ Profil İkonu | AppBar'daki profil avatarı henüz bir işlev sunmuyor |
| ⚠️ Ürün Silme | `deleteProduct()` DB metodu var ama UI'da silme butonu yok |
| ⚠️ Ürün Düzenleme | Ürün ismi, kategorisi vs. düzenleme ekranı yok (sadece fiyat/stok düzenlenebilir) |
| ⚠️ DB Migration | Veritabanı versiyonu 1'de, migration stratejisi henüz yok |
| ⚠️ Hata Yönetimi | Bazı yerlerde `debugPrint` ile loglama var, merkezi hata yönetimi yok |
| ⚠️ Test | Test dosyaları mevcut ama birim testler yazılmamış |

### Önerilen Geliştirmeler

1. **Provider/Riverpod Entegrasyonu:** Global state management
2. **Hareket Geçmişi Ekranı:** BottomNav index 3 için tam ekran
3. **Ürün Silme ve Düzenleme:** Tam CRUD UI desteği
4. **Arama/Filtreleme Geliştirme:** Tarih aralığı, fiyat aralığı filtresi
5. **Excel Dışa Aktarma:** Mevcut ürünleri Excel'e aktarma
6. **Raporlama:** Günlük/haftalık/aylık stok raporu
7. **Bildirimler:** Düşük stok bildirimi
8. **Dark Mode:** Koyu tema desteği
9. **Unit/Widget Tests:** Test coverage artırılması
10. **Barcode Generation:** Ürünler için barkod/QR etiket basımı

---

## 14. Çalıştırma / Geliştirme

### Ön Koşullar

- Flutter SDK (^3.11.0)
- Dart SDK (^3.11.0)
- Android Studio veya VS Code
- Android emülatör veya fiziksel cihaz (kamera desteği için)

### Kurulum ve Çalıştırma

```bash
# Bağımlılıkları yükle
flutter pub get

# Uygulamayı çalıştır (debug)
flutter run

# Platform belirtme
flutter run -d windows
flutter run -d android
flutter run -d chrome  # Web desteği sınırlı
```

### İlk Kurulumda

1. Uygulama ilk açılışta `warehouse_elite.db` dosyasını oluşturur
2. `products` ve `stock_movements` tabloları otomatik oluşturulur
3. İndeksler oluşturulur (barcode, product_id, created_at)
4. Splash ekranı 3 saniye gösterilir ve Dashboard'a yönlendirilir

---

*Son güncelleme: 12 Nisan 2026*
