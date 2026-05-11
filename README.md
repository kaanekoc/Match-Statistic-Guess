# ⚽ Maç İstatistik Tahmin Uygulaması

Transfermarkt API'lerini kullanarak futbol maçlarının detaylı analizini yapan ve makine öğrenimi modelleriyle bahis tahminleri üreten MATLAB uygulaması.

## 🎯 Özellikler

| Tahmin Türü | Açıklama |
|---|---|
| **Maç Skoru** | Ev sahibi ve deplasman gol sayısı tahmini |
| **2.5 Alt/Üst** | Toplam gol sayısının 2.5 üstü/altı tahmini |
| **Maç Sonucu (1X2)** | Ev sahibi galibiyeti, beraberlik veya deplasman galibiyeti |
| **Kart Tahmini** | Sarı ve kırmızı kart sayısı tahmini |
| **Korner Tahmini** | Toplam korner sayısı ve 9.5 alt/üst |

## 📁 Proje Yapısı

```
matlab/
├── main.m                  # Ana uygulama (başlatma scripti)
├── setup_paths.m           # MATLAB yol ayarları
├── config/
│   └── api_config.m        # API yapılandırma ve endpoint tanımları
├── utils/
│   ├── http_get.m          # HTTP GET istekleri (retry mekanizması)
│   ├── json_save.m         # JSON kaydetme
│   └── json_load.m         # JSON yükleme
├── api/
│   ├── get_league_teams.m              # Lig takımlarını listele
│   ├── get_team_squad.m                # Takım kadrosu
│   ├── get_team_last_formation.m       # Son maç dizilişi
│   ├── get_team_previous_matches.m     # Takım son maçları
│   ├── get_team_next_matches.m         # Takım gelecek maçları
│   ├── get_player_competition_performance.m  # Oyuncu müsabaka performansı
│   ├── get_player_seasonal_performance.m     # Oyuncu sezonluk performans
│   ├── get_player_previous_matches.m         # Oyuncu son maçları
│   └── get_player_sorare.m                   # Oyuncu Sorare kart bilgileri
├── data/
│   ├── collect_team_data.m         # Takım veri toplama
│   ├── collect_league_data.m       # Lig veri toplama
│   ├── parse_match_results.m       # Maç sonuçlarını ayrıştırma
│   └── extract_formation_stats.m   # Diziliş istatistikleri çıkarma
├── features/
│   ├── build_match_features.m      # Maç özellik vektörü oluşturma
│   └── prepare_training_data.m     # Eğitim verisi hazırlama
└── models/
    ├── train_all_models.m          # Tüm modelleri eğitme
    ├── predict_match.m             # Maç tahmini yapma
    ├── evaluate_models.m           # Model değerlendirme
    └── display_prediction.m        # Tahmin sonuç gösterimi
```

## 🚀 Kurulum ve Çalıştırma

### Gereksinimler
- MATLAB R2020b veya üzeri
- Statistics and Machine Learning Toolbox (opsiyonel)

### Hızlı Başlangıç

```matlab
% 1. Proje dizinine gidin
cd('d:/Github/Match-Statistic-Guess/matlab')

% 2. Yolları ayarlayın
setup_paths()

% 3. Uygulamayı başlatın
main
```

### Çalışma Modları

| Mod | Açıklama |
|---|---|
| **A - Tam Döngü** | Veri topla → Model eğit → Tahmin yap |
| **B - Veri Toplama** | Sadece API'den veri çek ve kaydet |
| **C - Tahmin** | Kayıtlı model ile yeni maç tahmini yap |
| **D - Demo** | Sentetik veri ile sistemi test et |

## 📊 Kullanılan API'ler

Transfermarkt üzerinden aşağıdaki veriler çekilmektedir:

- **Lige göre takım listesi** — Bir ligdeki tüm takımlar
- **Takım kadrosu** — Oyuncu listesi ve mevkileri
- **Son maç dizilişi** — İlk 11, goller, kartlar, değişiklikler
- **Takım son/gelecek maçları** — Maç skorları ve fikstur
- **Oyuncu performansları** — Müsabaka ve sezon bazlı istatistikler
- **Sorare kart bilgileri** — Fantazi futbol puanları ve metrikleri

## 🤖 Makine Öğrenimi Modelleri

| Model | Yöntem | Hedef |
|---|---|---|
| Skor Tahmini | Ensemble Ridge Regression | Ev/deplasman gol sayısı |
| 2.5 Alt/Üst | Lojistik Regresyon (L2) | İkili sınıflandırma |
| Maç Sonucu | One-vs-Rest Sınıflandırma | 1/X/2 çoklu sınıf |
| Kart Tahmini | Ridge Regresyon | Toplam kart sayısı |

### Özellik Mühendisliği

Modeller aşağıdaki özelliklerden faydalanır:
- Son N maç gol ortalaması (atılan/yenilen)
- Galibiyet/beraberlik/mağlubiyet oranları
- 2.5 üst/alt geçmiş oranı
- Son 3 maç form puanı
- Ev sahibi/deplasman avantajı
- Gol farkı istatistikleri
- Diziliş bazlı kart/gol verileri

## 📝 Lisans

Bu proje eğitim amaçlıdır. Transfermarkt verileri üçüncü taraf kaynaklıdır.
