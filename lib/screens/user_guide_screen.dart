import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/teacher_navigation.dart';
import '../widgets/app_card.dart';
import '../widgets/app_shell.dart';

class UserGuideScreen extends StatefulWidget {
  const UserGuideScreen({super.key});

  static const routeName = '/user-guide';

  @override
  State<UserGuideScreen> createState() => _UserGuideScreenState();
}

class _UserGuideScreenState extends State<UserGuideScreen> {
  String _query = '';

  static const _faqs = [
    (
      'Ders platformunu nasil olustururum?',
      'Ana sayfada "Ders Platformu Olustur" butonuna girin. '
          'Sinif ve ders secerek icerik yonetimine gecin.',
      Icons.build_outlined,
    ),
    (
      'Konu ve icerik ekleme sirasini nasil takip etmeliyim?',
      'Once konu secin, sonra Ekle butonundan dosya, video, audio '
          'veya web link ekleyin. Icerikler listeye otomatik eklenir.',
      Icons.topic_outlined,
    ),
    (
      'Iceriklerde arama ve filtreleme nasil calisir?',
      'Arama kutusuna dosya adini yazin. Etiketler varsa filtre '
          'chipleri ile daraltabilirsiniz.',
      Icons.search,
    ),
    (
      'Toplu tasima ve toplu silme ne yapar?',
      'Toplu tasi tum filtrelenmis icerikleri secilen konuya tasir. '
          'Toplu sil ayni filtre sonucundaki icerikleri siler.',
      Icons.move_to_inbox_outlined,
    ),
    (
      'Ders Platformuna Git ekrani ne ise yarar?',
      'Ders Platformuna Git ile iceriklerinizi izleme modunda gorur, '
          'sol menuden sinif/ders/konu secerek onizleme yaparsiniz.',
      Icons.apps_outlined,
    ),
    (
      'Ogrenci platformunda notlari nasil girerim?',
      'Sinif secip Sınavlar/Odevler/Aktiviteler bolumune girin. '
          'Kolon ekleyin ve notlari 1-10 arasi girin.',
      Icons.grade_outlined,
    ),
    (
      'Notlari veya kolonlari nasil temizlerim?',
      'Bolum icindeki Temizle butonu tum notlari sifirlar. '
          'Her kolonun yanindaki temizleme ikonu ise sadece o kolonu sifirlar.',
      Icons.cleaning_services_outlined,
    ),
    (
      'Soru bankasi ne icin kullanilir?',
      'Soru bankasina sorularinizi ekleyip saklayabilirsiniz. '
          'Sinav hazirlarken buradan soru secip kullanabilirsiniz.',
      Icons.quiz_outlined,
    ),
    (
      'Yedekleme ve tema ayarlari nerede?',
      'Ayarlar ekranindan dil, tema, guvenlik ve yedekleme '
          'seceneklerini yonetebilirsiniz.',
      Icons.settings_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final filtered = _faqs.where((faq) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return faq.$1.toLowerCase().contains(q) ||
          faq.$2.toLowerCase().contains(q);
    }).toList();

    return AppShell(
      teacherSection: TeacherNavSection.userGuide,
      title: strings.t('userGuide'),
      subtitle: strings.t('faqIntro'),
      showSearch: true,
      searchHint: strings.t('faqSearchHint'),
      onSearchChanged: (value) => setState(() => _query = value),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Text(
            strings.t('faqTitle'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            strings.t('faqIntro'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ...filtered.map(
            (faq) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _FaqItem(
                question: faq.$1,
                answer: faq.$2,
                icon: faq.$3,
              ),
            ),
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
    required this.icon,
  });

  final String question;
  final String answer;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 20),
          ),
          title: Text(
            question,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
