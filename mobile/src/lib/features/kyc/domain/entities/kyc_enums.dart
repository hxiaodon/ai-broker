// Shared enums used across KYC domain entities
enum EmploymentStatus {
  employed,
  selfEmployed,
  retired,
  student,
  other;

  String toApi() => switch (this) {
        employed => 'EMPLOYED',
        selfEmployed => 'SELF_EMPLOYED',
        retired => 'RETIRED',
        student => 'STUDENT',
        other => 'OTHER',
      };

  static EmploymentStatus fromApi(String v) => switch (v) {
        'EMPLOYED' => employed,
        'SELF_EMPLOYED' => selfEmployed,
        'RETIRED' => retired,
        'STUDENT' => student,
        _ => other,
      };
}
