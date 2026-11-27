import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
final _date = DateFormat('dd/MM/yyyy');

String formatCurrency(double value) => _currency.format(value);

String formatDate(DateTime date) => _date.format(date);

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
