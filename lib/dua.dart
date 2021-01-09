import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiahub2/audio.dart';
import 'theme.dart';
import 'dart:convert';
import 'package:rxdart/rxdart.dart';
import 'package:clipboard_manager/clipboard_manager.dart';
import 'package:audioplayers/audioplayers.dart';

class DuaList extends StatefulWidget {
  final String json;
  final String title;
  final String prefix;

  DuaList({Key key, this.json, this.title, this.prefix=""}) : super(key: key);
  
  @override
  _DuaListState createState() => _DuaListState();
}

class _DuaListState extends State<DuaList> {

  List<HomeCard> cards = [HomeCard(title: "")];

  Future<String> loadJson(String link) async {
    return await rootBundle.loadString(link);
  }

  @override
  void initState(){
    loadDuas();
    super.initState();
  }

  Future<void> loadDuas() async {
    cards = [];
    var duas = json.decode(await loadJson("assets/jsons/duas/"+widget.json));
    for(int i = 0; i<duas.length; i++){
      List<String> recitations = [];
      List<String> reciterNames = [];
      for(int x = 0; x<duas[i]["audio"].length; x++){
        recitations.add(duas[i]["audio"][x]["link"]);
        reciterNames.add(duas[i]["audio"][x]["name"]);
      }
      cards.add(HomeCard(
        title: widget.prefix + duas[i]["title"],
        fullLength: true,
        route: (){
          var route = new MaterialPageRoute(
            builder: (BuildContext context) =>
              new Dua(title: widget.prefix + duas[i]["title"], arabic: duas[i]["arabic"].split("\n"), english: duas[i]["english"].split("\n"), recitations: recitations, reciterNames: reciterNames,)
          );
          Navigator.of(context).push(route);
        },
      ));
    }
    setState(() {
      
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: HomeCardList(
        title: widget.title,
        cards: cards,
        fullLength: true,
      ),
    );
  }
}

class Dua extends StatefulWidget {
  final String title;
  final List<String> arabic;
  final List<String> english;
  final List<String> recitations;
  final List<String> reciterNames;

  Dua({Key key, this.title, this.arabic, this.english, this.recitations, this.reciterNames}) : super(key: key);
  
  @override
  _DuaState createState() => _DuaState();
}

class _DuaState extends State<Dua> {

  Widget dua = Column();
  bool eng = true;
  bool ar = true;
  BehaviorSubject<bool> engS;
  BehaviorSubject<bool> arS;
  SharedPreferences prefs;
  double arabicFontSize = 24;
  double englishFontSize = 24;
  List<DropdownMenuItem> recites = [];
  List<String> recitations;
  List<String> reciterNames;
  String curName;
  String curRecite;

  Future<String> loadJson(String link) async {
    return await rootBundle.loadString(link);
  }

  @override
  void initState(){
    loadDuas();
    super.initState();
  }
  @override
  void dispose(){
    release();
    super.dispose();
  }

  Future<void> loadDuas() async {
    audioPlayer = AudioPlayer();
    prefs = await SharedPreferences.getInstance();
    engS = new BehaviorSubject<bool>();
    arS = new BehaviorSubject<bool>();

    if(prefs.getBool("engDua")!=null){
      eng = prefs.getBool("engDua");
    }
    if(prefs.getBool("arDua")!=null){
      eng = prefs.getBool("arDua");
    }
    if(prefs.getDouble("duaArabicFont")!=null){
      arabicFontSize = prefs.getDouble("duaArabicFont");
    }
    if(prefs.getDouble("duaEnglishFont")!=null){
      englishFontSize = prefs.getDouble("duaEnglishFont");
    }



    List<Widget> textList = [];
    for(int i = 0; i<widget.arabic.length; i++){
      textList.add(
        StreamBuilder(
          stream: arS.stream.asBroadcastStream(),
          builder: (context, snapshot){
            return ar?Text(widget.arabic[i], 
              style: TextStyle(
                fontFamily: "Najaf",
                fontSize: arabicFontSize,
                height: 1.7,
                color: MyColors.text()
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ):Container();
          },
        )
      );
      textList.add(
        StreamBuilder(
          stream: engS.stream.asBroadcastStream(),
          builder: (context, snapshot){
            return eng?Text(widget.english[i]+"\n", 
              style: TextStyle(
                fontSize: englishFontSize,
                height: 1.7,
                color: MyColors.text()
              ),
              textAlign: TextAlign.center,)
            :Container();
          },
        )
      );
    }
    dua= Column(
      children: textList,
    );
    recitations = widget.recitations;
    reciterNames = widget.reciterNames;
    recites = [];
    for(int i = 0; i<reciterNames.length; i++){
      if(prefs.getString(widget.title+"Reciter")!=null){
        if(prefs.getString(widget.title+"Reciter")==reciterNames[i]){
          curName = reciterNames[i];
          curRecite = recitations[i];
        }
      }else{
        prefs.setString(widget.title+"Reciter", reciterNames[0]);
        curName = reciterNames[0];
        curRecite = recitations[0];
      }
      
      recites.add(
        DropdownMenuItem(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Container(
                width: constraints.maxWidth,
                child:Text(reciterNames[i], overflow: TextOverflow.clip, textAlign: TextAlign.center, style: TextStyle(
                  color: MyColors.text()
                ),)
              );
            }
          ),
          value: recitations[i],
          onTap: (){
            curName = reciterNames[i];
            prefs.setString(widget.title+"Reciter", curName);
          },
        )
      );
    }
    currentPage = Refresh(this.ref);
    update();
    setState(() {
      
    });
  }

  void update() async {
    isPlay = Icon(Icons.play_arrow);
    String path = (await localFileSave).path;
    String name = widget.title + " - " + curName;
    String temp = "$path/$name.mp3";
    File file = new File(temp);
    print(temp);
    if(await file.exists()) {
      await play(temp, isLocal: true);
      var snackBar = SnackBar(
        content: Text('Loaded Offline'),
      );

      // Find the Scaffold in the widget tree and use it to show a SnackBar.
      _scaffoldKey.currentState.showSnackBar(snackBar);
    }else {
      await play(curRecite);
      var snackBar = SnackBar(
        content: Text('Loaded Online'),
      );

      // Find the Scaffold in the widget tree and use it to show a SnackBar.
      _scaffoldKey.currentState.showSnackBar(snackBar);
    }
    audioPlayer.onDurationChanged.listen((Duration d) {
      print('Max duration: $d');
      setState(() => duration = d);
    });
    audioPlayer.onAudioPositionChanged.listen((Duration  p){
      print('Position: $p');
      setState(() => position = p);
    });
    
    audioPlayer.setReleaseMode(ReleaseMode.STOP);
    isPlay = Icon(Icons.play_arrow);
    await pause();
  }


  void ref(){
      setState(() {
              
            });
    }

  Duration duration;
  Duration position;

  String secs(Duration d){
      if(d.inSeconds%60<10) return '0'+ (d.inSeconds%60).toString();
      return (d.inSeconds%60).toString();
    }

  String pos(){
    if(position!=null) return position.inMinutes.toString()+':'+secs(position)+'/'+duration.inMinutes.toString()+':'+secs(duration);
    else if(duration!=null) return '0:00/'+duration.inMinutes.toString()+':'+secs(duration);
    return '';
  }

  double dur(){
    if(duration!=null) return duration.inMilliseconds.toDouble();
    return 0;
  }


  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  ScrollController _scrollController = new ScrollController(keepScrollOffset: true);
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      key: _scaffoldKey,
      body: CustomScrollView(
        controller: _scrollController,
        slivers:  [
          SliverAppBar(
            toolbarHeight: toolbarSize(context),
            backgroundColor: MyColors.appBar(),
            title: Padding(
              child:Text(widget.title, style: Theme.of(context).textTheme.headline6.copyWith(fontSize: titleSize(context)), overflow: TextOverflow.fade,),
                
              padding: EdgeInsets.fromLTRB(0, MediaQuery.of(context).size.height*0.015, 0, 0),
            ),
            
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: EdgeInsets.fromLTRB(MediaQuery.of(context).size.width*0.05, MediaQuery.of(context).size.height*0.105, MediaQuery.of(context).size.width*0.025, 0),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:[
                              new Text('English', style: TextStyle(fontSize: MediaQuery.of(context).size.height*0.02, color: Colors.white),),
                              Padding(
                                padding: EdgeInsets.only(top: MediaQuery.of(context).size.height*0.01),
                              ),
                              Container(
                                child: Switch(
                                  activeColor: MyColors.sliderInactive(),
                                  activeTrackColor: MyColors.sliderActive(),
                                  inactiveThumbColor: MyColors.sliderActive(),
                                  inactiveTrackColor: MyColors.sliderInactive(),
                                  value: eng,
                                  onChanged: (a)async{
                                    eng=a;
                                    
                                    engS.add(eng);
                                    setState(() {
                                      
                                    });
                                  },
                                )
                              ),
                              Text("Font Size", style: TextStyle(fontSize: MediaQuery.of(context).size.height*0.02, color: Colors.white),),
                              Slider(
                                value: englishFontSize,
                                inactiveColor: MyColors.sliderActive(),
                                activeColor: MyColors.sliderInactive(),
                                min: 16,
                                max: 64,
                                onChangeEnd: (d){
                                  prefs.setDouble("duaEnglishFont", d);
                                  englishFontSize=d;
                                  engS.add(eng);
                                },
                                onChanged: (d)async{
                                  englishFontSize=d;
                                  engS.add(eng);
                                  setState(() {
                                    
                                  });
                                },
                              ),
                            ]
                          )
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children:[
                              new Text('Arabic  ', style: TextStyle(fontSize: MediaQuery.of(context).size.height*0.02, color: Colors.white),),
                              Padding(
                                padding: EdgeInsets.only(top: MediaQuery.of(context).size.height*0.01),
                              ),
                              Container(
                                child: Switch(
                                  activeColor: MyColors.sliderInactive(),
                                  activeTrackColor: MyColors.sliderActive(),
                                  inactiveThumbColor: MyColors.sliderActive(),
                                  inactiveTrackColor: MyColors.sliderInactive(),
                                  value: ar,
                                  onChanged: (a)async{
                                    ar=a;
                                    
                                    arS.add(ar);
                                    setState(() {
                                      
                                    });
                                  },
                                )
                              ),
                            Text("Font Size", style: TextStyle(fontSize: MediaQuery.of(context).size.height*0.02, color: Colors.white),),
                              Slider(
                                value: arabicFontSize,
                                inactiveColor: MyColors.sliderActive(),
                                activeColor: MyColors.sliderInactive(),
                                min: 16,
                                max: 64,
                                onChangeEnd: (d){
                                  prefs.setDouble("duaArabicFont", d);
                                  arabicFontSize=d;
                                  arS.add(eng);
                                },
                                onChanged: (d)async{
                                  arabicFontSize=d;
                                  arS.add(eng);
                                  setState(() {
                                    
                                  });
                                },
                                
                              ),
                            ]
                          )
                        )
                      ],
                    ),
                    Row(
                      children: [
                        Flexible(
                          flex: 2,
                          child: new Text('Reciter', style: TextStyle(fontSize: MediaQuery.of(context).size.height*0.02, color: Colors.white), textAlign: TextAlign.center),
                          fit: FlexFit.tight,
                        ),
                        Flexible(
                          fit: FlexFit.tight,
                          flex: 4,
                          child: Padding(
                            child: Container(
                              child: DropdownButton(
                                isExpanded: true,
                                style: TextStyle(color: Colors.white,),
                                dropdownColor: MyColors.background(),
                                underline: Container(),
                                items: recites,
                                iconEnabledColor: MyColors.text(),
                                onChanged: (value) async {
                                  curRecite = value;
                                  release();
                                  isPlay = Icon(Icons.play_arrow);
                                  String path = (await localFileSave).path;
                                  String name = widget.title.toString() + " - " + curName;
                                  String temp = "$path/$name.mp3";
                                  File file = new File(temp);
                                  print(temp);
                                  if(await file.exists()) {
                                    print("true");
                                    play(temp, isLocal: true);
                                    var snackBar = SnackBar(
                                      content: Text('Playing Offline'),
                                    );

                                    // Find the Scaffold in the widget tree and use it to show a SnackBar.
                                    _scaffoldKey.currentState.showSnackBar(snackBar);
                                    }
                                  else {
                                    play(curRecite);
                                    var snackBar = SnackBar(
                                      content: Text('Playing Online'),
                                    );

                                    // Find the Scaffold in the widget tree and use it to show a SnackBar.
                                    _scaffoldKey.currentState.showSnackBar(snackBar);
                                    }
                                  setState(() {
                                    
                                  });
                                },
                                value: curRecite,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: MyColors.background(),
                              ),
                            ),
                            padding: EdgeInsets.only(top: MediaQuery.of(context).size.height*0.01, bottom: MediaQuery.of(context).size.height*0.01),
                          ) 
                          
                        ),
                        Flexible(
                          fit: FlexFit.tight,
                          child: IconButton(
                            icon: Icon(Icons.file_download, color: Colors.white),
                            onPressed: ()async{
                              var snackBar = SnackBar(
                                content: Text('Downloading, please wait.'),
                                duration: Duration(days: 365)
                                );

                              // Find the Scaffold in the widget tree and use it to show a SnackBar.
                              _scaffoldKey.currentState.showSnackBar(snackBar);
                              await downloadFile(curRecite, widget.title, curName);
                              snackBar = SnackBar(
                                content: Text('Downloaded'),
                                );

                              // Find the Scaffold in the widget tree and use it to show a SnackBar.
                              _scaffoldKey.currentState.removeCurrentSnackBar();
                              _scaffoldKey.currentState.showSnackBar(snackBar);
                            }
                          )
                        )
                      ],
                    )
                  ],
                )
              ),
              centerTitle: true,

            ),
            centerTitle: true,
            //pinned: true,
            floating: true,
            expandedHeight: MediaQuery.of(context).size.height*0.27,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))
            ),
            bottom: PreferredSize(                       // Add this code
              preferredSize: Size(double.infinity,MediaQuery.of(context).size.height*0.02),      // Add this code
              child: Text("")
            ),
            leading: Padding(
              child: IconButton(icon: Icon(Icons.arrow_back_ios), onPressed: (){Navigator.of(context).pop();}, ),
              padding: EdgeInsets.only(top: MediaQuery.of(context).size.height*0.015),
            ),
            actions: [Padding(
              child: Container(width: 56,),
              padding: EdgeInsets.only(top: MediaQuery.of(context).size.height*0.015),
            ),],
          ),
          SliverToBoxAdapter(
            child: Padding(
              child:Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  color: MyColors.card(),
                ),
                child: dua,
              ),
              padding: EdgeInsets.fromLTRB(MediaQuery.of(context).size.width*0.02, MediaQuery.of(context).size.height*0.01, MediaQuery.of(context).size.width*0.02, MediaQuery.of(context).size.height*0.06),
            )
          ),
        ]
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          color: MyColors.background(),
        ),
        width: MediaQuery.of(context).size.width*0.93,
        child: new Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Flexible(
              fit: FlexFit.tight,
              flex: 2,
              child: IconButton(
                icon: isPlay,
                color: MyColors.text(),
                onPressed: () async{
                  if(playerState==PlayerState.play) {
                    pause();
                    isPlay=Icon(Icons.play_arrow);
                  }
                  else if(playerState==PlayerState.pause) {
                    unpause();
                    isPlay=Icon(Icons.pause);
                  }else if(playerState==PlayerState.stop){
                    isPlay = Icon(Icons.play_arrow);
                    String path = (await localFileSave).path;
                    String name = widget.title + " - ";// + curName;
                    String temp = "$path/$name.mp3";
                    File file = new File(temp);
                    print(temp);
                    if(await file.exists()) {
                      play(temp, isLocal: true);
                      var snackBar = SnackBar(
                        content: Text('Playing Offline'),
                      );

                      // Find the Scaffold in the widget tree and use it to show a SnackBar.
                      _scaffoldKey.currentState.showSnackBar(snackBar);
                    }else {
                      //play(curRecite);
                      var snackBar = SnackBar(
                        content: Text('Playing Online'),
                      );

                      // Find the Scaffold in the widget tree and use it to show a SnackBar.
                      _scaffoldKey.currentState.showSnackBar(snackBar);
                    }
                  }
                  setState(() {
                  });
                },
              ),
            ),
            
            Flexible(
              fit: FlexFit.tight,
              flex: 8,
              child: Flex(
                direction: Axis.vertical,
                mainAxisSize: MainAxisSize.min,
                children: [
                  new Slider(
                    value: position?.inMilliseconds?.toDouble() ?? 0.0,
                    inactiveColor: MyColors.sliderActive(),
                    activeColor: MyColors.sliderInactive(),
                    onChanged: (double value) {
                        audioPlayer.seek(new Duration(milliseconds: value.toInt()));
                        unpause();
                        isPlay =Icon(Icons.pause);
                        setState(() {});
                        },
                    min: 0.0,
                    max: dur(),
                  ),
                ]
              ),
            ),
            Flexible(
              fit: FlexFit.tight,
              flex: 3,
              child: Text(pos()!=''?pos():'0:00/0:00', style: TextStyle(color: MyColors.text(),),),
            )
            
          ],
        ),
      )
    );
    
  }
}
