# SyncIn

**co-ordinating free time between friends**

Welcome to SyncIn,

Our product ensures students are getting the most out of their time. When students use socialising apps, such as snapchat, Instagram or WhatsApp it becomes increasingly more difficult to stay on topic with studying or focus in classes. ​
Our app offers an alternative, where a student can still arrange meet-ups and events with friends but it is fit around their studies. SyncIn helps avoid arranging events while some people would be busy with work or classes, allowing them to stay focused without the worry of missing out.

# Important

For this app to work you will need to set up FireBase Authentication to allow Google sign in and a FireBase Realtime Database with the following rules:

``
{ "rules": {
		"group_chat_messages": {
 			".read": true,
 			".write": true,
    },
    "free_time": {
 			".read": true,
 			".write": true,
    }
	}
}
``

And you will need the following permissions in your AndroidManifest.xml file:

``
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
``

You will also need to follow the steps to set up FireBase for your app, and make sure to include the **google-services.json** and **GoogleService-Info.plist** files from your FireBase app project. 

