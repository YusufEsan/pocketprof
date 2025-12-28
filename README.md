# 🎓 PocketProf - AI-Powered Personal Tutor

![PocketProf Banner](https://img.shields.io/badge/Flutter-Modern-blue?style=for-the-badge&logo=flutter)
![PocketProf Status](https://img.shields.io/badge/Status-Premium-gold?style=for-the-badge)

**PocketProf**, öğrencilerin ders çalışma süreçlerini yapay zeka ile optimize eden, modern ve kullanıcı dostu bir mobil öğrenme asistanıdır. PDF dosyalarınızı, görsellerinizi ve notlarınızı saniyeler içinde analiz eder; size özel sınavlar, hatırlatma kartları ve konu anlatımları oluşturur.

---

## ✨ Temel Özellikler

### 🤖 Akıllı AI Sohbet (Teacher Mode)

- **Çoklu Dosya Analizi:** Aynı anda birden fazla PDF ve görseli analiz edebilme.
- **İleri Seviye Anlatım:** Karmaşık konuları basit örneklerle açıklayan pedagojik yaklaşım.
- **Sürekli Hafıza:** Geçmiş sohbet oturumlarını saklar ve kaldığınız yerden devam etmenizi sağlar.

### 📝 Dinamik Quiz (Sınav) Oluşturma

- **Otomatik Soru Üretimi:** Kaynak dokümanlarınızdan anında test soruları oluşturur.
- **Zorluk Seviyeleri:** Kolay, Orta ve Zor seçenekleri.
- **Detaylı Açıklamalar:** Her yanlış cevapta o bilginin neden yanlış olduğunu açıklayan AI geri bildirimleri.

### 🎴 İnteraktif Hatırlatma Kartları (Flashcards)

- **Hızlı Öğrenme:** Dokümanlardaki kilit kavramları otomatik olarak kartlara dönüştürür.
- **Premium Tasarım:** Cam morfolojisi (glassmorphism) temalı, kullanımı keyifli kart arayüzü.
- **İpucu Desteği:** Zorlandığınızda AI'dan küçük ipuçları alabilme özelliği.

### 🎙️ Sesli Destek (Hocayı Dinle)

- AI'nın verdiği tüm anlatımları ve cevapları sesli olarak dinleyebilme imkanı.
- **Modern Oynatıcı:** İleri/geri sarma özellikli, şık ve sade ses çubuğu.

---

## 🗂️ Gelişmiş Sohbet Yönetimi (v1.2)

Yeni sürümle birlikte sohbetlerinizi yönetmek artık çok daha güçlü ve güvenli:

- **Sohbet Arşivi:** Tüm eski sohbetleriniz sol panelde liste halindedir. İstediğiniz an birinden diğerine geçiş yapabilirsiniz.
- **Dışa Aktar (Export):** Sohbet geçmişinizi tek tıkla JSON formatında yedekleyin.
- **İçe Aktar (Import):** Yedeklediğiniz sohbetleri başka bir cihaza veya tarayıcıya anında yükleyin.
- **Güvenli Silme:** Sohbetlerinizi tek tek silebilir, yerel hafızanızı temiz tutabilirsiniz.

---

## 🎨 Tasarım ve Kullanıcı Deneyimi (UI/UX)

- **Premium Renk Paleti:** Canlı mor tonları, derin lacivertler ve yumuşak geçişler.
- **Modern SnackBar Tasarımı:** Artık sistem mesajları alt çubuk olarak değil, sağ üstte şık ve kapatılabilir "yüzen kutular" (floating cards) olarak görünür.
- **Dinamik Animasyonlar:** Akıcı sayfa geçişleri ve interaktif kart döndürme efektleri.

---

## 🛠️ Teknik Mimari ve Teknoloji Yığını

- **Framework:** Flutter (Cross-platform)
- **State Management:** Riverpod (Reactive & Scalable)
- **LLM API:** OpenRouter (Gemini, GPT-4, Claude desteği)
- **Local Storage:** Hive (Universal NoSQL database)
- **Technical UUIDs:** Her sohbet ve mesaj için çakışmayı önleyen benzersiz kimlikleme.

---

## ⚙️ Kurulum ve Çalıştırma

1. **Depoyu Klonlayın:**
   ```bash
   git clone https://github.com/YusufEsan/pocketprof.git
   ```
2. **Bağımlılıkları Yükleyin:**
   ```bash
   flutter pub get
   ```
3. **API Anahtarını Ekleyin:**
   - Ayarlar (Settings) menüsünden [OpenRouter](https://openrouter.ai/) API anahtarınızı girin.
4. **Çalıştırın:**
   ```bash
   flutter run
   ```

---

## ️ Gizlilik ve Güvenlik

PocketProf, verilerinizin gizliliğine önem verir. Chat geçmişiniz ve doküman içerikleriniz sadece cihazınızda (Local Storage) saklanır. Harici bir sunucuya kullanıcı verisi kaydedilmez.

---

**PocketProf** - _Bilgiyi cebinize indirir, öğrenmeyi özgürleştirir._ 🚀
