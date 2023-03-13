List findFreeTime(user1, user2, time1, time2) {
  // Grabs all the users events within the time frame given
  List user1Events = getUserTime(user1, time1, time2);
  List user2Events = getUserTime(user2, time1, time2);

  // freeTime will store all the time where the to users are free [[startTime,endTime]]
  List freeTimeList = [];

  // Variables for the logic of finding free time
  DateTime tempTime = time1;
  var freeTimeStart = true;
  DateTime temp = DateTime.now();

  while (tempTime.isBefore(time2)) {
    //Finds if the user has any events at the given time
    bool user1Free = freeTime(user1Events, tempTime);
    bool user2Free = freeTime(user2Events, tempTime);

    // checks if it is start of free time
    if (user1Free && user2Free && freeTimeStart) {
      temp = tempTime;
      freeTimeStart = false;
    }

    // checks if it is end of the free time
    if ((!user1Free || !user2Free) && !freeTimeStart) {
      freeTimeList.add([temp, tempTime]);
      freeTimeStart = true;
    }

    // increments the tempTime for every 5 minutes
    tempTime.add(const Duration(minutes: 5));
  }

  return freeTimeList;
}

List getUserTime(user, time1, time2) {
  /*------------------------------------
  The firebase events pull go here
  --------------------------------------*/
  // ignore: prefer_typing_uninitialized_variables
  var events; //Placeholder for the events pull

  List userEvents = [];

  for (final event in events) {
    //Event is spilt into 2 part [0] being event details and event.startTime being the start time and .endTime being the end time
    if (event.startTime.isAfter(time1) && event.endTime.isBefore(time2)) {
      userEvents.add(event);
    }
  }

  // .sort might need more work but we will see when testing
  userEvents.sort();

  return userEvents;
}

bool freeTime(events, time) {
  for (final event in events) {
    if (event.startTime.isAtSameMomentAs(time) ||
        event.endTime.isAtSameMomentAs(time) ||
        (event.startTime.isBefore(time) && event.endTime.isAfter(time))) {
      return false;
    }
  }
  return true;
}
