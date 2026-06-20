/// Build flavors map to the strict Dev/Staging/Prod Firebase project
/// separation mandated by the discovery doc. Each entrypoint
/// (`main_<flavor>.dart`) boots a single flavor.
enum Flavor {
  dev('Task (Dev)'),
  staging('Task (Staging)'),
  prod('Task');

  const Flavor(this.appTitle);

  /// Title shown in the OS task switcher / window chrome.
  final String appTitle;

  bool get isProd => this == Flavor.prod;
}
