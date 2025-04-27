import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:project_1/models/product_catalog_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SellCoinScreen extends StatefulWidget {
  @override
  _SellCoinScreenState createState() => _SellCoinScreenState();
}

class _SellCoinScreenState extends State<SellCoinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _valueController = TextEditingController();
  final _inStockController = TextEditingController();
  final _yearController = TextEditingController();
  final _sellerPhoneController = TextEditingController();
  final _sellerNameController = TextEditingController();
  
  File? _coinFaceImage;
  File? _coinBackImage;
  bool _isUploading = false;
  String? _errorMessage;
  String? _selectedCountry;

  final String _imgbbApiKey = '90fd9d602c79c4bc285c8124ad0b00ea';

  final List<String> _countries = [
    'Afghanistan', 'Albania', 'Algeria', 'Andorra', 'Angola',
    'Antigua and Barbuda', 'Argentina', 'Armenia', 'Australia', 'Austria',
    'Azerbaijan', 'Bahamas', 'Bahrain', 'Bangladesh', 'Barbados',
    'Belarus', 'Belgium', 'Belize', 'Benin', 'Bhutan', 'Bolivia',
    'Bosnia and Herzegovina', 'Botswana', 'Brazil', 'Brunei', 'Bulgaria',
    'Burkina Faso', 'Burundi', 'Côte d\'Ivoire', 'Cabo Verde', 'Cambodia',
    'Cameroon', 'Canada', 'Central African Republic', 'Chad', 'Chile',
    'China', 'Colombia', 'Comoros', 'Congo', 'Costa Rica', 'Croatia',
    'Cuba', 'Cyprus', 'Czech Republic', 'Denmark', 'Djibouti', 'Dominica',
    'Dominican Republic', 'Ecuador', 'Egypt', 'El Salvador', 'Equatorial Guinea',
    'Eritrea', 'Estonia', 'Eswatini', 'Ethiopia', 'Fiji', 'Finland',
    'France', 'Gabon', 'Gambia', 'Georgia', 'Germany', 'Ghana', 'Greece',
    'Grenada', 'Guatemala', 'Guinea', 'Guinea-Bissau', 'Guyana', 'Haiti',
    'Holy See', 'Honduras', 'Hungary', 'Iceland', 'India', 'Indonesia',
    'Iran', 'Iraq', 'Ireland', 'Israel', 'Italy', 'Jamaica', 'Japan',
    'Jordan', 'Kazakhstan', 'Kenya', 'Kiribati', 'Kuwait', 'Kyrgyzstan',
    'Laos', 'Latvia', 'Lebanon', 'Lesotho', 'Liberia', 'Libya',
    'Liechtenstein', 'Lithuania', 'Luxembourg', 'Madagascar', 'Malawi',
    'Malaysia', 'Maldives', 'Mali', 'Malta', 'Marshall Islands', 'Mauritania',
    'Mauritius', 'Mexico', 'Micronesia', 'Moldova', 'Monaco', 'Mongolia',
    'Montenegro', 'Morocco', 'Mozambique', 'Myanmar', 'Namibia', 'Nauru',
    'Nepal', 'Netherlands', 'New Zealand', 'Nicaragua', 'Niger', 'Nigeria',
    'North Korea', 'North Macedonia', 'Norway', 'Oman', 'Pakistan', 'Palau',
    'Palestine State', 'Panama', 'Papua New Guinea', 'Paraguay', 'Peru',
    'Philippines', 'Poland', 'Portugal', 'Qatar', 'Romania', 'Russia',
    'Rwanda', 'Saint Kitts and Nevis', 'Saint Lucia', 'Saint Vincent and the Grenadines',
    'Samoa', 'San Marino', 'Sao Tome and Principe', 'Saudi Arabia', 'Senegal',
    'Serbia', 'Seychelles', 'Sierra Leone', 'Singapore', 'Slovakia', 'Slovenia',
    'Solomon Islands', 'Somalia', 'South Africa', 'South Korea', 'South Sudan',
    'Spain', 'Sri Lanka', 'Sudan', 'Suriname', 'Sweden', 'Switzerland',
    'Syria', 'Tajikistan', 'Tanzania', 'Thailand', 'Timor-Leste', 'Togo',
    'Tonga', 'Trinidad and Tobago', 'Tunisia', 'Turkey', 'Turkmenistan',
    'Tuvalu', 'Uganda', 'Ukraine', 'United Arab Emirates', 'United Kingdom',
    'United States', 'Uruguay', 'Uzbekistan', 'Vanuatu', 'Venezuela',
    'Vietnam', 'Yemen', 'Zambia', 'Zimbabwe'
  ];

  @override
  void initState() {
    super.initState();
    _loadSellerInfo();
  }

  Future<void> _loadSellerInfo() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(auth.currentUser!.uid)
          .get();
      
      if (userDoc.exists) {
        setState(() {
          _sellerNameController.text = userDoc.data()?['name'] ?? '';
          _sellerPhoneController.text = userDoc.data()?['phone'] ?? '';
        });
      }
    }
  }

  Future<String?> _uploadImageToImgBB(File image) async {
    try {
      final url = Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbApiKey');
      final request = http.MultipartRequest('POST', url)
        ..files.add(await http.MultipartFile.fromPath('image', image.path));

      final response = await request.send();
      final data = jsonDecode(await response.stream.bytesToString());
      return data['data']['url'];
    } catch (e) {
      setState(() => _errorMessage = 'Failed to upload image: ${e.toString()}');
      return null;
    }
  }

  Future<void> _pickImage(bool isFace) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        if (isFace) {
          _coinFaceImage = File(pickedFile.path);
        } else {
          _coinBackImage = File(pickedFile.path);
        }
      });
    }
  }

  String? _validateNumber(String? value, String fieldName, {bool allowDecimal = true}) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    final number = allowDecimal ? double.tryParse(value) : int.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    if (number <= 0) {
      return '$fieldName must be greater than 0';
    }
    return null;
  }

  Future<void> _submitForm(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    if (_coinFaceImage == null || _coinBackImage == null) {
      setState(() => _errorMessage = 'Please upload both coin images');
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final faceUrl = await _uploadImageToImgBB(_coinFaceImage!);
      final backUrl = await _uploadImageToImgBB(_coinBackImage!);

      if (faceUrl == null || backUrl == null) {
        throw Exception('Image upload failed');
      }

      final auth = FirebaseAuth.instance;
      final catalogState = Provider.of<ProductCatalogState>(context, listen: false);

      if (_sellerNameController.text.isEmpty || _sellerPhoneController.text.isEmpty) {
        throw Exception('Seller information is incomplete');
      }

      await FirebaseFirestore.instance.collection('products').add({
        'name': _nameController.text,
        'price': double.parse(_priceController.text),
        'value': double.parse(_valueController.text),
        'inStock': int.parse(_inStockController.text),
        'country': _selectedCountry,
        'year': int.parse(_yearController.text),
        'images': [faceUrl, backUrl],
        'createdAt': FieldValue.serverTimestamp(),
        'sellerId': auth.currentUser?.uid,
        'sellerName': _sellerNameController.text,
        'sellerPhone': _sellerPhoneController.text,
        'sellerEmail': auth.currentUser?.email,
      });

      if (auth.currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(auth.currentUser!.uid)
            .set({
              'name': _sellerNameController.text,
              'phone': _sellerPhoneController.text,
              'email': auth.currentUser?.email,
            }, SetOptions(merge: true));
      }

      Navigator.pop(context);
      catalogState.fetchProducts();
    } catch (e) {
      setState(() => _errorMessage = 'Error: ${e.toString()}');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sell Your Coin'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImagePreview(_coinFaceImage, 'Coin Face', () => _pickImage(true)),
                    _buildImagePreview(_coinBackImage, 'Coin Back', () => _pickImage(false)),
                  ],
                ),
                SizedBox(height: 20),

                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Coin Name'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),

                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(labelText: 'Price (EGP)'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => _validateNumber(value, 'Price'),
                ),

                TextFormField(
                  controller: _valueController,
                  decoration: InputDecoration(labelText: 'Original Value'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => _validateNumber(value, 'Value'),
                ),

                TextFormField(
                  controller: _inStockController,
                  decoration: InputDecoration(labelText: 'Quantity Available'),
                  keyboardType: TextInputType.number,
                  validator: (value) => _validateNumber(value, 'Quantity', allowDecimal: false),
                ),
                
                DropdownButtonFormField<String>(
                  value: _selectedCountry,
                  items: _countries.map((country) {
                    return DropdownMenuItem<String>(
                      value: country,
                      child: Text(country),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCountry = value;
                    });
                  },
                  decoration: InputDecoration(labelText: 'Country'),
                  validator: (value) => value == null ? 'Please select a country' : null,
                ),
                SizedBox(height: 16),

                TextFormField(
                  controller: _yearController,
                  decoration: InputDecoration(labelText: 'Year (1-2025)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a year';
                    }
                    final year = int.tryParse(value);
                    if (year == null) {
                      return 'Please enter a valid number';
                    }
                    if (year < 1 || year > 2025) {
                      return 'Year must be between 1 and 2025';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _isUploading ? null : () => _submitForm(context),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: Theme.of(context).primaryColor,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: _isUploading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'List Coin for Sale',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(File? image, String label, VoidCallback onPressed) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        GestureDetector(
          onTap: onPressed,
          child: Container(
            height: 150,
            width: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(image, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 40),
                      Text('Tap to upload'),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _valueController.dispose();
    _inStockController.dispose();
    _yearController.dispose();
    _sellerPhoneController.dispose();
    _sellerNameController.dispose();
    super.dispose();
  }
}