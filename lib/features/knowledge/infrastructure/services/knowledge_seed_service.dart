import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../data/drift/app_database.dart';

/// Service to seed the knowledge database with initial articles and tips
class KnowledgeSeedService {
  final AppDatabase _db;
  final _uuid = const Uuid();

  KnowledgeSeedService(this._db);

  /// Run seeding if the database is empty
  Future<void> seedIfNeeded() async {
    final existingArticles = await _db.getDriftArticles(limit: 1);
    if (existingArticles.isEmpty) {
      await _seedArticles();
      await _seedTips();
    }
  }

  Future<void> _seedArticles() async {
    final articles = [
      // ENGLISH
      KnowledgeArticlesCompanion(
        id: Value(_uuid.v4()),
        title: const Value('The 50/30/20 Rule: A Simple Way to Budget'),
        summary: const Value('Learn how to divide your income between needs, wants, and savings.'),
        content: const Value('# The 50/30/20 Rule\n\nOne of the most popular budgeting methods is the 50/30/20 rule. It\'s simple, effective, and helps you prioritize your spending without feeling restricted.\n\n## How it works:\n- **50% for Needs**: Rent, groceries, utilities, and transport.\n- **30% for Wants**: Dining out, hobbies, and entertainment.\n- **20% for Savings**: Debt repayment, emergency fund, and investments.\n\nBy following this framework, you ensure that your essentials are covered while still building for your future.'),
        topic: const Value('budgeting'),
        tags: const Value('["basics", "framework", "starting_out"]'),
        readTimeMinutes: const Value(5),
        languageCode: const Value('en'),
      ),
      KnowledgeArticlesCompanion(
        id: Value(_uuid.v4()),
        title: const Value('Building Your First Emergency Fund'),
        summary: const Value('Why you need one and how much you should save.'),
        content: const Value('# Emergency Funds 101\n\nAn emergency fund is your financial safety net. It protects you from unexpected expenses like car repairs, medical bills, or job loss.\n\n## Goal:\nAim for **3 to 6 months** of essential living expenses.\n\n## How to start:\n1. Start small (e.g., \$500).\n2. Automate your savings.\n3. Keep it in a separate, liquid account.'),
        topic: const Value('savings'),
        tags: const Value('["safety", "emergencies", "basics"]'),
        readTimeMinutes: const Value(4),
        languageCode: const Value('en'),
      ),
      KnowledgeArticlesCompanion(
        id: Value(_uuid.v4()),
        title: const Value('How to Stop Impulse Spending'),
        summary: const Value('Practical tips to control emotional purchases.'),
        content: const Value('# Master Your Impulse\n\nImpulse spending can derail even the best budgets. Here are three major tips to stay in control:\n\n1. **The 24-Hour Rule**: Wait 24 hours before buying anything non-essential.\n2. **Avoid Shopping as Entertainment**: Find hobbies that don\'t involve spending money.\n3. **Unsubscribe from Sales Emails**: Remove the temptation from your inbox.'),
        topic: const Value('impulse_control'),
        tags: const Value('["psychology", "habits", "savings"]'),
        readTimeMinutes: const Value(6),
        languageCode: const Value('en'),
      ),
      KnowledgeArticlesCompanion(
        id: Value(_uuid.v4()),
        title: const Value('Index Funds: The Lazy Way to Wealth'),
        summary: const Value('Introduction to low-cost, diversified investing.'),
        content: const Value('# Why Index Funds?\n\nMost active investors fail to beat the market. Index funds allow you to own a "piece of the whole market" at a very low cost.\n\n## Benefits:\n- **Diversification**: One share gives you exposure to hundreds of companies.\n- **Low Fees**: Lower expense ratios compared to mutual funds.\n- **Long-term Growth**: Historically, the market tends to go up over decades.'),
        topic: const Value('investing'),
        tags: const Value('["stocks", "long_term", "wealth"]'),
        readTimeMinutes: const Value(7),
        languageCode: const Value('en'),
      ),

      // BENGALI
      KnowledgeArticlesCompanion(
        id: Value(_uuid.v4()),
        title: const Value('৫০/৩০/২০ নিয়ম: বাজেটিংয়ের একটি সহজ উপায়'),
        summary: const Value('কিভাবে আপনার আয় প্রয়োজন, ইচ্ছা এবং সঞ্চয়ের মধ্যে ভাগ করবেন তা শিখুন।'),
        content: const Value('# ৫০/৩০/২০ নিয়ম\n\nবাজেট করার অন্যতম জনপ্রিয় পদ্ধতি হল ৫০/৩০/২০ নিয়ম। এটি সহজ, কার্যকর এবং আপনাকে সীমাবদ্ধ না রেখেই আপনার ব্যয়কে অগ্রাধিকার দিতে সহায়তা করে।\n\n## এটি যেভাবে কাজ করে:\n- **৫০% প্রয়োজনের জন্য**: ভাড়া, মুদি সামগ্রী, ইউটিলিটি এবং পরিবহন।\n- **৩০% ইচ্ছার জন্য**: বাইরে খাওয়া, শখ এবং বিনোদন।\n- **২০% সঞ্চয়ের জন্য**: ঋণ পরিশোধ, জরুরি তহবিল এবং বিনিয়োগ।'),
        topic: const Value('budgeting'),
        tags: const Value('["basics", "framework", "bengali"]'),
        readTimeMinutes: const Value(5),
        languageCode: const Value('bn'),
      ),
      KnowledgeArticlesCompanion(
        id: Value(_uuid.v4()),
        title: const Value('আপনার প্রথম জরুরি তহবিল গঠন'),
        summary: const Value('কেন আপনার এটি প্রয়োজন এবং কত টাকা জমানো উচিত।'),
        content: const Value('# জরুরি তহবিল ১০১\n\nএকটি জরুরি তহবিল হল আপনার আর্থিক সুরক্ষা জাল। এটি আপনাকে অপ্রত্যাশিত ব্যয় যেমন গাড়ি মেরামত, চিকিৎসা বিল বা চাকরি হারানো থেকে রক্ষা করে।\n\n## লক্ষ্য:\nঅন্তত **৩ থেকে ৬ মাসের** প্রয়োজনীয় জীবনযাত্রার ব্যয় জমানোর লক্ষ্য রাখুন।'),
        topic: const Value('savings'),
        tags: const Value('["safety", "emergencies", "bengali"]'),
        readTimeMinutes: const Value(4),
        languageCode: const Value('bn'),
      ),

      // FINNISH / SUOMI
      KnowledgeArticlesCompanion(
        id: Value(_uuid.v4()),
        title: const Value('50/30/20-sääntö: Yksinkertainen tapa budjetoida'),
        summary: const Value('Opi jakamaan tulosi tarpeiden, halujen ja säästöjen välillä.'),
        content: const Value('# 50/30/20-sääntö\n\nYksi suosituimmista budjetointimenetelmistä on 50/30/20-sääntö. Se on yksinkertainen ja auttaa priorisoimaan menoja ilman liiallisia rajoituksia.\n\n## Näin se toimii:\n- **50% Tarpeisiin**: Vuokra, ruoka, laskut ja kuljetus.\n- **30% Haluihin**: Ravintolat, harrastukset ja viihde.\n- **20% Säästöihin**: Velkojen maksu, hätävara ja sijoitukset.'),
        topic: const Value('budgeting'),
        tags: const Value('["perusteet", "suomi"]'),
        readTimeMinutes: const Value(5),
        languageCode: const Value('fi'),
      ),
      KnowledgeArticlesCompanion(
        id: Value(_uuid.v4()),
        title: const Value('Näin lopetat heräteostokset'),
        summary: const Value('Käytännön vinkkejä tunneperäisten ostosten hallintaan.'),
        content: const Value('# Hallitse heräteostoksesi\n\nHeräteostokset voivat suistaa parhaankin budjetin raiteiltaan. Tässä kolme vinkkiä:\n\n1. **24 tunnin sääntö**: Odota vuorokausi ennen kuin ostat mitään ei-välttämätöntä.\n2. **Vältä shoppailua viihteenä**: Etsi harrastuksia, jotka eivät vaadi rahanmenoa.\n3. **Lopeta mainosviestien tilaus**: Poista kiusaukset sähköpostistasi.'),
        topic: const Value('impulse_control'),
        tags: const Value('["psykologia", "tavat", "suomi"]'),
        readTimeMinutes: const Value(6),
        languageCode: const Value('fi'),
      ),
    ];

    for (final article in articles) {
      await _db.into(_db.knowledgeArticles).insert(article);
    }
  }

  Future<void> _seedTips() async {
    final tips = [
      // ENGLISH
      FinancialTipsCompanion(
        id: Value(_uuid.v4()),
        title: const Value('Tip: Grocery Shopping'),
        content: const Value('Never go grocery shopping while hungry - you\'ll spend 20% more on average.'),
        category: const Value('daily'),
        type: const Value('info'),
        actionLabel: const Value('Try it today'),
        languageCode: const Value('en'),
      ),
      FinancialTipsCompanion(
        id: Value(_uuid.v4()),
        title: const Value('Savings Hack'),
        content: const Value('Review your subscription list once a month. You might find "zombie" services you no longer use.'),
        category: const Value('daily'),
        type: const Value('success'),
        actionLabel: const Value('Check now'),
        languageCode: const Value('en'),
      ),

      // BENGALI
      FinancialTipsCompanion(
        id: Value(_uuid.v4()),
        title: const Value('টিপ: মুদি কেনাকাটা'),
        content: const Value('ক্ষুধার্ত অবস্থায় কখনোই মুদি কেনাকাটা করতে যাবেন না - এতে গড়ে ২০% বেশি খরচ হয়।'),
        category: const Value('daily'),
        type: const Value('info'),
        actionLabel: const Value('আজুই চেষ্টা করুন'),
        languageCode: const Value('bn'),
      ),

      // FINNISH
      FinancialTipsCompanion(
        id: Value(_uuid.v4()),
        title: const Value('Säästövinkki'),
        content: const Value('Tarkista tilauksesi kerran kuussa. Saatat löytää palveluita, joita et enää käytä.'),
        category: const Value('daily'),
        type: const Value('success'),
        actionLabel: const Value('Tarkista nyt'),
        languageCode: const Value('fi'),
      ),
    ];

    for (final tip in tips) {
      await _db.into(_db.financialTips).insert(tip);
    }
  }
}
