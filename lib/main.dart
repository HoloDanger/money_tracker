import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:money_tracker/providers/budget_provider.dart';
import 'package:money_tracker/providers/category_provider.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/screens/home_screen.dart';
import 'package:money_tracker/services/database_service.dart';
import 'package:money_tracker/services/recurring_transaction_service.dart';
import 'package:provider/provider.dart';

void main() {
  // Making zone errors fatal can help in debugging
  BindingBase.debugZoneErrorsAreFatal = true;

  final Logger logger = Logger();

  // Run the app initialization in a guarded zone
  runZonedGuarded(() async {
    // Ensure Flutter binding is initialized in this zone
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize services or perform async operations here
    final databaseService = DatabaseService();
    final recurringTransactionService = RecurringTransactionService();

    // Set up a custom error handler for Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      logger.e(
        'Flutter error: ${details.exceptionAsString()}\n${details.stack}',
      );
      // Optionally, send the error to a monitoring service
      // sendErrorToMonitoringService(details.exception, details.stack);
    };

    // Fetch existing transactions from the database
    databaseService.getTransactions().then((transactions) {
      // Schedule recurring transactions
      recurringTransactionService.scheduleRecurringTransactions(transactions);
      runApp(MyApp(databaseService: databaseService));
    });
  }, (error, stackTrace) {
    logger.e('Uncaught asynchronous error: $error\n$stackTrace');
    // Optionally, send the error to a monitoring service
    // sendErrorToMonitoringService(error, stackTrace);
  });
}

class MyApp extends StatelessWidget {
  final DatabaseService databaseService;

  const MyApp({super.key, required this.databaseService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TransactionProvider(databaseService: databaseService),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => BudgetProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'CashFlow - Money Tracker',
        theme: ThemeData(
          primarySwatch: Colors.green,
          hintColor: Colors.amber,
          textTheme: TextTheme(
            displayLarge:
                TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            bodyLarge: TextStyle(fontSize: 14.0),
          ),
          buttonTheme: ButtonThemeData(
              buttonColor: Colors.green, textTheme: ButtonTextTheme.primary),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
