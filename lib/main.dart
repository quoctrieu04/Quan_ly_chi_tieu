import 'package:chitieu/api/investment/investment_transaction_provider.dart';
import 'package:chitieu/api/investment/investment_transaction_service.dart';
import 'package:chitieu/api/real_estate/real_estate_income_plan_provider.dart';
import 'package:chitieu/api/real_estate/real_estate_income_plan_service.dart';
import 'package:chitieu/api/real_estate/real_estate_provider.dart';
import 'package:chitieu/api/real_estate/real_estate_service.dart';
import 'package:chitieu/financial_transaction/financial_transaction_provider.dart';
import 'package:chitieu/financial_transaction/financial_transaction_service.dart';
import 'package:chitieu/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- i18n (CUSTOM – CỦA BẠN) ---
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:chitieu/l10n/app_localizations.dart';

// --- Voice ---
import 'core/voice/voice_synonym_store.dart';

// --- Auth ---
import 'auth/auth_provider.dart';
import 'auth/auth_service.dart';
import 'auth/login.dart'; // Thêm trang đăng nhập

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
            incomePlanService: RealEstateIncomePlanService(ctx.read<Dio>()),
          )..fetch(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => RealEstateIncomePlanProvider(ctx.read<Dio>()),
        ),
        ChangeNotifierProvider(
          create: (context) => InvestmentTransactionProvider(
            InvestmentTransactionService(context.read<Dio>()),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => FinancialTransactionProvider(
            FinancialTransactionService(ctx.read<Dio>()),
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
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Chi Tiêu',
      builder: (context, child) {
        return MediaQuery(
          // Sử dụng copyWith(textScaler: ...) để bọc lại cỡ chữ toàn cục
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(settings.textScale),
          ),
          child: child!,
        );
      },

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: settings.seed,
          primary: settings.seed,
          secondary: AppColors.primaryLight,
          surface: AppColors.surface,
          error: AppColors.danger,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textMain,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        cardColor: AppColors.surface,
        dividerColor: AppColors.border,
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
          ),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: settings.seed,
          brightness: Brightness.dark,
          primary: AppColors.primaryLight,
          secondary: AppColors.primary,
          surface: AppColors.darkSurface,
          error: AppColors.danger,
        ),
        scaffoldBackgroundColor: AppColors.darkBackground,
      ),

      home:
          const RootRouter(), // Sử dụng RootRouter thay vì vào thẳng HomeScaffold
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

// ═══════════════════════════════════════
//  Root Router — Điều hướng khởi động
// ═══════════════════════════════════════
class RootRouter extends StatefulWidget {
  const RootRouter({super.key});

  @override
  State<RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<RootRouter> {
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    // Khởi động AuthProvider để check token
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().bootstrap(onReady: () {
        if (mounted) setState(() => _isReady = true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Lắng nghe trạng thái đăng nhập
    final auth = context.watch<AuthProvider>();

    // Nếu chưa đăng nhập -> Ép vào trang Login
    // (Bảo vệ toàn bộ màn hình chính)
    if (!auth.isAuthenticated) {
      return const LoginPage();
    }

    // Đã đăng nhập -> Vào bình thường
    return const HomeScaffold();
  }
}

class HomeScaffold extends StatefulWidget {
  const HomeScaffold({super.key});

  @override
  State<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends State<HomeScaffold> {
  static const _featureTourSeenKey = 'feature_tour_seen_v2';
  static const _budgetIntroSeenKey = 'budget_intro_seen_v1';
  static const _accountIntroSeenKey = 'account_intro_seen_v1';

  int _currentIndex = 0;
  bool _tourChecking = false;
  bool _tourRunning = false;

  void _onTabSelected(int index) => setState(() => _currentIndex = index);

  List<Widget> get _pages => [
        const BudgetsPage(),
        const AccountsPage(),
        const AnalyticsPage(),
        SettingsPage(onReplayGuide: _replayFeatureTour),
      ];

  void _maybeStartFeatureTour() {
    if (_tourChecking || _tourRunning) return;

    final accounts = context.read<BankAccountProvider>();
    final incomes = context.read<IncomeProvider>();
    final categories = context.read<CategoryProvider>();
    final budgets = context.read<BudgetsProvider>();

    final readyForTour = accounts.items.isNotEmpty &&
        incomes.items.isNotEmpty &&
        categories.items.isNotEmpty &&
        budgets.totalAssigned > 0;

    _tourChecking = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _tourRunning) return;

      final prefs = await SharedPreferences.getInstance();
      if (!mounted) {
        _tourChecking = false;
        return;
      }

      final budgetIntroSeen = prefs.getBool(_budgetIntroSeenKey) ?? false;
      if (_currentIndex == 0 && !budgetIntroSeen) {
        await _runTourSteps(_budgetIntroSteps);
        await prefs.setBool(_budgetIntroSeenKey, true);
        if (!mounted) return;
        setState(() {
          _tourChecking = false;
          _tourRunning = false;
        });
        return;
      }

      final accountIntroSeen = prefs.getBool(_accountIntroSeenKey) ?? false;
      if (_currentIndex == 1 && !accountIntroSeen) {
        await _runTourSteps(_accountIntroSteps);
        await prefs.setBool(_accountIntroSeenKey, true);
        if (!mounted) return;
        setState(() {
          _tourChecking = false;
          _tourRunning = false;
        });
        return;
      }

      final featureTourSeen = prefs.getBool(_featureTourSeenKey) ?? false;
      if (readyForTour && accountIntroSeen && !featureTourSeen) {
        await _runTourSteps(_featureTourSteps, endIndex: 0);
        await prefs.setBool(_featureTourSeenKey, true);
        if (!mounted) return;
        setState(() {
          _tourChecking = false;
          _tourRunning = false;
        });
        return;
      }

      _tourChecking = false;
    });
  }

  List<_FeatureTourStep> get _budgetIntroSteps => const [
        _FeatureTourStep(
          tabIndex: 0,
          icon: Icons.wallet_rounded,
          title: 'Ngân sách',
          message:
              'Đây là nơi bạn lên kế hoạch chi tiêu theo từng danh mục. Trước tiên app sẽ hướng dẫn bạn tạo dữ liệu cần thiết, sau đó bạn có thể đặt ngân sách cho tháng này.',
        ),
      ];

  List<_FeatureTourStep> get _accountIntroSteps => const [
        _FeatureTourStep(
          tabIndex: 1,
          icon: Icons.account_balance_rounded,
          title: 'Tài khoản',
          message:
              'Màn này giúp bạn thiết lập nơi quản lý tiền và nguồn tiền. Hãy thêm tài khoản trước, sau đó thêm nguồn thu để app ghi nhận dữ liệu chính xác.',
        ),
        _FeatureTourStep(
          tabIndex: 1,
          icon: Icons.account_balance_wallet_rounded,
          title: 'Tài khoản',
          message:
              'Tài khoản là nơi giữ tiền của bạn, ví dụ Tiền mặt, Ngân hàng hoặc Ví điện tử. Đây là bước đầu tiên để app biết bạn đang quản lý tiền ở đâu.',
        ),
        _FeatureTourStep(
          tabIndex: 1,
          icon: Icons.attach_money_rounded,
          title: 'Nguồn tiền',
          message:
              'Nguồn tiền là nơi khai báo tiền đến từ đâu, ví dụ Lương, Phụ cấp hoặc Kinh doanh. Sau bước này, bạn có thể ghi nhận giao dịch thu chi rõ ràng hơn.',
        ),
      ];

  List<_FeatureTourStep> get _featureTourSteps => const [
        _FeatureTourStep(
          tabIndex: 1,
          icon: Icons.savings_rounded,
          title: 'Tiết kiệm',
          message:
              'Chức năng Tiết kiệm giúp bạn tạo mục tiêu để dành tiền, theo dõi đã tiết kiệm được bao nhiêu và còn thiếu bao nhiêu để đạt mục tiêu.',
        ),
        _FeatureTourStep(
          tabIndex: 1,
          icon: Icons.trending_up_rounded,
          title: 'Đầu tư',
          message:
              'Chức năng Đầu tư dùng để theo dõi các khoản đầu tư như gửi ngân hàng, cổ phiếu hoặc tài sản khác, giúp bạn tách phần đầu tư khỏi chi tiêu hằng ngày.',
        ),
        _FeatureTourStep(
          tabIndex: 1,
          icon: Icons.history_rounded,
          title: 'Lịch sử',
          message:
              'Lịch sử lưu lại các giao dịch đã nhập trong tháng. Bạn có thể dùng mục này để kiểm tra lại khoản thu chi và đối chiếu khi cần.',
        ),
        _FeatureTourStep(
          tabIndex: 2,
          icon: Icons.insights_rounded,
          title: 'Phân tích',
          message:
              'Khi dữ liệu đủ điều kiện, app sẽ tự hiển thị dự báo chi tiêu và cảnh báo để bạn kiểm soát ngân sách tốt hơn.',
        ),
      ];

  List<_FeatureTourStep> get _fullGuideSteps => [
        ..._budgetIntroSteps,
        ..._accountIntroSteps,
        ..._featureTourSteps,
      ];

  Future<void> _runTourSteps(
    List<_FeatureTourStep> steps, {
    int? endIndex,
  }) async {
    _tourRunning = true;

    for (final step in steps) {
      if (!mounted) return;
      setState(() => _currentIndex = step.tabIndex);
      await Future<void>.delayed(const Duration(milliseconds: 260));
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _FeatureTourDialog(step: step),
      );
    }

    if (!mounted) return;
    if (endIndex != null) {
      setState(() => _currentIndex = endIndex);
    }
  }

  Future<void> _replayFeatureTour() async {
    if (_tourRunning) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_budgetIntroSeenKey);
    await prefs.remove(_accountIntroSeenKey);
    await prefs.remove(_featureTourSeenKey);
    if (!mounted) return;

    setState(() {
      _tourRunning = true;
      _currentIndex = 0;
    });

    await _runTourSteps(_fullGuideSteps, endIndex: 0);
    if (!mounted) return;
    await prefs.setBool(_budgetIntroSeenKey, true);
    await prefs.setBool(_accountIntroSeenKey, true);
    await prefs.setBool(_featureTourSeenKey, true);
    setState(() {
      _currentIndex = 0;
      _tourRunning = false;
      _tourChecking = false;
    });
  }

  void _onFabPressed() {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.40),
      barrierDismissible: true,
      barrierLabel: 'Close',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) {
        return _ActionMenuOverlay(onClose: () => Navigator.pop(ctx));
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(opacity: anim1, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    context.watch<BankAccountProvider>();
    context.watch<IncomeProvider>();
    context.watch<CategoryProvider>();
    context.watch<BudgetsProvider>();
    _maybeStartFeatureTour();

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _ModernBottomNav(
        currentIndex: _currentIndex,
        onTabSelected: _onTabSelected,
        onFabPressed: _onFabPressed,
        labels: [
          t.tabBudgets,
          t.tabAccounts,
          t.tabAnalytics,
          t.tabSettings,
        ],
        icons: const [
          Icons.wallet_rounded,
          Icons.account_balance_rounded,
          Icons.insights_rounded,
          Icons.settings_rounded,
        ],
        cs: cs,
        isDark: isDark,
      ),
    );
  }
}

// ═══════════════════════════════════════
//  Bottom Nav — Mint/Teal
// ═══════════════════════════════════════
class _ModernBottomNav extends StatelessWidget {
  static const _inactive = Color(0xFF9CA3AF);

  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onFabPressed;
  final List<String> labels;
  final List<IconData> icons;
  final ColorScheme cs;
  final bool isDark;

  const _ModernBottomNav({
    required this.currentIndex,
    required this.onTabSelected,
    required this.onFabPressed,
    required this.labels,
    required this.icons,
    required this.cs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final _mint = cs.primary;
    final _mintLight = Color.lerp(cs.primary, Colors.white, 0.3) ?? cs.primary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2530) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2A3544) : const Color(0xFFE8ECF0),
            width: 1,
          ),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(.06),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              _buildNavItem(0),
              _buildNavItem(1),
              // ── FAB: mint gradient ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: onFabPressed,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_mint, _mintLight],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _mint.withOpacity(.35),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
              _buildNavItem(2),
              _buildNavItem(3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final selected = currentIndex == index;
    final _mint = cs.primary;
    final color =
        selected ? _mint : (isDark ? Colors.white.withOpacity(.45) : _inactive);

    return Expanded(
      child: GestureDetector(
        onTap: () => onTabSelected(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: selected
                    ? const EdgeInsets.symmetric(horizontal: 14, vertical: 5)
                    : const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: selected
                      ? _mint.withOpacity(isDark ? .15 : .10)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icons[index], size: 21, color: color),
              ),
              const SizedBox(height: 3),
              Text(
                labels[index],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
//  Arc Menu Overlay
// ═══════════════════════════════════════
class _FeatureTourStep {
  const _FeatureTourStep({
    required this.tabIndex,
    required this.icon,
    required this.title,
    required this.message,
  });

  final int tabIndex;
  final IconData icon;
  final String title;
  final String message;
}

class _FeatureTourDialog extends StatelessWidget {
  const _FeatureTourDialog({required this.step});

  final _FeatureTourStep step;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                step.icon,
                color: AppColors.primaryDark,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              step.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              step.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: Color(0xFF667085),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Đã hiểu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionMenuOverlay extends StatelessWidget {
  final VoidCallback onClose;
  const _ActionMenuOverlay({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: onClose,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            bottom: bottomInset + 8,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 160,
              width: w,
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  // Nhập thường (Left)
                  Positioned(
                    left: w / 2 - 95,
                    bottom: 25,
                    child: _ActionBtn(
                      icon: Icons.receipt_long_rounded,
                      label: 'Nhập thường',
                      onTap: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NotePage()));
                      },
                    ),
                  ),
                  // Chụp ảnh (Center)
                  Positioned(
                    bottom: 75,
                    child: _ActionBtn(
                      icon: Icons.camera_alt_outlined,
                      label: 'Chụp ảnh',
                      onTap: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const NotePage(autoCamera: true)));
                      },
                    ),
                  ),
                  // Giọng nói (Right)
                  Positioned(
                    right: w / 2 - 95,
                    bottom: 25,
                    child: _ActionBtn(
                      icon: Icons.mic_none_rounded,
                      label: 'Giọng nói',
                      onTap: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const NotePage(autoVoice: true)));
                      },
                    ),
                  ),
                  // Nút X (Close)
                  Positioned(
                    bottom: 0,
                    child: GestureDetector(
                      onTap: onClose,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF2A3544)
                              : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(Icons.close_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 26),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector( 
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Color.lerp(Theme.of(context).colorScheme.primary,
                          Colors.white, 0.3) ??
                      Theme.of(context).colorScheme.primary
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ), 
      ],
    );
  }
}