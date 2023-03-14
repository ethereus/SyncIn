Future<void> uploadEventDataToFirebase(List<Event> events) async {
  final DatabaseReference databaseRef =
      FirebaseDatabase.instance.reference().child('events');

  for (final event in events) {
    final Map<String, dynamic> eventData = {
      'summary': event.summary,
      'startTime': event.start.millisecondsSinceEpoch,
      'endTime': event.end.millisecondsSinceEpoch,
    };

    await databaseRef.push().set(eventData);
  }
}
