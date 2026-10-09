import 'dart:ui' show Locale, TextDirection;

/// Giriş sayfası sol bilgi paneli metinleri — cihaz diline göre seçilir.
///
/// Uygulama çevrimdışı çalıştığı için çeviriler pakete gömülüdür.
class LoginHeroTexts {
  const LoginHeroTexts({
    required this.languageCode,
    required this.languageName,
    required this.tagline,
    required this.title,
    required this.subtitle,
    required this.bodyIntro,
    required this.bodyMain,
    required this.bodyOutro,
    required this.cta,
  });

  final String languageCode;

  /// Dilin kendi adıyla gösterimi (seçici menüsü için).
  final String languageName;
  final String tagline;
  final String title;
  final String subtitle;
  final String bodyIntro;
  final String bodyMain;
  final String bodyOutro;
  final String cta;

  static const _rtlLanguages = {'ar', 'fa', 'he', 'ur'};

  TextDirection get textDirection => _rtlLanguages.contains(languageCode)
      ? TextDirection.rtl
      : TextDirection.ltr;

  static LoginHeroTexts? forLanguage(String languageCode) {
    for (final t in all) {
      if (t.languageCode == languageCode) return t;
    }
    return null;
  }

  /// Cihazın tercih ettiği diller arasından ilk desteklenen dili seçer;
  /// hiçbiri yoksa [fallback] (uygulama dili), o da yoksa Türkçe.
  static LoginHeroTexts detect(Iterable<Locale> preferred, {Locale? fallback}) {
    for (final locale in preferred) {
      final match = forLanguage(locale.languageCode);
      if (match != null) return match;
    }
    if (fallback != null) {
      final match = forLanguage(fallback.languageCode);
      if (match != null) return match;
    }
    return all.first;
  }

  static const all = <LoginHeroTexts>[
    LoginHeroTexts(
      languageCode: 'tr',
      languageName: 'Türkçe',
      tagline: 'Eğitimde Bir Adım Önde',
      title: 'Eğitimin dijital dünyadaki en güçlü yardımcınız.',
      subtitle: 'Daha iyi bir eğitim deneyimi için doğru araçlar, doğru yerde.',
      bodyIntro: 'Eğitim yolculuğunuzda size eşlik etmek için buradayız.',
      bodyMain:
          'Modern teknolojimizle, öğrenmeyi daha erişilebilir, etkileşimli ve keyifli hale getiriyoruz. Öğrencilerden velilere, öğretmenlerden yöneticilere kadar herkes için tasarlanmış çözümlerimizle tanışın.',
      bodyOutro: 'Hayat boyu öğrenme serüveninizde yeni ufuklar keşfedin.',
      cta: 'Keşfetmeye Hazır mısınız?',
    ),
    LoginHeroTexts(
      languageCode: 'en',
      languageName: 'English',
      tagline: 'One Step Ahead in Education',
      title: 'Your strongest companion for education in the digital world.',
      subtitle:
          'The right tools, in the right place, for a better learning experience.',
      bodyIntro: 'We are here to accompany you on your education journey.',
      bodyMain:
          'With modern technology, we make learning more accessible, interactive and enjoyable. Meet solutions designed for everyone, from students and parents to teachers and administrators.',
      bodyOutro: 'Discover new horizons in your lifelong learning adventure.',
      cta: 'Ready to explore?',
    ),
    LoginHeroTexts(
      languageCode: 'ro',
      languageName: 'Română',
      tagline: 'Cu un pas înainte în educație',
      title: 'Cel mai puternic aliat al educației în lumea digitală.',
      subtitle:
          'Instrumentele potrivite, la locul potrivit, pentru o experiență educațională mai bună.',
      bodyIntro: 'Suntem aici pentru a vă însoți în parcursul educațional.',
      bodyMain:
          'Cu tehnologia noastră modernă, facem învățarea mai accesibilă, interactivă și plăcută. Descoperiți soluțiile noastre, create pentru toți: de la elevi și părinți până la profesori și administratori.',
      bodyOutro:
          'Descoperiți noi orizonturi în aventura învățării pe tot parcursul vieții.',
      cta: 'Sunteți gata să explorați?',
    ),
    LoginHeroTexts(
      languageCode: 'ru',
      languageName: 'Русский',
      tagline: 'На шаг впереди в образовании',
      title: 'Ваш самый надёжный помощник в цифровом мире образования.',
      subtitle:
          'Правильные инструменты в нужном месте для лучшего опыта обучения.',
      bodyIntro: 'Мы здесь, чтобы сопровождать вас на пути к знаниям.',
      bodyMain:
          'Благодаря современным технологиям мы делаем обучение более доступным, интерактивным и увлекательным. Познакомьтесь с нашими решениями, созданными для всех — от учеников и родителей до учителей и администраторов.',
      bodyOutro: 'Откройте новые горизонты в путешествии длиною в жизнь.',
      cta: 'Готовы начать?',
    ),
    LoginHeroTexts(
      languageCode: 'uk',
      languageName: 'Українська',
      tagline: 'На крок попереду в освіті',
      title: 'Ваш найнадійніший помічник у цифровому світі освіти.',
      subtitle:
          'Правильні інструменти в потрібному місці для кращого досвіду навчання.',
      bodyIntro: 'Ми тут, щоб супроводжувати вас на освітньому шляху.',
      bodyMain:
          'Завдяки сучасним технологіям ми робимо навчання доступнішим, інтерактивнішим і цікавішим. Знайомтеся з нашими рішеннями, створеними для всіх — від учнів і батьків до вчителів і адміністраторів.',
      bodyOutro: 'Відкривайте нові горизонти в навчанні протягом усього життя.',
      cta: 'Готові досліджувати?',
    ),
    LoginHeroTexts(
      languageCode: 'de',
      languageName: 'Deutsch',
      tagline: 'Einen Schritt voraus in der Bildung',
      title: 'Ihr stärkster Begleiter für Bildung in der digitalen Welt.',
      subtitle:
          'Die richtigen Werkzeuge am richtigen Ort für ein besseres Lernerlebnis.',
      bodyIntro: 'Wir begleiten Sie auf Ihrem Bildungsweg.',
      bodyMain:
          'Mit moderner Technologie machen wir das Lernen zugänglicher, interaktiver und angenehmer. Entdecken Sie unsere Lösungen, die für alle gemacht sind – von Schülern und Eltern bis zu Lehrkräften und Schulleitungen.',
      bodyOutro: 'Entdecken Sie neue Horizonte auf Ihrem lebenslangen Lernweg.',
      cta: 'Bereit zum Entdecken?',
    ),
    LoginHeroTexts(
      languageCode: 'fr',
      languageName: 'Français',
      tagline: "Une longueur d'avance dans l'éducation",
      title: "Votre meilleur allié pour l'éducation dans le monde numérique.",
      subtitle:
          "Les bons outils, au bon endroit, pour une meilleure expérience d'apprentissage.",
      bodyIntro:
          'Nous sommes là pour vous accompagner dans votre parcours éducatif.',
      bodyMain:
          "Grâce à notre technologie moderne, nous rendons l'apprentissage plus accessible, interactif et agréable. Découvrez nos solutions conçues pour tous, des élèves et parents aux enseignants et administrateurs.",
      bodyOutro:
          "Découvrez de nouveaux horizons dans votre aventure d'apprentissage tout au long de la vie.",
      cta: 'Prêt à explorer ?',
    ),
    LoginHeroTexts(
      languageCode: 'es',
      languageName: 'Español',
      tagline: 'Un paso adelante en la educación',
      title: 'Su mejor aliado para la educación en el mundo digital.',
      subtitle:
          'Las herramientas adecuadas, en el lugar adecuado, para una mejor experiencia educativa.',
      bodyIntro: 'Estamos aquí para acompañarle en su camino educativo.',
      bodyMain:
          'Con nuestra tecnología moderna, hacemos que el aprendizaje sea más accesible, interactivo y agradable. Conozca nuestras soluciones diseñadas para todos, desde estudiantes y familias hasta docentes y directivos.',
      bodyOutro:
          'Descubra nuevos horizontes en su aventura de aprendizaje permanente.',
      cta: '¿Listo para explorar?',
    ),
    LoginHeroTexts(
      languageCode: 'it',
      languageName: 'Italiano',
      tagline: "Un passo avanti nell'istruzione",
      title: "Il tuo alleato più forte per l'istruzione nel mondo digitale.",
      subtitle:
          "Gli strumenti giusti, al posto giusto, per un'esperienza di apprendimento migliore.",
      bodyIntro: 'Siamo qui per accompagnarti nel tuo percorso educativo.',
      bodyMain:
          "Con la nostra tecnologia moderna rendiamo l'apprendimento più accessibile, interattivo e piacevole. Scopri le nostre soluzioni pensate per tutti, da studenti e genitori a docenti e dirigenti.",
      bodyOutro:
          "Scopri nuovi orizzonti nella tua avventura di apprendimento permanente.",
      cta: 'Pronto a esplorare?',
    ),
    LoginHeroTexts(
      languageCode: 'pt',
      languageName: 'Português',
      tagline: 'Um passo à frente na educação',
      title: 'O seu maior aliado na educação no mundo digital.',
      subtitle:
          'As ferramentas certas, no lugar certo, para uma melhor experiência de aprendizagem.',
      bodyIntro: 'Estamos aqui para acompanhá-lo na sua jornada educativa.',
      bodyMain:
          'Com a nossa tecnologia moderna, tornamos a aprendizagem mais acessível, interativa e agradável. Conheça as nossas soluções criadas para todos, de alunos e pais a professores e gestores.',
      bodyOutro:
          'Descubra novos horizontes na sua aventura de aprendizagem ao longo da vida.',
      cta: 'Pronto para explorar?',
    ),
    LoginHeroTexts(
      languageCode: 'az',
      languageName: 'Azərbaycanca',
      tagline: 'Təhsildə bir addım öndə',
      title: 'Təhsilin rəqəmsal dünyadakı ən güclü köməkçisi.',
      subtitle: 'Daha yaxşı təhsil təcrübəsi üçün doğru alətlər, doğru yerdə.',
      bodyIntro: 'Təhsil yolunuzda sizi müşayiət etmək üçün buradayıq.',
      bodyMain:
          'Müasir texnologiyamızla öyrənməni daha əlçatan, interaktiv və maraqlı edirik. Şagirdlərdən valideynlərə, müəllimlərdən rəhbərlərə qədər hər kəs üçün hazırlanmış həllərimizlə tanış olun.',
      bodyOutro: 'Ömürboyu öyrənmə səyahətinizdə yeni üfüqlər kəşf edin.',
      cta: 'Kəşf etməyə hazırsınız?',
    ),
    LoginHeroTexts(
      languageCode: 'ar',
      languageName: 'العربية',
      tagline: 'خطوة إلى الأمام في التعليم',
      title: 'مساعدك الأقوى للتعليم في العالم الرقمي.',
      subtitle: 'الأدوات المناسبة في المكان المناسب لتجربة تعليمية أفضل.',
      bodyIntro: 'نحن هنا لمرافقتك في رحلتك التعليمية.',
      bodyMain:
          'بفضل تقنياتنا الحديثة، نجعل التعلّم أكثر سهولة وتفاعلاً ومتعة. تعرّف على حلولنا المصممة للجميع، من الطلاب وأولياء الأمور إلى المعلمين والإداريين.',
      bodyOutro: 'اكتشف آفاقاً جديدة في رحلة التعلّم مدى الحياة.',
      cta: 'هل أنت مستعد للاستكشاف؟',
    ),
  ];
}
