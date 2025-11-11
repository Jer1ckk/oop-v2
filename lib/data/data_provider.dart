import 'dart:convert';
import 'dart:io';

import '../domain/models/bed.dart';
import '../domain/models/patient.dart';
import '../domain/models/room.dart';
import '../domain/models/enum.dart';

class HospitalDataManager {
  final String filePath;

  HospitalDataManager({required this.filePath});

  Future<void> saveData(List<Patient> patients, List<Room> rooms) async {
    final data = {
      'patients': patients.map(_patientToJson).toList(),
      'rooms': rooms.map(_roomToJson).toList(),
    };

    final file = File(filePath);
    await file.writeAsString(jsonEncode(data), flush: true);
    //print('Data saved to $filePath');
  }

  Future<Map<String, dynamic>> loadData() async {
    final file = File(filePath);
    if (!await file.exists()) {
      return {'patients': <Patient>[], 'rooms': <Room>[]};
    }
    try {
      final content = await file.readAsString();
      final Map<String, dynamic> jsonData = jsonDecode(content);

      final patients = (jsonData['patients'] as List<dynamic>? ?? [])
          .map((p) => _patientFromJson(p))
          .toList();

      final rooms = (jsonData['rooms'] as List<dynamic>? ?? [])
          .map((r) => _roomFromJson(r))
          .toList();

      final patientMap = {for (var p in patients) p.patientId: p};
      final roomsJson = (jsonData['rooms'] as List<dynamic>? ?? []);
      for (var i = 0; i < rooms.length; i++) {
        final room = rooms[i];
        final roomJson = roomsJson.length > i ? roomsJson[i] as Map<String, dynamic> : null;
        final bedsJson = roomJson != null ? (roomJson['beds'] as List<dynamic>? ?? []) : [];
        for (var j = 0; j < room.beds.length; j++) {
          final bedJson = bedsJson.length > j ? bedsJson[j] as Map<String, dynamic> : null;
          final patientId = bedJson != null ? bedJson['patientId'] as String? : null;
          if (patientId != null && patientMap.containsKey(patientId)) {
            final patient = patientMap[patientId]!;
            room.beds[j].patient = patient;
            patient.currentBedId = room.beds[j].bedId;
            if (!patient.bedHistory.contains(room.beds[j].bedId)) {
              patient.bedHistory.add(room.beds[j].bedId);
            }
          }
        }
      }

      return {'patients': patients, 'rooms': rooms};
    } catch (e) {
      throw Exception('Failed to load hospital data from $filePath: $e');
    }
  }


  Map<String, dynamic> _patientToJson(Patient p) {
    return {
      'patientId': p.patientId,
      'patientName': p.patientName,
      'gender': p.gender.name,
      'entryDate': p.entryDate.toIso8601String(),
      'leaveDate': p.leaveDate?.toIso8601String(),
      'code': p.code.name,
      'currentBedId': p.currentBedId,
      'bedHistory': p.bedHistory,
    };
  }

Patient _patientFromJson(Map<String, dynamic> json) {
  final gender = (json['gender'] is String)
    ? Gender.values.firstWhere((g) => g.name == json['gender'], orElse: () => Gender.Male)
    : Gender.Male;

  final patient = Patient(
    patientId: json['patientId'],
    patientName: json['patientName'],
    gender: gender,
    entryDate: DateTime.parse(json['entryDate']),
    code: PatientCode.values.firstWhere(
      (c) => c.name == json['code'],
      orElse: () => PatientCode.Green,
    ),
    currentBedId: json['currentBedId'],
  );

  if (json['leaveDate'] != null) {
    patient.leaveDate = DateTime.parse(json['leaveDate']);
  }

  patient.bedHistory.addAll(List<String>.from(json['bedHistory'] ?? []));

  return patient;
}


  Map<String, dynamic> _roomToJson(Room r) {
    return {
      'roomId': r.roomId,
      'roomNumber': r.roomNumber,
      'roomType': r.roomType.name,
      'beds': r.beds.map((b) => _bedToJson(b)).toList(),
    };
  }

  Room _roomFromJson(Map<String, dynamic> json) {
    final type = RoomType.values
        .firstWhere((t) => t.name == json['roomType'], orElse: () => RoomType.General);

    late Room room;
    switch (type) {
      case RoomType.Emergency:
        room = EmergencyRoom(roomNumber: json['roomNumber']);
        break;
      case RoomType.ICU:
        room = ICURoom(roomNumber: json['roomNumber']);
        break;
      case RoomType.General:
        room = GeneralRoom(roomNumber: json['roomNumber']);
        break;
    }

    final bedList = (json['beds'] as List<dynamic>? ?? [])
        .map((b) => _bedFromJson(b))
        .toList();
    room.beds.clear();
    room.beds.addAll(bedList);

    return room;
  }

  Map<String, dynamic> _bedToJson(Bed b) {
    return {
      'bedId': b.bedId,
      'bedStatus': b.bedStatus.name,
      'patientId': b.patient?.patientId,
    };
  }

  Bed _bedFromJson(Map<String, dynamic> json) {
    final bed = Bed(bedId: json['bedId']);
    bed.bedStatus = BedStatus.values
        .firstWhere((s) => s.name == json['bedStatus'], orElse: () => BedStatus.Available);
    return bed;
  }
}
