import 'package:chitieu/api/real_estate/real_estate_provider.dart';
import 'package:chitieu/api/real_estate/real_estate_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

// --- i18n (CUSTOM – CỦA BẠN) ---
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:chitieu/l10n/app_localizations.dart';

// --- Voice ---
import 'core/voice/voice_synonym_store.dart';

// --- Auth ---
import 'auth/auth_provider.dart';
import 'auth/auth_service.dart';

// --- Settings ---
import 'pages/setting/settings_provider.dart';

// --- Pages ---
import 'pages/budgets_page.dart';
import 'pages/analytics_page.dart';
import 'pages/setting/setting_page.dart';
import 'pages/setting/money_settings_page.dart';
import 'pages/note_page.dart';

// --- BankAccount ---
import 'api/bankaccount/bank_account_service.dart';
import 'api/bankaccount/bank_account_provider.dart';
import 'pages/accounts_page.dart';
import 'pages/accounts_list_page.dart';

// --- Money ---
import 'core/money/money_settings_provider.dart';
import 'core/money/money_settings_service.dart';

// --- Budgets ---
import 'core/budget/budget_service.dart';
import 'core/budget/budgets_provider.dart';

// --- Category ---
import 'api/category/category_provider.dart';

// --- Transactions ---
import 'api/in_invoice/in_invoice_service.dart';
import 'api/in_invoice/in_invoice_provider.dart';
import 'api/out_invoice/out_invoice_service.dart';
import 'api/out_invoice/out_invoice_provider.dart';
import 'api/bank_transaction/bank_transaction_service.dart';
import 'api/bank_transaction/bank_transaction_provider.dart';
import 'api/transaction/transaction_provider.dart';
import 'pages/transactions_page.dart';

// --- Date ---
import 'core/date/year_month_provider.dart';

// --- Income ---
import 'api/income/income_service.dart';
import 'api/income/income_provider.dart';
import 'pages/income_list_page.dart';

// --- Saving ---
import 'api/saving/saving_service.dart';
import 'api/saving/saving_provider.dart';
import 'api/saving_transaction/saving_transaction_service.dart';
import 'api/saving_transaction/saving_transaction_provider.dart';
import 'pages/saving_list_page.dart';

// --- Investment ---
import 'api/investment/investment_service.dart';
import 'api/investment/investment_provider.dart';
import 'pages/investment_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Voice preload
  final voiceStore = VoiceSynonymStore();
  await voiceStore.load();

  const rawBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://thuchi.itcctv-soft.com',
  );

  final authApi = AuthService();

  // =======================
  // 🔥 DIO DUY NHẤT
  // =======================
  final dio = Dio(
    BaseOptions(
      baseUrl: '$rawBase/',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
      validateStatus: (s) => s != null && s < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Chuẩn hóa path để luôn thành /api/...
        var p = options.path;
        if (!p.startsWith('http')) {
          if (p.startsWith('/')) p = p.substring(1);
          if (!p.startsWith('api/')) p = 'api/$p';
          options.path = p;
        }

        final token = await authApi.getAccessToken();

        if (token != null && token.isNotEmpty && token != 'null') {
          options.headers['Authorization'] = 'Bearer $token';
        } else {
          options.headers.remove('Authorization');
        }

        handler.next(options);
      },

      // ✅ BẮT LỖI TOÀN CỤC Ở ĐÂY
      onError: (DioException e, handler) async {
        final status = e.response?.statusCode;

        // 1) Token hết hạn / sai token
        if (status == 401) {
          await authApi.logout();
          final ctx = navigatorKey.currentContext;
          if (ctx != null) {
            ctx.read<AuthProvider>().logout();
          }
        }

        // 2) Mất mạng / timeout
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          // Không crash, chỉ log
          debugPrint("🌐 Network error: ${e.message}");
        }

        handler.next(e);
      },
    ),
  );

  final moneyProv = MoneySettingsProvider(MoneySettingsService());
  await moneyProv.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<Dio>.value(value: dio),
        ChangeNotifierProvider(create: (_) => YearMonthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider<MoneySettingsProvider>.value(value: moneyProv),
        ChangeNotifierProvider(create: (_) => AuthProvider(authApi)),

        // ===== BankAccount =====
        ChangeNotifierProxyProvider<AuthProvider, BankAccountProvider>(
          create: (ctx) =>
              BankAccountProvider(service: BankAccountService(ctx.read<Dio>())),
          update: (ctx, auth, prev) {
            final p = prev!;
            p.updateAuthToken(auth.accessToken);
            return p;
          },
        ),

        // ===== Category =====
        ChangeNotifierProxyProvider<AuthProvider, CategoryProvider>(
          create: (ctx) =>
              CategoryProvider(ctx.read<Dio>(), ctx.read<AuthProvider>()),
          update: (ctx, auth, prev) {
            final p = prev!;
            if (!auth.isAuthenticated) {
              p.clear();
            } else if (p.items.isEmpty && !p.loading) {
              p.refresh();
            }

            return p;
          },
        ),

        // ===== Budgets =====
        ChangeNotifierProxyProvider<AuthProvider, BudgetsProvider>(
          create: (ctx) => BudgetsProvider(BudgetService(ctx.read<Dio>())),
          update: (ctx, auth, prev) {
            final p = prev!;
            if (!auth.isAuthenticated) {
              p.clear();
            }

            return p;
          },
        ),

        // ===== Income =====
        ChangeNotifierProxyProvider<AuthProvider, IncomeProvider>(
          create: (ctx) =>
              IncomeProvider(IncomeService(dio), ctx.read<AuthProvider>()),
          update: (ctx, auth, prev) {
            final p = prev!;
            if (!auth.isAuthenticated) {
              p.clear();
            }

            return p;
          },
        ),

        ChangeNotifierProvider(
          create: (ctx) => InInvoiceProvider(
            api: InInvoiceService(dio),
            bankAccounts: ctx.read<BankAccountProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => OutInvoiceProvider(
            api: OutInvoiceService(dio),
            bankAccounts: ctx.read<BankAccountProvider>(),
            budgets: ctx.read<BudgetsProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => BankTransactionProvider(
            api: BankTransactionService(dio),
            bankAccounts: ctx.read<BankAccountProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) =>
              TransactionProvider(ctx.read<Dio>(), ctx.read<AuthProvider>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => SavingProvider(api: SavingService(ctx.read<Dio>())),
        ),
        ChangeNotifierProvider(
          create: (ctx) => SavingTransactionProvider(
            api: SavingTransactionService(ctx.read<Dio>()),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) =>
              InvestmentProvider(api: InvestmentService(ctx.read<Dio>())),
        ),
        ChangeNotifierProvider(
          create: (ctx) => RealEstateProvider(
            service: RealEstateService(ctx.read<Dio>()),
          )..fetch(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Chi Tiêu',

      // ✅ i18n CUSTOM
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi'),
        Locale('en'),
      ],
      locale: settings.locale,

      themeMode: settings.themeMode,
      theme: ThemeData(
        useMaterial3: false,
        colorScheme: ColorScheme.fromSeed(seedColor: settings.seed),
        scaffoldBackgroundColor: const Color(0xFFFAF3E6),
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: settings.seed,
          brightness: Brightness.dark,
        ),
      ),

      home: const HomeScaffold(),
      routes: {
        '/settings/money': (_) => const MoneySettingsPage(),
        '/transactions': (_) => const TransactionsPage(),
        '/accounts': (_) => const AccountsListPage(),
        '/investment': (_) => InvestmentListPage(),
        '/saving': (_) => const SavingListPage(),
        '/income': (_) => const IncomeListPage(),
      },
    );
  }
}

class HomeScaffold extends StatefulWidget {
  const HomeScaffold({super.key});

  @override
  State<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends State<HomeScaffold> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    BudgetsPage(),
    AccountsPage(),
    AnalyticsPage(),
    SettingsPage(),
  ];

  void _onTabSelected(int index) => setState(() => _currentIndex = index);

  void _onFabPressed() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const NotePage()));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabPressed,
        elevation: 2,
        shape: const CircleBorder(),
        child: const Icon(Icons.assignment),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.wallet_rounded,
              label: t.tabBudgets,
              selected: _currentIndex == 0,
              onTap: () => _onTabSelected(0),
            ),
            _NavItem(
              icon: Icons.account_balance_rounded,
              label: t.tabAccounts,
              selected: _currentIndex == 1,
              onTap: () => _onTabSelected(1),
            ),
            const SizedBox(width: 48),
            _NavItem(
              icon: Icons.insights_rounded,
              label: t.tabAnalytics,
              selected: _currentIndex == 2,
              onTap: () => _onTabSelected(2),
            ),
            _NavItem(
              icon: Icons.settings_rounded,
              label: t.tabSettings,
              selected: _currentIndex == 3,
              onTap: () => _onTabSelected(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.amber : Colors.black54;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
