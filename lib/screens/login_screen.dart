import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_1/services/auth_service.dart';
import 'package:project_1/screens/signup_screen.dart';
import 'package:project_1/screens/product_catalog_screen.dart';

class LoginScreen extends StatefulWidget {
  final String email;
  final String errorMessage;

  LoginScreen({required this.email, required this.errorMessage});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLoading = false;
  String? _errorMessage;
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _resendCountdown = 60;
    });

    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.signInWithEmail(_email, _password);

      if (user != null && user.emailVerified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProductCatalogScreen()),
        );
      } else {
        setState(() {
          _errorMessage =
              'Please verify your email address before logging in.';
        });
        _startCountdown();
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_resendCountdown > 0) return;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.sendVerificationEmail();
      setState(() {
        _errorMessage = 'Verification email sent! Check your inbox.';
      });
      _startCountdown();
    } catch (e) {
      setState(() => _errorMessage = 'Failed to resend: ${e.toString()}');
    }
  }

  Future<void> _resetPassword() async {
    if (_email.trim().isEmpty || !_email.contains('@')) {
      setState(() {
        _errorMessage = 'Enter a valid email to reset password';
      });
      return;
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.sendPasswordResetEmail(_email);
      setState(() {
        _errorMessage = 'Password reset email sent. Check your inbox.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _email = widget.email;
    _errorMessage = widget.errorMessage.isEmpty ? null : widget.errorMessage;

    if (_errorMessage ==
        'Please verify your email address before logging in.') {
      _startCountdown();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Login',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  initialValue: _email,
                  decoration: InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      value!.contains('@') ? null : 'Invalid email',
                  onChanged: (value) => _email = value.trim(),
                ),
                SizedBox(height: 15),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) =>
                      value!.length >= 6 ? null : 'Minimum 6 characters',
                  onSaved: (value) => _password = value!,
                ),
                SizedBox(height: 20),
                if (_errorMessage != null)
                  Column(
                    children: [
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: _errorMessage!
                                  .startsWith('Verification') ||
                              _errorMessage!.startsWith('Password reset')
                              ? Colors.green
                              : Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_errorMessage ==
                              'Please verify your email address before logging in.' ||
                          _resendCountdown > 0)
                        Column(
                          children: [
                            if (_resendCountdown > 0)
                              Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Resend available in $_resendCountdown seconds',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            TextButton(
                              onPressed: _resendCountdown == 0
                                  ? _resendVerificationEmail
                                  : null,
                              child: Text('Resend Verification Email'),
                            ),
                          ],
                        ),
                    ],
                  ),
                SizedBox(height: 20),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                        ),
                        child: Text('Login'),
                      ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: _resetPassword,
                  child: Text('Forgot your password?'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => SignUpScreen()),
                    );
                  },
                  child: Text('Create an account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
