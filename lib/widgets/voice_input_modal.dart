import 'package:flutter/material.dart';
import '../services/app_language_service.dart';
import '../services/speech_service.dart';
import '../theme/app_theme.dart';

class VoiceInputModal extends StatefulWidget {
  const VoiceInputModal({
    super.key,
    required this.onResult,
    this.initialText = '',
    this.title,
    this.hint,
  });

  final void Function(String text) onResult;
  final String initialText;
  final String? title;
  final String? hint;

  static Future<String?> show(
    BuildContext context, {
    String initialText = '',
    String? title,
    String? hint,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VoiceInputModal(
        initialText: initialText,
        title: title,
        hint: hint,
        onResult: (text) => Navigator.of(ctx).pop(text),
      ),
    );
  }

  @override
  State<VoiceInputModal> createState() => _VoiceInputModalState();
}

class _VoiceInputModalState extends State<VoiceInputModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  String _spokenText = '';
  bool _isListening = false;
  bool _error = false;
  late AppLanguage _selectedSpeechLang;

  @override
  void initState() {
    super.initState();
    _spokenText = widget.initialText;
    _selectedSpeechLang = AppLanguageService.instance.currentLanguage;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _startListening();
  }

  @override
  void dispose() {
    SpeechService.instance.stop();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _error = false;
    });

    try {
      final available = await SpeechService.instance.initialize();
      if (!available) {
        if (mounted) {
          setState(() {
            _isListening = false;
            _error = true;
          });
        }
        return;
      }

      await SpeechService.instance.listen(
        localeId: _selectedSpeechLang.speechLocaleId,
        onResult: (text, isFinal) {
          if (!mounted) return;
          setState(() {
            _spokenText = text;
            if (isFinal) {
              _isListening = false;
            }
          });
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _error = true;
        });
      }
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await SpeechService.instance.stop();
      if (mounted) setState(() => _isListening = false);
    } else {
      await _startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title ?? AppLanguageService.t('voice_search');
    final hint = widget.hint ?? AppLanguageService.t('speech_listening_hint');

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header with Language Badge
          Row(
            children: [
              const Icon(Icons.mic_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              // Language switch button
              PopupMenuButton<AppLanguage>(
                initialValue: _selectedSpeechLang,
                tooltip: AppLanguageService.t('change_language'),
                onSelected: (lang) {
                  setState(() => _selectedSpeechLang = lang);
                  _startListening();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.language_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        _selectedSpeechLang.nativeName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
                itemBuilder: (ctx) => AppLanguageService.supportedLanguages.map((l) {
                  return PopupMenuItem(
                    value: l,
                    child: Text('${l.nativeName} (${l.name})'),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Pulsing Mic Circle
          GestureDetector(
            onTap: _toggleListening,
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Container(
                  width: 86 * (_isListening ? _scaleAnimation.value : 1.0),
                  height: 86 * (_isListening ? _scaleAnimation.value : 1.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isListening
                          ? [AppColors.primary, AppColors.mintDark]
                          : [Colors.grey.shade400, Colors.grey.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: _isListening
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 18,
                              spreadRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Listening Status
          Text(
            _isListening
                ? AppLanguageService.t('listening')
                : (_error
                    ? AppLanguageService.t('speech_error')
                    : AppLanguageService.t('tap_to_speak')),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _isListening
                  ? AppColors.primary
                  : (_error ? Colors.red.shade700 : AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 16),

          // Live Recognized Text Container
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 70, maxHeight: 130),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _spokenText.isNotEmpty ? AppColors.primary : AppColors.cardBorder,
                width: _spokenText.isNotEmpty ? 1.5 : 1,
              ),
            ),
            child: SingleChildScrollView(
              child: Text(
                _spokenText.isEmpty ? hint : _spokenText,
                style: TextStyle(
                  fontSize: 16,
                  color: _spokenText.isEmpty ? Colors.grey.shade500 : AppColors.textPrimary,
                  fontWeight: _spokenText.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              if (_spokenText.isNotEmpty) ...[
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _spokenText = '');
                  },
                  icon: const Icon(Icons.clear_rounded, size: 16),
                  label: Text(AppLanguageService.t('speech_clear')),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: _spokenText.trim().isEmpty
                      ? null
                      : () {
                          widget.onResult(_spokenText.trim());
                        },
                  icon: const Icon(Icons.check_rounded),
                  label: Text(AppLanguageService.t('speech_done')),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
