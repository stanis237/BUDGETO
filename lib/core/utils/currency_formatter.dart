import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, String currency) {
    switch (currency) {
      case 'FCFA':
        final formatter = NumberFormat('#,##0', 'fr_FR');
        return '${formatter.format(amount)} FCFA';
      case 'USD':
        final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
        return formatter.format(amount);
      case 'GBP':
        final formatter = NumberFormat.currency(symbol: '£', decimalDigits: 2);
        return formatter.format(amount);
      case 'EUR':
      default:
        final formatter = NumberFormat('#,##0.00', 'fr_FR');
        return '${formatter.format(amount)} €';
    }
  }

  static String symbol(String currency) {
    switch (currency) {
      case 'FCFA': return 'FCFA';
      case 'USD': return '\$';
      case 'GBP': return '£';
      case 'EUR': default: return '€';
    }
  }

  static List<Map<String, String>> get availableCurrencies => [
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€', 'flag': '🇪🇺'},
    {'code': 'FCFA', 'name': 'Franc CFA', 'symbol': 'FCFA', 'flag': '🌍'},
    {'code': 'USD', 'name': 'Dollar US', 'symbol': '\$', 'flag': '🇺🇸'},
    {'code': 'GBP', 'name': 'Livre Sterling', 'symbol': '£', 'flag': '🇬🇧'},
  ];
}
