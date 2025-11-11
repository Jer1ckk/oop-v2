import 'package:uuid/uuid.dart';
import 'patient.dart';
import 'enum.dart';
 
final uuid = Uuid();

class Bed {
  final String bedId;
  BedStatus bedStatus;
  Patient? patient;

  Bed({String? bedId, this.bedStatus = BedStatus.Available, this.patient})
      : bedId = bedId ?? uuid.v4();

  void assignPatient(Patient patient) {
    this.patient = patient;
    patient.assignBed(bedId);
    bedStatus = BedStatus.Occupied;
  }

  void releasePatient() {
    patient?.releasePatient();
    patient = null;
    bedStatus = BedStatus.Available;
  }
}
