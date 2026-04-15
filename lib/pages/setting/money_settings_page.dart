// lib/pages/setting/money_settings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/money/money_settings.dart';
import '../../core/money/money_settings_provider.dart';
import '../../core/money/money_formatter.dart';
import 'package:chitieu/l10n/app_localizations.dart';

class MoneySettingsPage extends StatelessWidget {
  const MoneySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final prov = context.watch<MoneySettingsProvider>();
    final s = prov.settings;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? cs.surface : const Color(0xFFFAFBFE);

    String sample(MoneySettings x) => MoneyFormatter(x).format(1234567.89);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? cs.surfaceContainerHigh : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          t.budgetSettingsTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark
                ? cs.outlineVariant.withOpacity(.1)
                : const Color(0xFFEEEFF3),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        children: [
          // ── Hero icon ──
          _buildHeroIcon(cs),
          const SizedBox(height: 24),

          // ── Currency ──
          _buildSectionTitle(t.currency, Icons.monetization_on_outlined, cs),
          const SizedBox(height: 10),
          _buildSettingCard(
            cs: cs,
            isDark: isDark,
            icon: Icons.attach_money_rounded,
            title: t.currency,
            subtitle: _currencyName(s),
            onTap: () async {
              final pick = await _pickCurrency(context, s, cs, isDark);
              if (pick != null) prov.update(pick);
            },
          ),
          const SizedBox(height: 12),

          // ── Number Format ──
          _buildSectionTitle(
              t.numberFormat, Icons.format_list_numbered_rounded, cs),
          const SizedBox(height: 10),
          _buildSettingCard(
            cs: cs,
            isDark: isDark,
            icon: Icons.numbers_rounded,
            title: t.numberFormat,
            subtitle: sample(s),
            onTap: () async {
              final pick = await _pickNumberFormat(context, s, cs, isDark);
              if (pick != null) prov.update(pick);
            },
          ),
          const SizedBox(height: 12),

          // ── Symbol Position ──
          _buildSectionTitle(
              t.currencySymbolPosition, Icons.swap_horiz_rounded, cs),
          const SizedBox(height: 10),
          _buildSettingCard(
            cs: cs,
            isDark: isDark,
            icon: Icons.text_format_rounded,
            title: t.currencySymbolPosition,
            subtitle: s.symbolPosition == CurrencySymbolPosition.after
                ? t.symbolAfter
                : t.symbolBefore,
            onTap: () async {
              final pick =
                  await _pickSymbolPosition(context, s, cs, isDark);
              if (pick != null) prov.update(pick);
            },
          ),
          const SizedBox(height: 12),

          // ── Preview ──
          _buildPreviewCard(cs, isDark, s),
          const SizedBox(height: 28),

          // ── Save Button ──
          _buildSaveButton(context, cs),
        ],
      ),
    );
  }

  // ═══════════════════════════
  //  HERO ICON
  // ═══════════════════════════
  Widget _buildHeroIcon(ColorScheme cs) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.elasticOut,
      builder: (_, v, child) => Transform.scale(
        scale: 0.5 + (0.5 * v),
        child: Opacity(opacity: v.clamp(0, 1), child: child),
      ),
      child: Center(
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primary.withOpacity(.12),
                cs.primary.withOpacity(.04),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: cs.primary.withOpacity(.15),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withOpacity(.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.tune_rounded,
            size: 32,
            color: cs.primary,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════
  //  SECTION TITLE
  // ═══════════════════════════
  Widget _buildSectionTitle(String title, IconData icon, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.primary.withOpacity(.7)),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withOpacity(.45),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════
  //  SETTING CARD
  // ═══════════════════════════
  Widget _buildSettingCard({
    required ColorScheme cs,
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isDark ? cs.surfaceContainerHigh : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? cs.outlineVariant.withOpacity(.08)
                  : const Color(0xFFECEDF2),
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: cs.primary, size: 22),
              ),
              const SizedBox(width: 14),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface.withOpacity(.45),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withOpacity(.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: cs.onSurface.withOpacity(.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════
  //  PREVIEW CARD
  // ═══════════════════════════
  Widget _buildPreviewCard(
      ColorScheme cs, bool isDark, MoneySettings s) {
    final formatted = MoneyFormatter(s).format(1234567.89);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withOpacity(.06),
            cs.tertiary.withOpacity(.04),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cs.primary.withOpacity(.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.preview_rounded,
                    color: cs.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Xem trước',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withOpacity(.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            formatted,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: cs.primary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Số tiền mẫu: 1.234.567,89',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withOpacity(.35),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════
  //  SAVE BUTTON
  // ═══════════════════════════
  Widget _buildSaveButton(BuildContext context, ColorScheme cs) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primary,
              Color.lerp(cs.primary, cs.tertiary, .3)!,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withOpacity(.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.check_rounded, size: 20),
          label: const Text(
            'Lưu cài đặt',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.3,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════
  //  BOTTOM SHEETS (styled)
  // ═══════════════════════════
  String _currencyName(MoneySettings s) =>
      '${s.currencyCode} - ${s.currencyCode == "VND" ? "Vietnamese Dong" : s.currencyCode} (${s.symbol})';

  Future<MoneySettings?> _pickCurrency(
      BuildContext ctx, MoneySettings s, ColorScheme cs, bool isDark) async {
    final opts = [MoneySettings.vnd, MoneySettings.usd];
    return showModalBottomSheet<MoneySettings>(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _StyledBottomSheet(
        title: 'Chọn loại tiền tệ',
        icon: Icons.monetization_on_outlined,
        cs: cs,
        isDark: isDark,
        children: opts
            .map((o) => _buildSheetOption(
                  label: _currencyName(o),
                  isSelected: o.currencyCode == s.currencyCode,
                  icon: Icons.paid_outlined,
                  cs: cs,
                  isDark: isDark,
                  onTap: () => Navigator.pop(ctx, o),
                ))
            .toList(),
      ),
    );
  }

  Future<MoneySettings?> _pickNumberFormat(
      BuildContext ctx, MoneySettings s, ColorScheme cs, bool isDark) {
    final vnd = s.currencyCode == 'VND';
    final variants = [
      s.copyWith(
          thousandSeparator: '.',
          decimalSeparator: ',',
          decimalDigits: vnd ? 0 : 2),
      s.copyWith(
          thousandSeparator: ',',
          decimalSeparator: '.',
          decimalDigits: vnd ? 0 : 2),
      s.copyWith(
          thousandSeparator: ' ',
          decimalSeparator: ',',
          decimalDigits: vnd ? 0 : 2),
    ];
    return showModalBottomSheet<MoneySettings>(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _StyledBottomSheet(
        title: 'Chọn định dạng số',
        icon: Icons.numbers_rounded,
        cs: cs,
        isDark: isDark,
        children: variants
            .map((o) => _buildSheetOption(
                  label: MoneyFormatter(o).format(1234567.89),
                  isSelected: (o.thousandSeparator == s.thousandSeparator &&
                      o.decimalSeparator == s.decimalSeparator),
                  icon: Icons.format_list_numbered_rounded,
                  cs: cs,
                  isDark: isDark,
                  onTap: () => Navigator.pop(ctx, o),
                ))
            .toList(),
      ),
    );
  }

  Future<MoneySettings?> _pickSymbolPosition(
      BuildContext ctx, MoneySettings s, ColorScheme cs, bool isDark) {
    final after = s.copyWith(symbolPosition: CurrencySymbolPosition.after);
    final before = s.copyWith(symbolPosition: CurrencySymbolPosition.before);
    final t = AppLocalizations.of(ctx)!;

    return showModalBottomSheet<MoneySettings>(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _StyledBottomSheet(
        title: 'Vị trí ký hiệu tiền',
        icon: Icons.swap_horiz_rounded,
        cs: cs,
        isDark: isDark,
        children: [
          _buildSheetOption(
            label: '${t.symbolBefore}  •  ${MoneyFormatter(before).format(1234567.89)}',
            isSelected: s.symbolPosition == CurrencySymbolPosition.before,
            icon: Icons.format_textdirection_l_to_r_rounded,
            cs: cs,
            isDark: isDark,
            onTap: () => Navigator.pop(ctx, before),
          ),
          _buildSheetOption(
            label: '${t.symbolAfter}  •  ${MoneyFormatter(after).format(1234567.89)}',
            isSelected: s.symbolPosition == CurrencySymbolPosition.after,
            icon: Icons.format_textdirection_r_to_l_rounded,
            cs: cs,
            isDark: isDark,
            onTap: () => Navigator.pop(ctx, after),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetOption({
    required String label,
    required bool isSelected,
    required IconData icon,
    required ColorScheme cs,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected
            ? cs.primary.withOpacity(.08)
            : (isDark ? cs.surfaceContainerHigh : Colors.white),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? cs.primary.withOpacity(.2)
                    : (isDark
                        ? cs.outlineVariant.withOpacity(.08)
                        : const Color(0xFFECEDF2)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cs.primary.withOpacity(.12)
                        : cs.surfaceContainerHighest.withOpacity(.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: isSelected
                        ? cs.primary
                        : cs.onSurface.withOpacity(.4),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? cs.primary
                          : cs.onSurface,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_rounded,
                        size: 16, color: cs.primary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════
//  STYLED BOTTOM SHEET
// ═══════════════════════════════════
class _StyledBottomSheet extends StatelessWidget {
  final String title;
  final IconData icon;
  final ColorScheme cs;
  final bool isDark;
  final List<Widget> children;

  const _StyledBottomSheet({
    required this.title,
    required this.icon,
    required this.cs,
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? cs.surface : const Color(0xFFFAFBFE),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Title row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: cs.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Options
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
