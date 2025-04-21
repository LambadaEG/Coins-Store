import 'package:flutter/material.dart';

class RequestCoinScreen extends StatefulWidget {
  @override
  _RequestCoinScreenState createState() => _RequestCoinScreenState();
}

class _RequestCoinScreenState extends State<RequestCoinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _countryController = TextEditingController();
  final _valueController = TextEditingController();
  final _yearController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _countryController.dispose();
    _valueController.dispose();
    _yearController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Coin')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Can\'t find your coin? Request it here!',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(
                  labelText: 'Country of Origin',
                  prefixIcon: Icon(Icons.flag),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the country';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(
                  labelText: 'Estimated Value (EGP)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the estimated value';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(
                  labelText: 'Year of Minting',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the year';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid year';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Your Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Here you would typically send the request to your backend
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Request submitted successfully!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Submit Request', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}