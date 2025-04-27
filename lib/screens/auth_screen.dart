import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_1/services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  String _email = '';
  String _password = '';
  String _name = '';
  String _phone = '';
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (_isLogin) {
        await authService.signInWithEmail(_email, _password);
      } else {
        await authService.signUpWithEmail(
          email: _email,
          password: _password,
          name: _name,
          phone: _phone,
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isLogin ? 'Login' : 'Sign Up',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(
          color: Theme.of(context).primaryColor,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Name field (only shown during sign up)
                if (!_isLogin) ...[
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Full Name'),
                    validator: (value) => 
                        value!.isEmpty ? 'Please enter your name' : null,
                    onSaved: (value) => _name = value!.trim(),
                  ),
                  SizedBox(height: 15),
                ],
                
                // Email field
                TextFormField(
                  decoration: InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => 
                      value!.contains('@') ? null : 'Invalid email',
                  onSaved: (value) => _email = value!.trim(),
                ),
                SizedBox(height: 15),

                // Phone field (only shown during sign up)
                if (!_isLogin) ...[
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Phone Number'),
                    keyboardType: TextInputType.phone,
                    validator: (value) => 
                        value!.isEmpty ? 'Please enter your phone' :
                        value.length < 10 ? 'Invalid phone number' : null,
                    onSaved: (value) => _phone = value!.trim(),
                  ),
                  SizedBox(height: 15),
                ],

                // Password field
                TextFormField(
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) => 
                      value!.length >= 6 ? null : 'Minimum 6 characters',
                  onSaved: (value) => _password = value!,
                ),
                SizedBox(height: 20),

                // Error message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),

                // Submit button
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                        ),
                        child: Text(_isLogin ? 'Login' : 'Sign Up'),
                      ),
                SizedBox(height: 10),

                // Toggle between login/signup
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(_isLogin
                      ? 'Create new account'
                      : 'Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}