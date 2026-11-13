import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'store.dart';

/// Parental lock: adult categories need a 4-digit PIN.
class Parental {
  static bool _unlocked = false;

  static final _adult = RegExp(
      r'(adult|xxx|porn|\+18|18\+|for adults|erotic|sex)',
      caseSensitive: false);

  static bool isAdult(String name) => _adult.hasMatch(name);

  static bool get unlocked => _unlocked;
  static void lock() => _unlocked = false;

  /// Asks for the PIN (or to create one). Returns true if access is allowed.
  static Future<bool> unlock(BuildContext context) async {
    if (_unlocked) return true;
    final hasPin = Store.parentalPin.isNotEmpty;
    final pin = await _askPin(context,
        title: hasPin ? 'Enter parental PIN' : 'Create a parental PIN',
        hint: hasPin
            ? 'This category is locked.'
            : 'Choose 4 digits. You will need them to open adult categories.');
    if (pin == null) return false;
    if (!hasPin) {
      Store.parentalPin = pin;
      _unlocked = true;
      return true;
    }
    if (pin == Store.parentalPin) {
      _unlocked = true;
      return true;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Wrong PIN')));
    }
    return false;
  }

  /// Change the PIN from settings (asks for the old one first).
  static Future<void> changePin(BuildContext context) async {
    if (Store.parentalPin.isNotEmpty) {
      final old = await _askPin(context,
          title: 'Current PIN', hint: 'Enter your current PIN.');
      if (old == null) return;
      if (old != Store.parentalPin) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Wrong PIN')));
        }
        return;
      }
    }
    if (!context.mounted) return;
    final pin = await _askPin(context,
        title: 'New PIN', hint: 'Choose 4 digits.');
    if (pin == null) return;
    Store.parentalPin = pin;
    _unlocked = false;
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('PIN saved')));
    }
  }

  static Future<String?> _askPin(BuildContext context,
      {required String title, required String hint}) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(hint),
          const SizedBox(height: 12),
          TextField(
            controller: c,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 12),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (c.text.length == 4) Navigator.pop(ctx, c.text);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
