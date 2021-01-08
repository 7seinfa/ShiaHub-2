import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shiahub2/theme.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class Marja extends StatefulWidget{
  @override
  MarjaState createState()=>new MarjaState();
}

class MarjaState extends State<Marja> {
  List<String> marjaNames = [];
  List<String> marjaNamesTitle = [];
  List<String> bookNames = [];
  List<String> bookLinks = [];
  List<Widget> tiles = [];
  List<List<Widget>> tilesBody = [];

  Future<String> getData() async{
    marjaNames = [];
    marjaNamesTitle = [];
    bookNames = [];
    bookLinks = [];
    tiles = [];
    tilesBody = [];
    http.Response response = await http.get("https://firebasestorage.googleapis.com/v0/b/shiahub-d11d2.appspot.com/o/marjeiya.json?alt=media");
    var resBody = json.decode(response.body);
    String curName = "";

    for(var u in resBody){
      curName = u["name"];
      marjaNames.add(curName);
      curName = u["book_name"];
      bookNames.add(curName);
      curName = u["url"];
      bookLinks.add(curName);
    }

    int x = 0;
    for(int i = 0; i<marjaNames.length; i++){
      if(i!=0){
        if(marjaNames[i]==marjaNames[i-1]){
          tilesBody[x].add(
            ListTile(
              title: new Text("   "+bookNames[i], style: TextStyle(color: MyColors.text(),),),
              onTap: (){
                launch(bookLinks[i]);
              },
            )
          );
          tilesBody[x].add(
            new Divider(height: 2.0,color: MyColors.background(),)
          );
        }else{
          x++;
          marjaNamesTitle.add(marjaNames[i]);
          tilesBody.add(
            List<Widget>()
          );
          tilesBody[x].add(
            ListTile(
              title: new Text("   "+bookNames[i], style: TextStyle(color: MyColors.text(),),),
              onTap: (){
                launch(bookLinks[i]);
              },
            )
          );
          tilesBody[x].add(
            new Divider(height: 2.0,color: MyColors.background(),)
          );
        }
      }else{
        tilesBody.add(
          List<Widget>()
        );
        tilesBody[x].add(
          ListTile(
            title: new Text("   "+bookNames[i], style: TextStyle(color: MyColors.text(),),),
            onTap: (){
                launch(bookLinks[i]);
              },
          )
        );
        tilesBody[x].add(
          new Divider(height: 2.0,color: MyColors.background(),)
        );
        marjaNamesTitle.add(marjaNames[i]);
      }
    }

    for(int i = 0; i<marjaNamesTitle.length; i++){
      tiles.add(
        Theme(
          data: ThemeData(
            accentColor: MyColors.text(),
            unselectedWidgetColor: MyColors.text(),
          ),
          child: Container(
            child: ExpansionTile(
              title: new Text(marjaNamesTitle[i], style: TextStyle(color: MyColors.text(),),),
              backgroundColor: MyColors.card(),
              children: tilesBody[i],
              //trailing: Icon(Icons.arrow_drop_down, color: MyColors.text(),),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
            ),
            padding: EdgeInsets.fromLTRB(5,5,5,0),
          )
        )
      );
      tiles.add(
        new Divider(height: 2.0,),
      );
    }
    return "Success";
    
  }
  
  Widget build(BuildContext context){
    
    var futureBuilder = new FutureBuilder(
      future: getData(),
      builder: (BuildContext context, AsyncSnapshot snapshot){
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return Text('Press button to start.');
          case ConnectionState.active:
          case ConnectionState.waiting:
            return SliverToBoxAdapter(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Fetching Books', textAlign: TextAlign.center,),
                    ]
                  ),
                  CircularProgressIndicator(),
                ],
              )
            );
          case ConnectionState.done:
            if (snapshot.hasError)
              return SliverToBoxAdapter(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: Could not Connect')
                  ]
                )
              );
            return createListLiew(context, snapshot);
        }
      return null;
      }
    );

    
    
    return new Scaffold(/*
      appBar:  new AppBar(title: new Text("Marja Books")),
      body: futureBuilder*/
      body: CustomScrollView(
      slivers:  [
        SliverAppBar(
          toolbarHeight: toolbarSize(context),
          backgroundColor: MyColors.appBar(),
          leading: Padding(
            child: IconButton(icon: Icon(Icons.arrow_back_ios), onPressed: (){Navigator.of(context).pop();}, ),
            padding: EdgeInsets.only(top: MediaQuery.of(context).size.height*0.015),
          ),
          title: Padding(
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Marja Books", style: Theme.of(context).textTheme.headline6.copyWith(fontSize: titleSize(context)), overflow: TextOverflow.visible,),
              ]
            ),
            padding: EdgeInsets.fromLTRB(0, MediaQuery.of(context).size.height*0.016, 0, 0),
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
        futureBuilder
        ]
      )
    );
  }

  List<Widget> rows(int numPerRow){
      List<Widget> rows=[];
      rows.add(Padding(padding: EdgeInsets.only(top: MediaQuery.of(context).size.width*0.01),));
      for (int i=0; i<tiles.length; i+=numPerRow){
        List<Widget> widgetInRows=[];
        int x = i;
        while(x<(i+numPerRow)){
          tiles.length>x?widgetInRows.add(tiles[x]):widgetInRows.add(HomeCard(title: "", isBlank: true,));
          x++;
        }
        rows.add(Row(
          children: [tiles[i]],
        ));
      }
      return rows;
    }

  Widget createListLiew(BuildContext context, AsyncSnapshot snapshot) {
    return new SliverList(
      delegate: SliverChildListDelegate(tiles)
    );
  }
}
