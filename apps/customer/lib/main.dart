// Default entrypoint delegates to the Dev flavor so `flutter run` (no
// --target) works out of the box. CI/release builds use the explicit
// `main_<flavor>.dart` entrypoints.
import 'package:customer/main_dev.dart' as dev;

void main() => dev.main();
