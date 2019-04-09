import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import '../scoped_models/main.dart';
import '../models/auth.dart';
import '../widgets/ui_elements/adaptive_progress_indicator.dart';

class AuthPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return AuthPageState();
  }
}

class AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  final Map formData = {'email': null, 'password': null};

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController passwordTextController = TextEditingController();
  AnimationController _controller;
  Animation _slideAnimation;

  AuthMode _authMode = AuthMode.Login;

  void initState() {
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _slideAnimation =
        Tween(begin: Offset(0.0, -2.0), end: Offset.zero).animate(_controller);

    super.initState();
  }

  DecorationImage _buildBackgroundImage() {
    return DecorationImage(
        fit: BoxFit.cover,
        colorFilter:
            ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.dstATop),
        image: AssetImage('assets/background.jpg'));
  }

  Widget _buildEmailTextField() {
    return TextFormField(
      validator: (String value) {
        if (!RegExp(
                r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
            .hasMatch(value)) {
          return 'Enter a valid email address e.g. example@example.com';
        }
      },
      onSaved: (String email) {
        formData['email'] = email;
      },
      decoration: InputDecoration(
          labelText: 'Email', filled: true, fillColor: Colors.white),
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildPasswordTextField() {
    return TextFormField(
      controller: passwordTextController,
      validator: (String value) {
        if (value.isEmpty || value.length < 5) {
          return 'Enter a password having 5+ characters.';
        }
      },
      onSaved: (String password) {
        formData['password'] = password;
      },
      obscureText: true,
      decoration: InputDecoration(
          labelText: 'Password', filled: true, fillColor: Colors.white),
    );
  }

  Widget _buildPasswordConfirmTextField() {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: Curves.easeIn),
      child: SlideTransition(
        position: _slideAnimation,
        child: TextFormField(
          validator: (String value) {
            if (passwordTextController.text != value &&
                _authMode == AuthMode.Signup) {
              return 'Password do not match.';
            }
          },
          obscureText: true,
          decoration: InputDecoration(
              labelText: 'Confirm Password',
              filled: true,
              fillColor: Colors.white),
        ),
      ),
    );
  }

  void _submitForm(MainModel model) async {
    if (!formKey.currentState.validate()) {
      return;
    }

    formKey.currentState.save();

    model.toggleIsLoading();
    Map resInfo =
        await model.auth(formData['email'], formData['password'], _authMode);
    model.toggleIsLoading();

    if (resInfo['success']) {
      //Navigator.pushReplacementNamed(context, '/');
    } else {
      showDialog(
          context: context,
          builder: (BuildContext contenxt) {
            return AlertDialog(
              title: Text('An error occured!'),
              content: Text(resInfo['message']),
              actions: <Widget>[
                FlatButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double deviceWidth = MediaQuery.of(context).size.width; //Media query
    final double targetWidth = deviceWidth > 768.0 ? 500.0 : deviceWidth * 0.95;

    return Scaffold(
        appBar: AppBar(
          title: Text('Login'),
        ),
        body: Container(
          decoration: BoxDecoration(image: _buildBackgroundImage()),
          padding: EdgeInsets.all(10.0),
          child: Center(
              child: SingleChildScrollView(
                  child: Container(
            width: targetWidth, //80% of our device width
            child: Form(
                key: formKey,
                child: Column(children: <Widget>[
                  _buildEmailTextField(),
                  SizedBox(
                    height: 10.0,
                  ),
                  _buildPasswordTextField(),
                  SizedBox(
                    height: 10.0,
                  ),
                  _buildPasswordConfirmTextField(),
                  _authMode == AuthMode.Signup
                      ? SizedBox(
                          height: 10.0,
                        )
                      : Container(),
                  FlatButton(
                    child: Text(
                        'Switch to ${_authMode == AuthMode.Login ? 'Signup' : 'Login'}'),
                    onPressed: () {
                      if (_authMode == AuthMode.Login) {
                        setState(() {
                          _authMode = AuthMode.Signup;
                        });
                        _controller.forward();
                      } else {
                        setState(() {
                          _authMode = AuthMode.Login;
                        });
                        _controller.reverse();
                      }
                    },
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  ScopedModelDescendant<MainModel>(
                    builder:
                        (BuildContext context, Widget child, MainModel model) {
                      return model.isLoading
                          ? AdaptiveProgressIndicator()
                          : RaisedButton(
                              textColor: Colors.white,
                              onPressed: () => _submitForm(model),
                              child: Text(_authMode == AuthMode.Login
                                  ? 'LOGIN'
                                  : 'SIGNUP'),
                            );
                    },
                  ),
                ])),
          ))),
        ));
  }
}
