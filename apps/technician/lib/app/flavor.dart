/// Build flavors map to the Dev/Staging/Prod Firebase project separation from
/// the discovery doc. Each entrypoint (`main_<flavor>.dart`) boots one flavor.
enum Flavor {
  dev('Task Pro (Dev)'),
  staging('Task Pro (Staging)'),
  prod('Task Pro');

  const Flavor(this.appTitle);

  /// Title shown in the OS task switcher / window chrome.
  final String appTitle;

  bool get isProd => this == Flavor.prod;
}
