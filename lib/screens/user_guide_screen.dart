import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  static const routeName = '/user-guide';

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('userGuide')),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: strings.t('goHome'),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            strings.t('faqTitle'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(strings.t('faqIntro')),
          const SizedBox(height: 16),
          _FaqItem(
            question: 'Ders platformunu nasil olustururum?',
            answer:
                'Ana sayfada "Ders Platformu Olustur" butonuna girin. '
                'Sinif ve ders secerek icerik yonetimine gecin.',
          ),
          _FaqItem(
            question: 'Konu ve icerik ekleme sirasini nasil takip etmeliyim?',
            answer:
                'Once konu secin, sonra Ekle butonundan dosya, video, audio '
                'veya web link ekleyin. Icerikler listeye otomatik eklenir.',
          ),
          _FaqItem(
            question: 'Iceriklerde arama ve filtreleme nasil calisir?',
            answer:
                'Arama kutusuna dosya adini yazin. Etiketler varsa filtre '
                'chipleri ile daraltabilirsiniz.',
          ),
          _FaqItem(
            question: 'Toplu tasima ve toplu silme ne yapar?',
            answer:
                'Toplu tasi tum filtrelenmis icerikleri secilen konuya tasir. '
                'Toplu sil ayni filtre sonucundaki icerikleri siler.',
          ),
          _FaqItem(
            question: 'Ders Platformuna Git ekrani ne ise yarar?',
            answer:
                'Ders Platformuna Git ile iceriklerinizi izleme modunda gorur, '
                'sol menuden sinif/ders/konu secerek onizleme yaparsiniz.',
          ),
          _FaqItem(
            question: 'Ogrenci platformunda notlari nasil girerim?',
            answer:
                'Sinif secip Sınavlar/Odevler/Aktiviteler bolumune girin. '
                'Kolon ekleyin ve notlari 1-10 arasi girin.',
          ),
          _FaqItem(
            question: 'Notlari veya kolonlari nasil temizlerim?',
            answer:
                'Bolum icindeki Temizle butonu tum notlari sifirlar. '
                'Her kolonun yanindaki temizleme ikonu ise sadece o kolonu sifirlar.',
          ),
          _FaqItem(
            question: 'Soru bankasi ne icin kullanilir?',
            answer:
                'Soru bankasina sorularinizi ekleyip saklayabilirsiniz. '
                'Sinav hazirlarken buradan soru secip kullanabilirsiniz.',
          ),
          _FaqItem(
            question: 'Yedekleme ve tema ayarlari nerede?',
            answer:
                'Ayarlar ekranindan dil, tema, guvenlik ve yedekleme '
                'seceneklerini yonetebilirsiniz.',
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(answer),
          ],
        ),
      ),
    );
  }
}

