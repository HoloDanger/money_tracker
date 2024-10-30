import 'dart:async';
import 'package:logger/logger.dart';
import 'package:money_tracker/models/recurrence_frequency.dart';
import 'package:money_tracker/models/transaction.dart';
import 'package:money_tracker/services/database_service.dart';

/// A service class for managing recurring transactions.
class RecurringTransactionService {
  final DatabaseService databaseService = DatabaseService();
  final Logger logger = Logger();

  /// Schedules recurring transaction.
  void scheduleRecurringTransactions(List<Transaction> transactions) {
    for (var transaction in transactions) {
      if (transaction.isRecurring && transaction.recurrenceFrequency != null) {
        _scheduleTransaction(transaction);
      }
    }
  }

  /// Schedules a single recurring transaction
  void _scheduleTransaction(Transaction transaction) {
    Duration interval;
    switch (transaction.recurrenceFrequency) {
      case RecurrenceFrequency.daily:
        interval = const Duration(days: 1);
        break;
      case RecurrenceFrequency.weekly:
        interval = const Duration(days: 7);
        break;
      case RecurrenceFrequency.monthly:
        interval = const Duration(days: 30); // Simplified for example purposes
        break;
      default:
        return;
    }

    try {
      Timer.periodic(interval, (timer) {
        // Logic to create a new transaction based on the recurring transaction
        createTransaction(
          id: generateNewId(), // Implement this function to generate a unique ID
          amount: transaction.amount,
          category: transaction.category,
          date: DateTime.now(),
          formattedDate: formatDate(
              DateTime.now()), // Implement this function to format the date
          formattedAmount: formatAmount(transaction
              .amount), // Implement this function to format the amount
          isRecurring: transaction.isRecurring,
          recurrenceFrequency: transaction.recurrenceFrequency,
          nextOccurrence: calculateNextOccurrence(
              DateTime.now(), transaction.recurrenceFrequency!),
        );
      });
    } catch (e) {
      // Handle scheduling error
      logger.e('Error scheduling transaction: $e');
    }
  }

  /// Creates a new transaction.
  void createTransaction({
    required String id,
    required double amount,
    required String category,
    required DateTime date,
    required String formattedDate,
    required String formattedAmount,
    bool isRecurring = false,
    RecurrenceFrequency? recurrenceFrequency,
    required DateTime nextOccurrence,
  }) {
    final transaction = Transaction(
      id: id,
      amount: amount,
      category: category,
      date: date,
      formattedDate: formattedDate,
      formattedAmount: formattedAmount,
      isRecurring: isRecurring,
      recurrenceFrequency: recurrenceFrequency,
      nextOccurrence: nextOccurrence,
    );

    try {
      // Save the transaction to the database or state
      databaseService.insertTransaction(transaction);
    } catch (e) {
      // Handle database error
      logger.e('Error inserting transaction: $e');
    }
  }

  String generateNewId() {
    // Implement a method to generate a unique ID for each transaction
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Generates a unique ID for each transaction.
  String formatDate(DateTime date) {
    // Implement a method to format the date as a string
    return date.toIso8601String();
  }

  /// Formats the amount as a string.
  String formatAmount(double amount) {
    // Implement a method to format the amount as a string
    return amount.toStringAsFixed(2);
  }

  /// Calculates the next occurrence date based on the recurrence frequency.
  DateTime calculateNextOccurrence(
      DateTime date, RecurrenceFrequency recurrenceFrequency) {
    switch (recurrenceFrequency) {
      case RecurrenceFrequency.daily:
        return date.add(const Duration(days: 1));
      case RecurrenceFrequency.weekly:
        return date.add(const Duration(days: 7));
      case RecurrenceFrequency.monthly:
        return DateTime(date.year, date.month + 1, date.day);
      default:
        return date;
    }
  }
}
