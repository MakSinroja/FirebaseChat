import 'dart:async';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'MainScreen.dart';
import '../constants/constants.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key key, this.title}) : super(key: key);

  final String title;

  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  SharedPreferences preferences;

  bool isLoading = false;
  bool isLoggedIn = false;
  FirebaseUser currentUser;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    isSignedIn();
  }

  void isSignedIn() async {
    this.setState(() {
      isLoading = true;
    });

    preferences = await SharedPreferences.getInstance();

    isLoggedIn = await googleSignIn.isSignedIn();
    if (isLoggedIn) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  MainScreen(currentUserId: preferences.getString("id"))));
    }

    this.setState(() {
      isLoading = false;
    });
  }

  Future<Null> handleSignIn() async {
    preferences = await SharedPreferences.getInstance();

    this.setState(() {
      isLoading = true;
    });

    GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
    GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken);

    FirebaseUser firebaseUser =
        await firebaseAuth.signInWithCredential(credential);

    if (firebaseUser != null) {
      final QuerySnapshot result = await Firestore.instance
          .collection('users')
          .where('id', isEqualTo: firebaseUser.uid)
          .getDocuments();
      final List<DocumentSnapshot> documents = result.documents;

      if (documents.length == 0) {
        Firestore.instance
            .collection("users")
            .document(firebaseUser.uid)
            .setData({
          "nickname": firebaseUser.displayName,
          'photoUrl': firebaseUser.photoUrl,
          'id': firebaseUser.uid
        });

        /* Store data into the local preference */
        currentUser = firebaseUser;
        await preferences.setString("id", currentUser.uid);
        await preferences.setString("nickname", currentUser.displayName);
        await preferences.setString("photoUrl", currentUser.photoUrl);
      } else {
        await preferences.setString("id", documents[0]['id']);
        await preferences.setString("nickname", documents[0]['nickname']);
        await preferences.setString("photoUrl", documents[0]['photoUrl']);
        await preferences.setString("aboutMe", documents[0]['aboutMe']);
      }

      Fluttertoast.showToast(msg: "Sign in successfully!");

      this.setState(() {
        isLoading = false;
      });

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MainScreen(
                    currentUserId: firebaseUser.uid,
                  )));
    } else {
      Fluttertoast.showToast(msg: "Sign in fail!");
      this.setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: <Widget>[
          Center(
            child: FlatButton(
              onPressed: handleSignIn,
              child:
                  Text('Sign In With Google', style: TextStyle(fontSize: 16.0)),
              color: Color(0xffdd4b39),
              highlightColor: Color(0xffff7f7f),
              splashColor: Colors.transparent,
              textColor: Colors.white,
              padding: EdgeInsets.fromLTRB(30.0, 15.0, 30.0, 15.0),
            ),
          ),
          Positioned(
              child: isLoading
                  ? Container(
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                        ),
                      ),
                      color: Colors.white.withOpacity(0.8),
                    )
                  : Container())
        ],
      ),
    );
  }
}
