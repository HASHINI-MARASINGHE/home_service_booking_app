import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_service_bookin_app/services/payment_method_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PaymentMethodService & PaymentMethodItem', () {
    test('PaymentMethodItem serialization and deserialization', () {
      final item = PaymentMethodItem(
        id: 'card_123',
        brand: 'Visa',
        last4: '4242',
        holderName: 'John Doe',
        expiry: '12/28',
        isDefault: true,
      );

      final json = item.toJson();
      expect(json['id'], 'card_123');
      expect(json['brand'], 'Visa');
      expect(json['last4'], '4242');
      expect(json['holderName'], 'John Doe');
      expect(json['expiry'], '12/28');
      expect(json['isDefault'], true);

      final fromJson = PaymentMethodItem.fromJson(json);
      expect(fromJson.id, item.id);
      expect(fromJson.brand, item.brand);
      expect(fromJson.last4, item.last4);
      expect(fromJson.holderName, item.holderName);
      expect(fromJson.expiry, item.expiry);
      expect(fromJson.isDefault, item.isDefault);
    });

    test('addCard, setDefault, updateCard, deleteCard and local caching', () async {
      final service = PaymentMethodService();

      var cards = await service.getCards();
      expect(cards, isEmpty);

      final card1 = PaymentMethodItem(
        id: 'c1',
        brand: 'Visa',
        last4: '1111',
        holderName: 'Alice',
        expiry: '05/27',
        isDefault: true,
      );
      await service.addCard(card1);

      cards = await service.getCards();
      expect(cards.length, 1);
      expect(cards.first.id, 'c1');
      expect(cards.first.isDefault, true);

      final card2 = PaymentMethodItem(
        id: 'c2',
        brand: 'Mastercard',
        last4: '2222',
        holderName: 'Alice',
        expiry: '08/29',
        isDefault: false,
      );
      await service.addCard(card2);

      cards = await service.getCards();
      expect(cards.length, 2);

      // Set card2 as default
      await service.setDefault(card2);
      cards = await service.getCards();
      expect(cards.first.id, 'c2');
      expect(cards.first.isDefault, true);
      expect(cards.last.id, 'c1');
      expect(cards.last.isDefault, false);

      // Update card2
      final updatedCard2 = PaymentMethodItem(
        id: 'c2',
        brand: 'Mastercard',
        last4: '2222',
        holderName: 'Alice Smith',
        expiry: '09/29',
        isDefault: true,
      );
      await service.updateCard(updatedCard2);
      cards = await service.getCards();
      expect(cards.first.holderName, 'Alice Smith');
      expect(cards.first.expiry, '09/29');

      // Delete card2
      await service.deleteCard(updatedCard2);
      cards = await service.getCards();
      expect(cards.length, 1);
      expect(cards.first.id, 'c1');
      expect(cards.first.isDefault, true);

      // loadDefaultCard
      final defaultCard = await PaymentMethodService.loadDefaultCard();
      expect(defaultCard, isNotNull);
      expect(defaultCard!.id, 'c1');
    });
  });
}
