import 'package:flutter/material.dart';

/// Owner-deck finish (#35): the reject-reason dialog for the customer
/// profile. It owns its [TextEditingController] and disposes it in its
/// own [State.dispose] — disposing the controller from the caller the
/// moment `showDialog` returns touches a TextField that is still built
/// while the dialog route animates out ("used after being disposed").
class CustomerRejectReasonDialog extends StatefulWidget {
  const CustomerRejectReasonDialog({
    super.key,
    required this.title,
    required this.hint,
    required this.requiredMessage,
    required this.confirmLabel,
    required this.cancelLabel,
  });

  final String title;
  final String hint;
  final String requiredMessage;
  final String confirmLabel;
  final String cancelLabel;

  @override
  State<CustomerRejectReasonDialog> createState() =>
      _CustomerRejectReasonDialogState();
}

class _CustomerRejectReasonDialogState
    extends State<CustomerRejectReasonDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: widget.hint,
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel),
        ),
        TextButton(
          onPressed: () {
            final value = _controller.text.trim();
            if (value.isEmpty) {
              setState(() => _error = widget.requiredMessage);
              return;
            }
            Navigator.of(context).pop(value);
          },
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
