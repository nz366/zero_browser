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
    Provider.of<TabProvider>(
      context,
      listen: false,
    ).submitForm(widget.page, widget.formSection);
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
