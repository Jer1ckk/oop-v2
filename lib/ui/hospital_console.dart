import 'dart:io';
import '../domain/services/mananger.dart';
import '../domain/models/patient.dart';
import '../domain/models/enum.dart';
import '../data/data_provider.dart';
import '../domain/models/room.dart';

class HospitalConsoleUI {
  late HospitalManaging system ;
  final HospitalDataManager dataManager;

  HospitalConsoleUI({required String dataFilePath})
      : dataManager = HospitalDataManager(filePath: dataFilePath);

  Future<void> start() async {
    // ===== LOAD DATA ON START =====
    try {
      final loadedData = await dataManager.loadData();
      final patients = loadedData['patients'] as List<Patient>;
      final rooms = loadedData['rooms'] as List<Room>;

      system = HospitalManaging(loadedRooms: rooms);
      for (var p in patients) {
        system.assignLoadedPatient(p);
      }

      print('Data loaded from ${dataManager.filePath}');
    } catch (e) {
      print('Failed to load data: $e');
    }

    // ===== MAIN MENU =====
    while (true) {
      print('\n=== Hospital Management System ===');
      print('1. Add new patient');
      print('2. Change Patient Code or Move Room');
      print('3. Show active patients');
      print('4. Show room & bed availability');
      print('5. Search patient by name');
      print('0. Exit');
      stdout.write('Select: ');
      final choice = stdin.readLineSync()?.trim();

      switch (choice) {
        case '1':
          addNewPatient();
          await saveData();
          break;
        case '2':
          updatePatientCode();
          await saveData();
          break;
        case '3':
          showActivePatients();
          break;
        case '4':
          showRoomAvailability();
          break;
        case '5':
          searchPatient();
          break;
        case '0':
          await saveData();
          print('Exiting...');
          return;
        default:
          print('Invalid option.');
      }
    }
  }

  Future<void> saveData() async {
    try {
      await dataManager.saveData(system.activePatient, system.allRoom);
      //print('Data saved successfully.');
    } catch (e) {
      print('Error saving data: $e');
    }
  }

  // ===== MENU ACTIONS =====

  void addNewPatient() {
    final name = inputEmpty('Enter patient name: ');
    final gender = inputGender();
    final code = inputPatientCode();

    final patient = Patient(
      patientName: name,
      gender: gender,
      entryDate: DateTime.now(),
      code: code,
    );

    system.assignPatient(patient);
    print('Patient $name added successfully.');
  }

  void updatePatientCode() {
    if (system.activePatient.isEmpty) {
      print('No active patients.');
      return;
    }

    for (int i = 0; i < system.activePatient.length; i++) {
      final p = system.activePatient[i];
      print('${i + 1}. ${p.patientName} (${p.code.name})');
    }

    final index =
        patientIndex('Select patient number: ', 1, system.activePatient.length) - 1;
    final patient = system.activePatient[index];
    final newCode = inputPatientCode(prompt: 'Enter new code: ');

    system.updatePatientCode(patient, newCode);
    print('Patient ${patient.patientName} updated to ${newCode.name}.');
  }

  void showActivePatients() {
    if (system.activePatient.isEmpty) {
      print('No active patients.');
      return;
    }

    for (var p in system.activePatient) {
      final room = system.findPatientRoom(p);
      final bed = system.findPatientBed(p);
      final roomInfo =
          room != null ? 'Room: ${room.roomNumber} (${room.roomType.name})' : 'Room: -';
      final bedInfo = bed != null ? 'Bed: ${bed.bedId}' : 'Bed: -';
      print(
          '${p.patientName} | Code: ${p.code.name} | Gender: ${p.gender.name} | $roomInfo | $bedInfo');
    }
  }

  void showRoomAvailability() {
    final statsList = system.getRoomStatus();
    for (var s in statsList) {
      print(
          '${s.type.name} → Rooms: ${s.rooms}, Available: ${s.available}, Occupied: ${s.occupied}, Total: ${s.total}');
    }

    print('\nPer-room details:');
    for (var room in system.allRoom) {
      final total = room.beds.length;
      final available =
          room.beds.where((b) => b.bedStatus == BedStatus.Available).length;
      final occupied = total - available;
      print(
          'Room #${room.roomNumber} (${room.roomType.name}) → Available: $available | Occupied: $occupied | Total: $total');
    }
  }

  void searchPatient() {
    final name = inputEmpty('Enter patient name to search: ').toLowerCase();
    final matches = system.activePatient
        .where((p) => p.patientName.toLowerCase() == name)
        .toList();

    if (matches.isEmpty) {
      print('No active patient found.');
      return;
    }

    for (var p in matches) {
      final room = system.findPatientRoom(p);
      final bed = system.findPatientBed(p);
      final roomInfo =
          room != null ? 'Room: ${room.roomNumber} (${room.roomType.name})' : 'Room: -';
      final bedInfo = bed != null ? 'Bed: ${bed.bedId}' : 'Bed: -';
      print(
          '${p.patientName} | Code: ${p.code.name} | Gender: ${p.gender.name} | $roomInfo | $bedInfo');
    }
  }

  // ===== INPUT HELPERS =====

  Gender inputGender() {
    while (true) {
      stdout.write('Gender (Male/Female): ');
      final input = stdin.readLineSync()?.trim().toLowerCase();
      if (input == 'male' || input == 'm') return Gender.Male;
      if (input == 'female' || input == 'f') return Gender.Female;
      print("Enter 'Male' or 'Female'.");
    }
  }

  String inputEmpty(String prompt) {
    while (true) {
      stdout.write(prompt);
      final input = stdin.readLineSync();
      if (input != null && input.trim().isNotEmpty) return input.trim();
      print('Input cannot be empty.');
    }
  }

  PatientCode inputPatientCode({String prompt = 'Patient code (Black/Red/Yellow/Green): '}) {
    while (true) {
      stdout.write(prompt);
      final input = stdin.readLineSync()?.trim().toLowerCase();
      switch (input) {
        case 'black':
        case 'b':
        case '1':
          return PatientCode.Black;
        case 'red':
        case 'r':
        case '2':
          return PatientCode.Red;
        case 'yellow':
        case 'y':
        case '3':
          return PatientCode.Yellow;
        case 'green':
        case 'g':
        case '4':
          return PatientCode.Green;
      }
      print("Invalid code.");
    }
  }

  int patientIndex(String prompt, int min, int max) {
    while (true) {
      stdout.write(prompt);
      final idx = int.tryParse(stdin.readLineSync() ?? '');
      if (idx != null && idx >= min && idx <= max) return idx;
      print('Enter a number between $min and $max.');
    }
  }
}
