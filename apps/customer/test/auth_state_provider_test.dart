import 'package:customer/features/auth/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('authStateProvider yields null in mock mode (firebase not ready)', () async {
    final container = ProviderContainer(
      overrides: <Override>[
        firebaseReadyProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);

    // First read is loading; await the resolved value.
    final user = await container.read(authStateProvider.future);
    expect(user, isNull);
  });
}
