import 'package:flutter_test/flutter_test.dart';
import 'package:styleconnect/core/utils/whatsapp_launcher.dart';

/// Le lien wa.me partait sur un numéro inexistant quand le styliste saisissait
/// le téléphone de son client en format local (« 70 00 00 00 »), ce qui est le
/// cas le plus fréquent au Mali : WhatsApp ne s'ouvrait alors jamais.
void main() {
  group('WhatsAppLauncher.normalizePhone', () {
    test('ajoute l\'indicatif du Mali à un numéro saisi en local', () {
      expect(WhatsAppLauncher.normalizePhone('70 00 00 00'), '22370000000');
      expect(WhatsAppLauncher.normalizePhone('76-12-34-56'), '22376123456');
      expect(WhatsAppLauncher.normalizePhone(' 66 11 22 33 '), '22366112233');
    });

    test('conserve un numéro déjà au format international', () {
      expect(WhatsAppLauncher.normalizePhone('+223 70 00 00 00'), '22370000000');
      expect(WhatsAppLauncher.normalizePhone('00223 70 00 00 00'), '22370000000');
    });

    test('retourne une chaîne vide quand aucun chiffre exploitable n\'est présent', () {
      expect(WhatsAppLauncher.normalizePhone(''), '');
      expect(WhatsAppLauncher.normalizePhone('   '), '');
      expect(WhatsAppLauncher.normalizePhone('abc'), '');
    });
  });
}
