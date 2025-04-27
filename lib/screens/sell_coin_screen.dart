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
  final _countryController = TextEditingController();
  final _yearController = TextEditingController();
  final _sellerPhoneController = TextEditingController();
  final _sellerNameController = TextEditingController();
  
  File? _coinFaceImage;
  File? _coinBackImage;
  bool _isUploading = false;
  String? _errorMessage;

  final String _imgbbApiKey = '90fd9d602c79c4bc285c8124ad0b00ea';

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

      // Validate seller info
      if (_sellerNameController.text.isEmpty || _sellerPhoneController.text.isEmpty) {
        throw Exception('Seller information is incomplete');
      }

      await FirebaseFirestore.instance.collection('products').add({
        'name': _nameController.text,
        'price': double.parse(_priceController.text),
        'value': double.parse(_valueController.text),
        'inStock': int.parse(_inStockController.text),
        'country': _countryController.text,
        'year': int.parse(_yearController.text),
        'images': [faceUrl, backUrl],
        'createdAt': FieldValue.serverTimestamp(),
        'sellerId': auth.currentUser?.uid,
        'sellerName': _sellerNameController.text,
        'sellerPhone': _sellerPhoneController.text,
        'sellerEmail': auth.currentUser?.email,
      });

      // Update user document with phone and name
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
      setState(() => _errorMessage = e.toString());
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
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _valueController,
                  decoration: InputDecoration(labelText: 'Original Value'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _inStockController,
                  decoration: InputDecoration(labelText: 'Quantity Available'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _countryController,
                  decoration: InputDecoration(labelText: 'Country'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _yearController,
                  decoration: InputDecoration(labelText: 'Year'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Required' : null,
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
    _countryController.dispose();
    _yearController.dispose();
    _sellerPhoneController.dispose();
    _sellerNameController.dispose();
    super.dispose();
  }
}