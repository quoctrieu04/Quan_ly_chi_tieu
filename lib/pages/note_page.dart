import 'dart:async';
import 'dart:io';

import 'package:chitieu/api/transaction/transaction_provider.dart';
import 'package:chitieu/core/voice/voice_synonym_store.dart';
import 'package:chitieu/utils/safe_ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chitieu/l10n/app_localizations.dart';

// Providers & models
import 'package:chitieu/api/category/category_provider.dart';
import 'package:chitieu/api/category/category_model.dart';
import 'package:chitieu/core/budget/budgets_provider.dart';

import 'package:chitieu/api/bankaccount/bank_account_provider.dart';
import 'package:chitieu/api/income/income_provider.dart';
import 'package:chitieu/api/income/income_model.dart';
import 'package:chitieu/api/in_invoice/in_invoice_provider.dart';
import 'package:chitieu/api/out_invoice/out_invoice_provider.dart';
import 'package:chitieu/api/out_invoice/out_invoice_model.dart';
import 'package:chitieu/financial_transaction/financial_transaction_provider.dart';

// VOICE
import 'package:chitieu/api/ai/voice_intent.dart';
import 'package:chitieu/utils/math_utils.dart';
import 'package:chitieu/pages/note_voice_controller.dart';
import 'package:chitieu/widgets/note/note_guide_dialog.dart';
import 'package:chitieu/widgets/note/tool_chip.dart';
import 'package:chitieu/widgets/note/wallet_picker_sheet.dart';
import 'package:chitieu/widgets/note/category_picker_sheet.dart';
import 'package:chitieu/widgets/note/voice_confirm_dialog.dart';


import 'package:chitieu/widgets/note/voice_caption.dart';
import 'package:chitieu/widgets/note/flow_segmented.dart';
import 'package:chitieu/widgets/note/keypad_bar.dart';

class NotePage extends StatefulWidget {
  final bool autoVoice;
  final bool autoCamera;
  const NotePage({super.key, this.autoVoice = false, this.autoCamera = false});

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  static const _noteGuideSeenKey = 'note_page_guide_seen_v1';

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
  late final NoteVoiceController _voiceController;
  String? _originalVoiceInput;

  @override
  void initState() {
    super.initState();
    _voiceController = NoteVoiceController();
    _voiceController.init();
    
    _voiceController.addListener(() {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showFirstUseGuideThenAutoAction();
    });

    Future.microtask(() async {
      final cats = context.read<CategoryProvider>();
      if (!cats.loading && cats.items.isEmpty) await cats.refresh();

      final wals = context.read<BankAccountProvider>();
      if (!wals.loading && wals.items.isEmpty) await wals.fetch();

      final inc = context.read<IncomeProvider>();
      if (!inc.loading && inc.items.isEmpty) await inc.fetchAll();
    });
  }

  Future<void> _showFirstUseGuideThenAutoAction() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_noteGuideSeenKey) ?? false;

    if (!seen && mounted) {
      final steps = <NoteGuideStep>[
        const NoteGuideStep(
          icon: Icons.edit_note_rounded,
          title: 'Nhập thường',
          message:
              'Chọn Thu hoặc Chi, nhập số tiền bằng bàn phím, ghi chú nội dung nếu cần rồi chọn danh mục và tài khoản trước khi lưu.',
        ),
        const NoteGuideStep(
          icon: Icons.mic_none_rounded,
          title: 'Nhập bằng giọng nói',
          message:
              'Hãy nói đủ số tiền, nội dung, danh mục hoặc nguồn thu và tài khoản. Ví dụ: "Chi 40 nghìn ăn uống bằng tiền mặt" hoặc "Thu 5 triệu lương vào ngân hàng".',
        ),
        const NoteGuideStep(
          icon: Icons.camera_alt_outlined,
          title: 'Chụp ảnh',
          message:
              'Chụp hóa đơn hoặc ảnh liên quan cho khoản chi. Ảnh sẽ được lưu kèm giao dịch; bạn vẫn cần kiểm tra số tiền, ghi chú, danh mục và tài khoản chi.',
        ),
        const NoteGuideStep(
          icon: Icons.account_balance_wallet_rounded,
          title: 'Danh mục và tài khoản',
          message:
              'Với khoản chi, hãy chọn Danh mục và Tài khoản chi. Với khoản thu, hãy chọn Nguồn thu và Tài khoản nhận tiền. Nếu voice nhận diện chưa đúng, bạn có thể chọn lại thủ công.',
        ),
      ];

      for (final step in steps) {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => NoteGuideDialog(step: step),
        );
      }

      await prefs.setBool(_noteGuideSeenKey, true);
    }

    if (!mounted) return;

    if (widget.autoVoice) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (mounted) _toggleListening();
    } else if (widget.autoCamera) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (mounted) _pickExpensePhoto();
    }
  }

  @override
  void dispose() {
    _noteCtl.dispose();
    _voiceController.dispose();
    super.dispose();
  }

  Future<void> _cancelAll() async {
    await _voiceController.stop();

    setState(() {
      _forceCancel = true;
      amount = '';
      selectedCategory = null;
      selectedWallet = null;
      selectedIncome = null;
      _noteText = '';
      _pickedPhoto = null;
    });

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
    await _voiceController.toggleListening(
      context: context,
      currentType: type,
      onEmptySpeech: () {
        if (!mounted) return;
        final cs = Theme.of(context).colorScheme;
        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel: 'voice_retry',
          barrierColor: Colors.black54,
          transitionDuration: const Duration(milliseconds: 300),
          transitionBuilder: (_, anim, __, child) {
            return ScaleTransition(
              scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
              child: FadeTransition(opacity: anim, child: child),
            );
          },
          pageBuilder: (ctx, _, __) {
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.18),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated mic icon
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              cs.primary.withValues(alpha: 0.15),
                              cs.primary.withValues(alpha: 0.06),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(
                          Icons.mic_off_rounded,
                          size: 36,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Không nghe rõ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Có vẻ mình chưa bắt được giọng nói của bạn.\nVui lòng thử lại nhé!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurface.withValues(alpha: 0.6),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _toggleListening();
                          },
                          icon: const Icon(Icons.mic_rounded, size: 20),
                          label: const Text(
                            'Thử lại',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Bỏ qua',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.45),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      onSuccess: (result) {
        if (!mounted) return;
        if (_forceCancel) {
          _forceCancel = false;
          return;
        }
        setState(() {
          _originalVoiceInput = _voiceController.voiceText;
          if (result.intent.amount != null) amount = result.intent.amount.toString();
          _noteText = result.intent.note ?? '';
          if (result.intent.type == VoiceIntentType.spend) type = FlowType.out;
          if (result.intent.type == VoiceIntentType.income) type = FlowType.in_;

          if (result.wallet != null) selectedWallet = result.wallet;
          if (result.category != null) selectedCategory = result.category;
        });
      },
      onReadyToSubmit: () async {
        if (!mounted) return;
        await _showVoiceConfirmDialog();
      },
    );
  }

  /// Hiển thị popup xác nhận trước khi lưu giao dịch giọng nói.
  Future<void> _showVoiceConfirmDialog() async {
    final amt = evaluateMathExpression(amount);
    if (amt <= 0) return;

    final wals = context.read<BankAccountProvider>().items;
    final cats = context.read<CategoryProvider>().items;
    final incs = context.read<IncomeProvider>().items;

    final result = await showVoiceConfirmDialog(
      context: context,
      type: type,
      amount: amt.toDouble(),
      note: _noteText,
      selectedWallet: selectedWallet,
      selectedCategory: selectedCategory,
      selectedIncome: selectedIncome,
      wallets: wals,
      categories: cats,
      incomes: incs,
    );

    if (result == null || !result.confirmed) return;
    if (!mounted) return;

    // Cập nhật lại thông tin đã chỉnh sửa từ dialog
    setState(() {
      if (result.wallet != null) selectedWallet = result.wallet;
      if (result.category != null) selectedCategory = result.category;
      if (result.income != null) selectedIncome = result.income;
    });

    await _submit();
  }

  /* ================= handlers ================= */

  void _onKey(String k) {
    setState(() {
      if (k == 'C') {
        amount = '';
        return;
      }
      if (k == '=') {
        amount = evaluateMathExpression(amount).toString();
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
      final amt = evaluateMathExpression(amount);
      final selectedWalletId = (selectedWallet as dynamic)?.id ?? 0;
      final categoryId = selectedCategory?.id ?? 0;
      final incomeId = selectedIncome?.id ?? 0;

      if (amt <= 0) {
        showAppSnackBar(context, 'Vui lòng nhập số tiền > 0.', isError: true);
        return;
      }

      if (isOut && selectedWalletId == 0) {
        showAppSnackBar(context, 'Vui lòng chọn tài khoản chi.', isError: true);
        return;
      }

      if (isOut && categoryId == 0) {
        showAppSnackBar(context, 'Vui lòng chọn danh mục.', isError: true);
        return;
      }

      if (!isOut && (selectedWalletId == 0 || incomeId == 0)) {
        showAppSnackBar(context, 'Vui lòng chọn nguồn thu và ví.',
            isError: true);
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
            ? 'Đã ghi giao dịch chi thành công'
            : 'Đã ghi giao dịch thu thành công',
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
      showAppSnackBar(context, 'Lỗi lưu giao dịch: $e', isError: true);
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
            color: cs.surface,
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
                        subtitle: Text('Số tiền: \${_vi.format(inc.balance)}'),
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
      builder: (_) => WalletPickerSheet(
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
      builder: (_) => CategoryPickerSheet(
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
        debugPrint('🧠 Đã học: "\$textToLearn" -> "\${picked.name}"');
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
            color: cs.surface,
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
    final mint = cs.primary;
    final color = active ? mint : cs.onSurface.withValues(alpha: .35);
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
                  ? mint.withValues(alpha: .08)
                  : (isDark
                      ? cs.surfaceContainerHigh
                      : const Color(0xFFF1F5F9)),
              shape: BoxShape.circle,
              border: Border.all(
                  color: active
                      ? mint.withValues(alpha: .2)
                      : (cs.outlineVariant.withValues(alpha: .08))),
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
            ToolChip(
              icon: Icons.category_rounded,
              label: selectedCategory?.name ?? 'Danh mục',
              active: selectedCategory != null,
              onTap: _openCategoryPicker,
            ),
            const SizedBox(width: 8),
            ToolChip(
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
            ToolChip(
              icon: Icons.savings_rounded,
              label: selectedIncome?.title ?? 'Nguồn thu',
              active: selectedIncome != null,
              onTap: _openIncomePicker,
            ),
            const SizedBox(width: 8),
            ToolChip(
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
          ToolChip(
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
        cs.primary;

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
                      Border.all(color: chipColor.withValues(alpha: .35), width: 1.2),
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
    final mint = cs.primary;
    final color =
        !hasAmount ? cs.onSurface.withValues(alpha: .15) : (isOut ? cs.error : mint);

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
                    color: color.withValues(alpha: .5))),
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
    final bgColor = cs.surface;
    final isOut = type == FlowType.out;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ▬▬▬ Top bar ▬▬▬
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
                            size: 18, color: cs.onSurface.withValues(alpha: .5)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FlowSegmented(
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
            // ▬▬▬ Content ▬▬▬
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
                          color: cs.onSurface.withValues(alpha: .35),
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
                            color: cs.surfaceTint.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _noteText,
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (_voiceController.isListening || _voiceController.voiceText.isNotEmpty) ...[
                      VoiceCaption(text: _voiceController.voiceText, listening: _voiceController.isListening),
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
            // ▬▬▬ Keypad ▬▬▬
            KeypadBar(
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
