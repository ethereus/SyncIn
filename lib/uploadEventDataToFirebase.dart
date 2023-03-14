Future<void> uploadEventDataToFirebase(List<Event> events) async {
  final DatabaseReference databaseRef =
      FirebaseDatabase.instance.reference().child('events');

  for (final event in events) {
    final Map<String, dynamic> eventData = {
      'title': event.title,
      'description': event.description,
      'startTime': event.start.millisecondsSinceEpoch,
      'endTime': event.end.millisecondsSinceEpoch,
      'allDay': event.allDay,
    };

    await databaseRef.push().set(eventData);
  }
}
