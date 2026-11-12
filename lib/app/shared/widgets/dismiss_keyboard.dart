import 'package:flutter/material.dart';

/// Text fields already know their tap region. Override the touch default as
/// well as mouse behavior, without stealing taps from controls or other fields.
class DismissKeyboard extends StatelessWidget {
  const DismissKeyboard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Actions(
    actions: <Type, Action<Intent>>{
      EditableTextTapOutsideIntent:
          CallbackAction<EditableTextTapOutsideIntent>(
            onInvoke: (intent) {
              intent.focusNode.unfocus();
              return null;
            },
          ),
    },
    child: child,
  );
}
