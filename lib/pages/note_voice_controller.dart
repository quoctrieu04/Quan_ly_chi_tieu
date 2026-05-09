import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diacritic/diacritic.dart';

import 'package:chitieu/api/ai/stt_service.dart';
import 'package:chitieu/api/ai/voice_intent.dart';
import 'package:chitieu/core/voice/voice_synonym_store.dart';
import 'package:chitieu/api/category/category_provider.dart';
import 'package:chitieu/api/category/category_model.dart';
import 'package:chitieu/api/bankaccount/bank_account_provider.dart';
import 'package:chitieu/widgets/note/flow_segmented.dart';

class NoteVoiceResult {
  final VoiceIntent intent;
  final dynamic wallet;
  final Category? category;
  
  NoteVoiceResult({required this.intent, this.wallet, this.category});
}

class NoteVoiceController extends ChangeNotifier {
  final SttService _stt = SttService();
  final VoiceIntentParser _parser = VoiceIntentParser();

  bool isListening = false;
  String voiceText = '';

  Future<void> init() async {
    await _stt.init();
  }

  @override
  void dispose() {
    _stt.dispose();
    super.dispose();
  }

  Future<void> stop() async {
    await _stt.stop();
    isListening = false;
    voiceText = '';
    notifyListeners();
  }

  Future<void> toggleListening({
    required BuildContext context,
    required FlowType currentType,
    required VoidCallback onEmptySpeech,
    required Function(NoteVoiceResult result) onSuccess,
    required VoidCallback onReadyToSubmit,
  }) async {
    if (isListening) {
      await stop();
      return;
    }

    final voiceStore = VoiceSynonymStore();
    await voiceStore.load();

    isListening = true;
    voiceText = '';
    notifyListeners();

    final outcome = await _stt.listenOnceEx(
      onPartial: (text) {
        voiceText = text;
        notifyListeners();
      },
    );

    final text = outcome.text?.trim() ?? '';
    voiceText = text;
    isListening = false;
    notifyListeners();

    if (text.isEmpty) {
      onEmptySpeech();
      return;
    }

    final intent = await _parser.parse(text, context: context);
    debugPrint('🎯 Voice intent: $intent');

    dynamic foundWallet;
    final wals = context.read<BankAccountProvider>().items;
    if (wals.isNotEmpty) {
      if (intent.walletName != null) {
        final target = intent.walletName!.toLowerCase();
        try {
          foundWallet = wals.firstWhere((w) {
            final name = (w.name ?? '').toLowerCase();
            final title = (w.title ?? '').toLowerCase();
            return name.contains(target) || title.contains(target);
          });
          debugPrint('🎯 Ví được nói: ${foundWallet.name ?? foundWallet.title}');
          await voiceStore.learnFromUtterance(
            intent.walletName!,
            'wallet:${foundWallet.name ?? foundWallet.title}',
          );
        } catch (_) {
          foundWallet = null;
        }
      }
      foundWallet ??= wals.reduce((a, b) => ((a.balance ?? 0) >= (b.balance ?? 0)) ? a : b);
    }

    Category? foundCategory;
    FlowType resolvedType = currentType;
    if (intent.type == VoiceIntentType.spend) resolvedType = FlowType.out;
    if (intent.type == VoiceIntentType.income) resolvedType = FlowType.in_;

    if (resolvedType == FlowType.out && intent.categoryName != null) {
      final cats = context.read<CategoryProvider>().items;
      if (cats.isNotEmpty) {
        final input = removeDiacritics(intent.categoryName!.toLowerCase());
        try {
          foundCategory = cats.firstWhere(
            (c) {
              final name = removeDiacritics(c.name.toLowerCase());
              return name == input ||
                  name.contains(input) ||
                  input.contains(name);
            },
          );
        } catch (_) {
          foundCategory = null;
        }

        if (foundCategory != null) {
          debugPrint('📚 Nhận diện danh mục: ${foundCategory.name}');
        } else {
          debugPrint('⚠️ Không tìm thấy danh mục "${intent.categoryName}".');
        }
      }
    }

    onSuccess(NoteVoiceResult(
      intent: intent,
      wallet: foundWallet,
      category: foundCategory,
    ));

    final amt = intent.amount ?? 0;
    if (amt > 0 &&
        foundWallet != null &&
        ((resolvedType == FlowType.out && foundCategory != null) ||
            (resolvedType == FlowType.in_))) {
      onReadyToSubmit();
    }
  }
}
