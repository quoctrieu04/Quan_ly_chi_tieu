// lib/api/ai/stt_service.dart
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// STT service: tối giản, ổn định, có metadata & API mở rộng.
/// - KHÔNG dùng MethodChannel (tránh MissingPluginException)
/// - Fallback: nếu không có final -> trả partial cuối cùng
/// - Chống treo bằng hard timeout
/// - Chọn locale tiếng Việt hợp lệ nếu có
/// - Giữ tương thích: listenOnce() vẫn trả String?
/// - Thêm API listenOnceEx() trả SttOutcome (kèm metadata)
class SttService {
  final stt.SpeechToText _stt = stt.SpeechToText();

  bool _inited = false;
  bool _hasPermission = false;
  String? _chosenLocaleId;

  /// Trạng thái đang nghe để tránh chồng phiên
  bool _listening = false;

  /// Guard phiên để chặn kết quả trễ từ phiên cũ chen vào
  int _sessionSeq = 0;

  /// Cấu hình mặc định (có thể đổi khi gọi)
  static const Duration kDefaultPauseFor = Duration(seconds: 5);
  static const Duration kDefaultListenFor = Duration(seconds: 15);
  static const Duration kDefaultHardTimeout = Duration(seconds: 22);
  static const int kDefaultMinChars = 2;

  Future<bool> init() async {
    try {
      _inited = await _stt.initialize(
        onStatus: (s) => _log('[STT status] $s'),
        onError: (e) => _log('[STT error] $e'),
      );
    } catch (e) {
      _log('[STT initialize EX] $e');
      _inited = false;
    }

    // FIX: hasPermission là bool, không phải Future
    _hasPermission = await _stt.hasPermission;
    _log('[STT] inited=$_inited, hasPermission=$_hasPermission');
    if (!_inited || !_hasPermission) return false;

    // Chọn locale VN hợp lệ nếu có
    try {
      final locales = await _stt.locales();
      _chosenLocaleId = _pickVietnameseLocaleId(locales);
      _log('[STT] chosenLocaleId=$_chosenLocaleId');
    } catch (e) {
      _log('[STT locales EX] $e');
      _chosenLocaleId = null;
    }
    return true;
  }

  bool get isAvailable => _inited && _hasPermission;

  Future<void> stop() async {
    try {
      await _stt.stop();
    } finally {
      _listening = false;
    }
  }

  Future<void> cancel() async {
    try {
      await _stt.cancel();
    } finally {
      _listening = false;
    }
  }

  Future<void> dispose() async {
    await stop();
  }

  /// API cũ (giữ tương thích): trả về text (final hoặc partial), null nếu fail
  Future<String?> listenOnce({
    String? localeId,
    Duration pauseFor = kDefaultPauseFor,
    Duration listenFor = kDefaultListenFor,
    Duration hardTimeout = kDefaultHardTimeout,
    void Function(String text)? onPartial,
    int maxRetries = 0,
    int minChars = kDefaultMinChars,
  }) async {
    final out = await listenOnceEx(
      localeId: localeId,
      pauseFor: pauseFor,
      listenFor: listenFor,
      hardTimeout: hardTimeout,
      onPartial: onPartial,
      maxRetries: maxRetries,
      minChars: minChars,
    );
    return out.text;
  }

  /// API mới: trả cả metadata (có final không, có timeout không, locale dùng gì…)
  Future<SttOutcome> listenOnceEx({
    String? localeId,
    Duration pauseFor = kDefaultPauseFor,
    Duration listenFor = kDefaultListenFor,
    Duration hardTimeout = kDefaultHardTimeout,
    void Function(String text)? onPartial,
    int maxRetries = 0,
    int minChars = kDefaultMinChars,
  }) async {
    if (!isAvailable) {
      final ok = await init();
      if (!ok) {
        return const SttOutcome(
          text: null,
          fromFinal: false,
          timedOut: false,
          localeUsed: null,
          earlyStop: false,
        );
      }
    }

    // Chặn chồng phiên nghe
    if (_listening) {
      _log('[listenOnceEx] Already listening; cancel previous.');
      await cancel();
    }

    // Ưu tiên ép locale Việt; caller có thể truyền localeId để override
    String? effectiveLocale = localeId ?? _chosenLocaleId;

    // chạy n lần (retry nếu rỗng/quá ngắn)
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      final outcome = await _oneShot(
        effectiveLocale: effectiveLocale,
        pauseFor: pauseFor,
        listenFor: listenFor,
        hardTimeout: hardTimeout,
        onPartial: onPartial,
        minChars: minChars,
      );
      // Nếu có đủ ký tự thì trả luôn
      if ((outcome.text ?? '').trim().length >= minChars) return outcome;

      // Lần tiếp theo: bỏ ép locale để hệ thống tự chọn
      if (attempt < maxRetries && effectiveLocale != null) {
        _log('[listenOnceEx] Retry with default system locale');
        effectiveLocale = null;
      }
    }

    // hết retry
    return SttOutcome(
      text: null,
      fromFinal: false,
      timedOut: false,
      localeUsed: effectiveLocale,
      earlyStop: false,
    );
  }

  /// Thực thi 1 lượt nghe; trả về cả metadata
  Future<SttOutcome> _oneShot({
    required String? effectiveLocale,
    required Duration pauseFor,
    required Duration listenFor,
    required Duration hardTimeout,
    required void Function(String text)? onPartial,
    required int minChars,
  }) async {
    _listening = true;

    final completer = Completer<SttOutcome>();
    final int sessionId = ++_sessionSeq; // tạo mã phiên
    String? lastPartial;
    String? lastFinal;
    bool endedByStatus = false; // kết thúc do status notListening/done
    bool timedOut = false;

    // Helper: complete an toàn theo session
    void safeComplete(SttOutcome out) {
      if (!completer.isCompleted && sessionId == _sessionSeq) {
        _listening = false;
        completer.complete(out);
      }
    }

    // Hook status: nếu engine kết thúc mà không có final, trả partial
    final prevStatus = _stt.statusListener;
    void statusHook(String s) {
      _log('[STT status] $s');
      if ((s == 'notListening' || s == 'done') && !completer.isCompleted) {
        endedByStatus = true;
        final ret = (lastFinal?.trim().isNotEmpty == true)
            ? lastFinal
            : (lastPartial?.trim().isNotEmpty == true ? lastPartial : null);
        _log('[listenOnceEx] status finalize -> return: "${ret ?? ''}"');
        safeComplete(SttOutcome(
          text: ret,
          fromFinal: lastFinal?.isNotEmpty == true,
          timedOut: false,
          localeUsed: effectiveLocale,
          earlyStop: true,
        ));
      }
    }
    _stt.statusListener = (s) {
      prevStatus?.call(s);
      statusHook(s);
    };

    // Hard timeout (phòng treo)
    final killer = Timer(hardTimeout, () {
      if (!completer.isCompleted) {
        _log('[listenOnceEx] hardTimeout -> stop()');
        timedOut = true;
        _stt.stop();
        final ret = (lastFinal?.trim().isNotEmpty == true)
            ? lastFinal
            : (lastPartial?.trim().isNotEmpty == true ? lastPartial : null);
        safeComplete(SttOutcome(
          text: ret,
          fromFinal: lastFinal?.isNotEmpty == true,
          timedOut: true,
          localeUsed: effectiveLocale,
          earlyStop: false,
        ));
      }
    });

    try {
      await _stt.listen(
        localeId: effectiveLocale, // null -> mặc định hệ thống
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
        pauseFor: pauseFor,       // thời gian im lặng để auto-finalize
        listenFor: listenFor,     // giới hạn tối đa 1 lượt
        onResult: (res) {
          final txt = res.recognizedWords.trim();
          if (!res.finalResult) {
            if (txt.isNotEmpty) {
              lastPartial = txt;
              onPartial?.call(txt);
            }
            return;
          }
          lastFinal = txt;
          safeComplete(SttOutcome(
            text: txt,
            fromFinal: true,
            timedOut: false,
            localeUsed: effectiveLocale,
            earlyStop: false,
          ));
        },
        onSoundLevelChange: (level) {
          // Bạn có thể dùng level để vẽ UI hoặc debug VAD
          // _log('[level] $level');
        },
      );
    } catch (e) {
      _log('[listenOnceEx] listen EX: $e');
      safeComplete(SttOutcome(
        text: lastPartial,
        fromFinal: false,
        timedOut: timedOut,
        localeUsed: effectiveLocale,
        earlyStop: endedByStatus,
      ));
    }

    final out = await completer.future;
    killer.cancel();

    // restore status listener cũ
    _stt.statusListener = prevStatus;

    return out;
  }

  /// Lấy danh sách locale khả dụng (tiện debug/hiển thị cài đặt)
  Future<List<stt.LocaleName>> availableLocales() async {
    if (!isAvailable) {
      final ok = await init();
      if (!ok) return const [];
    }
    try {
      return await _stt.locales();
    } catch (_) {
      return const [];
    }
  }

  /// Gợi ý locale tiếng Việt tốt nhất (nếu muốn hiển thị cho user chọn)
  Future<String?> preferredVietnameseLocale() async {
    final list = await availableLocales();
    return _pickVietnameseLocaleId(list);
  }

  String? _pickVietnameseLocaleId(List<stt.LocaleName> locales) {
    if (locales.isEmpty) return null;
    final exact = locales.firstWhere(
      (l) => l.localeId.toLowerCase() == 'vi_vn' || l.localeId.toLowerCase() == 'vi-vn',
      orElse: () => stt.LocaleName('', ''),
    );
    if (exact.localeId.isNotEmpty) return exact.localeId;
    final startsWithVi = locales.firstWhere(
      (l) => l.localeId.toLowerCase().startsWith('vi'),
      orElse: () => stt.LocaleName('', ''),
    );
    if (startsWithVi.localeId.isNotEmpty) return startsWithVi.localeId;
    return null;
  }

  void _log(Object? o) {
    // ignore: avoid_print
    print(o);
  }
}

/// Kết quả 1 lượt nghe (API mở rộng)
class SttOutcome {
  final String? text;        // kết quả (final hoặc partial)
  final bool fromFinal;      // true nếu là finalResult
  final bool timedOut;       // true nếu kết thúc do hard timeout
  final String? localeUsed;  // locale thực tế dùng
  final bool earlyStop;      // true nếu stop do status (notListening/done) trước khi có final

  const SttOutcome({
    required this.text,
    required this.fromFinal,
    required this.timedOut,
    required this.localeUsed,
    required this.earlyStop,
  });

  @override
  String toString() {
    return 'SttOutcome(text: "$text", fromFinal: $fromFinal, timedOut: $timedOut, '
        'localeUsed: $localeUsed, earlyStop: $earlyStop)';
  }
}
