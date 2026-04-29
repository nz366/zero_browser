import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:zero_browser/model/data.dart' as forms;
import 'package:zero_browser/providers/history_provider.dart';

class FormSectionWidget extends StatefulWidget {
  final forms.FormSection formSection;
  final forms.PageData page;

  const FormSectionWidget({
    super.key,
    required this.formSection,
    required this.page,
  });

  @override
  State<FormSectionWidget> createState() => _FormSectionState();
}

class _FormSectionState extends State<FormSectionWidget> {
  // Store keys dynamically
  final Map<String, FormKey> _fieldKeys = {};

  @override
  void initState() {
    super.initState();
    _initializeKeys();
  }

  void _initializeKeys() {
    _fieldKeys.clear();

    for (var field in widget.formSection.fields.values) {
      FormKey key;
      switch (field) {
        case forms.TextField _:
          key = FormKey<String>(field.name);
        case forms.CheckboxField _:
          key = FormKey<bool>(field.name);
        default:
          key = FormKey(field.name);
      }
      _fieldKeys[field.name] = key;
    }
  }

  @override
  Widget build(BuildContext context) {
    // return FormExample4(formSection: widget.formSection, page: widget.page);
    return SizedBox(
      width: 480,
      child: Form(
        onSubmit: onSubmit,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FormTableLayout(
              rows: widget.formSection.fields.entries.map((entry) {
                return _buildFormField(entry.value);
              }).toList(),
            ),
            const Gap(24),
            const SubmitButton(child: Text('Submit')),
          ],
        ),
      ),
    );
  }

  void onSubmit(context, Map<FormKey, Object?> _) {
    final json = jsonEncode(widget.formSection.toJson());

    Provider.of<TabProvider>(
      context,
      listen: false,
    ).submitForm(widget.page, json);

    // showDialog(
    //   context: context,
    //   builder: (context) => AlertDialog(
    //     title: const Text('Submitted Form Values'),
    //     content: SingleChildScrollView(
    //       child: Column(
    //         mainAxisSize: MainAxisSize.min,
    //         crossAxisAlignment: CrossAxisAlignment.start,
    //         children: [
    //           const Text('Raw Values Map:'),
    //           const SizedBox(height: 8),
    //           Text(json, style: const TextStyle(fontFamily: 'monospace')),
    //           const Divider(),
    //           const Text('Individual Fields:'),
    //           ...widget.formSection.fields.map((field) {
    //             final value = values[_fieldKeys[field.name]];
    //             return Text('${field.label ?? field.name}: $value');
    //           }),
    //         ],
    //       ),
    //     ),
    //     actions: [
    //       PrimaryButton(
    //         onPressed: () => Navigator.of(context).pop(),
    //         child: const Text('Close'),
    //       ),
    //     ],
    //   ),
    // );
  }

  FormField _buildFormField(forms.Field field) {
    final key = _fieldKeys[field.name]!;

    switch (field) {
      case forms.TextField f:
        return FormField<String>(
          key: key as FormKey<String>,
          label: Text(f.label ?? f.name.capitalize()),
          hint: f.hint != null ? Text(f.hint!) : null,
          validator: const LengthValidator(
            min: 1,
          ), // You can make this dynamic too
          showErrors: const {
            FormValidationMode.changed,
            FormValidationMode.submitted,
          },
          child: TextField(
            onChanged: (value) {
              f.value = value;
            },
          ),
        );

      case forms.CheckboxField f:
        return FormField<bool>(
          key: key as FormKey<bool>,
          label: Text(f.label ?? f.name.capitalize()),
          validator: null,
          showErrors: const {
            FormValidationMode.changed,
            FormValidationMode.submitted,
          },
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Checkbox(
              // Initial value from model
              state: f.value ? CheckboxState.checked : CheckboxState.unchecked,
              onChanged: (value) {
                field.value = value == CheckboxState.checked;
              },
            ),
          ),
        );

      // TODO: Add more field types here
      // case forms.TextAreaField f:
      // case forms.SelectField f:
      // case forms.RadioField f:
      // case forms.FileField f:
      // case forms.ImageField f:
    }
  }
}

// Optional helper
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

/// Demonstrates using the correct typed FormKey for each widget.
///
/// Every form-capable widget reports a specific value type. The FormKey's
/// generic type must match — use the typed alias (TextFieldKey, CheckboxKey,
/// DatePickerKey, SwitchKey, etc.) instead of the generic FormKey.
class FormExample4 extends StatefulWidget {
  final forms.FormSection formSection;
  final forms.PageData page;
  const FormExample4({
    super.key,
    required this.formSection,
    required this.page,
  });

  @override
  State<FormExample4> createState() => _FormExample4State();
}

class _FormExample4State extends State<FormExample4> {
  // ✅ Each key uses the correct typed alias for the widget it pairs with.
  //    Always use const to preserve key identity across rebuilds.
  final _nameKey = const TextFieldKey('name'); // TextField → String
  final _agreeKey = const CheckboxKey('agree'); // Checkbox → CheckboxState
  final _birthdayKey = const DatePickerKey('birthday'); // DatePicker → DateTime
  final _notifyKey = const SwitchKey('notify'); // Switch → bool

  CheckboxState _agreeState = CheckboxState.unchecked;
  bool _notifyState = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 480,
      child: Form(
        onSubmit: (context, values) {
          // Read values with full type safety — no casting needed.
          String? name = _nameKey[values];
          CheckboxState? agree = _agreeKey[values];
          DateTime? birthday = _birthdayKey[values];
          bool? notify = _notifyKey[values];
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Form Values'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name: $name'),
                    Text('Agree: $agree'),
                    Text('Birthday: $birthday'),
                    Text('Notify: $notify'),
                  ],
                ),
                actions: [
                  PrimaryButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              );
            },
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FormField<String>(
                  key: _nameKey,
                  label: const Text('Name'),
                  validator: const LengthValidator(min: 2),
                  child: const TextField(initialValue: 'Jane Doe'),
                ),
                FormInline<CheckboxState>(
                  key: _agreeKey,
                  label: const Text('I agree to the terms'),
                  validator: const CompareTo.equal(
                    CheckboxState.checked,
                    message: 'You must agree',
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Checkbox(
                      state: _agreeState,
                      onChanged: (value) {
                        setState(() {
                          _agreeState = value;
                        });
                      },
                    ),
                  ),
                ),
                FormField<DateTime>(
                  key: _birthdayKey,
                  label: const Text('Birthday'),
                  validator: const NonNullValidator(
                    message: 'Please select a date',
                  ),
                  child: const ControlledDatePicker(),
                ),
                FormInline<bool>(
                  key: _notifyKey,
                  label: const Text('Email notifications'),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Switch(
                      value: _notifyState,
                      onChanged: (value) {
                        setState(() {
                          _notifyState = value;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ).gap(24),
            const Gap(24),
            FormErrorBuilder(
              builder: (context, errors, child) {
                return PrimaryButton(
                  onPressed: errors.isEmpty ? () => context.submitForm() : null,
                  child: const Text('Submit'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
