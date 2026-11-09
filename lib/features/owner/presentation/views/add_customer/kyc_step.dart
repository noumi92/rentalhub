import 'package:flutter/material.dart';

/// Base [State] for a wizard step. The shell advances only when the
/// current step's [validate] passes. It may be async — step 1 runs
/// the blacklist check there, so the shell awaits it and shows the
/// Next button as loading while it runs.
abstract class KycStepState<T extends StatefulWidget> extends State<T> {
  Future<bool> validate();
}
