import 'package:libpray/libpray.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'main.dart';

CalculationMethod bayynatCalc = CalculationMethod((CalculationMethodBuilder b) => b
      ..preset = CalculationMethodPreset.custom
      ..fajrParameter.replace(PrayerCalculationParameter((PrayerCalculationParameterBuilder b) => b
      ..type = PrayerCalculationParameterType.angle
      ..value = 18))
      ..maghribParameter.replace(PrayerCalculationParameter((PrayerCalculationParameterBuilder b) => b
      ..type = PrayerCalculationParameterType.minutesAdjust
      ..value = 13))
      ..ishaParameter.replace(PrayerCalculationParameter((PrayerCalculationParameterBuilder b) => b
      ..type = PrayerCalculationParameterType.angle
      ..value = 18))
      ..midnight = Midnight.jafari);
PrayerCalculationSettings bayynatSet = PrayerCalculationSettings((PrayerCalculationSettingsBuilder b) => b
      ..imsakParameter.value = -10.0
      ..imsakParameter.type = PrayerCalculationParameterType.minutesAdjust
      ..calculationMethod.replace(bayynatCalc)
      ..juristicMethod.replace(JuristicMethod.fromPreset(preset: JuristicMethodPreset.standard))
      ..highLatitudeAdjustment = HighLatitudeAdjustment.none
      ..imsakMinutesAdjustment = 0
      ..fajrMinutesAdjustment = 0
      ..sunriseMinutesAdjustment = 0
      ..dhuhaMinutesAdjustment = 0
      ..dhuhrMinutesAdjustment = 0
      ..asrMinutesAdjustment = 0
      ..maghribMinutesAdjustment = 0
      ..ishaMinutesAdjustment = 0);
PrayerCalculationSettings qomSet = PrayerCalculationSettings((PrayerCalculationSettingsBuilder b) => b
      ..imsakParameter.value = -10.0
      ..imsakParameter.type = PrayerCalculationParameterType.minutesAdjust
      ..calculationMethod.replace(CalculationMethod.fromPreset(preset: CalculationMethodPreset.ithnaAshari))
      ..juristicMethod.replace(JuristicMethod.fromPreset(preset: JuristicMethodPreset.standard))
      ..highLatitudeAdjustment = HighLatitudeAdjustment.none
      ..imsakMinutesAdjustment = 0
      ..fajrMinutesAdjustment = 0
      ..sunriseMinutesAdjustment = 0
      ..dhuhaMinutesAdjustment = 0
      ..dhuhrMinutesAdjustment = 0
      ..asrMinutesAdjustment = 0
      ..maghribMinutesAdjustment = 0
      ..ishaMinutesAdjustment = 0);
PrayerCalculationSettings tehranSet = PrayerCalculationSettings((PrayerCalculationSettingsBuilder b) => b
      ..imsakParameter.value = -10.0
      ..imsakParameter.type = PrayerCalculationParameterType.minutesAdjust
      ..calculationMethod.replace(CalculationMethod.fromPreset(preset: CalculationMethodPreset.instituteOfGeophysicsUniversityOfTehran))
      ..juristicMethod.replace(JuristicMethod.fromPreset(preset: JuristicMethodPreset.standard))
      ..highLatitudeAdjustment = HighLatitudeAdjustment.none
      ..imsakMinutesAdjustment = 0
      ..fajrMinutesAdjustment = 0
      ..sunriseMinutesAdjustment = 0
      ..dhuhaMinutesAdjustment = 0
      ..dhuhrMinutesAdjustment = 0
      ..asrMinutesAdjustment = 0
      ..maghribMinutesAdjustment = 0
      ..ishaMinutesAdjustment = 0);
      
Geocoordinate geo;
Prayers prayers;

Future<List<DateTime>> prayerTimes() async {
  SharedPreferences prefs;
  prefs = await SharedPreferences.getInstance();
  Geocoordinate geo = new Geocoordinate((GeocoordinateBuilder b) => b
    ..latitude = 0
    ..longitude = 0
    ..altitude = 0);
  
  Prayers prayers;
  DateTime midnight;
  
  if(prefs.getDouble('latitude')!=null&&prefs.getDouble('longitude')!=null&&prefs.getDouble('altitude')!=null){
    geo = Geocoordinate((GeocoordinateBuilder b) => b
      ..latitude=prefs.getDouble('latitude')
      ..longitude=prefs.getDouble('longitude')
      ..altitude=0);
  }else{
    LocationPermission permission = await checkPermission();
    while(permission==null){permission = await checkPermission();}
    print(permission);
    Position position;
    if(permission==LocationPermission.denied||permission==LocationPermission.deniedForever){
      return [DateTime.now().subtract(Duration(hours:DateTime.now().hour, minutes: DateTime.now().minute),),DateTime.now().subtract(Duration(hours:DateTime.now().hour, minutes: DateTime.now().minute),),DateTime.now().subtract(Duration(hours:DateTime.now().hour, minutes: DateTime.now().minute),),DateTime.now().subtract(Duration(hours:DateTime.now().hour, minutes: DateTime.now().minute),),DateTime.now().subtract(Duration(hours:DateTime.now().hour, minutes: DateTime.now().minute),),DateTime.now().subtract(Duration(hours:DateTime.now().hour, minutes: DateTime.now().minute),),DateTime.now().subtract(Duration(hours:DateTime.now().hour, minutes: DateTime.now().minute),)];
    }else{
      position = await getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      geo = Geocoordinate((GeocoordinateBuilder b) => b
        ..latitude = position.latitude
        ..longitude = position.longitude
        ..altitude = 0);
      prefs.setDouble('latitude', position.latitude);
      prefs.setDouble('longitude', position.longitude);
      prefs.setDouble('altitude', position.altitude);
    }
  }

  DateTime currentDate = DateTime.now();
  if(prefs.getInt('fajrOffset')==null) prefs.setInt('fajrOffset', 0);
  if(prefs.getInt('dhuhrOffset')==null) prefs.setInt('dhuhrOffset', 0);
  if(prefs.getInt('maghribOffset')==null) prefs.setInt('maghribOffset', 0);

  if(prefs.getInt('fajrOffset')!=0){
    qomSet=qomSet.rebuild((qomSet)=>qomSet.fajrMinutesAdjustment=prefs.getInt('fajrOffset'));
    tehranSet=tehranSet.rebuild((tehranSet)=>tehranSet.fajrMinutesAdjustment=prefs.getInt('fajrOffset'));
    bayynatSet=bayynatSet.rebuild((bayynatSet)=>bayynatSet.fajrMinutesAdjustment=prefs.getInt('fajrOffset'));
  }
  if(prefs.getInt('dhuhrOffset')!=0){
    qomSet=qomSet.rebuild((qomSet)=>qomSet.dhuhrMinutesAdjustment=prefs.getInt('dhuhrOffset'));
    tehranSet=tehranSet.rebuild((tehranSet)=>tehranSet.dhuhrMinutesAdjustment=prefs.getInt('dhuhrOffset'));
    bayynatSet=bayynatSet.rebuild((bayynatSet)=>bayynatSet.dhuhrMinutesAdjustment=prefs.getInt('dhuhrOffset'));
  }
  if(prefs.getInt('maghribOffset')!=0){
    qomSet=qomSet.rebuild((qomSet)=>qomSet.maghribMinutesAdjustment=prefs.getInt('maghribOffset'));
    tehranSet=tehranSet.rebuild((tehranSet)=>tehranSet.maghribMinutesAdjustment=prefs.getInt('maghribOffset'));
    bayynatSet=bayynatSet.rebuild((bayynatSet)=>bayynatSet.maghribMinutesAdjustment=prefs.getInt('maghribOffset'));
  }
  //currentDate.add(Duration(days: 30));
  double timezone = currentDate.timeZoneOffset.inHours.toDouble();
  
  if(prefs.getInt('calcMethod')!=null){
    switch (prefs.getInt('calcMethod')){
      case 0:
        prayers = Prayers.on(coordinate: geo, timeZone: timezone, date: currentDate, settings: qomSet);
        break;
      case 1:
        prayers = Prayers.on(coordinate: geo, timeZone: timezone, date: currentDate, settings: tehranSet);
        break;
      case 2:
        prayers = Prayers.on(coordinate: geo, timeZone: timezone, date: currentDate, settings: bayynatSet);
        break;
    }
  }else{
    prayers = Prayers.on(coordinate: geo, timeZone: timezone, date: currentDate, settings: qomSet);
    prefs.setInt('calcMethod', 0);
  }
  if(prefs.getInt('midnightMethod')!=null){
    switch (prefs.getInt('midnightMethod')){
      case 0:
        midnight=prayers.sunset.add(new Duration(minutes: (-prayers.sunset.difference(prayers.fajr.add(new Duration(days: 1))).inMinutes)~/2));
        break;
      case 1:
        midnight=prayers.sunset.add(new Duration(minutes: (-prayers.sunset.difference(prayers.sunrise.add(new Duration(days: 1))).inMinutes)~/2));
        break;
    }
  }else{
    midnight=prayers.sunset.add(new Duration(minutes: (-prayers.sunset.difference(prayers.fajr.add(new Duration(days: 1))).inMinutes)~/2));
    prefs.setInt('midnightMethod', 0);
  }
  List<DateTime> salahTimes = [prayers.imsak,prayers.fajr,prayers.sunrise,prayers.dhuhr,prayers.sunset,prayers.maghrib,midnight];
  return salahTimes;
}

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

setNotifcations(String s) async{
  SharedPreferences prefs;
  prefs = await SharedPreferences.getInstance();
  Geocoordinate geo = new Geocoordinate((GeocoordinateBuilder b) => b
    ..latitude = 0
    ..longitude = 0
    ..altitude = 0);
  
  Prayers prayers;
  DateTime midnight;
  
  if(prefs.getDouble('latitude')!=null&&prefs.getDouble('longitude')!=null&&prefs.getDouble('altitude')!=null){
    geo = Geocoordinate((GeocoordinateBuilder b) => b
      ..latitude=prefs.getDouble('latitude')
      ..longitude=prefs.getDouble('longitude')
      ..altitude=0);
  }else{
    LocationPermission permission = await Geolocator.checkPermission();
    while(permission==null){permission = await Geolocator.checkPermission();}
    Position position;
    if(permission==LocationPermission.denied||permission==LocationPermission.deniedForever){
      return [DateTime.now().subtract(Duration(hours:DateTime.now().hour, minutes: DateTime.now().minute),),DateTime.now().subtract(Duration(hours:DateTime.now().hour, minutes: DateTime.now().minute),),DateTime.now().subtract(Duration(hours:DateTime.now().hour, minutes: DateTime.now().minute),),DateTime.now().subtract(Duration(hours:DateTime.now().hour, minutes: DateTime.now().minute),),DateTime.now().subtract(Duration(hours:DateTime.now().hour, minutes: DateTime.now().minute),),DateTime.now().subtract(Duration(hours:DateTime.now().hour, minutes: DateTime.now().minute),),DateTime.now().subtract(Duration(hours:DateTime.now().hour, minutes: DateTime.now().minute),)];
    }else{
      position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      geo = Geocoordinate((GeocoordinateBuilder b) => b
        ..latitude = position.latitude
        ..longitude = position.longitude
        ..altitude = 0);
      prefs.setDouble('latitude', position.latitude);
      prefs.setDouble('longitude', position.longitude);
      prefs.setDouble('altitude', position.altitude);
    }
  }

  DateTime currentDate = DateTime.now();
  if(prefs.getInt('fajrOffset')==null) prefs.setInt('fajrOffset', 0);
  if(prefs.getInt('dhuhrOffset')==null) prefs.setInt('dhuhrOffset', 0);
  if(prefs.getInt('maghribOffset')==null) prefs.setInt('maghribOffset', 0);

  if(prefs.getInt('fajrOffset')!=0){
    qomSet=qomSet.rebuild((qomSet)=>qomSet.fajrMinutesAdjustment=prefs.getInt('fajrOffset'));
    tehranSet=tehranSet.rebuild((tehranSet)=>tehranSet.fajrMinutesAdjustment=prefs.getInt('fajrOffset'));
    bayynatSet=bayynatSet.rebuild((bayynatSet)=>bayynatSet.fajrMinutesAdjustment=prefs.getInt('fajrOffset'));
  }
  if(prefs.getInt('dhuhrOffset')!=0){
    qomSet=qomSet.rebuild((qomSet)=>qomSet.dhuhrMinutesAdjustment=prefs.getInt('dhuhrOffset'));
    tehranSet=tehranSet.rebuild((tehranSet)=>tehranSet.dhuhrMinutesAdjustment=prefs.getInt('dhuhrOffset'));
    bayynatSet=bayynatSet.rebuild((bayynatSet)=>bayynatSet.dhuhrMinutesAdjustment=prefs.getInt('dhuhrOffset'));
  }
  if(prefs.getInt('maghribOffset')!=0){
    qomSet=qomSet.rebuild((qomSet)=>qomSet.maghribMinutesAdjustment=prefs.getInt('maghribOffset'));
    tehranSet=tehranSet.rebuild((tehranSet)=>tehranSet.maghribMinutesAdjustment=prefs.getInt('maghribOffset'));
    bayynatSet=bayynatSet.rebuild((bayynatSet)=>bayynatSet.maghribMinutesAdjustment=prefs.getInt('maghribOffset'));
  }
  //currentDate.add(Duration(days: 30));
  double timezone = currentDate.timeZoneOffset.inHours.toDouble();
  
  if(prefs.getInt('calcMethod')!=null){
    switch (prefs.getInt('calcMethod')){
      case 0:
        prayers = Prayers.on(coordinate: geo, timeZone: timezone, date: currentDate, settings: qomSet);
        break;
      case 1:
        prayers = Prayers.on(coordinate: geo, timeZone: timezone, date: currentDate, settings: tehranSet);
        break;
      case 2:
        prayers = Prayers.on(coordinate: geo, timeZone: timezone, date: currentDate, settings: bayynatSet);
        break;
    }
  }else{
    prayers = Prayers.on(coordinate: geo, timeZone: timezone, date: currentDate, settings: qomSet);
    prefs.setInt('calcMethod', 0);
  }
  if(prefs.getInt('midnightMethod')!=null){
    switch (prefs.getInt('midnightMethod')){
      case 0:
        midnight=prayers.sunset.add(new Duration(minutes: (-prayers.sunset.difference(prayers.fajr.add(new Duration(days: 1))).inMinutes)~/2));
        break;
      case 1:
        midnight=prayers.sunset.add(new Duration(minutes: (-prayers.sunset.difference(prayers.sunrise.add(new Duration(days: 1))).inMinutes)~/2));
        break;
    }
  }else{
    midnight=prayers.sunset.add(new Duration(minutes: (-prayers.sunset.difference(prayers.fajr.add(new Duration(days: 1))).inMinutes)~/2));
    prefs.setInt('midnightMethod', 0);
  }
  List<DateTime> prayersTimes = [prayers.imsak,prayers.fajr,prayers.sunrise,prayers.dhuhr,prayers.sunset,prayers.maghrib,midnight];
  bool fajrOn, dhuhrOn, maghribOn;
  if(prefs.getBool('fajrOn')==null) {await prefs.setBool('fajrOn', true); fajrOn=true;}
  else fajrOn=prefs.getBool('fajrOn');
  if(prefs.getBool('dhuhrOn')==null) {await prefs.setBool('dhuhrOn', true); dhuhrOn=true;}
  else dhuhrOn=prefs.getBool('dhuhrOn');
  if(prefs.getBool('maghribOn')==null) {await prefs.setBool('maghribOn', true); maghribOn=true;}
  else maghribOn=prefs.getBool('maghribOn');
  var notifcationdetails;
  var rammal = NotificationDetails(android:AndroidNotificationDetails('adhanChannelRammal', 'Adhan', 'Adhan', sound: RawResourceAndroidNotificationSound('rammal'), playSound: true, priority: Priority.max, importance: Importance.max, enableVibration: true));
  var qatari = NotificationDetails(android:AndroidNotificationDetails('adhanChannelQatari', 'Adhan', 'Adhan', sound: RawResourceAndroidNotificationSound('qatari'), playSound: true, priority: Priority.max, importance: Importance.max, enableVibration: true));
  var dabbagh = NotificationDetails(android:AndroidNotificationDetails('adhanChannelDabbagh', 'Adhan', 'Adhan', sound: RawResourceAndroidNotificationSound('dabbagh'), playSound: true, priority: Priority.max, importance: Importance.max, enableVibration: true));
  var tlees = NotificationDetails(android:AndroidNotificationDetails('adhanChannelTlees', 'Adhan', 'Adhan', sound: RawResourceAndroidNotificationSound('tlees'), playSound: true, priority: Priority.max, importance: Importance.max, enableVibration: true));
  var vibrate = NotificationDetails(android:AndroidNotificationDetails('adhanChannelTlees', 'Adhan', 'Adhan', playSound: false, priority: Priority.max, importance: Importance.max, enableVibration: true));
  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_launcher');
  final IOSInitializationSettings initializationSettingsIOS = IOSInitializationSettings(onDidReceiveLocalNotification: (a,b,c,d)async{});
  flutterLocalNotificationsPlugin.initialize(InitializationSettings(android:initializationSettingsAndroid, iOS:initializationSettingsIOS));
  tz.initializeTimeZones();
  if(prefs.getInt('adhanRecitor')!=null){
    switch (prefs.getInt('adhanRecitor')) {
      case 0:
        notifcationdetails=rammal;
        break;
      case 1:
        notifcationdetails=qatari;
        break;
      case 2:
        notifcationdetails=dabbagh;
        break;
      case 3:
        notifcationdetails=tlees;
        break;
      case 4:
        notifcationdetails=vibrate;
        break;
    }
  }else{
    prefs.setInt('adhanRecitor', 0);
    notifcationdetails=rammal;
  }

  if(fajrOn&&prayersTimes[1].isAfter(DateTime.now())){
    flutterLocalNotificationsPlugin.zonedSchedule(0, "Time to pray!", "Time to pray Fajr!", tz.TZDateTime.from(prayersTimes[1], tz.local), notifcationdetails, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime, androidAllowWhileIdle: true);
  }
  if(dhuhrOn&&prayersTimes[3].isAfter(DateTime.now())){
    flutterLocalNotificationsPlugin.zonedSchedule(1, "Time to pray!", "Time to pray Dhuhr!", tz.TZDateTime.from(prayersTimes[3], tz.local), notifcationdetails, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime, androidAllowWhileIdle: true);
  }
  if(maghribOn&&prayersTimes[5].isAfter(DateTime.now())){
    flutterLocalNotificationsPlugin.zonedSchedule(2, "Time to pray!", "Time to pray Maghrib!", tz.TZDateTime.from(prayersTimes[5], tz.local), notifcationdetails, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime, androidAllowWhileIdle: true);
  }
  List<PendingNotificationRequest> pending = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
  prefs.setString("lastFetch", DateTime.now().toString());
  print(DateTime.now().toString());
  var i = 0;
  try{
    if(prefs.containsKey('numOfFetches')) i = prefs.getInt("numOfFetches");
  }catch(e){
    i = 0;
  }
  prefs.setInt('numOfFetches', i+1);
}