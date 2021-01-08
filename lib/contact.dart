import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'theme.dart';

class Contact extends StatefulWidget{
  @override
  ContactState createState()=>new ContactState();
}

class ContactState extends State<Contact> {
  final TextEditingController _controller = new TextEditingController();
  String subject = "Request";
  String body = "";


  @override
  Widget build(BuildContext context){

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
                  Text("Contact Us", style: Theme.of(context).textTheme.headline6.copyWith(fontSize: titleSize(context)), overflow: TextOverflow.visible,),
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
          SliverToBoxAdapter(
            child: Container(
              height: MediaQuery.of(context).size.height*0.8,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Padding(
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          color: MyColors.card(),
                          
                        ),
                        padding: EdgeInsets.only(left: MediaQuery.of(context).size.width*0.02, right: MediaQuery.of(context).size.width*0.01),
                        child: DropdownButton(
                          //isExpanded: true,
                          style: TextStyle(color: MyColors.text(),),
                          focusColor: MyColors.card(),
                          dropdownColor: MyColors.card(),
                          underline: Container(),
                          iconEnabledColor: MyColors.text(),
                          value: subject,
                          items: [
                            DropdownMenuItem(
                              child: Text("Request a Feature",),
                              value: "Request",
                            ),
                            DropdownMenuItem(
                              child: Text("Report an Issue",),
                              value: "Report",
                            ),
                            DropdownMenuItem(
                              child: Text("Inquiries",),
                              value: "Inquiry",
                            ),
                            DropdownMenuItem(
                              child: Text("Other Feedback",),
                              value: "Feedback",
                            ),
                          ],
                          onChanged: (value){
                            setState(() {
                              subject=value;
                            });
                          },
                        ),
                      ),
                    padding: EdgeInsets.only(top: MediaQuery.of(context).size.height*0.01, bottom: MediaQuery.of(context).size.height*0.02),
                  ),
                  
                  Padding(
                    padding: EdgeInsets.fromLTRB(12, 0, 12, 16),
                      child: Container(
                        child: TextField(
                          maxLines: 8,
                          enabled: true,
                          controller: _controller,
                          style: TextStyle(color: MyColors.text()),
                          decoration: InputDecoration(
                            hintStyle: TextStyle(color: MyColors.card()),
                            hintText: 'You can contact us here. Pressing send will launch your email app.',
                          ),
                          onChanged: (String e){
                            setState(() {
                              body=e;
                            });
                          },
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          color: MyColors.jungle(),
                          
                        ),
                        padding: EdgeInsets.only(left: MediaQuery.of(context).size.width*0.02, right: MediaQuery.of(context).size.width*0.01),
                    )
                  ),
                  FlatButton(
                    color: MyColors.card(),
                    child: Text("Send the Email!", textAlign: TextAlign.center, style: TextStyle(color:MyColors.text()),),
                    onPressed: ()async{
                      final Email email = Email(
                        body: body,
                        subject: subject,
                        recipients: ['shiahubapp@gmail.com'],
                      );
                      await FlutterEmailSender.send(email);
                    },
                  )
                ],
              )
            )
          )
        ]
      )
    );
  }
}