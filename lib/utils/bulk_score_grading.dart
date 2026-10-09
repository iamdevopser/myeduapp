/// Toplu not kaydı — her öğrenci için mevcut save çağrısını sırayla uygular.
Future<int> applyBulkStudentScores({
  required Iterable<int> studentIds,
  required Future<void> Function(int studentId) saveStudent,
}) async {
  var failures = 0;
  for (final studentId in studentIds) {
    try {
      await saveStudent(studentId);
    } catch (_) {
      failures++;
    }
  }
  return failures;
}
