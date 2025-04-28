import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/request_coin_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/product_catalog_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/sell_coin_screen.dart';
import 'screens/profile_screen.dart';
import 'services/auth_service.dart';
import 'models/product_catalog_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

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
            backgroundColor: Colors.white,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            iconTheme: IconThemeData(
              color: Colors.black, // ✅ icons black
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
          '/login': (context) => LoginScreen(email: '', errorMessage: ''),
          '/signup': (context) => SignUpScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data;
          if (user != null && user.emailVerified) {
            return ProductCatalogScreen();
          } else {
            return LoginScreen(
              email: user?.email ?? '',
              errorMessage: 'Please verify your email before logging in.',
            );
          }
        }

        return LoginScreen(
          email: '',
          errorMessage: '',
        );
      },
    );
  }
}
