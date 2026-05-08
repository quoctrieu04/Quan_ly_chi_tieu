import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/auth_provider.dart';
import '../../auth/login.dart';
import 'package:chitieu/core/theme/app_colors.dart';
import 'money_settings_page.dart';
import 'settings_provider.dart';
import '../profile_page.dart'; // 👈 trang thông tin tài khoản
import 'package:chitieu/widgets/app_page_header.dart';

// import file i18n đã generate trong lib/l10n
import 'package:chitieu/l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, this.onReplayGuide});

  final VoidCallback? onReplayGuide;

  Future<void> _openProfileOrLogin(BuildContext context) async {
    final auth = context.read<AuthProvider>();

    if (!auth.isAuthenticated) {
      // mở trang đăng nhập trước
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );

      // nếu đăng nhập xong thì mở luôn trang hồ sơ
      if (!context.mounted) return;
      if (context.read<AuthProvider>().isAuthenticated) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
      }
    } else {
      // đã đăng nhập → mở trang hồ sơ
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final name = auth.user?['name'] ?? '';
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? cs.surface : AppColors.background;

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(child: _buildHeader(context, cs, isDark)),
            // ── Body ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    // ── Profile card ──
                    _buildProfileCard(context, cs, isDark, auth, name, t),
                    const SizedBox(height: 16),

                    // ── Appearance section ──
                    _buildSectionTitle('Giao diện', Icons.palette_outlined, cs),
                    const SizedBox(height: 10),
                    _buildSettingsCard(cs, isDark, [
                      // Language
                      _buildSettingRow(
                        icon: Icons.language_rounded,
                        label: t.language,
                        cs: cs,
                        trailing: _buildChipDropdown<Locale>(
                          value: settings.locale,
                          items: const [
                            DropdownMenuItem(
                                value: Locale('vi'), child: Text('Tiếng Việt')),
                            DropdownMenuItem(
                                value: Locale('en'), child: Text('English')),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              context.read<SettingsProvider>().setLocale(v);
                            }
                          },
                          cs: cs,
                          isDark: isDark,
                        ),
                      ),
                      _thinDivider(cs, isDark),
                      _buildActionRow(
                        icon: Icons.payments_outlined,
                        label: 'Định dạng tiền',
                        cs: cs,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MoneySettingsPage(),
                            ),
                          );
                        },
                      ),
                      _thinDivider(cs, isDark),
                      // Theme toggle
                      _buildSettingRow(
                        icon: isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        label: t.brightness,
                        cs: cs,
                        trailing: _buildPremiumSwitch(
                          value: settings.themeMode == ThemeMode.light,
                          onChanged: (isLight) => context
                              .read<SettingsProvider>()
                              .toggleTheme(isLight),
                          cs: cs,
                        ),
                      ),
                      _thinDivider(cs, isDark),
                      // Font size
                      _buildActionRow(
                        icon: Icons.text_fields_rounded,
                        label: t.fontSize,
                        cs: cs,
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => _FontSizeSliderSheet(
                                initialScale: settings.textScale),
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // ── Theme colors ──
                    _buildSectionTitle(t.color, Icons.color_lens_outlined, cs),
                    const SizedBox(height: 10),
                    _buildColorPicker(context, settings, cs, isDark),
                    const SizedBox(height: 20),

                    // ── Account section ──
                    _buildSectionTitle(
                        'Tài khoản', Icons.person_outline_rounded, cs),
                    const SizedBox(height: 10),
                    _buildSettingsCard(cs, isDark, [
                      _buildActionRow(
                        icon: Icons.help_outline_rounded,
                        label: 'Xem lại hướng dẫn sử dụng',
                        cs: cs,
                        onTap: onReplayGuide,
                      ),
                      _thinDivider(cs, isDark),
                      _buildActionRow(
                        icon: Icons.lock_outline_rounded,
                        label: t.changePassword,
                        cs: cs,
                        onTap: () {
                          // TODO: mở form đổi mật khẩu
                        },
                      ),
                      _thinDivider(cs, isDark),
                      _buildActionRow(
                        icon: Icons.shield_outlined,
                        label: t.policy,
                        cs: cs,
                        onTap: () {
                          // TODO: mở trang policy
                        },
                      ),
                    ]),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════
  //  HEADER
  // ═══════════════════════════
  Widget _buildHeader(BuildContext context, ColorScheme cs, bool isDark) {
    return AppPageHeader(
      icon: Icons.settings_rounded,
      title: 'Cài đặt',
      actions: [
        HeaderIconButton(
          icon: Icons.person_outline_rounded,
          tooltip: 'Tài khoản',
          onPressed: () => _openProfileOrLogin(context),
        ),
      ],
    );
  }

  // ═══════════════════════════
  //  PROFILE CARD
  // ═══════════════════════════
  Widget _buildProfileCard(BuildContext context, ColorScheme cs, bool isDark,
      AuthProvider auth, String name, AppLocalizations t) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openProfileOrLogin(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primary,
                Color.lerp(cs.primary, Colors.white, 0.2)!,
                Color.lerp(cs.primary, Colors.black, 0.1)!,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withOpacity(.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(.4),
                    width: 2,
                  ),
                ),
                child: Icon(
                  auth.isAuthenticated
                      ? Icons.person_rounded
                      : Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Name + status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isNotEmpty ? name : t.userNamePlaceholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        auth.isAuthenticated
                            ? 'Đã đăng nhập'
                            : 'Chưa đăng nhập',
                        style: TextStyle(
                          color: Colors.white.withOpacity(.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  auth.isAuthenticated
                      ? Icons.arrow_forward_ios_rounded
                      : Icons.login_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
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
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withOpacity(.5),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════
  //  SETTINGS CARD
  // ═══════════════════════════
  Widget _buildSettingsCard(
      ColorScheme cs, bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : Colors.white,
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
      child: Column(children: children),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String label,
    required ColorScheme cs,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: cs.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String label,
    required ColorScheme cs,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: cs.primary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: cs.onSurface.withOpacity(.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thinDivider(ColorScheme cs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 1,
        color: isDark
            ? cs.outlineVariant.withOpacity(.08)
            : const Color(0xFFF2F3F7),
      ),
    );
  }

  // ═══════════════════════════
  //  COLOR PICKER
  // ═══════════════════════════
  Widget _buildColorPicker(BuildContext context, SettingsProvider settings,
      ColorScheme cs, bool isDark) {
    const colors = <Color>[
      AppColors.primary, // Mint (Mặc định)
      AppColors.primaryLight,
      Color(0xFF7BB7F7),
      Color(0xFF8FD8FF),
      Color(0xFF7DD3C7),
      Color(0xFF9FB7FF),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : Colors.white,
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final c in colors) _buildColorDot(context, c, settings, cs),
        ],
      ),
    );
  }

  Widget _buildColorDot(BuildContext context, Color c,
      SettingsProvider settings, ColorScheme cs) {
    final isSelected = settings.seed == c;
    return GestureDetector(
      onTap: () => context.read<SettingsProvider>().setSeed(c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: isSelected ? 44 : 38,
        height: isSelected ? 44 : 38,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: isSelected ? 3 : 0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: c.withOpacity(.4),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: c.withOpacity(.15),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: isSelected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
            : null,
      ),
    );
  }

  // ═══════════════════════════
  //  PREMIUM COMPONENTS
  // ═══════════════════════════
  Widget _buildChipDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required ColorScheme cs,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.primary,
          ),
          icon: Icon(Icons.expand_more_rounded, size: 18, color: cs.primary),
          borderRadius: BorderRadius.circular(14),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildPremiumSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
    required ColorScheme cs,
  }) {
    return Switch.adaptive(
      value: value,
      onChanged: onChanged,
      activeColor: cs.primary,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

// ═══════════════════════════
//  FONT SIZE SLIDER SHEET
// ═══════════════════════════
class _FontSizeSliderSheet extends StatefulWidget {
  final double initialScale;
  const _FontSizeSliderSheet({required this.initialScale});

  @override
  State<_FontSizeSliderSheet> createState() => _FontSizeSliderSheetState();
}

class _FontSizeSliderSheetState extends State<_FontSizeSliderSheet> {
  late double _scale;

  @override
  void initState() {
    super.initState();
    _scale = widget.initialScale;
    if (_scale < 0.8) _scale = 0.8;
    if (_scale > 1.3) _scale = 1.3;
  }

  String _getLabel() {
    if (_scale < 0.95) return 'Nhỏ';
    if (_scale > 1.15) return 'Lớn';
    return 'Bình thường';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Điều chỉnh cỡ chữ',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Text(
              _getLabel(),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text('A',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white54 : Colors.black54)),
                const SizedBox(width: 8),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: Theme.of(context).colorScheme.primary,
                      inactiveTrackColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.2),
                      thumbColor: Theme.of(context).colorScheme.primary,
                      overlayColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      trackHeight: 6,
                    ),
                    child: Slider(
                      value: _scale,
                      min: 0.8,
                      max: 1.3,
                      divisions: 5, // Tương ứng: 0.8, 0.9, 1.0, 1.1, 1.2, 1.3
                      onChanged: (val) {
                        setState(() => _scale = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('A',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withOpacity(0.05)),
              ),
              child: Text(
                'Đây là văn bản xem trước.\nBạn có thể kéo thanh trượt để thấy cỡ chữ thay đổi ngay lập tức.',
                textAlign: TextAlign.center,
                // textScaleFactor is deprecated, but textScaler is the new one
                textScaler: TextScaler.linear(_scale),
                style: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                context.read<SettingsProvider>().setTextScale(_scale);
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Lưu thay đổi',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
