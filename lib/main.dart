import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/request_coin_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/product_catalog_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/sell_coin_screen.dart';
import 'services/auth_service.dart';
import 'models/product_catalog_state.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<ProductCatalogState>(
          create: (_) => ProductCatalogState(),
        ),
      ],
      child: MaterialApp(
        title: 'Coin Catalog',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        home: AuthWrapper(),
        routes: {
          '/catalog': (context) => ProductCatalogScreen(),
          '/cart': (context) => CartScreen(),
          '/request': (context) => RequestCoinScreen(),
          '/sell': (context) => SellCoinScreen(),
          '/profile': (context) => ProfileScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is logged in, go to catalog
        if (snapshot.hasData) {
          return ProductCatalogScreen();
        }
        
        // Otherwise show auth screen
        return AuthScreen();
      },
    );
  }
}