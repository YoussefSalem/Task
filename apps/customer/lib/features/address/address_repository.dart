import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../booking/booking_state.dart';

/// Per-user saved addresses, stored in the top-level `addresses` collection and
/// tagged with `user_id` so they're unique to each customer and pull on any
/// device they sign in from.
class AddressRepository {
  AddressRepository(this._uid);

  final String _uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('addresses');

  Stream<List<SavedAddress>> watch() {
    return _col.where('user_id', isEqualTo: _uid).snapshots().map((qs) {
      final list = qs.docs.map(_fromDoc).toList();
      list.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
      return list;
    });
  }

  Future<void> add({
    required String label,
    required String line,
    required AddressIconKind iconKind,
    double? lat,
    double? lng,
  }) async {
    await _col.add(<String, dynamic>{
      'user_id': _uid,
      'label': label,
      'line': line,
      'icon_kind': iconKind.name,
      'lat': lat,
      'lng': lng,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> remove(String id) => _col.doc(id).delete();

  SavedAddress _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return SavedAddress(
      id: doc.id,
      label: (d['label'] as String?) ?? '',
      line: (d['line'] as String?) ?? '',
      iconKind: AddressIconKindX.fromName(d['icon_kind']),
      lat: (d['lat'] as num?)?.toDouble(),
      lng: (d['lng'] as num?)?.toDouble(),
    );
  }
}

/// Address repo scoped to the signed-in user, or null when signed out.
final addressRepositoryProvider = Provider<AddressRepository?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;
  return AddressRepository(user.uid);
});

/// Live stream of the user's saved addresses (empty when signed out).
final savedAddressesProvider = StreamProvider<List<SavedAddress>>((ref) {
  final repo = ref.watch(addressRepositoryProvider);
  if (repo == null) {
    return Stream<List<SavedAddress>>.value(const <SavedAddress>[]);
  }
  return repo.watch();
});
