import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:libpray/libpray.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shiahub2/adhan.dart';
import 'package:shiahub2/contact.dart';
import 'package:shiahub2/marja.dart';
import 'package:shiahub2/quran.dart';
import 'theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dua.dart';
import 'package:hijri/umm_alqura_calendar.dart';
import 'package:background_fetch/background_fetch.dart';


void main() {
  runApp(MyApp());
  BackgroundFetch.registerHeadlessTask(setNotifcations);
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        backgroundColor: Colors.white,
        scaffoldBackgroundColor: MyColors.background(),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: TextTheme(
          headline5: TextStyle(
            color: Colors.white,
          ),
          headline6: TextStyle(
            color: Colors.white,
          )
        )
      ),
      home: MyHomePage(title: 'ShiaHub'),
      routes: <String, WidgetBuilder>{
        "/quran/": (BuildContext context) => new JuzOrSurah(),
        "/quran/juz/": (BuildContext context) => new Juz(),
        "/quran/surah/": (BuildContext context) => new Surah(),
        "/duas/": (BuildContext context) => new DuaList(json: "duas.json", title: "Duas",),
        "/munajat/": (BuildContext context) => new DuaList(json: "munajat.json", title: "Munajat",),
        "/sahifa/": (BuildContext context) => new DuaList(json: "sahifa.json", title: "Sahifa Sajadiyyah",),
        "/taaqibat/": (BuildContext context) => new DuaList(json: "taaqibat.json", title: "Taaqibat",),
        "/ziyarat/": (BuildContext context) => new DuaList(json: "ziyarat.json", title: "Ziyarat",),
        "/marja/": (BuildContext context) => new Marja(),
        "/contact/": (BuildContext context) => new Contact(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<DateTime> salahTimes;
  SharedPreferences prefs;
  bool fajrOn = true, dhuhrOn = true, maghribOn = true;
  double fajrOffset = 0, dhuhrOffset = 0, maghribOffset = 0;
  bool isSettings = false;
  int calcMethod = 0, midnightMethod = 0, adhanReciter = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  TextEditingController _locationText = new TextEditingController();
  String loc = '';

  @override
  void initState(){
    loadPrayerTimes();
    super.initState();
  }
  loadPrayerTimes()async{
    prefs = await SharedPreferences.getInstance();
    try{
      print(prefs.getString("lastFetch"));
    }catch(e){
      print(e.toString());
    }
    try{
      print(prefs.getInt("numOfFetches"));
    }catch(e){
      print(e.toString());
    }
    await requestPermission();
    BackgroundFetch.configure(BackgroundFetchConfig(
        minimumFetchInterval: 15,
        stopOnTerminate: false,
        enableHeadless: true,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
        requiredNetworkType: NetworkType.NONE,
        startOnBoot: true,
        
    ), setNotifcations);

    salahTimes= await prayerTimes();
    
    if(prefs.containsKey("fajrOn")){
      fajrOn = prefs.getBool("fajrOn");
      dhuhrOn = prefs.getBool("dhuhrOn");
      maghribOn = prefs.getBool("maghribOn");
      fajrOffset = prefs.getInt("fajrOffset").toDouble();
      dhuhrOffset = prefs.getInt("dhuhrOffset").toDouble();
      maghribOffset = prefs.getInt("maghribOffset").toDouble();
      calcMethod = prefs.getInt("calcMethod");
      midnightMethod = prefs.getInt("midnightMethod");
      adhanReciter = prefs.getInt("adhanRecitor");
    }else{
      prefs.setBool("fajrOn", true);
      prefs.setBool("dhuhrOn", true);
      prefs.setBool("maghribOn", true);
      prefs.setInt("fajrOffset", 0);
      prefs.setInt("dhuhrOffset", 0);
      prefs.setInt("maghribOffset", 0);
      prefs.setInt("calcMethod", 0);
      prefs.setInt("midnightMethod", 0);
      prefs.setInt('adhanReciter', 0);
    }
    setState(() {
      
    });
  }



  @override
  Widget build(BuildContext context) {

    Widget settings(){
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: MyColors.background(),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              toolbarHeight: toolbarSize(context),
              backgroundColor: MyColors.appBar(),
              leading: Padding(
                child: IconButton(icon: Icon(Icons.arrow_back_ios), onPressed: ()async{isSettings=false;await loadPrayerTimes();setState(() {
                  
                });}, ),
                padding: EdgeInsets.only(top: MediaQuery.of(context).size.height*0.015),
              ),
              title: Padding(
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Settings", style: Theme.of(context).textTheme.headline6.copyWith(fontSize: titleSize(context))),
                  ]
                ),
                padding: EdgeInsets.fromLTRB(0, MediaQuery.of(context).size.height*0.015, 0, 0),
              ),
              actions: [Container(width: 56,)],
              centerTitle: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))
              ),
              bottom: PreferredSize(                       // Add this code
                preferredSize: Size(double.infinity,MediaQuery.of(context).size.height*0.02),      // Add this code
                child: Text("")
              ) 
            ),
            SliverToBoxAdapter(
              child: WillPopScope(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      height: MediaQuery.of(context).size.height*0.8,
                      child: new Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Text("Adhan Notifications", style: TextStyle(color: MyColors.text()),),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text("Fajr", style: TextStyle(color: MyColors.text()),),
                              Switch(
                                value: fajrOn,
                                onChanged: (d)async{
                                  prefs.setBool("fajrOn", d);
                                  fajrOn=d;
                                  setState(() {
                                    
                                  });
                                },
                                activeColor: MyColors.sliderInactive(),
                                activeTrackColor: MyColors.sliderActive(),
                                inactiveThumbColor: MyColors.sliderActive(),
                                inactiveTrackColor: MyColors.sliderInactive(),
                              ),
                              Text("Dhuhr", style: TextStyle(color: MyColors.text()),),
                              Switch(
                                value: dhuhrOn,
                                onChanged: (d)async{
                                  prefs.setBool("dhuhrOn", d);
                                  dhuhrOn=d;
                                  setState(() {
                                    
                                  });
                                },
                                activeColor: MyColors.sliderInactive(),
                                activeTrackColor: MyColors.sliderActive(),
                                inactiveThumbColor: MyColors.sliderActive(),
                                inactiveTrackColor: MyColors.sliderInactive(),
                              ),
                              Text("Maghrib", style: TextStyle(color: MyColors.text()),),
                              Switch(
                                value: maghribOn,
                                onChanged: (d)async{
                                  prefs.setBool("maghribOn", d);
                                  maghribOn=d;
                                  setState(() {
                                    
                                  });
                                },
                                activeColor: MyColors.sliderInactive(),
                                activeTrackColor: MyColors.sliderActive(),
                                inactiveThumbColor: MyColors.sliderActive(),
                                inactiveTrackColor: MyColors.sliderInactive(),
                              ),
                            ],
                          ),
                          Text("Calculation Method", style: TextStyle(color: MyColors.text()),),
                          Padding(padding: EdgeInsets.only(top: 5, left: 10, right: 10, bottom: 10),
                            child: Container(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children:[
                                  Container(
                                    child: DropdownButton(
                                      isExpanded: true,
                                      style: TextStyle(color: Colors.white,),
                                      dropdownColor: MyColors.sliderActive(),
                                      underline: Container(),
                                      iconEnabledColor: MyColors.text(),
                                      items: [
                                        DropdownMenuItem(
                                          child: LayoutBuilder(
                                            builder: (BuildContext context, BoxConstraints constraints) {
                                              return Container(
                                                width: constraints.maxWidth,
                                                child:Text("Leva Research Institute, Qom", overflow: TextOverflow.clip, textAlign: TextAlign.center, style: TextStyle(
                                                  color: MyColors.text()
                                                ),)
                                              );
                                            }
                                          ),
                                          value: 0,
                                        ),
                                        DropdownMenuItem(
                                          child: LayoutBuilder(
                                            builder: (BuildContext context, BoxConstraints constraints) {
                                              return Container(
                                                width: constraints.maxWidth,
                                                child:Text("Institute of Geophysics, Tehran", overflow: TextOverflow.clip, textAlign: TextAlign.center, style: TextStyle(
                                                  color: MyColors.text()
                                                ),)
                                              );
                                            }
                                          ),
                                          value: 1,
                                        ),
                                        DropdownMenuItem(
                                          child: LayoutBuilder(
                                            builder: (BuildContext context, BoxConstraints constraints) {
                                              return Container(
                                                width: constraints.maxWidth,
                                                child:Text("Bayynat, Lebanon (Sayyed Fadlallah", overflow: TextOverflow.clip, textAlign: TextAlign.center, style: TextStyle(
                                                  color: MyColors.text()
                                                ),)
                                              );
                                            }
                                          ),
                                          value: 2,
                                        ),
                                      ],
                                      onChanged: (value)async{
                                        calcMethod = value;
                                        prefs.setInt("calcMethod", value);
                                        await loadPrayerTimes();
                                        setState(() {
                                          
                                        });
                                      },
                                      value: calcMethod,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      color: MyColors.sliderActive(),
                                    ),
                                  )
                                  
                                ]
                              )
                            ),
                          ),
                          Text("Midnight Method", style: TextStyle(color: MyColors.text()),),
                          Padding(padding: EdgeInsets.only(top: 5, left: 10, right: 10),
                            child: Container(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children:[
                                  Container(
                                    child: DropdownButton(
                                      isExpanded: true,
                                      style: TextStyle(color: Colors.white,),
                                      dropdownColor: MyColors.sliderActive(),
                                      underline: Container(),
                                      iconEnabledColor: MyColors.text(),
                                      items: [
                                        DropdownMenuItem(
                                          child: LayoutBuilder(
                                            builder: (BuildContext context, BoxConstraints constraints) {
                                              return Container(
                                                width: constraints.maxWidth,
                                                child:Text("Sunset to Fajr (Sistani, Khamenei, Fadlallah)", overflow: TextOverflow.clip, textAlign: TextAlign.center, style: TextStyle(
                                                  color: MyColors.text()
                                                ),)
                                              );
                                            }
                                          ),
                                          value: 0,
                                        ),
                                        DropdownMenuItem(
                                          child: LayoutBuilder(
                                            builder: (BuildContext context, BoxConstraints constraints) {
                                              return Container(
                                                width: constraints.maxWidth,
                                                child:Text("Sunset to Sunrise (Khoei)", overflow: TextOverflow.clip, textAlign: TextAlign.center, style: TextStyle(
                                                  color: MyColors.text()
                                                ),)
                                              );
                                            }
                                          ),
                                          value: 1,
                                        ),
                                      ],
                                      onChanged: (value)async{
                                        midnightMethod = value;
                                        prefs.setInt("midnightMethod", value);
                                        await loadPrayerTimes();
                                        setState(() {
                                          
                                        });
                                      },
                                      value: midnightMethod,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      color: MyColors.sliderActive(),
                                    ),
                                  )
                                  
                                ]
                              )
                            ),
                          ),
                          Padding(padding: EdgeInsets.only(top: 15)),
                          Text("Adhan Offsets", style: TextStyle(color: MyColors.text()),),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Flexible(flex: 4, child: Text("Fajr", style: TextStyle(color: MyColors.text()), textAlign: TextAlign.center,), fit: FlexFit.tight,),
                              Flexible(flex: 14, child: Slider(
                                value: fajrOffset,
                                inactiveColor: MyColors.sliderActive(),
                                activeColor: MyColors.sliderInactive(),
                                min: -20,
                                max: 20,
                                divisions: 40,
                                onChangeEnd: (d){
                                  prefs.setInt("fajrOffset", d.toInt());
                                },
                                onChanged: (d)async{
                                  fajrOffset=d;
                                  setState(() {
                                    
                                  });
                                },
                              )),
                              Flexible(flex: 2, child: Text(fajrOffset.toInt().toString(), style: TextStyle(color: MyColors.text())), fit: FlexFit.tight,),
                            ],
                          ),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Flexible(flex: 4, child: Text("Dhuhr", style: TextStyle(color: MyColors.text()), textAlign: TextAlign.center,), fit: FlexFit.tight,),
                              Flexible(flex: 14, child: Slider(
                                value: dhuhrOffset,
                                inactiveColor: MyColors.sliderActive(),
                                activeColor: MyColors.sliderInactive(),
                                min: -20,
                                max: 20,
                                divisions: 40,
                                onChangeEnd: (d){
                                  prefs.setInt("dhuhrOffset", d.toInt());
                                },
                                onChanged: (d)async{
                                  dhuhrOffset=d;
                                  setState(() {
                                    
                                  });
                                },
                              )),
                              Flexible(flex: 2, child: Text(dhuhrOffset.toInt().toString(), style: TextStyle(color: MyColors.text()),), fit: FlexFit.tight,),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Flexible(flex: 4, child: Text("Maghrib", style: TextStyle(color: MyColors.text()), textAlign: TextAlign.center,), fit: FlexFit.tight,),
                              Flexible(flex: 14, child: Slider(
                                value: maghribOffset,
                                inactiveColor: MyColors.sliderActive(),
                                activeColor: MyColors.sliderInactive(),
                                min: -20,
                                max: 20,
                                divisions: 40,
                                onChangeEnd: (d){
                                  prefs.setInt("maghribOffset", d.toInt());
                                },
                                onChanged: (d)async{
                                  maghribOffset=d;
                                  setState(() {
                                    
                                  });
                                },
                              )),
                              Flexible(flex: 2, child: Text(maghribOffset.toInt().toString(), style: TextStyle(color: MyColors.text()),), fit: FlexFit.tight,),
                            ],
                          ),
                          Text("Adhan Voice", style: TextStyle(color: MyColors.text()),),
                          Padding(padding: EdgeInsets.only(top: 5, left: 10, right: 10),
                            child: Container(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children:[
                                  Container(
                                    child: Container(
                                      child: DropdownButton(
                                        isExpanded: true,
                                        style: TextStyle(color: Colors.white,),
                                        dropdownColor: MyColors.background(),
                                        underline: Container(),
                                        iconEnabledColor: MyColors.text(),
                                        items: [
                                          DropdownMenuItem(
                                            child: LayoutBuilder(
                                              builder: (BuildContext context, BoxConstraints constraints) {
                                                return Container(
                                                  width: constraints.maxWidth,
                                                  child:Text("Hajj Mohammad Rammal", overflow: TextOverflow.clip, textAlign: TextAlign.center, style: TextStyle(
                                                    color: MyColors.text()
                                                  ),)
                                                );
                                              }
                                            ),
                                            value: 0,
                                          ),
                                          DropdownMenuItem(
                                            child: LayoutBuilder(
                                              builder: (BuildContext context, BoxConstraints constraints) {
                                                return Container(
                                                  width: constraints.maxWidth,
                                                  child:Text("Nizar Al Qatari", overflow: TextOverflow.clip, textAlign: TextAlign.center, style: TextStyle(
                                                    color: MyColors.text()
                                                  ),)
                                                );
                                              }
                                            ),
                                            value: 1,
                                          ),
                                          DropdownMenuItem(
                                            child: LayoutBuilder(
                                              builder: (BuildContext context, BoxConstraints constraints) {
                                                return Container(
                                                  width: constraints.maxWidth,
                                                  child:Text("Ahmad Al Dabbagh", overflow: TextOverflow.clip, textAlign: TextAlign.center, style: TextStyle(
                                                    color: MyColors.text()
                                                  ),)
                                                );
                                              }
                                            ),
                                            value: 2,
                                          ),
                                          DropdownMenuItem(
                                            child: LayoutBuilder(
                                              builder: (BuildContext context, BoxConstraints constraints) {
                                                return Container(
                                                  width: constraints.maxWidth,
                                                  child:Text("Hussein Ali Qasem Tlees", overflow: TextOverflow.clip, textAlign: TextAlign.center, style: TextStyle(
                                                    color: MyColors.text()
                                                  ),)
                                                );
                                              }
                                            ),
                                            value: 3,
                                          ),
                                          DropdownMenuItem(
                                            child: LayoutBuilder(
                                              builder: (BuildContext context, BoxConstraints constraints) {
                                                return Container(
                                                  width: constraints.maxWidth,
                                                  child:Text("Vibrate", overflow: TextOverflow.clip, textAlign: TextAlign.center, style: TextStyle(
                                                    color: MyColors.text()
                                                  ),)
                                                );
                                              }
                                            ),
                                            value: 4,
                                          ),
                                        ],
                                        onChanged: (value)async{
                                          await prefs.setInt('adhanRecitor', value);
                                          adhanReciter = value;
                                          setState(() {
                                            
                                          });
                                        },
                                        value: adhanReciter,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10.0),
                                        color: MyColors.sliderActive(),
                                      ),
                                    )
                                  )
                                ]
                              )
                            )
                          ),
                          Padding(padding: EdgeInsets.only(top: 15)),
                          InkWell(
                            child: Container(
                              child: Text("Test Adhan", style: TextStyle(color: MyColors.text()),),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: MyColors.sliderActive(),
                              ),
                              padding: EdgeInsets.all(MediaQuery.of(context).size.width*0.04),
                            ),
                            onTap: ()async{
                              var notifcationdetails;
                              var rammal = NotificationDetails(android:AndroidNotificationDetails('adhanChannelRammal', 'Adhan', 'Adhan', sound: RawResourceAndroidNotificationSound('rammal'), playSound: true, priority: Priority.max, importance: Importance.max));
                              var qatari = NotificationDetails(android:AndroidNotificationDetails('adhanChannelQatari', 'Adhan', 'Adhan', sound: RawResourceAndroidNotificationSound('qatari'), playSound: true, priority: Priority.max, importance: Importance.max, enableVibration: true));
                              var dabbagh = NotificationDetails(android:AndroidNotificationDetails('adhanChannelDabbagh', 'Adhan', 'Adhan', sound: RawResourceAndroidNotificationSound('dabbagh'), playSound: true, priority: Priority.max, importance: Importance.max, enableVibration: true));
                              var tlees = NotificationDetails(android:AndroidNotificationDetails('adhanChannelTlees', 'Adhan', 'Adhan', sound: RawResourceAndroidNotificationSound('tlees'), playSound: true, priority: Priority.max, importance: Importance.max, enableVibration: true));
                              var vibrate = NotificationDetails(android:AndroidNotificationDetails('adhanChannelTlees', 'Adhan', 'Adhan', playSound: false, priority: Priority.max, importance: Importance.max, enableVibration: true));
                              flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
                              // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
                              const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_launcher');
                              final IOSInitializationSettings initializationSettingsIOS = IOSInitializationSettings(onDidReceiveLocalNotification: (a,b,c,d)async{});
                              flutterLocalNotificationsPlugin.initialize(InitializationSettings(android:initializationSettingsAndroid, iOS:initializationSettingsIOS));
                              switch (adhanReciter) {
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
                              flutterLocalNotificationsPlugin.show(3, "Test Adhan", "Test Adhan", notifcationdetails);
                              var path = await getApplicationDocumentsDirectory();
                              print(await Directory((await path.parent.list().toList())[0].path).list().toList());
                            },
                          ),
                          Padding(padding: EdgeInsets.only(top: 15)),
                          Text("Location", style: TextStyle(color: MyColors.text()),),
                          Padding(padding: EdgeInsets.only(top: 5)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              InkWell(
                                child: Container(
                                  child: Text("Find Location by GPS", style: TextStyle(color: MyColors.text()),),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                    color: MyColors.sliderActive(),
                                  ),
                                  padding: EdgeInsets.all(MediaQuery.of(context).size.width*0.04),
                                ),
                                onTap: ()async{
                                  LocationPermission permission = await requestPermission();
                                  Position position;
                                  if(permission==LocationPermission.denied||permission==LocationPermission.deniedForever){
                                    var snackBar = SnackBar(
                                      content: Text('Unable to Retrieve Location'),
                                    );
                                    _scaffoldKey.currentState.showSnackBar(snackBar);
                                  }else{
                                    position = await getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                                    geo = Geocoordinate((GeocoordinateBuilder b) => b
                                      ..latitude = position.latitude
                                      ..longitude = position.longitude
                                      ..altitude = 0);
                                    prefs.setDouble('latitude', position.latitude);
                                    prefs.setDouble('longitude', position.longitude);
                                    prefs.setDouble('altitude', position.altitude);
                                    salahTimes = await prayerTimes();
                                    var snackBar = SnackBar(
                                      content: Text('Location Set!'),
                                    );
                                    _scaffoldKey.currentState.showSnackBar(snackBar);
                                  }
                                },
                              ),
                              InkWell(
                                child: Container(
                                  child: Text("Set Location Manually", style: TextStyle(color: MyColors.text()),),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                    color: MyColors.sliderActive(),
                                  ),
                                  padding: EdgeInsets.all(MediaQuery.of(context).size.width*0.04),
                                ),
                                onTap: ()async{
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context){
                                      return AlertDialog(
                                        title: new Text("Location", style: TextStyle(color: MyColors.text()),),
                                        content: SingleChildScrollView(
                                          child: Container(
                                            child: TextField(
                                              controller: _locationText,
                                              style: TextStyle(color: MyColors.text()),
                                              enabled: true,
                                              maxLines: 2,
                                              decoration: InputDecoration(
                                                hintStyle: TextStyle(color: MyColors.springGreen()),
                                                hintText: 'Please enter a location (address, city, etc)',
                                                border: InputBorder.none
                                              ),
                                              onChanged: (String e){
                                                loc = e;
                                                setState(() {
                                                  
                                                });
                                              }
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(10.0),
                                              color: MyColors.sliderActive(),
                                            ),
                                            padding: EdgeInsets.only(left: MediaQuery.of(context).size.width*0.02, right: MediaQuery.of(context).size.width*0.02),
                                          ),
                                        ),
                                        actions: <Widget>[
                                          new Row(
                                            children: <Widget>[
                                              new FlatButton(
                                                child: new Text("Set", style: TextStyle(color: MyColors.text())),
                                                onPressed: ()async{
                                                  if(loc!=''){
                                                    List<Location> geo = await locationFromAddress(loc);
                                                    if(geo.length!=0){
                                                      Location geoCo = geo[0];
                                                      prefs.setDouble('latitude', geoCo.latitude);
                                                      prefs.setDouble('longitude', geoCo.longitude);
                                                      prefs.setDouble('altitude', 0);
                                                      salahTimes = await prayerTimes();
                                                      var snackBar = SnackBar(
                                                        content: Text('Location Found and Set!'),
                                                      );
                                                      _scaffoldKey.currentState.showSnackBar(snackBar);
                                                      Navigator.pop(context);
                                                    }else{
                                                      var snackBar = SnackBar(
                                                        content: Text('Location Not Found!'),
                                                      );
                                                      _scaffoldKey.currentState.showSnackBar(snackBar);
                                                    }
                                                  }else{
                                                    var snackBar = SnackBar(
                                                      content: Text('No Location Entered!'),
                                                    );
                                                    _scaffoldKey.currentState.showSnackBar(snackBar);
                                                    Navigator.of(context).pop();
                                                  }
                                                },
                                              ),
                                              new FlatButton(
                                                child: new Text("Back", style: TextStyle(color: MyColors.text())),
                                                onPressed: (){
                                                  Navigator.of(context).pop();
                                                },
                                              )
                                            ],
                                          )
                                        ],
                                        backgroundColor: MyColors.card(),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20.0)
                                        ),
                                      );
                                    },
                                  );
                                },
                              )
                            ],
                          )
                        ]
                      )
                    ),
                  ],
                ),
                onWillPop: () async {
                  isSettings=false;
                  await loadPrayerTimes();
                  setState(() {
                    
                  });
                  return Future.value(false);
                  
                },
              )
            )
          ]
        )
      );
    }

    
  
    return isSettings?settings():Scaffold(
      /*appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))
        ),
      ),*/
      body: HomeCardList(
        appbar: SliverAppBar(
          toolbarHeight: toolbarSize(context),
          leading: IconButton(icon: Container(), onPressed: (){}),
          actions: [
            IconButton(
              icon: Icon(Icons.calendar_today),
              padding: EdgeInsets.only(top: MediaQuery.of(context).size.width*0.03),
              onPressed: (){
                showDialog(
                  context: context,
                  builder: (BuildContext context){
                    return AlertDialog(
                      title: new Text("Prayer Times", style: TextStyle(color: MyColors.text(), fontSize: MediaQuery.of(context).size.width*0.06), textAlign: TextAlign.center,),
                      content:Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment:MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Imsak:", style: TextStyle(color: MyColors.text(), fontSize: MediaQuery.of(context).size.width*0.05),),
                              Text(salahTimes!=null?hourIn24(salahTimes[0].hour).toString() + ":" + lessThan10(salahTimes[0].minute).toString()+(salahTimes[0].hour>=12?" PM":" AM"):"", style: TextStyle(color: MyColors.text(), fontSize: MediaQuery.of(context).size.width*0.05),)
                            ]
                          ),
                          Padding(padding: EdgeInsets.only(bottom: 5)),
                          Row(
                            mainAxisAlignment:MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Fajr:", style: TextStyle(color: MyColors.text(), fontSize: MediaQuery.of(context).size.width*0.05),),
                              Text(salahTimes!=null?hourIn24(salahTimes[1].hour).toString() + ":" + lessThan10(salahTimes[1].minute).toString()+(salahTimes[1].hour>=12?" PM":" AM"):"", style: TextStyle(color: MyColors.text(), fontSize: MediaQuery.of(context).size.width*0.05),)
                            ]
                          ),
                          Padding(padding: EdgeInsets.only(bottom: 5)),
                          Row(
                            mainAxisAlignment:MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Sunrise:", style: TextStyle(color: MyColors.text(), fontSize: MediaQuery.of(context).size.width*0.05),),
                              Text(salahTimes!=null?hourIn24(salahTimes[2].hour).toString() + ":" + lessThan10(salahTimes[2].minute).toString()+(salahTimes[2].hour>=12?" PM":" AM"):"", style: TextStyle(color: MyColors.text(), fontSize: MediaQuery.of(context).size.width*0.05),)
                            ]
                          ),
                          Padding(padding: EdgeInsets.only(bottom: 5)),
                          Row(
                            mainAxisAlignment:MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Dhuhr:", style: TextStyle(color: MyColors.text(), fontSize: MediaQuery.of(context).size.width*0.05),),
                              Text(salahTimes!=null?hourIn24(salahTimes[3].hour).toString() + ":" + lessThan10(salahTimes[3].minute).toString()+(salahTimes[3].hour>=12?" PM":" AM"):"", style: TextStyle(color: MyColors.text(), fontSize: MediaQuery.of(context).size.width*0.05),)
                            ]
                          ),
                          Padding(padding: EdgeInsets.only(bottom: 5)),
                          Row(
                            mainAxisAlignment:MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Sunset:", style: TextStyle(color: MyColors.text(), fontSize: MediaQuery.of(context).size.width*0.05),),
                              Text(salahTimes!=null?hourIn24(salahTimes[4].hour).toString() + ":" + lessThan10(salahTimes[4].minute).toString()+(salahTimes[4].hour>=12?" PM":" AM"):"", style: TextStyle(color: MyColors.text(), fontSize: MediaQuery.of(context).size.width*0.05),)
                            ]
                          ),
                          Padding(padding: EdgeInsets.only(bottom: 5)),
                          Row(
                            mainAxisAlignment:MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Maghrib:", style: TextStyle(color: MyColors.text(), fontSize: MediaQuery.of(context).size.width*0.05),),
                              Text(salahTimes!=null?hourIn24(salahTimes[5].hour).toString() + ":" + lessThan10(salahTimes[5].minute).toString()+(salahTimes[5].hour>=12?" PM":" AM"):"", style: TextStyle(color: MyColors.text(), fontSize: MediaQuery.of(context).size.width*0.05),)
                            ]
                          ),
                          Padding(padding: EdgeInsets.only(bottom: 5)),
                          Row(
                            mainAxisAlignment:MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Midnight:", style: TextStyle(color: MyColors.text(), fontSize: MediaQuery.of(context).size.width*0.05),),
                              Text(salahTimes!=null?hourIn24(salahTimes[6].hour).toString() + ":" + lessThan10(salahTimes[6].minute).toString()+(salahTimes[6].hour>=12?" PM":" AM"):"", style: TextStyle(color: MyColors.text(), fontSize: MediaQuery.of(context).size.width*0.05),)
                            ]
                          ),
                        ],
                      ),
                      backgroundColor: MyColors.card(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0)
                      ),
                    );
                  }
                 );
                 setState(() {
                   
                 });
              },
            ),
            IconButton(
              icon: Icon(Icons.settings),
              padding: EdgeInsets.only(top: MediaQuery.of(context).size.width*0.03),
              onPressed: (){
                 isSettings=true;
                 setState(() {
                   
                 });
              },
            )
          ],
          backgroundColor: MyColors.appBar(),
          title: Padding(
            child:   Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.title, style: Theme.of(context).textTheme.headline6.copyWith(fontSize: titleSize(context))
                ),
              ]
            ),
            padding: EdgeInsets.fromLTRB(0, MediaQuery.of(context).size.height*0.015, 0, 0),
          ),
          
          flexibleSpace: FlexibleSpaceBar(
            
            background: Padding(
              padding: EdgeInsets.fromLTRB(0, MediaQuery.of(context).size.height*0.105, 0, 0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        child: Text(UmmAlquraCalendar.now().fullDate(), style: Theme.of(context).textTheme.headline5,),
                        padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height*0.005, top: MediaQuery.of(context).size.height*0.005),
                      ),
                    ]
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          //padding: EdgeInsets.fromLTRB(0, MediaQuery.of(context).size.height*0.015, 0, 0),
                          child: Column(
                            children:[
                              new Text('Fajr', style: TextStyle(fontSize: MediaQuery.of(context).size.height*0.02, color: Colors.white),),
                              new Text(salahTimes!=null?hourIn24(salahTimes[1].hour).toString()+":"+lessThan10(salahTimes[1].minute)+(salahTimes[1].hour>=12?" PM":" AM"):"", style: TextStyle(fontSize: MediaQuery.of(context).size.height*0.035, color: Colors.white),),
                            ]
                          )
                        ),
                      ),
                      Expanded(
                        child: Container(
                          //padding: EdgeInsets.fromLTRB(0, MediaQuery.of(context).size.height*0.015, 0, 0),
                          child: Column(
                            children:[
                              new Text('Dhuhr', style: TextStyle(fontSize: MediaQuery.of(context).size.height*0.02, color: Colors.white),),
                              new Text(salahTimes!=null?hourIn24(salahTimes[3].hour).toString()+":"+lessThan10(salahTimes[3].minute)+(salahTimes[3].hour>=12?" PM":" AM"):"", style: TextStyle(fontSize: MediaQuery.of(context).size.height*0.035, color: Colors.white),),
                            ]
                          )
                        ),
                      ),
                      Expanded(
                        child: Container(
                          //padding: EdgeInsets.fromLTRB(0, MediaQuery.of(context).size.height*0.015, 0, 0),
                          child: Column(
                            children:[
                              new Text('Maghrib', style: TextStyle(fontSize: MediaQuery.of(context).size.height*0.02, color: Colors.white),),
                              new Text(salahTimes!=null?hourIn24(salahTimes[5].hour).toString()+":"+lessThan10(salahTimes[5].minute)+(salahTimes[5].hour>=12?" PM":" AM"):"", style: TextStyle(fontSize: MediaQuery.of(context).size.height*0.035, color: Colors.white),),
                            ]
                          )
                        ),
                      ),
                    ],
                  ),
                   
                ],
              )
              
            ),
            centerTitle: true,

          ),
          centerTitle: true,
          pinned: true,
          expandedHeight: MediaQuery.of(context).size.height*0.20,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))
          ),
          bottom: PreferredSize(                       // Add this code
            preferredSize: Size(double.infinity,MediaQuery.of(context).size.height*0.02),      // Add this code
            child: Text("")
          ) 
        ),
        cards: [
          HomeCard(
            title: "Quran", 
            description: "The Holy Book\nby Surah or Juz'", 
            gradient: LinearGradient(colors: [MyColors.turquoise()[0], MyColors.turquoise()[100]], begin: Alignment.topLeft, end: Alignment.bottomRight), 
            icon: AssetImage("assets/icons/quran.png"),
            iconBackground: Colors.transparent,
            route: (){Navigator.of(context).pushNamed("/quran/");},
          ),
          HomeCard(
            title: "Duas", 
            description: "Varius supplications\nfrom the Masumeen (as)", 
            gradient: LinearGradient(colors: [MyColors.green()[0], MyColors.green()[100]], begin: Alignment.topLeft, end: Alignment.bottomRight), 
            icon: AssetImage("assets/icons/dua.png"),
            iconBackground: Colors.transparent,
            route: (){Navigator.of(context).pushNamed("/duas/");},
          ),
          HomeCard(
            title: "Munajat", 
            description: "Silent supplications", 
            gradient: LinearGradient(colors: [MyColors.lightGreen()[0], MyColors.lightGreen()[100]], begin: Alignment.topLeft, end: Alignment.bottomRight), 
            icon: AssetImage("assets/icons/munajaat.png"),
            iconBackground: Colors.transparent,
            route: (){Navigator.of(context).pushNamed("/munajat/");},
          ),
          HomeCard(
            title: "Sahifa Sajadiyyah", 
            description: "Supplications from\nthe Fourth Imam (as)", 
            gradient: LinearGradient(colors: [MyColors.sky()[0], MyColors.sky()[100]], begin: Alignment.topLeft, end: Alignment.bottomRight), 
            icon: AssetImage("assets/icons/sahifa.png"),
            iconBackground: Colors.transparent,
            route: (){Navigator.of(context).pushNamed("/sahifa/");},
          ),
          HomeCard(
            title: "Taaqibat", 
            description: "Supplications after each prayer", 
            gradient: LinearGradient(colors: [MyColors.blue()[0], MyColors.blue()[100]], begin: Alignment.topLeft, end: Alignment.bottomRight), 
            icon: AssetImage("assets/icons/taaqibat.png"),
            iconBackground: Colors.transparent,
            route: (){Navigator.of(context).pushNamed("/taaqibat/");},
          ),
          HomeCard(
            title: "Ziyarat", 
            description: "Visitation of the\nMasumeen (as)", 
            gradient: LinearGradient(colors: [MyColors.jungle()[0], MyColors.jungle()[100]], begin: Alignment.topLeft, end: Alignment.bottomRight), 
            icon: AssetImage("assets/icons/ziyara.png"),
            iconBackground: Colors.transparent,
            route: (){Navigator.of(context).pushNamed("/ziyarat/");},
          ),
          HomeCard(
            title: "Marja Books", 
            description: "A collection of books\nfrom our Maraje", 
            gradient: LinearGradient(colors: [MyColors.emerald()[0], MyColors.emerald()[100]], begin: Alignment.topLeft, end: Alignment.bottomRight), 
            icon: AssetImage("assets/icons/books.png"),
            iconBackground: Colors.transparent,
            route: (){Navigator.of(context).pushNamed("/marja/");},
          ),
          HomeCard(
            title: "Contact Us", 
            description: "Feedback, inquiries,\nand support", 
            gradient: LinearGradient(colors: [MyColors.lightBlue()[0], MyColors.lightBlue()[100]], begin: Alignment.topLeft, end: Alignment.bottomRight), 
            icon: AssetImage("assets/icons/email.png"),
            iconBackground: Colors.transparent,
            route: (){Navigator.of(context).pushNamed("/contact/");},
          ),
        ]
      )
      
    );
  }
}

int hourIn24(int hour){
    if(hour<=12&&hour>=1) return hour;
    else if(hour==0) return 12;
    else return hour-12;
  }

String lessThan10(int i){
  if(i<10) return '0$i';
  else return '$i';
}