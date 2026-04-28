import 'dart:async';
import 'dart:io';

import 'package:chitieu/api/transaction/transaction_provider.dart';
import 'package:chitieu/core/voice/voice_synonym_store.dart';
import 'package:chitieu/utils/safe_ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:diacritic/diacritic.dart';
import 'package:image_picker/image_picker.dart';

import 'package:chitieu/l10n/app_localizations.dart';

// Providers & models
import 'package:chitieu/api/category/category_provider.dart';
import 'package:chitieu/api/category/category_model.dart';
import 'package:chitieu/core/budget/budgets_provider.dart';
import 'package:chitieu/core/money/widgets/money_text.dart';
import 'package:chitieu/api/bankaccount/bank_account_provider.dart';
import 'package:chitieu/api/income/income_provider.dart';
import 'package:chitieu/api/income/income_model.dart';
import 'package:chitieu/api/in_invoice/in_invoice_provider.dart';
import 'package:chitieu/api/out_invoice/out_invoice_provider.dart';
import 'package:chitieu/api/out_invoice/out_invoice_model.dart';
import 'package:chitieu/financial_transaction/financial_transaction_provider.dart';

// VOICE
import 'package:chitieu/api/ai/stt_service.dart';
import 'package:chitieu/api/ai/voice_intent.dart';
import 'package:chitieu/api/ai/tts_service.dart';

enum FlowType { out, in_ }

class NotePage extends StatefulWidget {
  final bool autoVoice;
  final bool autoCamera;
  const NotePage({super.key, this.autoVoice = false, this.autoCamera = false});

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  FlowType type = FlowType.out;
  String amount = '';

  dynamic selectedWallet;
  IncomeCategory? selectedIncome;
  Category? selectedCategory;
  DateTime _selectedDate = DateTime.now();

  String _noteText = '';
  final TextEditingController _noteCtl = TextEditingController();

  final NumberFormat _vi = NumberFormat.decimalPattern('vi_VN');

  String _formatExpression(String raw) {
    if (raw.isEmpty) return '0';
    try {
      return raw.replaceAllMapped(
          RegExp(r'(\d+)'), (m) => _vi.format(int.parse(m[1]!)));
    } catch (_) {
      return raw;
    }
  }

  bool _forceCancel = false;
  bool _submitting = false;

  // PHOTO
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedPhoto;

  // ================= VOICE =================
  late final SttService _stt;
  late final VoiceIntentParser _parser;
  late final TtsService _tts;
  bool _listening = false;
  String _voiceText = '';
  String? _originalVoiceInput;

  @override
  void initState() {
    super.initState();
    _stt = SttService();
    _parser = VoiceIntentParser();
    _tts = TtsService();
    _stt.init();
    _tts.init();

    if (widget.autoVoice) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _toggleListening();
      });
    }

    if (widget.autoCamera) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _pickExpensePhoto();
      });
    }

    Future.microtask(() async {
      final cats = context.read<CategoryProvider>();
      if (!cats.loading && cats.items.isEmpty) await cats.refresh();

      final wals = context.read<BankAccountProvider>();
      if (!wals.loading && wals.items.isEmpty) await wals.fetch();

      final inc = context.read<IncomeProvider>();
      if (!inc.loading && inc.items.isEmpty) await inc.fetchAll();
    });
  }

  @override
  void dispose() {
    _noteCtl.dispose();
    _stt.stop();
    _tts.dispose();
    super.dispose();
  }

  Future<void> _cancelAll() async {
    await _stt.stop();

    setState(() {
      _forceCancel = true;
      _listening = false;
      _voiceText = '';
      amount = '';
      selectedCategory = null;
      selectedWallet = null;
      selectedIncome = null;
      _noteText = '';
      _pickedPhoto = null;
    });

    await _tts.say('Đã hủy giao dịch.');

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _pickExpensePhoto() async {
    if (type != FlowType.out) return;

    final file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 70,
    );

    if (file != null && mounted) {
      setState(() => _pickedPhoto = file);
    }
  }

  /* ================= VOICE HANDLER ================= */
  Future<void> _toggleListening() async {
    if (_listening) {
      await _stt.stop();
      setState(() => _listening = false);
      return;
    }

    final voiceStore = VoiceSynonymStore();
    await voiceStore.load();

    setState(() {
      _listening = true;
      _voiceText = '';
    });

    // Đừng cản trở quá trình STT bật mic bằng TTS chậm chạp
    // await _tts.say('Tôi đang nghe bạn nói...');

    final outcome = await _stt.listenOnceEx(
      onPartial: (text) => setState(() => _voiceText = text),
    );

    final text = outcome.text?.trim() ?? '';
    setState(() {
      _voiceText = text;
      _listening = false;
      _originalVoiceInput = text;
    });

    if (_forceCancel) {
      _forceCancel = false;
      return;
    }

    if (text.isEmpty) {
      await _tts.say('Mình không nghe rõ, bạn nói lại nhé.');
      return;
    }

    // Truyền context vào để _parser tự động hốt mảng Danh Mục của bạn gửi cho Gemini
    final intent = await _parser.parse(text, context: context);
    debugPrint('🎯 Voice intent: $intent');

    setState(() {
      if (intent.amount != null) amount = intent.amount.toString();
      _noteText = intent.note ?? '';
      if (intent.type == VoiceIntentType.spend) type = FlowType.out;
      if (intent.type == VoiceIntentType.income) type = FlowType.in_;
    });

    final catsDebug =
        context.read<CategoryProvider>().items.map((e) => e.name).toList();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          'DEBUG: List Cat: $catsDebug\nGemini Cat: ${intent.categoryName}'),
      duration: const Duration(seconds: 4),
    ));

    final wals = context.read<BankAccountProvider>().items;
    if (wals.isNotEmpty) {
      dynamic found;
      if (intent.walletName != null) {
        final target = intent.walletName!.toLowerCase();
        try {
          found = wals.firstWhere((w) {
            final name = (w.name ?? '').toLowerCase();
            final title = (w.title ?? '').toLowerCase();
            return name.contains(target) || title.contains(target);
          });
          debugPrint('🎯 Ví được nói: ${found.name ?? found.title}');
          await voiceStore.learnFromUtterance(
            intent.walletName!,
            'wallet:${found.name ?? found.title}',
          );
        } catch (_) {
          found = null;
        }
      }

      found ??=
          wals.reduce((a, b) => ((a.balance ?? 0) >= (b.balance ?? 0)) ? a : b);

      setState(() => selectedWallet = found);
      debugPrint('💰 Ví được chọn: ${found.name ?? found.title}');
    }

    if (type == FlowType.out && intent.categoryName != null) {
      final cats = context.read<CategoryProvider>().items;
      if (cats.isNotEmpty) {
        Category? found;
        final input = removeDiacritics(intent.categoryName!.toLowerCase());

        try {
          found = cats.firstWhere(
            (c) {
              final name = removeDiacritics(c.name.toLowerCase());
              return name == input ||
                  name.contains(input) ||
                  input.contains(name);
            },
          );
        } catch (_) {
          found = null;
        }

        if (found != null) {
          setState(() => selectedCategory = found);
          debugPrint('📚 Nhận diện danh mục: ${found.name}');
        } else {
          debugPrint('⚠️ Không tìm thấy danh mục "${intent.categoryName}".');
          await _tts.say(
            'Không tìm thấy danh mục ${intent.categoryName}. Bạn có thể chọn thủ công nhé.',
          );
        }
      }
    }

    if (type == FlowType.in_ && selectedIncome == null) {
      await _tts.say(
          'Đã nhận thông tin, bạn vui lòng chọn nguồn thu trên màn hình để hoàn tất nhé.');
    }

    final amt = intent.amount ?? 0;
    if (type == FlowType.out && selectedCategory == null && amt > 0) {
      await _tts.say(
          'Trường hợp này đặc biệt, bạn vui lòng tự tay chạm vào danh mục trên màn hình để lưu nhé.');
    }

    // TODO: Không hỏi lằng nhằng nữa, mặc định user nhìn trên UI là hiểu.
    // Chỉ cần phát âm báo ngắn gọn hoặc không nói gì để user tự tay bấm nút Check màu xanh là nhanh nhất.
    if (amt > 0 &&
        selectedWallet != null &&
        ((type == FlowType.out && selectedCategory != null) ||
            (type == FlowType.in_ && selectedIncome != null))) {
      await _tts.say('Đã lưu');
      await _submit();
    }
  }

  /* ================= handlers ================= */

  int _evaluate(String expr) {
    try {
      String s = expr;
      List<String> tokens = [];
      String num = '';
      for (var i = 0; i < s.length; i++) {
        var c = s[i];
        if ('+-*/'.contains(c)) {
          if (num.isNotEmpty) tokens.add(num);
          tokens.add(c);
          num = '';
        } else {
          num += c;
        }
      }
      if (num.isNotEmpty) tokens.add(num);

      if (tokens.isEmpty) return 0;
      double res = double.tryParse(tokens[0]) ?? 0;
      for (var i = 1; i < tokens.length - 1; i += 2) {
        var op = tokens[i];
        var next = double.tryParse(tokens[i + 1]) ?? 0;
        if (op == '+')
          res += next;
        else if (op == '-')
          res -= next;
        else if (op == '*')
          res *= next;
        else if (op == '/') res /= next;
      }
      return res.toInt();
    } catch (_) {
      return int.tryParse(expr) ?? 0;
    }
  }

  void _onKey(String k) {
    setState(() {
      if (k == 'C') {
        amount = '';
        return;
      }
      if (k == '=') {
        amount = _evaluate(amount).toString();
        return;
      }
      // Khóa nhập ký tự đặc biệt bất hợp lý
      if ('+-*/'.contains(k) &&
          amount.isNotEmpty &&
          '+-*/'.contains(amount[amount.length - 1])) {
        amount = amount.substring(0, amount.length - 1) + k;
        return;
      }
      amount += k;
    });
  }

  void _onBackspace() {
    if (amount.isEmpty) return;
    setState(() => amount = amount.substring(0, amount.length - 1));
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final isOut = type == FlowType.out;
      final amt = _evaluate(amount);
      final selectedWalletId = (selectedWallet as dynamic)?.id ?? 0;
      final categoryId = selectedCategory?.id ?? 0;
      final incomeId = selectedIncome?.id ?? 0;

      if (amt <= 0) {
        showAppSnackBar(context, 'Vui long nhap so tien > 0.', isError: true);
        await _tts.say('Ban muon ghi so tien bao nhieu?');
        return;
      }

      if (isOut && selectedWalletId == 0) {
        showAppSnackBar(context, 'Vui long chon tai khoan chi.', isError: true);
        await _tts.say('Ban chua chon tai khoan chi.');
        return;
      }

      if (isOut && categoryId == 0) {
        showAppSnackBar(context, 'Vui long chon danh muc.', isError: true);
        await _tts.say('Ban chua chon danh muc.');
        return;
      }

      if (!isOut && (selectedWalletId == 0 || incomeId == 0)) {
        showAppSnackBar(context, 'Vui long chon nguon thu va vi.',
            isError: true);
        await _tts.say('Ban chua chon nguon thu hoac vi nap tien.');
        return;
      }

      final trimmedNote = _noteText.trim();
      final safeNote = trimmedNote.isEmpty
          ? null
          : (trimmedNote.length <= 300
              ? trimmedNote
              : trimmedNote.substring(0, 300));
      final bankAccountProv = context.read<BankAccountProvider>();
      final inInvoiceProv = context.read<InInvoiceProvider>();
      final outInvoiceProv = context.read<OutInvoiceProvider>();
      final incomeProv = context.read<IncomeProvider>();
      final budgetsProv = context.read<BudgetsProvider>();
      final financialTxProv = context.read<FinancialTransactionProvider>();
      final transactionProv = context.read<TransactionProvider>();

      if (isOut) {
        final invoice = OutInvoice(
          id: 0,
          userId: 0,
          bankId: selectedWalletId,
          outcatId: categoryId,
          amount: amt,
          docType: 'OUT',
          content: safeNote,
          month: _selectedDate.month,
          year: _selectedDate.year,
          occurredAt: _selectedDate,
        );

        final ok = await outInvoiceProv.create(
          context,
          invoice,
          photoFile: _pickedPhoto != null ? File(_pickedPhoto!.path) : null,
          refreshAfterCreate: false,
          showSuccessMessage: false,
        );

        if (!ok) return;
      } else {
        await transactionProv.create(
          isIncome: true,
          bankId: selectedWalletId,
          categoryId: incomeId,
          amount: amt,
          content: safeNote,
          month: _selectedDate.month,
          year: _selectedDate.year,
          occurredAt: _selectedDate.toIso8601String(),
          refreshAfterCreate: false,
        );
      }

      final refreshYear = _selectedDate.year;
      final refreshMonth = _selectedDate.month;

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      final successSnackBar = appSnackBar(
        isOut
            ? 'Da ghi giao dich chi thanh cong'
            : 'Da ghi giao dich thu thanh cong',
        icon: Icons.receipt_long_rounded,
      );

      Navigator.pop(context, true);

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(successSnackBar);

      unawaited(Future.wait([
        bankAccountProv.fetchAccounts(),
        inInvoiceProv.fetch(
          year: refreshYear,
          month: refreshMonth,
        ),
        outInvoiceProv.fetch(
          year: refreshYear,
          month: refreshMonth,
        ),
        transactionProv.fetchAll(),
        incomeProv.fetchAll(),
        budgetsProv.loadForMonth(
          year: refreshYear,
          month: refreshMonth,
        ),
        financialTxProv.fetchByMonth(
          year: refreshYear,
          month: refreshMonth,
        ),
      ]).catchError((e, st) {
        debugPrint('Background refresh after transaction failed: $e\n$st');
        return <void>[];
      }));
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'Loi luu giao dich: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
  // ================= Pickers =================

  Future<void> _openIncomePicker() async {
    final incProv = context.read<IncomeProvider>();
    if (!incProv.loading && incProv.items.isEmpty) await incProv.fetchAll();

    final picked = await showModalBottomSheet<IncomeCategory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? cs.surface : const Color(0xFFFAFBFE),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Chọn nguồn thu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  for (final inc in incProv.items)
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.savings)),
                        title: Text(
                          inc.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text('Số tiền: ${_vi.format(inc.balance)}'),
                        trailing: (inc.id == selectedIncome?.id)
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                        onTap: () => Navigator.pop(ctx, inc),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => selectedIncome = picked);
    }
  }

  Future<void> _openWalletPicker() async {
    final wProv = context.read<BankAccountProvider>();
    if (!wProv.loading && wProv.items.isEmpty) await wProv.fetch();

    final picked = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WalletPickerSheet(
        items: wProv.items,
        selectedId: selectedWallet?.id,
        onTopUp: (wallet) async {},
      ),
    );

    if (picked != null && mounted) {
      setState(() => selectedWallet = picked);
    }
  }

  Future<void> _openCategoryPicker() async {
    final catProv = context.read<CategoryProvider>();
    if (!catProv.loading && catProv.items.isEmpty) await catProv.refresh();

    final picked = await showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryPickerSheet(
        items: catProv.items,
        selectedId: selectedCategory?.id,
      ),
    );

    if (picked != null && mounted) {
      setState(() => selectedCategory = picked);

      final textToLearn = _originalVoiceInput?.trim() ?? _noteText.trim();

      if (textToLearn.isNotEmpty) {
        final store = VoiceSynonymStore();
        await store.load();
        await store.learnFromUtterance(textToLearn, picked.name);
        debugPrint('🧠 Đã học: "$textToLearn" → "${picked.name}"');
      }
    }
  }

  Future<void> _openDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Chọn ngày',
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _openNoteEditor() async {
    _noteCtl.text = _noteText;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? cs.surface : const Color(0xFFFAFBFE),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Ghi chú',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteCtl,
                maxLines: 3,
                maxLength: 300,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Thêm mô tả cho giao dịch',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Hủy'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, _noteCtl.text.trim()),
                    child: const Text('Lưu'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (result != null && mounted) {
      setState(() => _noteText = result);
    }
  }

  // ====== UI HELPERS ======

  Widget _buildQuickActions() {
    if (widget.autoVoice) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (type == FlowType.out && widget.autoCamera)
            _quickBtn(
              icon: _pickedPhoto != null
                  ? Icons.check_circle_rounded
                  : Icons.camera_alt_outlined,
              label: _pickedPhoto != null ? 'Đã chụp' : 'Chụp ảnh',
              active: _pickedPhoto != null,
              onTap: _pickExpensePhoto,
              cs: cs,
              isDark: isDark,
            ),
          if (!widget.autoCamera && !widget.autoVoice)
            _quickBtn(
              icon: _noteText.isNotEmpty
                  ? Icons.check_circle_rounded
                  : Icons.edit_note_rounded,
              label: _noteText.isNotEmpty ? 'Đã ghi chú' : 'Ghi chú',
              active: _noteText.isNotEmpty,
              onTap: _openNoteEditor,
              cs: cs,
              isDark: isDark,
            ),
        ],
      ),
    );
  }

  Widget _quickBtn({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
    required ColorScheme cs,
    required bool isDark,
  }) {
    const mint = Color(0xFF2EC4B6);
    final color = active ? mint : cs.onSurface.withOpacity(.35);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: active
                  ? mint.withOpacity(.08)
                  : (isDark
                      ? cs.surfaceContainerHigh
                      : const Color(0xFFF1F5F9)),
              shape: BoxShape.circle,
              border: Border.all(
                  color: active
                      ? mint.withOpacity(.2)
                      : (isDark
                          ? cs.outlineVariant.withOpacity(.08)
                          : const Color(0xFFE5E8ED))),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildSelectionList() {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateLabel = DateFormat('dd/MM/yyyy').format(_selectedDate);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (type == FlowType.out) ...[
            _ToolChip(
              icon: Icons.category_rounded,
              label: selectedCategory?.name ?? 'Danh mục',
              active: selectedCategory != null,
              onTap: _openCategoryPicker,
            ),
            const SizedBox(width: 8),
            _ToolChip(
              icon: Icons.account_balance_wallet_rounded,
              label: selectedWallet != null
                  ? ((selectedWallet as dynamic).name ??
                      (selectedWallet as dynamic).title ??
                      '—')
                  : 'Chọn tài ...',
              active: selectedWallet != null,
              onTap: _openWalletPicker,
            ),
          ],
          if (type == FlowType.in_) ...[
            _ToolChip(
              icon: Icons.savings_rounded,
              label: selectedIncome?.title ?? 'Nguồn thu',
              active: selectedIncome != null,
              onTap: _openIncomePicker,
            ),
            const SizedBox(width: 8),
            _ToolChip(
              icon: Icons.account_balance_wallet_rounded,
              label: selectedWallet != null
                  ? ((selectedWallet as dynamic).name ??
                      (selectedWallet as dynamic).title ??
                      '—')
                  : 'Tài khoản',
              active: selectedWallet != null,
              onTap: _openWalletPicker,
            ),
          ],
          const SizedBox(width: 8),
          _ToolChip(
            icon: Icons.calendar_month_rounded,
            label: dateLabel,
            active: true,
            onTap: _openDatePicker,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountSuggestions() {
    final raw = amount.replaceAll(RegExp(r'[^0-9]'), '');
    final base = int.tryParse(raw) ?? 0;

    if (base <= 0 || base >= 1000000000) return const SizedBox.shrink();

    final moneyFmt = NumberFormat('#,###', 'vi_VN');

    final suggestions = <int>[];
    for (final m in [1000, 10000, 100000, 1000000, 10000000]) {
      final v = base * m;
      if (v > base && v <= 10000000000 && !suggestions.contains(v)) {
        suggestions.add(v);
      }
      if (suggestions.length >= 3) break;
    }

    if (suggestions.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipColor =
        isDark ? cs.onSurface.withOpacity(.5) : const Color(0xFF3F51B5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final v = suggestions[i];
            return GestureDetector(
              onTap: () => setState(() => amount = v.toString()),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: chipColor.withOpacity(.35), width: 1.2),
                ),
                child: Text(
                  moneyFmt.format(v).replaceAll(',', '.'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: chipColor,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAmountDisplay() {
    final cs = Theme.of(context).colorScheme;
    final isOut = type == FlowType.out;
    // hiển thị dãy biểu thức dạng 1.000 + 2.000
    final formatted = amount.isEmpty
        ? '0'
        : _formatExpression(amount)
            .replaceAll('*', ' × ')
            .replaceAll('/', ' ÷ ')
            .replaceAll('+', ' + ')
            .replaceAll('-', ' - ');
    final hasAmount = amount.isNotEmpty;
    const mint = Color(0xFF2EC4B6);
    final color =
        !hasAmount ? cs.onSurface.withOpacity(.15) : (isOut ? cs.error : mint);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            if (hasAmount)
              Text(isOut ? '-' : '+',
                  style: TextStyle(
                      fontSize: 32, fontWeight: FontWeight.w700, color: color)),
            Text(formatted,
                style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: -2)),
            const SizedBox(width: 4),
            Text('đ',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    color: color.withOpacity(.5))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? cs.surface : const Color(0xFFFAFBFE);
    final isOut = type == FlowType.out;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  Material(
                    color: isDark
                        ? cs.surfaceContainerHigh
                        : const Color(0xFFF1F5F9),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.maybePop(context),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(Icons.close_rounded,
                            size: 18, color: cs.onSurface.withOpacity(.5)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FlowSegmented(
                      value: type,
                      onChanged: (v) => setState(() {
                        type = v;
                        selectedWallet = null;
                        selectedCategory = null;
                        selectedIncome = null;
                        if (type != FlowType.out) _pickedPhoto = null;
                      }),
                    ),
                  ),
                ],
              ),
            ),
            // ── Content ──
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    Text(
                      isOut ? 'Chi tiêu' : 'Thu nhập',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withOpacity(.35),
                          letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    _buildAmountDisplay(),
                    if (_pickedPhoto != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(_pickedPhoto!.path),
                            height: 120,
                            width: 120,
                            cacheHeight: 240,
                            cacheWidth: 240,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    if (_noteText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.surfaceTint.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _noteText,
                            style: TextStyle(
                              color: cs.onSurface.withOpacity(0.8),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (_listening || _voiceText.isNotEmpty) ...[
                      _VoiceCaption(text: _voiceText, listening: _listening),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _cancelAll,
                        icon: Icon(Icons.cancel_rounded, color: cs.error),
                        label: Text('Hủy giao dịch',
                            style: TextStyle(
                                color: cs.error, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 16),
                    _buildQuickActions(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            _buildSelectionList(),
            const SizedBox(height: 4),
            _buildQuickAmountSuggestions(),
            // ── Keypad ──
            _KeypadBar(
                onTap: _onKey,
                onBack: _onBackspace,
                onConfirm: _submit,
                isConfirming: _submitting,
                onVoice: _toggleListening),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
//  STANDALONE WIDGETS
// ═══════════════════════════════════════

class _VoiceCaption extends StatelessWidget {
  const _VoiceCaption({required this.text, required this.listening});
  final String text;
  final bool listening;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const mint = Color(0xFF2EC4B6);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHigh : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: listening
                  ? mint.withOpacity(.3)
                  : (isDark
                      ? cs.outlineVariant.withOpacity(.08)
                      : const Color(0xFFECEDF2))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
                listening ? Icons.mic_rounded : Icons.record_voice_over_rounded,
                size: 18,
                color: listening ? mint : cs.onSurface.withOpacity(.5)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text.isEmpty ? 'Đang nghe…' : text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowSegmented extends StatelessWidget {
  const _FlowSegmented({required this.value, required this.onChanged});
  final FlowType value;
  final ValueChanged<FlowType> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = AppLocalizations.of(context)!;
    const mint = Color(0xFF2EC4B6);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? cs.surfaceContainerHigh : const Color(0xFFF1F5F9),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _seg(t.moneyOut, Icons.arrow_outward_rounded, value == FlowType.out,
              cs.error, cs, isDark, () => onChanged(FlowType.out)),
          const SizedBox(width: 3),
          _seg(t.moneyIn, Icons.arrow_downward_rounded, value == FlowType.in_,
              mint, cs, isDark, () => onChanged(FlowType.in_)),
        ],
      ),
    );
  }

  Widget _seg(String label, IconData icon, bool active, Color ac,
      ColorScheme cs, bool isDark, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: active
                ? (isDark ? cs.surface : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1))
                  ]
                : null,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 16,
                    color: active ? ac : cs.onSurface.withOpacity(.3)),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13.5,
                        color: active ? ac : cs.onSurface.withOpacity(.3))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KeypadBar extends StatelessWidget {
  const _KeypadBar(
      {required this.onTap,
      required this.onBack,
      required this.onConfirm,
      required this.isConfirming,
      this.onVoice});
  final ValueChanged<String> onTap;
  final VoidCallback onBack;
  final VoidCallback onConfirm;
  final bool isConfirming;
  final VoidCallback? onVoice;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEBEBEB);
    final keyBg = isDark ? const Color(0xFF2D2D2D) : Colors.white;
    const mint = Color(0xFF2EC4B6);

    Widget btn(String label, {Color? textColor, VoidCallback? action}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Material(
            color: keyBg,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: action ?? () => onTap(label),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color:
                        textColor ?? (isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget iconBtn(IconData icon,
        {Color? color, required VoidCallback action}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Material(
            color: keyBg,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: action,
              child: Center(
                child: Icon(icon, color: color ?? mint, size: 24),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: 7  8  9  ⌫
          SizedBox(
            height: 56,
            child: Row(children: [
              btn('7'),
              btn('8'),
              btn('9'),
              iconBtn(Icons.backspace_outlined, action: onBack),
            ]),
          ),
          // Rows 2-4: left(4-5-6 / 1-2-3 / 0) + right(✓ spanning all 3)
          SizedBox(
            height: 168,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left 3 columns
                Expanded(
                  flex: 3,
                  child: Column(children: [
                    Expanded(
                        child: Row(children: [btn('4'), btn('5'), btn('6')])),
                    Expanded(
                        child: Row(children: [btn('1'), btn('2'), btn('3')])),
                    Expanded(child: Row(children: [btn('0')])),
                  ]),
                ),
                // Right col: ✓ spanning 3 rows
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Material(
                      color: isConfirming ? mint.withOpacity(.55) : mint,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: isConfirming ? null : onConfirm,
                        child: Center(
                          child: isConfirming
                              ? const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 36),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletPickerSheet extends StatelessWidget {
  const _WalletPickerSheet(
      {required this.items, required this.selectedId, required this.onTopUp});
  final List<dynamic> items;
  final dynamic selectedId;
  final Future<void> Function(dynamic wallet) onTopUp;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const mint = Color(0xFF2EC4B6);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? cs.surface : const Color(0xFFFAFBFE),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: cs.onSurface.withOpacity(.12),
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Row(children: [
                  Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: mint.withOpacity(.08),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.account_balance_wallet_rounded,
                          color: mint, size: 18)),
                  const SizedBox(width: 12),
                  Text('Chọn tài khoản',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface)),
                ]),
                const SizedBox(height: 14),
                for (final w in items)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isDark ? cs.surfaceContainerHigh : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: (w as dynamic).id == selectedId
                              ? mint.withOpacity(.3)
                              : (isDark
                                  ? cs.outlineVariant.withOpacity(.08)
                                  : const Color(0xFFECEDF2))),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                              color: mint.withOpacity(.08),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.account_balance_rounded,
                              color: mint, size: 20)),
                      title: Text(
                          (w as dynamic).name ?? (w as dynamic).title ?? '—',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface)),
                      subtitle: Row(children: [
                        Text('Số dư: ',
                            style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withOpacity(.4))),
                        MoneyText((w as dynamic).balance ??
                            (w as dynamic).amount ??
                            0),
                      ]),
                      trailing: (w as dynamic).id == selectedId
                          ? const Icon(Icons.check_circle_rounded,
                              color: mint, size: 22)
                          : null,
                      onTap: () => Navigator.pop(context, w),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
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

class _CategoryPickerSheet extends StatelessWidget {
  const _CategoryPickerSheet({required this.items, required this.selectedId});
  final List<Category> items;
  final int? selectedId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const mint = Color(0xFF2EC4B6);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? cs.surface : const Color(0xFFFAFBFE),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: cs.onSurface.withOpacity(.12),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Row(children: [
                Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: mint.withOpacity(.08),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.category_rounded,
                        color: mint, size: 18)),
                const SizedBox(width: 12),
                Text('Chọn danh mục',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface)),
              ]),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.15,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8),
                itemBuilder: (_, i) {
                  final c = items[i];
                  final selected = c.id == selectedId;
                  final first =
                      (c.name.isNotEmpty ? c.name[0] : '•').toUpperCase();
                  return Material(
                    color: selected
                        ? mint.withOpacity(.08)
                        : (isDark ? cs.surfaceContainerHigh : Colors.white),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.pop(_, c),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: selected
                                  ? mint.withOpacity(.3)
                                  : (isDark
                                      ? cs.outlineVariant.withOpacity(.08)
                                      : const Color(0xFFECEDF2))),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                  color: mint.withOpacity(.1),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Center(
                                  child: Text(first,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: mint,
                                          fontSize: 15))),
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(c.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: selected ? mint : cs.onSurface)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const mint = Color(0xFF2EC4B6);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active
                ? mint.withOpacity(0.08)
                : (isDark ? cs.surfaceContainerHigh : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? mint.withOpacity(0.3)
                  : (isDark
                      ? cs.outlineVariant.withOpacity(0.08)
                      : const Color(0xFFE5E8ED)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? mint : cs.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    color: active ? mint : cs.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
