sealed class Field<T> {
  T? value;
  final String name;
  final String? label;

  Field({required this.name, this.label});

  bool checkConstraints();

  static Field fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final name = json['name'] as String;
    final label = json['label'] as String?;
    final data = json['data'];

    return switch (type) {
      'text' => TextField(
        name: name,
        label: label,
        hint: json['hint'] as String?,
      )..value = data as String?,
      'checkbox' => CheckboxField(
        name: name,
        label: label,
      )..value = data as bool?,
      'dropdown' => DropdownField(
        name: name,
        label: label,
        options: json['options'] as List<String>,
      )..value = data as String?,
      String() => throw UnimplementedError(),
    };
  }

  Object? toJson();
}

class TextField extends Field<String> {
  final String? hint;

  TextField({required super.name, super.label, this.hint});

  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'type': 'text',
    'label': label,
    'hint': hint,
    'data': value,
  };

  @override
  bool checkConstraints() => true;
}

class CheckboxField extends Field<bool> {
  @override
  bool get value => super.value ?? false;

  CheckboxField({required super.name, super.label});

  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'type': 'checkbox',
    'label': label,
    'data': value,
  };

  @override
  bool checkConstraints() => true;
}

class DropdownField extends Field<String> {
  final List<String> options;

  DropdownField({required super.name, super.label, required this.options});

  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'type': 'dropdown',
    'label': label,
    'data': value,
    'options': options,
  };

  @override
  bool checkConstraints() => true;
}

// TODO: Add more field types here
// case forms.TextAreaField f:
// case forms.SelectField f:
// case forms.RadioField f:
// case forms.FileField f:
// case forms.ImageField f:
