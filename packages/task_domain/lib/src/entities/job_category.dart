/// Canonical service categories for the fixed-price marketplace. Pure data —
/// icons and tints live in the UI layer (`task_design`). The `id` is the stable
/// string persisted with a job; `displayLabel` is English copy.
enum JobCategory {
  plumbing('plumbing', 'Plumbing'),
  electrical('electrical', 'Electrical'),
  ac('ac', 'AC & Cooling'),
  cleaning('cleaning', 'Cleaning'),
  carpentry('carpentry', 'Carpentry'),
  painting('painting', 'Painting'),
  satelliteInstallation('satellite', 'Satellite Installation & Repair'),
  smartHome('smart_home', 'Smart Home Installation & Automation');

  const JobCategory(this.id, this.displayLabel);

  final String id;
  final String displayLabel;

  static JobCategory fromId(String id) =>
      JobCategory.values.firstWhere((JobCategory c) => c.id == id);
}
