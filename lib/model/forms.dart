sealed class Field<T> {
  T? value;
  final String name;
  final String? label;

  Field({required this.name, this.label});

  bool checkConstraints();

  Object? toJson();
}

class TextField extends Field<String> {
  final String? hint;

  TextField({required super.name, super.label, this.hint});

  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'type': 'text',
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
    'data': value,
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
