import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentMethodItem {
  PaymentMethodItem({
    required this.id,
    required this.brand,
    required this.last4,
    required this.holderName,
    required this.expiry,
    this.isDefault = false,
  });

  final String id;
  final String brand;
  final String last4;
  final String holderName;
  final String expiry;
  bool isDefault;

  Map<String, dynamic> toJson() => {
    'id': id,
    'brand': brand,
    'last4': last4,
    'holderName': holderName,
    'expiry': expiry,
    'isDefault': isDefault,
  };

  factory PaymentMethodItem.fromJson(Map<String, dynamic> json) =>
      PaymentMethodItem(
        id: json['id'] as String? ?? '',
        brand: json['brand'] as String? ?? 'Card',
        last4: json['last4'] as String? ?? '0000',
        holderName: json['holderName'] as String? ?? '',
        expiry: json['expiry'] as String? ?? '',
        isDefault: json['isDefault'] as bool? ?? false,
      );

  factory PaymentMethodItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return PaymentMethodItem(
      id: doc.id,
      brand: data['brand'] as String? ?? 'Card',
      last4: data['last4'] as String? ?? '0000',
      holderName: data['holderName'] as String? ?? '',
      expiry: data['expiry'] as String? ?? '',
      isDefault: data['isDefault'] as bool? ?? false,
    );
  }
}

class PaymentMethodService {
  PaymentMethodService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _authOverride = auth,
        _dbOverride = firestore;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _dbOverride;

  FirebaseAuth? get _auth {
    try {
      return _authOverride ?? FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFirestore? get _db {
    try {
      return _dbOverride ?? FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static const String savedCardsKey = 'saved_payment_cards_v2';
  static const String legacySavedCardsKey = 'saved_payment_cards_v1';

  String? get _currentUid => _auth?.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? _cardsCollection(String uid) {
    final db = _db;
    if (db == null) return null;
    return db.collection('users').doc(uid).collection('paymentMethods');
  }

  static void _sortCards(List<PaymentMethodItem> cards) {
    cards.sort((a, b) {
      if (a.isDefault != b.isDefault) {
        return a.isDefault ? -1 : 1;
      }
      return 0;
    });
  }

  /// Loads saved cards for current customer from Firestore if signed in,
  /// with automatic fallback and local sync to SharedPreferences.
  Future<List<PaymentMethodItem>> getCards() async {
    final uid = _currentUid;
    if (uid != null) {
      final col = _cardsCollection(uid);
      if (col != null) {
        try {
          final snapshot = await col.get();
          if (snapshot.docs.isNotEmpty) {
            final list = snapshot.docs
                .map((doc) => PaymentMethodItem.fromFirestore(doc))
                .toList();
            _sortCards(list);
            await _saveToLocalCache(list);
            return list;
          } else {
            // Check if local cache has cards that can be migrated to Firestore
            final local = await _loadFromLocalCache();
            if (local.isNotEmpty) {
              for (final card in local) {
                await _saveCardToFirestore(uid, card);
              }
              return local;
            }
          }
        } catch (e) {
          debugPrint('Error fetching payment methods from Firestore: $e');
        }
      }
    }
    return _loadFromLocalCache();
  }

  Future<void> _saveCardToFirestore(String uid, PaymentMethodItem card) async {
    final col = _cardsCollection(uid);
    if (col == null) return;
    try {
      await col.doc(card.id).set({
        'id': card.id,
        'brand': card.brand,
        'last4': card.last4,
        'holderName': card.holderName,
        'expiry': card.expiry,
        'isDefault': card.isDefault,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving card to Firestore: $e');
    }
  }

  /// Adds a new card to Firestore and local cache.
  Future<void> addCard(PaymentMethodItem card) async {
    final uid = _currentUid;
    if (uid != null) {
      final col = _cardsCollection(uid);
      final db = _db;
      if (col != null && db != null) {
        try {
          final batch = db.batch();
          if (card.isDefault) {
            final existing = await col.get();
            for (final doc in existing.docs) {
              if (doc.id != card.id) {
                batch.update(doc.reference, {
                  'isDefault': false,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
              }
            }
          }
          batch.set(col.doc(card.id), {
            'id': card.id,
            'brand': card.brand,
            'last4': card.last4,
            'holderName': card.holderName,
            'expiry': card.expiry,
            'isDefault': card.isDefault,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          await batch.commit();
        } catch (e) {
          debugPrint('Error adding card to Firestore: $e');
        }
      }
    }

    final local = await _loadFromLocalCache();
    local.removeWhere((c) => c.id == card.id);
    if (card.isDefault) {
      for (final c in local) {
        c.isDefault = false;
      }
    }
    local.add(card);
    _sortCards(local);
    await _saveToLocalCache(local);
  }

  /// Updates an existing card's details (holder name and expiry) in Firestore and local cache.
  Future<void> updateCard(PaymentMethodItem card) async {
    final uid = _currentUid;
    if (uid != null) {
      final col = _cardsCollection(uid);
      if (col != null) {
        try {
          await col.doc(card.id).set({
            'holderName': card.holderName,
            'expiry': card.expiry,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Error updating card in Firestore: $e');
        }
      }
    }

    final local = await _loadFromLocalCache();
    final idx = local.indexWhere((c) => c.id == card.id);
    if (idx != -1) {
      local[idx] = card;
      await _saveToLocalCache(local);
    }
  }

  /// Removes a card from Firestore and local cache.
  Future<void> deleteCard(PaymentMethodItem card) async {
    final uid = _currentUid;
    if (uid != null) {
      final col = _cardsCollection(uid);
      if (col != null) {
        try {
          await col.doc(card.id).delete();
        } catch (e) {
          debugPrint('Error deleting card from Firestore: $e');
        }
      }
    }

    final local = await _loadFromLocalCache();
    local.removeWhere((c) => c.id == card.id);
    if (card.isDefault && local.isNotEmpty) {
      local.first.isDefault = true;
      if (uid != null) {
        await setDefault(local.first);
      }
    }
    await _saveToLocalCache(local);
  }

  /// Sets a card as the default payment method in Firestore and local cache.
  Future<void> setDefault(PaymentMethodItem card) async {
    final uid = _currentUid;
    if (uid != null) {
      final col = _cardsCollection(uid);
      final db = _db;
      if (col != null && db != null) {
        try {
          final snapshot = await col.get();
          final batch = db.batch();
          for (final doc in snapshot.docs) {
            batch.update(doc.reference, {
              'isDefault': doc.id == card.id,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
          await batch.commit();
        } catch (e) {
          debugPrint('Error setting default card in Firestore: $e');
        }
      }
    }

    final local = await _loadFromLocalCache();
    for (final c in local) {
      c.isDefault = c.id == card.id;
    }
    _sortCards(local);
    await _saveToLocalCache(local);
  }

  /// Reads default card (checks Firestore if logged in, falls back to cache).
  static Future<PaymentMethodItem?> loadDefaultCard() async {
    try {
      final service = PaymentMethodService();
      final cards = await service.getCards();
      if (cards.isEmpty) return null;
      return cards.firstWhere((c) => c.isDefault, orElse: () => cards.first);
    } catch (_) {
      return null;
    }
  }

  static Future<List<PaymentMethodItem>> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawV2 = prefs.getString(savedCardsKey);
      final rawV1 = prefs.getString(legacySavedCardsKey);
      final raw = rawV2 ?? rawV1;
      if (raw == null) return [];
      final list = (jsonDecode(raw) as List)
          .map((e) => PaymentMethodItem.fromJson(e as Map<String, dynamic>))
          .toList();
      _sortCards(list);
      return list;
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveToLocalCache(List<PaymentMethodItem> cards) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        savedCardsKey,
        jsonEncode(cards.map((c) => c.toJson()).toList()),
      );
    } catch (_) {}
  }
}
