from django import forms
from .models import PulseMessage


class ColorWidget(forms.TextInput):
    """Custom widget that shows both a color picker and text input."""
    template_name = 'admin/widgets/color_input.html'

    def __init__(self, attrs=None):
        default_attrs = {'class': 'color-text-input', 'style': 'width: 100px;'}
        if attrs:
            default_attrs.update(attrs)
        super().__init__(attrs=default_attrs)


class PulseMessageAdminForm(forms.ModelForm):
    class Meta:
        model = PulseMessage
        fields = '__all__'
        widgets = {
            'background_color': ColorWidget(),
            'title_color': ColorWidget(),
            'body_color': ColorWidget(),
            'button_color': ColorWidget(),
            'button_text_color': ColorWidget(),
        }
