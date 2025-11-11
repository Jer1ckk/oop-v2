enum BedStatus { Occupied, Available }

enum Gender { Male, Female }

enum PatientCode { Black, Red, Yellow, Green }

enum RoomType {
  Emergency(1),
  ICU(2),
  General(8);

  final int beds;
  const RoomType(this.beds);
}
