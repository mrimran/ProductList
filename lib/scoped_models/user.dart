import 'package:scoped_model/scoped_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:rxdart/subjects.dart';

import '../models/user.dart';
import '../models/auth.dart';
import './products.dart';

mixin UserModel on Model {
  User _authUser;
  final authEndpoint =
      'https://www.googleapis.com/identitytoolkit/v3/relyingparty/';
  final authKey = 'AIzaSyBxr8j7o3760Nvp-kkDgJK7IcAsUQBCbTs';
  static User loggedInUser;
  Timer authTimer;
  ProductsModel _productsModel;

  //To emit events so that on other places of application we can moniter if the logout got triggered on time out
  PublishSubject<bool> userSubject = PublishSubject();

  User get authUser {
    return _authUser;
  }

  void setAuthUser(User user) {
    UserModel.loggedInUser = this._authUser = user;
  }

  Future<Map> auth(String email, String password,
      [AuthMode mode = AuthMode.Login]) async {
    Map authData = this.authPayload(email, password);

    http.Response res;

    if (mode == AuthMode.Login) {
      res = await http.post(this.authEndpoint + 'verifyPassword?key=$authKey',
          body: json.encode(authData),
          headers: {'Content-Type': 'application/json'});
      //authUser = User(id: '1', email: email, password: password);
    } else {
      res = await http.post(
          this.authEndpoint +
              'signupNewUser?key=AIzaSyBxr8j7o3760Nvp-kkDgJK7IcAsUQBCbTs',
          body: json.encode(authData),
          headers: {'Content-Type': 'application/json'});
    }

    final Map resBody = json.decode(res.body);

    print(resBody);

    bool hasError = false;
    String message = 'Auth successeeded';
    if (resBody.containsKey('error')) {
      hasError = true;
      if (resBody['error']['message'] == 'EMAIL_NOT_FOUND' ||
          resBody['error']['message'] == 'INVALID_PASSWORD') {
        message = 'Wrong email or password.';
      } else if (resBody['error']['message'] == 'EMAIL_EXISTS') {
        message = 'Email already exists.';
      } else {
        message = 'Something went wrong.';
      }
    }

    if (!hasError) {
      this.setAuthUser(User(
          id: resBody['localId'], email: email, token: resBody['idToken']));

      SharedPreferences pref = await SharedPreferences.getInstance();
      pref.setString('token', resBody['idToken']);
      pref.setString('userEmail', email);
      pref.setString('userId', resBody['localId']);

      final DateTime now = DateTime.now();
      final DateTime expiryTime =
          now.add(Duration(seconds: int.parse(resBody['expiresIn'])));

      pref.setString('expiryTime', expiryTime.toIso8601String());

      this.setAuthTimeout(int.parse(resBody['expiresIn']));
      print("ayaaa...");
      userSubject.add(true);
      notifyListeners();
    }

    return {'success': !hasError, 'message': message};
  }

  void autoAuth() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String token = pref.getString('token');
    String expiryTimeString = pref.getString('expiryTime');

    if (token != null) {
      final DateTime now = DateTime.now();
      final expiryTime = DateTime.parse(expiryTimeString);
      if (expiryTime.isBefore(now)) {
        setAuthToNull();
        notifyListeners();
        return;
      }

      String userEmail = pref.getString('userEmail');
      String userId = pref.getString('userId');

      int tokenLifespan = expiryTime.difference(now).inSeconds;
      setAuthTimeout(tokenLifespan);

      this.setAuthUser(User(id: userId, email: userEmail, token: token));
      userSubject.add(true);

      notifyListeners();
   }
  }

  Map authPayload(String email, String password) {
    return {
      //required by google auth
      'email': email,
      'password': password,
      'returnSecureToken': true
    };
  }

  setAuthToNull() {
    this._authUser = UserModel.loggedInUser = null;
  }

  void logout() async {
    print('logout...');
    setAuthToNull();
    final SharedPreferences pref = await SharedPreferences.getInstance();

    pref.remove('token');
    pref.remove('userEmail');
    pref.remove('userId');
    pref.remove('expiresIn');

    if (authTimer != null) {
      authTimer.cancel();
    }

    userSubject.add(false);
  }

  void setAuthTimeout(int time) {
    authTimer = Timer(Duration(seconds: time), () {
      this.logout();
    });
  }
}
