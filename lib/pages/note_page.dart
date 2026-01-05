import 'package:chitieu/api/transaction/transaction_provider.dart';
import 'package:chitieu/core/voice/voice_synonym_store.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:diacritic/diacritic.dart';
import 'package:chitieu/l10n/app_localizations.dart';
import 'package:chitieu/core/date/year_month_provider.dart';

// Providers & models
import 'package:chitieu/api/category/category_provider.dart';
import 'package:chitieu/api/category/category_model.dart';
import 'package:chitieu/core/budget/budgets_provider.dart';
import 'package:chitieu/core/money/widgets/money_text.dart';
import 'package:chitieu/api/bankaccount/bank_account_provider.dart';
import 'package:chitieu/api/income/income_provider.dart';
import 'package:chitieu/api/income/income_model.dart';

// VOICE
import 'package:chitieu/api/ai/stt_service.dart';
import 'package:chitieu/api/ai/voice_intent.dart';
import 'package:chitieu/api/ai/tts_service.dart';

enum FlowType { out, in_ }

class NotePage extends StatefulWidget {
  const NotePage({super.key});

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
  String _formatVn(String raw) {
    if (raw.isEmpty) return '0';
    final n = int.tryParse(raw) ?? 0;
    return _vi.format(n);
  }

  bool _forceCancel = false;

  // ================= VOICE =================
  late final SttService _stt;
  late final VoiceIntentParser _parser;
  late final TtsService _tts;
  bool _listening = false;
  String _voiceText = '';
  String? _originalVoiceInput; // ← THÊM DÒNG NÀY

  @override
  void initState() {
    super.initState();
    _stt = SttService();
    _parser = VoiceIntentParser();
    _tts = TtsService();
    _stt.init();
    _tts.init();

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

  void _cancelAll() async {
    // Nếu đang nghe thì dừng
    await _stt.stop();

    setState(() {
      _forceCancel = true;

      // trạng thái voice
      _listening = false;
      _voiceText = '';

      // dữ liệu giao dịch
      amount = '';
      selectedCategory = null;
      selectedWallet = null;
      selectedIncome = null;
      _noteText = '';
    });

    await _tts.say('Đã hủy giao dịch.');
    void _cancelAll() async {
      await _stt.stop();
      setState(() {/* reset như trên */});
      await _tts.say('Đã hủy giao dịch.');

      if (mounted) Navigator.pop(context); // đóng NotePage
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

    await _tts.say('Tôi đang nghe bạn nói...');

    // 🎤 Bắt đầu nghe
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
      _forceCancel = false; // reset
      return; // ← KHÔNG NÓI "mình không nghe rõ"
    }

    if (text.isEmpty) {
      await _tts.say('Mình không nghe rõ, bạn nói lại nhé.');
      return;
    }

    final intent = await _parser.parse(text);
    debugPrint('🎯 Voice intent: $intent');

    // 🎯 Cập nhật UI
    setState(() {
      if (intent.amount != null) amount = intent.amount.toString();
      _noteText = intent.note ?? ''; // ← SỬA: Bỏ if, luôn gán
      if (intent.type == VoiceIntentType.spend) type = FlowType.out;
      if (intent.type == VoiceIntentType.income) type = FlowType.in_;
    });

    // ============================================
    // ✅ Ưu tiên ví được nói hoặc ví có số dư cao nhất
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
              intent.walletName!, 'wallet:${found.name ?? found.title}');
        } catch (_) {
          found = null;
        }
      }

      found ??=
          wals.reduce((a, b) => ((a.balance ?? 0) >= (b.balance ?? 0)) ? a : b);

      setState(() => selectedWallet = found);
      debugPrint('💰 Ví được chọn: ${found.name ?? found.title}');
    }

    // ============================================
    // ✅ Nếu là tiền ra -> nhận diện danh mục thông minh
    if (type == FlowType.out && intent.categoryName != null) {
      final cats = context.read<CategoryProvider>().items;
      if (cats.isNotEmpty) {
        Category? found;
        final input = removeDiacritics(intent.categoryName!.toLowerCase());

        try {
          // 🔹 So khớp chính xác theo tên danh mục
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
              'Không tìm thấy danh mục ${intent.categoryName}. Bạn có thể chọn thủ công nhé.');
        }
      }
    }

    // ============================================
    // ✅ Nếu là TIỀN VÀO → hỏi chọn nguồn thu nếu chưa có
    if (type == FlowType.in_ && selectedIncome == null) {
      await _tts.say('Bạn muốn ghi vào nguồn thu nào?');
      final incProv = context.read<IncomeProvider>();
      final items = incProv.items;

      final next =
          await _stt.listenOnceEx(hardTimeout: const Duration(seconds: 6));
      final nextText = next.text?.toLowerCase().trim() ?? '';

      if (nextText.isEmpty) {
        await _tts.say('Không nghe rõ nguồn thu. Bạn có thể chọn thủ công.');
      } else {
        final found = items.firstWhere(
          (inc) =>
              inc.title.toLowerCase().contains(nextText) ||
              inc.title
                  .toLowerCase()
                  .split(' ')
                  .any((word) => nextText.contains(word)),
          orElse: () => items.first,
        );
        setState(() => selectedIncome = found);
        await voiceStore.learnFromUtterance(nextText, 'income:${found.title}');
        await _tts.say('Đã chọn nguồn thu ${found.title}');
      }
    }

    // ============================================
    // 💬 Nếu là tiền ra mà chưa có danh mục -> hỏi người dùng
    final amt = intent.amount ?? 0;
    if (type == FlowType.out && selectedCategory == null && amt > 0) {
      await _tts.say('Bạn muốn lưu giao dịch này vào danh mục nào?');
      final next =
          await _stt.listenOnceEx(hardTimeout: const Duration(seconds: 6));
      final nextText = next.text?.toLowerCase().trim() ?? '';

      if (nextText.isNotEmpty) {
        final cats = context.read<CategoryProvider>().items;
        final found = cats.firstWhere(
          (c) => removeDiacritics(c.name.toLowerCase())
              .contains(removeDiacritics(nextText)),
          orElse: () => cats.first,
        );
        setState(() => selectedCategory = found);

        // 🔹 Học cả từ câu nói ban đầu và câu xác nhận
        await voiceStore.learnFromUtterance(nextText, found.name);
        await voiceStore.learnFromUtterance(nextText, found.name);

        print('🧠 Đã học: "${intent.note}" và "${nextText}" → "${found.name}"');
        voiceStore.debugPrintAll();

        await _tts.say('Đã chọn danh mục ${found.name}');
      } else {
        await _tts.say('Không nghe rõ danh mục. Bạn có thể chọn thủ công.');
        return;
      }
    }

    // ============================================
    // 💾 Hỏi xác nhận trước khi lưu
    final isChangeCommand = _voiceText.contains('chuyển') ||
        _voiceText.contains('đổi') ||
        _voiceText.contains('sang');

    if (!isChangeCommand &&
        amt > 0 &&
        selectedWallet != null &&
        ((type == FlowType.out && selectedCategory != null) ||
            (type == FlowType.in_ && selectedIncome != null))) {
      await _tts.say(
          'Bạn đã ${type == FlowType.out ? "chi" : "thu"} ${_vi.format(amt)} cho ${intent.note ?? "giao dịch"}. Nói "đổi ví" hoặc "lưu lại".');

// 🔥 cần delay 400–500ms để Android nhả audio
      await Future.delayed(const Duration(milliseconds: 450));

      final nextOutcome = await _stt.listenOnceEx(
        hardTimeout: const Duration(seconds: 6),
      );

      final nextText = nextOutcome.text?.toLowerCase() ?? '';

      if (nextText.contains('đổi') || nextText.contains('chuyển')) {
        for (final w in wals) {
          final name = (w.name ?? '').toLowerCase();
          final title = (w.title ?? '').toLowerCase();
          if (nextText.contains(name) || nextText.contains(title)) {
            setState(() => selectedWallet = w);
            await voiceStore.learnFromUtterance(
                w.name ?? w.title ?? '', 'wallet:${w.name ?? w.title}');
            await _tts.say('Đã chuyển sang ví ${w.name ?? w.title}');
            break;
          }
        }
      }

      if (nextText.contains('lưu') || nextText.isEmpty) {
        await _submit();
        await _tts.say('Đã lưu giao dịch thành công.');
      } else {
        await _tts.say('Đã hủy lưu giao dịch.');
      }
    } else if (isChangeCommand) {
      await _tts.say('Đã đổi ví, bạn có thể tiếp tục thêm giao dịch mới.');
    } else {
      await _tts.say('Bạn có muốn kiểm tra lại trước khi lưu không?');
    }

    // ============================================
    // ✅ Tổng hợp phản hồi cuối
    await _tts.say(
      'Giao dịch: ${intent.note ?? "—"}, ${_vi.format(intent.amount ?? 0)} đồng${intent.walletName != null ? " từ ví ${intent.walletName}" : ""}.',
    );
  }

  /* ================= handlers ================= */

  void _onKey(String k) {
    setState(() {
      if (k == '.' && amount.contains('.')) return;
      amount += k;
    });
  }

  void _onBackspace() {
    if (amount.isEmpty) return;
    setState(() => amount = amount.substring(0, amount.length - 1));
  }

  Future<void> _submit() async {
    final isOut = type == FlowType.out;
    final amt = int.tryParse(amount) ?? 0;
    final selectedWalletId = (selectedWallet as dynamic)?.id ?? 0;
    final categoryId = selectedCategory?.id ?? 0;
    final incomeId = selectedIncome?.id ?? 0;

    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền > 0.')),
      );
      await _tts.say('Bạn muốn ghi số tiền bao nhiêu?');
      return;
    }

    if (isOut && categoryId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn danh mục.')),
      );
      await _tts.say('Bạn chưa chọn danh mục.');
      return;
    }

    if (!isOut && (selectedWalletId == 0 || incomeId == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn nguồn thu và ví.')),
      );
      await _tts.say('Bạn chưa chọn nguồn thu hoặc ví nạp tiền.');
      return;
    }

    final trimmedNote = _noteText.trim();
    final safeNote = trimmedNote.isEmpty
        ? null
        : (trimmedNote.length <= 300
            ? trimmedNote
            : trimmedNote.substring(0, 300));

    try {
      final tx = context.read<TransactionProvider>();

      await tx.create(
        isIncome: !isOut,
        bankId: selectedWalletId,
        categoryId: isOut ? categoryId : incomeId,
        amount: amt,
        content: safeNote,
        month: _selectedDate.month,
        year: _selectedDate.year,
        occurredAt: _selectedDate.toIso8601String(),
      );

      final ym = context.read<YearMonthProvider>().ym;

      await Future.wait([
        context
            .read<BankAccountProvider>()
            .fetch(year: ym.year, month: ym.month),
        context.read<IncomeProvider>().fetchAll(),
        context
            .read<BudgetsProvider>()
            .loadForMonth(year: ym.year, month: ym.month),
      ]);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOut
                  ? '✅ Đã ghi giao dịch chi thành công'
                  : '✅ Đã ghi giao dịch thu thành công',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Lỗi lưu giao dịch: $e')),
      );
    }
  }
  // ================= Pickers =================

  Future<void> _openIncomePicker() async {
    final incProv = context.read<IncomeProvider>();
    if (!incProv.loading && incProv.items.isEmpty) await incProv.fetchAll();

    final picked = await showModalBottomSheet<IncomeCategory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
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
              const Text('Chọn nguồn thu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final inc in incProv.items)
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.savings)),
                    title: Text(inc.title,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('Số tiền: ${_vi.format(inc.balance)}'),
                    trailing: (inc.id == selectedIncome?.id)
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () => Navigator.pop(context, inc),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (picked != null && mounted) setState(() => selectedIncome = picked);
  }

  Future<void> _openWalletPicker() async {
    final wProv = context.read<BankAccountProvider>();
    if (!wProv.loading && wProv.items.isEmpty) await wProv.fetch();

    final picked = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _WalletPickerSheet(
        items: wProv.items,
        selectedId: selectedWallet?.id,
        onTopUp: (wallet) async {},
      ),
    );

    if (picked != null && mounted) setState(() => selectedWallet = picked);
  }

  Future<void> _openCategoryPicker() async {
    final catProv = context.read<CategoryProvider>();
    if (!catProv.loading && catProv.items.isEmpty) await catProv.refresh();

    final picked = await showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _CategoryPickerSheet(
          items: catProv.items, selectedId: selectedCategory?.id),
    );

    if (picked != null && mounted) {
      setState(() => selectedCategory = picked);

      // 🧠 Học khi người dùng chọn thủ công danh mục
      final textToLearn = _originalVoiceInput?.trim() ??
          _noteText.trim(); // ← SỬA: Ưu tiên câu gốc

      if (textToLearn.isNotEmpty) {
        final store = VoiceSynonymStore();
        await store.load(); // ← THÊM: Load dữ liệu cũ
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
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  Future<void> _openNoteEditor() async {
    _noteCtl.text = _noteText;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
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
              const Text('Ghi chú',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
    if (result != null && mounted) setState(() => _noteText = result);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final dateLabel = DateFormat('dd/MM/yyyy').format(_selectedDate);

    const borderGrey = Color(0xFFDBD5C9);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ===== HEADER =====
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  _circleIcon(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.maybePop(context),
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
                      }),
                      borderColor: borderGrey,
                      selectedColor: const Color(0xFFF7CF54),
                    ),
                  ),
                ],
              ),
            ),

            // ===== MAIN CONTENT =====
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 28),
                    _amountText(context: context, type: type, amount: amount),
                    const SizedBox(height: 8),

                    InkWell(
                      onTap: _openNoteEditor,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 2)
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.notes_rounded,
                                  color: Colors.brown),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _noteText.isEmpty ? 'Thêm mô tả…' : _noteText,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _noteText.isEmpty
                                        ? Colors.black38
                                        : Colors.black87,
                                    fontWeight: _noteText.isEmpty
                                        ? FontWeight.w400
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ✅ Thêm phần hiển thị voice trạng thái
                    // ===== Voice caption =====
                    if (_listening || _voiceText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            _VoiceCaption(
                              text: _voiceText,
                              listening: _listening,
                            ),

                            const SizedBox(height: 8),

                            // ==========================
                            // 🔴 NÚT HỦY GIAO DỊCH
                            // ==========================
                            TextButton.icon(
                              onPressed: _cancelAll,
                              icon: const Icon(
                                Icons.cancel_rounded,
                                color: Colors.red,
                              ),
                              label: const Text(
                                'Hủy giao dịch',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // ===== TOOL CHIPS =====
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: Colors.white,
              child: Row(
                children: [
                  if (type == FlowType.in_) ...[
                    Expanded(
                      child: _ToolChip(
                        icon: Icons.savings_rounded,
                        label: selectedIncome?.title ?? 'Nguồn thu',
                        onTap: _openIncomePicker,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ToolChip(
                        icon: Icons.account_balance_wallet_rounded,
                        label: (selectedWallet?.name ??
                            selectedWallet?.title ??
                            t.cash),
                        onTap: _openWalletPicker,
                      ),
                    ),
                  ],
                  if (type == FlowType.out) ...[
                    Expanded(
                      child: _ToolChip(
                        icon: Icons.add_box_outlined,
                        label: selectedCategory?.name ?? t.category,
                        onTap: _openCategoryPicker,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ToolChip(
                        icon: Icons.account_balance_wallet_rounded,
                        label: (selectedWallet?.name ??
                            selectedWallet?.title ??
                            'Chọn tài khoản'),
                        onTap: _openWalletPicker,
                      ),
                    ),
                  ],
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ToolChip(
                      icon: Icons.calendar_month_rounded,
                      label: dateLabel,
                      onTap: _openDatePicker,
                    ),
                  ),
                ],
              ),
            ),

            // ===== KEYPAD =====
            _KeypadBar(
              onTap: _onKey,
              onBack: _onBackspace,
              onConfirm: _submit,
              onVoice: _toggleListening, // ✅ thêm xử lý voice
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountText({
    required BuildContext context,
    required FlowType type,
    required String amount,
  }) {
    final isOut = type == FlowType.out;
    final formattedCore = amount.isEmpty ? '0' : _formatVn(amount);
    final text = amount.isEmpty
        ? 'đ0'
        : (isOut ? '-đ$formattedCore' : '+đ$formattedCore');
    return Text(
      text,
      style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: isOut ? const Color(0xFFD64545) : const Color(0xFF1F9D4C),
          ),
    );
  }

  Widget _circleIcon({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: const Color(0xFFEDE6D9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.close_rounded, size: 18, color: Colors.black54),
        ),
      ),
    );
  }
}

/* ================= Voice Caption widget ================= */

class _VoiceCaption extends StatelessWidget {
  const _VoiceCaption({required this.text, required this.listening});
  final String text;
  final bool listening;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: 1.0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
            border: Border.all(color: const Color(0xFFE8E4DA)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                listening ? Icons.mic_rounded : Icons.record_voice_over_rounded,
                size: 18,
                color: listening ? const Color(0xFF2DBE60) : Colors.brown,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text.isEmpty ? 'Đang nghe…' : text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ================= Segmented ================= */
// (giữ nguyên như bạn đã có; code không đổi)

class _FlowSegmented extends StatelessWidget {
  const _FlowSegmented({
    required this.value,
    required this.onChanged,
    required this.borderColor,
    required this.selectedColor,
  });

  final FlowType value;
  final ValueChanged<FlowType> onChanged;
  final Color borderColor;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    const selectedText = TextStyle(
      fontWeight: FontWeight.w700,
      color: Colors.black87,
    );
    final normalText = const TextStyle(
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    );

    return Container(
      height: 44,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(28),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentTile(
              icon: Icons.call_made_rounded,
              label: t.moneyOut,
              selected: value == FlowType.out,
              selectedColor: selectedColor,
              textStyle: value == FlowType.out ? selectedText : normalText,
              onTap: () => onChanged(FlowType.out),
              left: true,
            ),
          ),
          Expanded(
            child: _SegmentTile(
              icon: Icons.call_received_rounded,
              label: t.moneyIn,
              selected: value == FlowType.in_,
              selectedColor: selectedColor,
              textStyle: value == FlowType.in_ ? selectedText : normalText,
              onTap: () => onChanged(FlowType.in_),
              right: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentTile extends StatelessWidget {
  const _SegmentTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.textStyle,
    required this.onTap,
    this.left = false,
    this.right = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color selectedColor;
  final TextStyle textStyle;
  final VoidCallback onTap;
  final bool left;
  final bool right;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      margin: EdgeInsets.only(
          left: left ? 4 : 2, right: right ? 4 : 2, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: selected ? selectedColor : Colors.transparent,
        borderRadius: BorderRadius.horizontal(
          left: left ? const Radius.circular(24) : Radius.zero,
          right: right ? const Radius.circular(24) : Radius.zero,
        ),
        boxShadow: selected
            ? const [
                BoxShadow(
                    color: Color(0x22A58B00),
                    offset: Offset(0, 2),
                    blurRadius: 4)
              ]
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.horizontal(
          left: left ? const Radius.circular(24) : Radius.zero,
          right: right ? const Radius.circular(24) : Radius.zero,
        ),
        onTap: onTap,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.black87),
              const SizedBox(width: 6),
              Text(label, style: textStyle),
            ],
          ),
        ),
      ),
    );
  }
}

/* ================= Tool chip / Keypad / Pickers ================= */
// (giữ nguyên phần còn lại như bạn đã có; mình không đổi logic UI cũ)
class _ToolChip extends StatelessWidget {
  const _ToolChip({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: Colors.brown.shade600),
                const SizedBox(width: 6),
                Expanded(
                  // 👈 thêm Expanded
                  child: Text(
                    label,
                    maxLines: 1, // 👈 không cho vượt 1 dòng
                    overflow: TextOverflow.ellipsis, // 👈 tự động rút gọn
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
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

class _KeypadBar extends StatelessWidget {
  const _KeypadBar({
    required this.onTap,
    required this.onBack,
    required this.onConfirm,
    this.onVoice,
  });

  final ValueChanged<String> onTap;
  final VoidCallback onBack;
  final VoidCallback onConfirm;
  final VoidCallback? onVoice;

  @override
  Widget build(BuildContext context) {
    const grey = Color(0xFFE9E7E5);
    const green = Color(0xFF2DBE60);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: const BoxDecoration(
        color: Color(0xFFF2F1EF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SizedBox(
        height: 260,
        child: Row(
          children: [
            // lưới phím
            Expanded(
              flex: 3,
              child: GridView.count(
                crossAxisCount: 3,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.25,
                children: [
                  for (final n in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
                    _PadKey(label: n, onTap: () => onTap(n)),
                  _PadKey(
                      icon: Icons.mic_none_rounded,
                      onTap: onVoice ?? () {},
                      bg: Colors.white),
                  _PadKey(label: '0', onTap: () => onTap('0')),
                  _PadKey(
                      icon: Icons.backspace_outlined, onTap: onBack, bg: grey),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // nút xác nhận cao
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: _PadKey(
                      bg: green,
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 36),
                      onTap: onConfirm,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PadKey extends StatelessWidget {
  const _PadKey({
    this.label,
    this.icon,
    this.child,
    required this.onTap,
    this.bg = Colors.white,
  });

  final String? label;
  final IconData? icon;
  final Widget? child;
  final VoidCallback onTap;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    final content = child ??
        (icon != null
            ? Icon(icon, color: Colors.black87)
            : Text(label!,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w600)));

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Center(child: content),
      ),
    );
  }
}

class _WalletPickerSheet extends StatelessWidget {
  const _WalletPickerSheet({
    required this.items,
    required this.selectedId,
    required this.onTopUp,
  });

  final List<dynamic> items;
  final dynamic selectedId;
  final Future<void> Function(dynamic wallet) onTopUp;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 12),
              const Text('Chọn ví / Nạp tiền',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final w in items)
                Card(
                  elevation: .4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const CircleAvatar(
                        child: Icon(Icons.account_balance_wallet_rounded)),
                    title: Text(
                      (w as dynamic).name ?? (w as dynamic).title ?? '—',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Row(children: [
                      const Text('Số dư: '),
                      MoneyText(
                          (w as dynamic).balance ?? (w as dynamic).amount ?? 0),
                    ]),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          tooltip: 'Nạp',
                          icon: const Icon(Icons.add_card_rounded),
                          onPressed: () => onTopUp(w),
                        ),
                        if ((w as dynamic).id == selectedId)
                          const Icon(Icons.check_rounded,
                              color: Color(0xFF2DBE60)),
                      ],
                    ),
                    onTap: () => Navigator.pop(context, w), // chọn ví
                  ),
                ),
            ],
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
    return SafeArea(
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
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            const Text('Chọn danh mục',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
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
                  color:
                      selected ? Colors.green.withOpacity(.08) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.pop(_, c),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.green.withOpacity(.1),
                          child: Text(first,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          c.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.green : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
