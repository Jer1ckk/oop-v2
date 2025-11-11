import 'package:uuid/uuid.dart';
import 'enum.dart';

final uuid = Uuid();

class Patient {
  String patientId;
  String patientName;
  Gender gender;
  DateTime entryDate;
  DateTime? leaveDate;
  PatientCode code;
  String? currentBedId;
  List<String> bedHistory = [];

  Patient({
    String? patientId,
    required this.patientName,
    required this.gender,
    required this.entryDate,
    required this.code,
    this.currentBedId,
  }) : patientId = patientId ?? uuid.v4();

  void updatePatientCode(PatientCode newCode) {
    code = newCode;
  }

  void assignBed(String bedId) {
    currentBedId = bedId;
    bedHistory.add(bedId);
  }

  void releasePatient() => currentBedId = null;
}
