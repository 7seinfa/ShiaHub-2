  
import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

  AudioPlayer audioPlayer = new AudioPlayer();

  enum PlayerState{stop, play, pause}

  PlayerState playerState = PlayerState.stop;

  Icon isPlay = Icon(Icons.play_arrow);
  Color isLoop = Colors.grey;

  Refresh currentPage;

  int curNum;

  Future<void> play(String kUrl, {bool isLocal = false, int curSong}) async {
    curNum=curSong;
    if(isLocal){
      await audioPlayer.play(kUrl, isLocal: true);
    }else{
      print(kUrl);
      print(await audioPlayer.play(kUrl));
    }
    playerState = PlayerState.play;
    isPlay=Icon(Icons.pause);
    //currentPage.ref;
  }

  Future<void> pause() async {
    await audioPlayer.pause();
    playerState = PlayerState.pause;
  }

  Future<void> unpause() async {
    await audioPlayer.resume();
    playerState = PlayerState.play;
    
  }

  Future<void> stop() async {
    await audioPlayer.stop();
    playerState = PlayerState.stop;
    isPlay = Icon(Icons.stop);
  }

  Future<void> newUrl(String kUrl) async {
    await audioPlayer.setUrl(kUrl);
  }
  Future<void> release() async {
    await audioPlayer.release();
    playerState = PlayerState.stop;
  }

  class ControlAudio extends StatefulWidget{
    final bool isNext;
    final List<String> filesList;

    ControlAudio({Key key, this.isNext=false, this.filesList}) : super (key: key);

    @override
    ControlAudioState createState()=> new ControlAudioState();
  }

  class ControlAudioState extends State<ControlAudio>{
    Duration duration;
    Duration position;

    @override
    void initState() {
      super.initState();
      update();
      if(widget.isNext){
        audioPlayer.onPlayerCompletion.listen((event){
          if(curNum+1==widget.filesList.length){
            curNum=-1;
          }
          play(widget.filesList[curNum+1], curSong: curNum+1);
        });
      }
      currentPage = Refresh(this.ref);
    }

    void update(){
      audioPlayer.onDurationChanged.listen((Duration d) {
        print('Max duration: $d');
        setState(() => duration = d);
      });
      audioPlayer.onAudioPositionChanged.listen((Duration  p){
        print('Position: $p');
        setState(() => position = p);
      });
      audioPlayer.setReleaseMode(ReleaseMode.STOP);
    }

    void ref(){
      setState(() {
              
            });
    }
    @override
    Widget build(BuildContext context){
      return BottomAppBar(
        child: new Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              icon: isPlay,
              onPressed: (){
                if(playerState==PlayerState.play) {
                  pause();
                  isPlay=Icon(Icons.play_arrow);
                }
                else if(playerState==PlayerState.pause) {
                  unpause();
                  isPlay=Icon(Icons.pause);
                }else{
                  isPlay = Icon(Icons.stop);
                }
                setState(() {
                });
              },
            ),
            Flex(
              direction: Axis.vertical,
              mainAxisSize: MainAxisSize.min,
              children: [
                new Slider(
                  value: position?.inMilliseconds?.toDouble() ?? 0.0,
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
            Text(pos()!=''?pos():'0:00/0:00'),
          ],
        ),
      );
    }

    String pos(){
      if(position!=null) return position.inMinutes.toString()+':'+secs(position)+'/'+duration.inMinutes.toString()+':'+secs(duration);
      return '';
    }

    String secs(Duration d){
      if(d.inSeconds%60<10) return '0'+ (d.inSeconds%60).toString();
      return (d.inSeconds%60).toString();
    }

    double dur(){
      if(duration!=null) return duration.inMilliseconds.toDouble();
      return 0;
    }
  }

  class Refresh{
    Function ref;
    Refresh(this.ref);
  }

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();

  return directory.path;
}

Future<Directory> get localFileSave async {
  final path = await _localPath;
  final myDir = new Directory('$path/saved/quran');
  await new Directory('$path/saved/quran').create(recursive: true);
  return myDir;
}
Future<Directory> get localFileSaveDel async {
  final path = await _localPath;
  
  Directory dir = Directory('$path/saved/quran');
  return dir.delete(recursive: true);
}
Future<File> deleteLocalFile(String path) async {
  File f = File(path);
  return f.delete(recursive: true);
}
Future<dynamic> downloadFile(String url, String songName, String singerName) async {
  String path = (await localFileSave).path;
  String temp = songName+' - '+singerName;
  File file = new File('$path/$temp.mp3');
  print('$path/$temp.mp3');

  var request = await http.get(url,);
  var bytes = request.bodyBytes;//close();
  await file.writeAsBytes(bytes);
  print("done");
}

  class ControlAudioQuran extends StatefulWidget{
    final String reciterLink;
    final String title;

    ControlAudioQuran({Key key, this.reciterLink, this.title}) : super (key: key);

    @override
    ControlAudioQuranState createState()=> new ControlAudioQuranState();
  }

  class ControlAudioQuranState extends State<ControlAudioQuran>{
    bool loop=false;

    Duration duration;
    Duration position;

    @override
    void initState() {
      super.initState();
      audioPlayer.setReleaseMode(ReleaseMode.RELEASE);
      currentPage = Refresh(this.ref);
      isPlay=Icon(Icons.play_arrow);
      update();
    }

    void update(){
      audioPlayer.onDurationChanged.listen((Duration d) {
        print('Max duration: $d');
        setState(() => duration = d);
      });
      audioPlayer.onAudioPositionChanged.listen((Duration  p){
        print('Position: $p');
        setState(() => position = p);
      });
      audioPlayer.setReleaseMode(ReleaseMode.STOP);
    }

    void ref(){
      setState(() {
              
            });
    }
    @override
    Widget build(BuildContext context){
      return BottomAppBar(
        child: new Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                IconButton(
                  icon: isPlay,
                  onPressed: ()async{
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
                      String name = widget.title;
                      String temp = "$path/$name.mp3";
                      File file = new File(temp);
                      print(temp);
                      if(await file.exists()) play(temp, isLocal: true);
                      else play(widget.reciterLink);
                      play(widget.reciterLink);
                    }
                    setState(() {
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.loop),
                  color: isLoop,
                  onPressed: (){
                    if(!loop) {
                      audioPlayer.setReleaseMode(ReleaseMode.LOOP);
                      isLoop=Colors.black;
                      loop=true;
                      setState(() {
                        
                      });
                    }else{
                      audioPlayer.setReleaseMode(ReleaseMode.RELEASE);
                      isLoop=Colors.grey;
                      loop=false;
                      setState(() {
                        
                      });
                    }
                  },
                ),
                Flex(
                  direction: Axis.vertical,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    new Slider(
                      value: position?.inMilliseconds?.toDouble() ?? 0.0,
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
                Text(pos()!=''?pos():'0:00/0:00'),
              ],
            )
          ]
        ),
      );
    }

    String pos(){
      if(position!=null) return position.inMinutes.toString()+':'+secs(position)+'/'+duration.inMinutes.toString()+':'+secs(duration);
      return '';
    }

    String secs(Duration d){
      if(d.inSeconds%60<10) return '0'+ (d.inSeconds%60).toString();
      return (d.inSeconds%60).toString();
    }

    double dur(){
      if(duration!=null) return duration.inMilliseconds.toDouble();
      return 0;
    }
  }