import 'package:flutter/material.dart';
import 'package:funny_chat/screens/welcome_screen.dart';
import '../constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

final _firestore = Firestore.instance;
FirebaseUser logInUser;
int count = 0;

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  String messageText;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async{
    try {
      final user = await _auth.currentUser();
      if(user != null){
        logInUser = user;
        print(logInUser.email);
      }
    }catch(e){
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
                Navigator.pushNamed(context, WelcomeScreen.id);
              }),
        ],
        title: Text('FunnyChat'),
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessagesStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      DateTime now = DateTime.now();
                      String formattedDate = DateFormat.Hm().format(now);
                      messageTextController.clear();
                      _firestore.collection('messages').add({
                        'id': ++count,
                        'text':messageText,
                        'sender':logInUser.email,
                        'date': formattedDate,
                      });
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessagesStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('messages').snapshots(),
      builder: (context, snapshot){
        if(snapshot.hasData){
          final messagesOfStreem = snapshot.data.documents.reversed;
          List<RoundedMessage> messageWidgets = [];
          for(var message in messagesOfStreem){
            final messageId = message.data['id'];
            final messageText = message.data['text'];
            final messageSender = message.data['sender'];
            final messageDate = message.data['date'];
            final currentUser = logInUser.email;

            final roundedMessage = RoundedMessage(sender: messageSender, text: messageText, date: messageDate, isMe: currentUser == messageSender,);
            messageWidgets.add(roundedMessage);
          }
          return Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
              children: messageWidgets,
            ),
          );
        }
      },
    );
  }
}


class RoundedMessage extends StatelessWidget {

  RoundedMessage({this.id, this.sender, this.text, this.date, this.isMe});
  int id;
  String sender;
  String text;
  String date;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:  EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(sender, style: TextStyle(fontSize: 13.0),),
              SizedBox(width: 10.0,),
              Text(date, style: TextStyle(fontSize: 13.0),),
            ],
          ),
          Material(
            borderRadius: BorderRadius.circular(30.0),
            elevation: 5.0,
            color: isMe? Colors.blue : Colors.white,
            child: FlatButton(
              onLongPress: (){
                showDialog(
                  context: context,
                  builder: (BuildContext context) {

                    return AlertDialog(
                      title: Text("Do you want to delete this message ?"),
                      content: null,
                      actions: <Widget>[  Row(
                          children: <Widget>[
                            FlatButton(
                              child: Text("Delete"),
                              onPressed: () {
                                _firestore.collection('messages').document('$text').delete();
                              },
                            ),
                            FlatButton(
                              child: Text("Close"),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                child: Text('$text', style: TextStyle(fontSize: 18.0, color: isMe ? Colors.white : Colors.black),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
