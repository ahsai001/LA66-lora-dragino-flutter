import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// modified : 08 agustus 2023
class CustomCurrencyInputFormatter extends TextInputFormatter {
  final String symbol;
  final int decimalDigits;
  NumberFormat? numberFormat;
  String? groupChar;
  String? decimalChar;
  CustomCurrencyInputFormatter(
      {this.symbol = "",
      this.decimalDigits = 2,
      this.groupChar,
      this.decimalChar,
      this.numberFormat}) {
    init();
  }
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var newText = newValue.text;
    //1. checking special case
    if (newText.isEmpty) {
      newText = "0";
    } else {
      //conditions when need to use oldvalue

      if (decimalDigits == 0 && newText.contains(decimalChar!)) {
        //handle ketika decimal 0 tapi kok ada decimal char
        return oldValue;
      }

      if (decimalDigits > 0 && !newValue.text.contains(decimalChar!)) {
        //handle ketika perlu decimal tapi decimal char kehapus
        if (oldValue.text.length == newValue.text.length + 1) {
          return oldValue.copyWith(
              selection: TextSelection.collapsed(
                  offset: oldValue.text.indexOf(decimalChar!)));
        }
      }

      if (symbol.isNotEmpty && !newValue.text.startsWith("$symbol ")) {
        //handle ketika symbol kehapus
        return oldValue;
      }

      if (decimalDigits > 0 &&
          _countString(newValue.text, decimalChar!) >
              _countString(oldValue.text, decimalChar!)) {
        //handle hapus dan tambah decimal char
        return oldValue.copyWith(
            selection: TextSelection.collapsed(
                offset: oldValue.text.indexOf(decimalChar!) + 1));
      }
      if (oldValue.selection.baseOffset == oldValue.text.length &&
          (newValue.selection.baseOffset == oldValue.text.length + 1)) {
        //handle ketika cursor di akhir text kemudian ditambah huruf
        return oldValue;
      }

      if (_countString(newValue.text, groupChar!) <
          _countString(oldValue.text, groupChar!)) {
        //handle ketika group char di hapus
        return oldValue.copyWith(
            selection:
                TextSelection.collapsed(offset: newValue.selection.baseOffset));
      }

      if (newValue.text.contains("$decimalChar$decimalChar")) {
        //handle ketika group char lebih dari 1
        return oldValue.copyWith(
            selection: TextSelection.collapsed(
                offset: oldValue.text.indexOf(decimalChar!)));
      }
      if (_countString(newValue.text, decimalChar!) > 1) {
        //handle ketika decimal char lebih dari 1
        return oldValue;
      }

      // if (!RegExp(
      //         "^$symbol( ){0,1}[0-9$groupChar]{0,}[$decimalChar]{0,1}[0-9]{0,$decimalDigits}\$")
      //     .hasMatch(newText)) {
      //   //handle ketika ...
      //   return oldValue;

      // }

      // if (!RegExp(
      //         "^$symbol( ){0,1}[0-9$groupChar]{0,}\\$decimalChar{0,1}[0-9$groupChar]{0,}\$")
      //     .hasMatch(newText)) {
      //   //handle ketika ...
      //   return oldValue;
      //}
    }

    //2. clean, get value and reformat
    bool isReset = false;
    try {
      num newNumberValue = value(newText, needClean: true);
      if (newNumberValue == 0) {
        isReset = true;
      }
      newText = format(newNumberValue);
    } catch (e) {
      return oldValue;
    }

    //3. calculate text selection offset
    final beforeFormatLength = _countString(newValue.text, groupChar!);
    final afterFormatLength = _countString(newText, groupChar!);
    int newOffset = newValue.selection.baseOffset;
    if (afterFormatLength > beforeFormatLength) {
      newOffset += 1;
      if (symbol.isNotEmpty &&
          oldValue.selection.baseOffset == symbol.length + 1) {
        newOffset -= 1;
      }
    } else if (afterFormatLength < beforeFormatLength) {
      newOffset -= 1;
      if (symbol.isNotEmpty && newOffset == symbol.length) {
        newOffset += 1;
      }
    }

    if (isReset) {
      newOffset = symbol.isEmpty ? 1 : symbol.length + 2;
    }

    if (newText.length == oldValue.text.length &&
        oldValue.selection.baseOffset ==
            (symbol.isEmpty ? 1 : symbol.length + 2)) {
      newOffset = oldValue.selection.baseOffset;
    }

    if (newOffset > newText.length) {
      newOffset = newText.length;
    }
    return newValue.copyWith(
        text: newText, selection: TextSelection.collapsed(offset: newOffset));
  }

  int _countString(String source, String needle) {
    return needle.allMatches(source).length;
  }

  String _clean(String input) {
    var newText = input
        .replaceAll(groupChar!, '')
        .replaceAll(symbol, "")
        .replaceAll(" ", "")
        .replaceAll(decimalChar!, ".");
    if (newText.isEmpty) {
      newText = "0";
    }
    return newText;
  }

  num _convert(String input) {
    try {
      return double.parse(input);
    } catch (e) {
      return 0;
    }
  }

  num value(String input, {bool needClean = false}) {
    return _convert(needClean ? _clean(input) : input);
  }

  String reformat(String input, {bool needClean = false}) {
    try {
      var newNumberValue = value(input, needClean: needClean);
      return format(newNumberValue);
    } catch (e) {
      rethrow;
    }
  }

  String format(num input,
      {String? whenZero, String? whenNaN, String? whenInfinity}) {
    if (whenZero != null && input == 0.0) {
      return whenZero;
    }
    if (whenNaN != null && input.isNaN) {
      return whenNaN;
    }
    if (whenInfinity != null && input.isInfinite) {
      return whenInfinity;
    }
    var newText = numberFormat!.format(input);
    newText = newText
        .replaceAll(numberFormat!.symbols.DECIMAL_SEP, "/!")
        .replaceAll(numberFormat!.symbols.GROUP_SEP, groupChar!)
        .replaceAll("/!", decimalChar!);
    return newText;
  }

  void init() {
    if (numberFormat == null) {
      String baseFormat = '#,##0';
      if (symbol.isNotEmpty) {
        baseFormat = "$symbol $baseFormat";
      }
      if (decimalDigits > 0) {
        baseFormat = "$baseFormat.";
        baseFormat =
            baseFormat.padRight(baseFormat.length + decimalDigits, '0');
      }
      numberFormat = NumberFormat(baseFormat); //use system locale
    }

    groupChar ??= numberFormat!.symbols.GROUP_SEP;
    decimalChar ??= numberFormat!.symbols.DECIMAL_SEP;
  }
}
