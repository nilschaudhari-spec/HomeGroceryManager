import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_grocery_manager/services/app_language_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppLanguageService Tests', () {
    test('verifies all 13 supported languages are configured', () {
      final languages = AppLanguageService.supportedLanguages;
      expect(languages.length, 13);

      final codes = languages.map((l) => l.code).toSet();
      expect(codes.contains('en'), isTrue);
      expect(codes.contains('hi'), isTrue);
      expect(codes.contains('mr'), isTrue);
      expect(codes.contains('bn'), isTrue);
      expect(codes.contains('te'), isTrue);
      expect(codes.contains('ta'), isTrue);
      expect(codes.contains('gu'), isTrue);
      expect(codes.contains('kn'), isTrue);
      expect(codes.contains('ml'), isTrue);
      expect(codes.contains('pa'), isTrue);
      expect(codes.contains('or'), isTrue);
      expect(codes.contains('as'), isTrue);
      expect(codes.contains('ur'), isTrue);
    });

    test('verifies default translations in English', () {
      AppLanguageService.instance.setLanguageByCode('en');
      expect(AppLanguageService.t('app_title'), 'Home Grocery Manager');
      expect(AppLanguageService.t('voice_search'), 'Voice Search');
    });

    test('verifies language switching to Hindi and Marathi', () {
      AppLanguageService.instance.setLanguageByCode('hi');
      expect(AppLanguageService.t('app_title'), 'होम ग्रोसरी मैनेजर');
      expect(AppLanguageService.t('voice_search'), 'आवाज़ से खोजें (बोलें)');

      AppLanguageService.instance.setLanguageByCode('mr');
      expect(AppLanguageService.t('app_title'), 'होम किराणा मॅनेजर');
      expect(AppLanguageService.t('voice_search'), 'बोलून शोधा');
    });

    test('verifies parameter interpolation in translations', () {
      AppLanguageService.instance.setLanguageByCode('en');
      final enResult = AppLanguageService.t('delete_item_confirm', params: {'name': 'Rice'});
      expect(enResult, 'Delete Rice?');

      AppLanguageService.instance.setLanguageByCode('hi');
      final hiResult = AppLanguageService.t('delete_item_confirm', params: {'name': 'चावल'});
      expect(hiResult, 'चावल हटाएं?');
    });

    test('verifies speech locale IDs for all Indian languages', () {
      for (final lang in AppLanguageService.supportedLanguages) {
        expect(lang.speechLocaleId.contains('_IN') || lang.speechLocaleId == 'ur_PK', isTrue);
        expect(lang.nativeName.isNotEmpty, isTrue);
      }
    });
  });
}
