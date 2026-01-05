// lib/api/ai/tts_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _inited = false;

  Future<void> init() async {
    if (_inited) return;
    // chờ đọc xong mới trả
    await _tts.awaitSpeakCompletion(true);

    // chọn tiếng Việt nếu có, fallback mặc định
    try {
      final voices = await _tts.getVoices;
      final vi = (voices as List)
          .cast<Map>()
          .firstWhere(
            (v) => (v['locale']?.toString().toLowerCase().startsWith('vi') ?? false),
            orElse: () => {},
          );
      if (vi.isNotEmpty) {
        await _tts.setVoice({
          'name': vi['name'],
          'locale': vi['locale'],
        });
        await _tts.setLanguage(vi['locale']);
      } else {
        await _tts.setLanguage(Platform.isIOS ? 'vi-VN' : 'vi_VN');
      }
    } catch (_) {
      await _tts.setLanguage(Platform.isIOS ? 'vi-VN' : 'vi_VN');
    }

    // tốc độ & cao độ dễ nghe
    await _tts.setSpeechRate(Platform.isIOS ? 0.48 : 0.52);
    await _tts.setPitch(1.0);
    _inited = true;
  }

  Future<void> say(String text) async {
  final c = Completer<void>();

  // Khi TTS đọc xong → gọi complete()
  _tts.setCompletionHandler(() {
    if (!c.isCompleted) c.complete();
  });

  await _tts.speak(text);

  // CHỜ TTS đọc xong thật sự
  return c.future;
}


  Future<void> stop() => _tts.stop();

  Future<void> dispose() async {
    await _tts.stop();
  }
}
