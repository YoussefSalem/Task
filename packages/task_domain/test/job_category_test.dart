import 'package:task_domain/task_domain.dart';
import 'package:test/test.dart';

void main() {
  test('JobCategory has the 8 canonical categories incl. the 2 new ones', () {
    expect(JobCategory.values.length, 8);
    expect(JobCategory.satelliteInstallation.id, 'satellite');
    expect(JobCategory.satelliteInstallation.displayLabel,
        'Satellite Installation & Repair');
    expect(JobCategory.smartHome.id, 'smart_home');
    expect(JobCategory.smartHome.displayLabel,
        'Smart Home Installation & Automation');
  });

  test('fromId round-trips every category id', () {
    for (final JobCategory c in JobCategory.values) {
      expect(JobCategory.fromId(c.id), c);
    }
  });
}
