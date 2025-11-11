import 'bed.dart';
import 'enum.dart';
import 'package:uuid/uuid.dart';

final uuid = Uuid();

abstract class Room {
  final String roomId;
  final int roomNumber;
  final RoomType roomType;
  final List<Bed> beds;

  Room({required this.roomNumber, required this.roomType, List<Bed>? beds})
      : roomId = uuid.v4(),
        beds = beds ?? List.generate(roomType.beds, (index) => Bed());

  Bed? getAvailableBed() {
    for (var bed in beds) {
      if (bed.bedStatus == BedStatus.Available) return bed;
    }
    return null;
  }
}

class EmergencyRoom extends Room {
  EmergencyRoom({required int roomNumber})
      : super(roomNumber: roomNumber, roomType: RoomType.Emergency);
}

class ICURoom extends Room {
  ICURoom({required int roomNumber})
      : super(roomNumber: roomNumber, roomType: RoomType.ICU);
}

class GeneralRoom extends Room {
  GeneralRoom({required int roomNumber})
      : super(roomNumber: roomNumber, roomType: RoomType.General);
}
