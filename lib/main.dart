import 'package:chitieu/api/investment/investment_provider.dart';
import 'package:chitieu/api/investment/investment_service.dart';
import 'package:chitieu/api/transaction/transaction_provider.dart';
import 'package:chitieu/pages/accounts_list_page.dart';
import 'package:chitieu/pages/income_list_page.dart';
import 'package:chitieu/pages/investment_list_page.dart';
import 'package:chitieu/pages/saving_list_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

// --- Voice ---
import 'package:chitieu/core/voice/voice_synonym_store.dart';

// --- Auth ---
import 'package:chitieu/auth/auth_provider.dart';
import 'package:chitieu/auth/auth_service.dart';

// --- Settings ---
import 'pages/setting/settings_provider.dart';

// --- Pages ---
import 'pages/budgets_page.dart';
import 'pages/analytics_page.dart';
import 'pages/setting/setting_page.dart';
import 'pages/setting/money_settings_page.dart';
import 'pages/note_page.dart';

// --- i18n ---
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:chitieu/l10n/app_localizations.dart';

// --- BankAccount ---
import 'api/bankaccount/bank_account_service.dart';
import 'api/bankaccount/bank_account_provider.dart';
import 'package:chitieu/pages/accounts_page.dart';

// --- Money ---
import 'core/money/money_settings_provider.dart';
import 'core/money/money_settings_service.dart';

// --- Budgets ---
import 'core/budget/budget_service.dart';
import 'core/budget/budgets_provider.dart';

// --- Category ---
import 'api/category/category_provider.dart';

// --- Transactions (Mới) ---
import 'api/in_invoice/in_invoice_service.dart';
import 'api/in_invoice/in_invoice_provider.dart';
import 'api/out_invoice/out_invoice_service.dart';
import 'api/out_invoice/out_invoice_provider.dart';
import 'api/bank_transaction/bank_transaction_service.dart';
import 'api/bank_transaction/bank_transaction_provider.dart';
import 'pages/transactions_page.dart';

// --- Date ---
import 'core/date/year_month_provider.dart';

// --- Income ---
import 'api/income/income_service.dart';
import 'api/income/income_provider.dart';

import 'api/saving/saving_service.dart';
import 'api/saving/saving_provider.dart';

import 'api/saving_transaction/saving_transaction_service.dart';
import 'api/saving_transaction/saving_transaction_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Tải dữ liệu học giọng nói sớm trước khi app chạy
  final voiceStore = VoiceSynonymStore();
  await voiceStore.load();
  print('✅ VoiceSynonymStore loaded at startup');

  const rawBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://192.168.1.67:8000',
  );

  final authApi = AuthService(rawBase);

  final dio = Dio(BaseOptions(
    baseUrl: '$rawBase/',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Accept': 'application/json'},
    validateStatus: (s) => s != null && s < 500,
  ));

  // Thêm token vào mọi request
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      var p = options.path;
      if (!p.startsWith('http')) {
        if (p.startsWith('/')) p = p.substring(1);
        if (!p.startsWith('api/')) p = 'api/$p';
        options.path = p;
      }

      final token = await authApi.getToken();
      if (token != null && token.isNotEmpty && token != 'null') {
        options.headers['Authorization'] = 'Bearer $token';
      } else {
        options.headers.remove('Authorization');
      }
      handler.next(options);
    },
  ));

  final moneyProv = MoneySettingsProvider(MoneySettingsService());
  await moneyProv.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<Dio>(create: (_) => dio),
        ChangeNotifierProvider(create: (_) => YearMonthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider<MoneySettingsProvider>.value(value: moneyProv),
        ChangeNotifierProvider(create: (_) => AuthProvider(authApi)),

        // ===== BankAccount =====
        ChangeNotifierProxyProvider<AuthProvider, BankAccountProvider>(
          create: (context) {
            final auth = context.read<AuthProvider>();
            final dioLocal = Dio(BaseOptions(
                baseUrl: '$rawBase/', headers: {'Accept': 'application/json'}));
            dioLocal.interceptors.add(InterceptorsWrapper(
              onRequest: (options, handler) async {
                final token = auth.token;
                if (token != null && token.isNotEmpty && token != 'null') {
                  options.headers['Authorization'] = 'Bearer $token';
                } else {
                  options.headers.remove('Authorization');
                }
                handler.next(options);
              },
            ));
            return BankAccountProvider(service: BankAccountService(dioLocal));
          },
          update: (context, auth, prev) {
            final dioLocal = Dio(BaseOptions(
                baseUrl: '$rawBase/', headers: {'Accept': 'application/json'}));
            dioLocal.interceptors.add(InterceptorsWrapper(
              onRequest: (options, handler) async {
                final token = auth.token;
                if (token != null && token.isNotEmpty && token != 'null') {
                  options.headers['Authorization'] = 'Bearer $token';
                } else {
                  options.headers.remove('Authorization');
                }
                handler.next(options);
              },
            ));
            final service = BankAccountService(dioLocal);
            final provider = prev ?? BankAccountProvider(service: service);
            provider.updateService(service);

            if (auth.isAuthenticated) {
              provider.fetchAccounts(token: auth.token);
            } else {
              provider.clear();
            }
            return provider;
          },
        ),

        // ===== Category =====
        ChangeNotifierProxyProvider<AuthProvider, CategoryProvider>(
          create: (ctx) =>
              CategoryProvider(ctx.read<Dio>(), ctx.read<AuthProvider>()),
          update: (ctx, auth, prev) {
            final p = prev ?? CategoryProvider(ctx.read<Dio>(), auth);
            if ((auth.token ?? '').isEmpty) {
              p.clear();
            } else if (p.items.isEmpty && !p.loading) {
              p.refresh();
            }
            return p;
          },
        ),

        // ===== Budgets =====
        ChangeNotifierProxyProvider<AuthProvider, BudgetsProvider>(
          create: (context) {
            final auth = context.read<AuthProvider>();
            final dioInstance = context.read<Dio>();
            return BudgetsProvider(BudgetService(dioInstance, auth));
          },
          update: (context, auth, prev) {
            final dioInstance = context.read<Dio>();
            final provider =
                prev ?? BudgetsProvider(BudgetService(dioInstance, auth));

            if ((auth.token ?? '').isEmpty) {
              provider.clear();
            } else {
              final ym = context.read<YearMonthProvider>().ym;
              if (provider.items.isEmpty && !provider.loading) {
                provider.loadForMonth(year: ym.year, month: ym.month);
              }
            }
            return provider;
          },
        ),

        // ===== Income =====
        ChangeNotifierProxyProvider<AuthProvider, IncomeProvider>(
          create: (context) =>
              IncomeProvider(IncomeService(dio), context.read<AuthProvider>()),
          update: (context, auth, prev) {
            final p = prev ?? IncomeProvider(IncomeService(dio), auth);
            final token = auth.token ?? '';
            final ym = context.read<YearMonthProvider>().ym;

            if (token.isEmpty) {
              p.clear();
            } else if (!p.loading) {
              p.fetch(year: ym.year, month: ym.month);
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
          create: (context) => TransactionProvider(
            context.read<Dio>(),
            context.read<AuthProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => SavingProvider(
            api: SavingService(ctx.read<Dio>()),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => SavingTransactionProvider(
            api: SavingTransactionService(ctx.read<Dio>()),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => InvestmentProvider(
            api: InvestmentService(ctx.read<Dio>()),
          ),
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
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi'), Locale('en')],
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
      title: 'Chi Tiêu',
      home: const HomeScaffold(),
      routes: {
        '/settings/money': (_) => const MoneySettingsPage(),
        '/transactions': (_) => const TransactionsPage(),
        '/accounts': (_) => const AccountsListPage(),
        '/investment': (_) => const InvestmentListPage(),
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
  void _onFabPressed() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const NotePage()));

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: _pages),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabPressed,
        elevation: 2,
        shape: const CircleBorder(),
        child: const Icon(Icons.assignment),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          color: Colors.white,
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                    ],
                  ),
                ),
                const SizedBox(width: 64),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
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
              ],
            ),
          ),
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
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
