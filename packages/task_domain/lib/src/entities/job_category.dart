/// Canonical service categories for the fixed-price marketplace. Pure data —
/// icons and tints live in the UI layer (`task_design`). The `id` is the stable
/// string persisted with a job; `displayLabel` is English copy.
enum JobCategory {
  plumbing('plumbing', 'Plumber'),
  electrical('electrical', 'Electrician'),
  ac('ac', 'AC Maintenance'),
  cleaning('cleaning', 'Cleaning'),
  carpentry('carpentry', 'Carpenter'),
  painting('painting', 'Painter'),
  satelliteInstallation('satellite', 'Satellite'),
  smartHome('smart_home', 'Smart Home'),
  tilesHandyman('tiles_handyman', 'Tiles Handyman'),
  masonStones('mason_stones', 'Mason & Decoration Stones'),
  plaster('plaster', 'Plaster'),
  smith('smith', 'Smith'),
  parquet('parquet', 'Parquet'),
  gypsumWorks('gypsum_works', 'Gypsum Works'),
  gypsumBoard('gypsum_board', 'Gypsum Board'),
  marbleGranite('marble_granite', 'Marble & Granite'),
  alumetal('alumetal', 'Alumetal'),
  glassCecurit('glass_cecurit', 'Glass & Cecurit'),
  curtainsUpholstery('curtains_upholstery', 'Curtains & Upholstery'),
  woodPainter('wood_painter', 'Wood Painter'),
  movingServices('moving_services', 'Moving Services'),
  puCornices('pu_cornices', 'PU Cornices'),
  materialWinch('material_winch', 'Material Winch'),
  appliancesMaintenance('appliances_maintenance', 'Appliances Maintenance'),
  swimmingPool('swimming_pool', 'Swimming Pool Maintenance'),
  pestControl('pest_control', 'Pest Control');

  const JobCategory(this.id, this.displayLabel);

  final String id;
  final String displayLabel;

  static JobCategory fromId(String id) =>
      JobCategory.values.firstWhere((JobCategory c) => c.id == id);
}
