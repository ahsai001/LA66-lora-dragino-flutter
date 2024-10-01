import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final void Function()? onPressed;
  final String? label;
  final ButtonLayerBuilder? backgroundBuilder;
  final Color? foregroundColor;
  final Color? backgroundColor;
  const CustomButton(
      {super.key,
      this.onPressed,
      this.label,
      this.backgroundBuilder,
      this.foregroundColor,
      this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        backgroundBuilder: backgroundColor != null
            ? null
            : backgroundBuilder ??
                (context, states, child) {
                  if (states.contains(WidgetState.pressed)) {
                    return Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red, Colors.white, Colors.red],
                          ),
                        ),
                        child: child);
                  }
                  return Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green, Colors.white, Colors.green],
                        ),
                      ),
                      child: child);
                },
      ),
      child: Text(
        label ?? "",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
