Future<void> uploadEventDataToFirebase(List<Event> events) async {
  final DatabaseReference databaseRef =
      FirebaseDatabase.instance.reference().child('events');

  for (final event in events) {
    final Map<String, dynamic> eventData = {
      'summary': event.summary,
      'startTime': event.startTime,
      'endTime': event.endTime,
    };

    await databaseRef.push().set(eventData);
  }
}
