from django import forms
from .models import APIKey
from .encryption import encrypt_value


class APIKeyAdminForm(forms.ModelForm):
    """Admin form with password input for API key value."""

    key_value = forms.CharField(
        widget=forms.PasswordInput(render_value=True, attrs={
            'style': 'width: 100%; font-family: monospace;',
            'placeholder': 'Enter API key value',
            'autocomplete': 'off',
        }),
        required=False,
        label="Key Value",
        help_text="The plaintext API key. Leave blank to keep existing value when editing."
    )

    class Meta:
        model = APIKey
        fields = ['name', 'service_name', 'description', 'is_active']

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # For existing keys, update placeholder to indicate value exists
        if self.instance and self.instance.pk and self.instance.encrypted_value:
            self.fields['key_value'].widget.attrs['placeholder'] = 'Value is set (leave blank to keep)'

    def clean(self):
        cleaned_data = super().clean()
        key_value = cleaned_data.get('key_value')

        # Require value for new keys
        if not self.instance.pk and not key_value:
            raise forms.ValidationError({'key_value': 'API key value is required for new keys.'})

        return cleaned_data

    def save(self, commit=True):
        instance = super().save(commit=False)
        key_value = self.cleaned_data.get('key_value')

        # Only update encrypted value if a new value was provided
        if key_value:
            instance.encrypted_value = encrypt_value(key_value)

        if commit:
            instance.save()
        return instance
