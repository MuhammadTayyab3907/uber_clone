import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uber/AllScreen/mainscreen.dart';
import 'package:uber/AllScreen/registration_screen.dart';
import 'package:uber/all_widget/progress_dialog.dart';
import 'package:uber/main.dart';

class LoginScreen extends StatelessWidget {
  static const String idScreen = 'loginScreen';
  final TextEditingController emailEditingcontroller = TextEditingController();
  final TextEditingController passwordEditingcontroller =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              SizedBox(
                height: 35,
              ),
              Image(
                image: AssetImage('images/logo.png'),
                width: 390,
                height: 250,
                alignment: Alignment.center,
              ),
              SizedBox(
                height: 1,
              ),
              Text(
                'Login as a Rider',
                style: TextStyle(fontSize: 24, fontFamily: 'Brand Bold'),
                textAlign: TextAlign.center,
              ),
              Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      height: 1,
                    ),
                    TextField(
                      controller: emailEditingcontroller,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(fontSize: 14),
                          hintStyle:
                              TextStyle(fontSize: 10, color: Colors.grey)),
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(
                      height: 1,
                    ),
                    TextField(
                      controller: passwordEditingcontroller,
                      obscureText: true,
                      decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(fontSize: 14),
                          hintStyle:
                              TextStyle(fontSize: 10, color: Colors.grey)),
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    RaisedButton(
                      onPressed: () {
                        if (!emailEditingcontroller.text.contains('@')) {
                          displayToastMessage(
                              'Invalid email address.', context);
                        } else if (passwordEditingcontroller.text.length < 7) {
                          displayToastMessage('Password is mandatory', context);
                        } else {
                          loginAndAuthticateUser(context);
                        }
                      },
                      textColor: Colors.white,
                      color: Colors.yellow,
                      child: Container(
                        height: 50,
                        child: Center(
                          child: Text(
                            "Login",
                            style: TextStyle(
                                fontSize: 18, fontFamily: 'Brand Bold'),
                          ),
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.0)),
                    ),
                  ],
                ),
              ),
              FlatButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                        context, RegistrationScreen.idScreen, (route) => false);
                  },
                  child: Text('Do not have an Account? Register Here.')),
            ],
          ),
        ),
      ),
    );
  }

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  void loginAndAuthticateUser(BuildContext context) async {

    showDialog(context: context,barrierDismissible: false,builder: (BuildContext context){
      return ProgressDialog(message: "Authenticating, Please wait...",);
    });

    final User firebaseUser = (await _firebaseAuth
            .signInWithEmailAndPassword(
                email: emailEditingcontroller.text,
                password: passwordEditingcontroller.text)
            .catchError((onError) {
              Navigator.pop(context);
      displayToastMessage(onError.toString(), context);
    }))
        .user;

    if (firebaseUser != null) {
      userRef.child(firebaseUser.uid).once().then((DataSnapshot snap) {
        if (snap.value != null) {
          displayToastMessage('You are log-in now.', context);
          Navigator.pushNamedAndRemoveUntil(
              context, MainScreen.idScreen, (route) => false);
        } else {
          Navigator.pop(context);
          _firebaseAuth.signOut();
          displayToastMessage(
              'No record exist for this user, Please create new account.',
              context);
        }
      });
    } else {
      Navigator.pop(context);
      displayToastMessage('Error occur.', context);
    }
  }
}

displayToastMessage(String msg, BuildContext context) {
  Fluttertoast.showToast(msg: msg);
}
