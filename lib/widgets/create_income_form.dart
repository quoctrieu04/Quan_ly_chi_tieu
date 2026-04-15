import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chitieu/l10n/app_localizations.dart';
import 'package:chitieu/api/income/income_provider.dart';
import 'package:chitieu/core/date/year_month_provider.dart';

class CreateIncomeForm extends StatefulWidget {
  const CreateIncomeForm({super.key});

  @override
  State<CreateIncomeForm> createState() => _CreateIncomeFormState();
}

class _CreateIncomeFormState extends State<CreateIncomeForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _saving = true);

    final incomeProv = context.read<IncomeProvider>();
    final ym = context.read<YearMonthProvider>().ym;

    final ok = await incomeProv.createIncomeCategory(
      _nameController.text.trim(),
      year: ym.year,
      month: ym.month,
    );

    setState(() => _saving = false);

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context, true);
      messenger.hideCurrentMaterialBanner();
      messenger.showMaterialBanner(
        MaterialBanner(
          content: Text(
              '✅ ${t.walletCreated.isNotEmpty ? t.walletCreated : 'Đã tạo khoản thu tháng ${ym.month}/${ym.year}!'}'),
          leading: const Icon(Icons.check_circle, color: Colors.white),
          backgroundColor: Theme.of(context).colorScheme.primary,
          contentTextStyle: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 16,
          ),
          actions: [
            TextButton(
              onPressed: () => messenger.hideCurrentMaterialBanner(),
              child: Text(
                'OK',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary),
              ),
            ),
          ],
        ),
      );
      Future.delayed(
          const Duration(seconds: 2), messenger.hideCurrentMaterialBanner);
    } else {
      final err = incomeProv.error ?? t.somethingWrong;
      messenger.showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? cs.surface : const Color(0xFFFAFBFE);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Handle bar ──
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: cs.onSurface.withOpacity(.12),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── Header ──
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF2E7D32).withOpacity(.12),
                                const Color(0xFF2E7D32).withOpacity(.04),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color:
                                  const Color(0xFF2E7D32).withOpacity(.1),
                            ),
                          ),
                          child: const Icon(
                              Icons.attach_money_rounded,
                              color: Color(0xFF2E7D32),
                              size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tạo khoản thu',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Thêm nguồn thu nhập mới',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: cs.onSurface.withOpacity(.4),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // ── Name field ──
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? cs.surfaceContainerHigh
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? cs.outlineVariant.withOpacity(.08)
                              : const Color(0xFFECEDF2),
                        ),
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(
                              color: Colors.black.withOpacity(.015),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Tên khoản thu',
                          labelStyle: TextStyle(
                            color: cs.primary.withOpacity(.7),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          hintText: 'VD: Tiền lương, Freelance...',
                          hintStyle: TextStyle(
                            color: cs.onSurface.withOpacity(.25),
                            fontWeight: FontWeight.w400,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding:
                              const EdgeInsets.fromLTRB(18, 16, 18, 16),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(
                                left: 14, right: 10),
                            child: Icon(Icons.label_outline_rounded,
                                color: cs.primary, size: 22),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: cs.primary, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: cs.error, width: 1.5),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: cs.error, width: 2),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Vui lòng nhập tên khoản thu'
                                : null,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Save button ──
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: _saving
                              ? null
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    cs.primary,
                                    Color.lerp(
                                        cs.primary, cs.tertiary, .3)!,
                                  ],
                                ),
                          boxShadow: _saving
                              ? []
                              : [
                                  BoxShadow(
                                    color:
                                        cs.primary.withOpacity(.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _submit,
                          icon: AnimatedSwitcher(
                            duration:
                                const Duration(milliseconds: 200),
                            transitionBuilder: (child, anim) =>
                                FadeTransition(
                                    opacity: anim, child: child),
                            child: _saving
                                ? const SizedBox(
                                    key: ValueKey('spin'),
                                    width: 20,
                                    height: 20,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.check_rounded,
                                    key: ValueKey('icon'),
                                    size: 20,
                                  ),
                          ),
                          label: Text(
                            _saving ? 'Đang lưu...' : 'Lưu khoản thu',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: 0.3,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            disabledBackgroundColor:
                                cs.primary.withOpacity(.3),
                            disabledForegroundColor:
                                Colors.white.withOpacity(.7),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
