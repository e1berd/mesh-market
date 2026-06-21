import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';

class RemoteCodeField extends StatefulWidget {
  const RemoteCodeField({
    super.key,
    required this.hint,
    required this.action,
    required this.validator,
    required this.onSubmit,
  });

  final String hint;
  final String action;
  final String? Function(String code) validator;
  final Future<void> Function(String code) onSubmit;

  @override
  State<RemoteCodeField> createState() => _RemoteCodeFieldState();
}

class _RemoteCodeFieldState extends State<RemoteCodeField> {
  final _controller = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final code = _controller.text.trim();
    final error = widget.validator(code);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    await widget.onSubmit(code);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(hintText: widget.hint, errorText: _error),
          ),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const ExpressiveLoadingIndicator(
                    constraints: BoxConstraints.tightFor(width: 20, height: 20),
                  )
                : Text(widget.action),
          ),
        ),
      ],
    );
  }
}
