import '../models/room.dart';
import '../models/bed.dart';
import '../models/enum.dart';
import '../models/patient.dart';

class RoomTypeStats {
  final RoomType type;
  int rooms = 0;
  int available = 0;
  int occupied = 0;
  int total = 0;

  RoomTypeStats(this.type);

  void addCounts(int rooms, int available, int occupied, int total) {
    this.rooms += rooms;
    this.available += available;
    this.occupied += occupied;
    this.total += total;
  }
}

class HospitalManaging {
  final List<Room> emergencyRoom = [];
  final List<Room> icuRoom = [];
  final List<Room> generalRoom = [];

  // int emergencyRoomCount = 5;
  // int icuRoomCount = 10;
  // int generalRoomCount = 20;

  // int emergencyRoomNumber = 100;
  // int icuRoomNumber = 200;
  // int generalRoomNumber = 300;

  // HospitalManaging() {
  //   for (int i = 0; i < emergencyRoomCount; i++) {
  //     emergencyRoom.add(EmergencyRoom(roomNumber: emergencyRoomNumber++));
  //   }
  //   for (int i = 0; i < icuRoomCount; i++) {
  //     icuRoom.add(ICURoom(roomNumber: icuRoomNumber++));
  //   }
  //   for (int i = 0; i < generalRoomCount; i++) {
  //     generalRoom.add(GeneralRoom(roomNumber: generalRoomNumber++));
  //   }
  // }
  HospitalManaging({required List<Room> loadedRooms}) {
    initializeFromLoadedRooms(loadedRooms);
  }

  void initializeFromLoadedRooms(List<Room> loadedRooms) {
    for (var room in loadedRooms) {
      switch (room.roomType) {
        case RoomType.Emergency:
          emergencyRoom.add(room);
          break;
        case RoomType.ICU:
          icuRoom.add(room);
          break;
        case RoomType.General:
          generalRoom.add(room);
          break;
      }
    }
  }

  final List<Patient> activePatient = [];

  List<Room> get allRoom => [...emergencyRoom, ...icuRoom, ...generalRoom];

  void assignPatient(Patient patient) {
    activePatient.add(patient);
    switch (patient.code) {
      case PatientCode.Black:
        moveToEmergency(patient);
        break;
      case PatientCode.Red:
        moveToICU(patient);
        break;
      case PatientCode.Yellow:
        moveToGeneral(patient);
        break;
      case PatientCode.Green:
        break;
    }
  }

  void updatePatientCode(Patient patient, PatientCode newCode) {
    patient.code = newCode;
    if (newCode == PatientCode.Green) {
      markAsRecovery(patient);
    }
  }

  void assignToRoom(List<Room> rooms, Patient patient) {
    for (var room in rooms) {
      final bed = room.getAvailableBed();
      if (bed != null) {
        bed.assignPatient(patient);
        return;
      }
    }
  }

  void moveToEmergency(Patient patient) => assignToRoom(emergencyRoom, patient);
  void moveToICU(Patient patient) => assignToRoom(icuRoom, patient);
  void moveToGeneral(Patient patient) => assignToRoom(generalRoom, patient);

  void releasePatientBed(Patient patient) {
    for (var room in allRoom) {
      for (var bed in room.beds) {
        if (bed.patient?.patientId == patient.patientId) {
          bed.releasePatient();
        }
      }
    }
  }

  void markAsRecovery(Patient patient) {
    patient.leaveDate = DateTime.now();
    releasePatientBed(patient);
    activePatient.remove(patient);
  }

  void movePatientRoom(Patient patient, Room room) {
    releasePatientBed(patient);
    final bed = room.getAvailableBed();
    if (bed != null) {
      bed.assignPatient(patient);
    }
  }

  bool isRoomAvailable(Room room) => room.getAvailableBed() != null;

  Room? findRoomForCode(PatientCode code) {
    switch (code) {
      case PatientCode.Black:
        for (var room in emergencyRoom) {
          if (isRoomAvailable(room)) return room;
        }
        break;
      case PatientCode.Red:
        for (var room in icuRoom) {
          if (isRoomAvailable(room)) return room;
        }
        break;
      case PatientCode.Yellow:
        for (var room in generalRoom) {
          if (isRoomAvailable(room)) return room;
        }
        break;
      case PatientCode.Green:
        return null;
    }
    return null;
  }

  Room? findPatientRoom(Patient patient) {
    for (var room in allRoom) {
      for (var bed in room.beds) {
        if (bed.patient?.patientId == patient.patientId) {
          return room;
        }
      }
    }
    return null;
  }

  Bed? findPatientBed(Patient patient) {
    for (var room in allRoom) {
      for (var bed in room.beds) {
        if (bed.patient?.patientId == patient.patientId) {
          return bed;
        }
      }
    }
    return null;
  }

  List<RoomTypeStats> getRoomStatus() {
    final emergencyStats = RoomTypeStats(RoomType.Emergency);
    final icuStats = RoomTypeStats(RoomType.ICU);
    final generalStats = RoomTypeStats(RoomType.General);

    for (var room in allRoom) {
      final total = room.beds.length;
      final available =
          room.beds.where((b) => b.bedStatus == BedStatus.Available).length;
      final occupied = total - available;

      switch (room.roomType) {
        case RoomType.Emergency:
          emergencyStats.addCounts(1, available, occupied, total);
          break;
        case RoomType.ICU:
          icuStats.addCounts(1, available, occupied, total);
          break;
        case RoomType.General:
          generalStats.addCounts(1, available, occupied, total);
          break;
      }
    }

    return [emergencyStats, icuStats, generalStats];
  }

  void initializeRooms(List<Room> rooms) {
    allRoom.clear();
    allRoom.addAll(rooms);
  }

  void assignLoadedPatient(Patient patient) {
    activePatient.add(patient);
  }
}
