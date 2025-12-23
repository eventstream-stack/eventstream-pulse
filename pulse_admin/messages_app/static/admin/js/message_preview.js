/**
 * Pulse Message Live Preview
 * Real-time preview of message styling in phone mockup
 */

(function() {
    'use strict';

    // Wait for DOM ready
    document.addEventListener('DOMContentLoaded', function() {
        // Only run on PulseMessage change form
        if (!document.querySelector('#pulsemessage_form')) {
            return;
        }

        initializePreview();
    });

    function initializePreview() {
        // Get form fields
        const fields = {
            title: document.querySelector('#id_title'),
            body: document.querySelector('#id_body'),
            imageUrl: document.querySelector('#id_image_url'),
            ctaText: document.querySelector('#id_cta_text'),
            ctaAction: document.querySelector('#id_cta_action'),
            messageType: document.querySelector('#id_message_type'),
            bgColor: document.querySelector('#id_background_color'),
            titleColor: document.querySelector('#id_title_color'),
            bodyColor: document.querySelector('#id_body_color'),
            buttonColor: document.querySelector('#id_button_color')
        };

        // Get preview elements
        const preview = {
            title: document.querySelector('#preview-title'),
            body: document.querySelector('#preview-body'),
            button: document.querySelector('#preview-button'),
            message: document.querySelector('#preview-message'),
            image: document.querySelector('#preview-image'),
            typeIndicator: document.querySelector('.preview-type-indicator')
        };

        // Exit if preview panel doesn't exist yet
        if (!preview.message) {
            return;
        }

        // Add color picker enhancements to color fields
        enhanceColorFields(fields);

        // Set up event listeners
        Object.values(fields).forEach(field => {
            if (field) {
                field.addEventListener('input', () => updatePreview(fields, preview));
                field.addEventListener('change', () => updatePreview(fields, preview));
            }
        });

        // Initial preview update
        updatePreview(fields, preview);
    }

    function enhanceColorFields(fields) {
        const colorFields = [
            { field: fields.bgColor, defaultColor: '#FFFFFF' },
            { field: fields.titleColor, defaultColor: '#1a1a1a' },
            { field: fields.bodyColor, defaultColor: '#666666' },
            { field: fields.buttonColor, defaultColor: '#007AFF' }
        ];

        colorFields.forEach(({ field, defaultColor }) => {
            if (!field) return;

            const fieldBox = field.closest('.fieldBox');
            if (!fieldBox) return;

            // Skip if already enhanced
            if (field.dataset.colorEnhanced === 'true') return;
            field.dataset.colorEnhanced = 'true';

            // CLEANUP: Remove any wrapper divs from old code
            fieldBox.querySelectorAll('.color-picker-wrapper').forEach(wrapper => {
                while (wrapper.firstChild) {
                    wrapper.parentNode.insertBefore(wrapper.firstChild, wrapper);
                }
                wrapper.remove();
            });

            // CLEANUP: Remove any existing color inputs
            fieldBox.querySelectorAll('input[type="color"]').forEach(el => el.remove());

            // Create fresh color input
            const colorInput = document.createElement('input');
            colorInput.type = 'color';
            colorInput.className = 'color-swatch';
            colorInput.value = field.value || defaultColor;

            // Sync bidirectionally
            colorInput.addEventListener('input', function() {
                field.value = this.value;
                field.dispatchEvent(new Event('input', { bubbles: true }));
            });

            field.addEventListener('input', function() {
                if (/^#[0-9A-Fa-f]{6}$/i.test(this.value)) {
                    colorInput.value = this.value;
                }
            });

            // Insert BEFORE the text field
            field.insertAdjacentElement('beforebegin', colorInput);
        });
    }

    function updatePreview(fields, preview) {
        // Update text content
        if (preview.title) {
            preview.title.textContent = fields.title?.value || 'Your Title Here';
        }
        if (preview.body) {
            preview.body.textContent = fields.body?.value || 'Your message body text will appear here...';
        }
        if (preview.button) {
            const ctaText = fields.ctaText?.value;
            preview.button.textContent = ctaText || '';
            preview.button.style.display = ctaText ? 'block' : 'none';
        }

        // Update colors
        if (fields.bgColor?.value && preview.message) {
            preview.message.style.backgroundColor = fields.bgColor.value;
        } else if (preview.message) {
            preview.message.style.backgroundColor = '#FFFFFF';
        }

        if (fields.titleColor?.value && preview.title) {
            preview.title.style.color = fields.titleColor.value;
        } else if (preview.title) {
            preview.title.style.color = '#1a1a1a';
        }

        if (fields.bodyColor?.value && preview.body) {
            preview.body.style.color = fields.bodyColor.value;
        } else if (preview.body) {
            preview.body.style.color = '#666666';
        }

        if (fields.buttonColor?.value && preview.button) {
            preview.button.style.backgroundColor = fields.buttonColor.value;
            // Calculate contrasting text color
            const textColor = getContrastColor(fields.buttonColor.value);
            preview.button.style.color = textColor;
        } else if (preview.button) {
            preview.button.style.backgroundColor = '#007AFF';
            preview.button.style.color = '#FFFFFF';
        }

        // Update image
        if (preview.image) {
            if (fields.imageUrl?.value) {
                preview.image.innerHTML = `<img src="${escapeHtml(fields.imageUrl.value)}" alt="Preview" onerror="this.style.display='none'">`;
            } else {
                preview.image.innerHTML = '';
            }
        }

        // Update message type indicator
        if (preview.typeIndicator && fields.messageType) {
            const typeMap = {
                'modal': 'Modal',
                'banner': 'Banner',
                'bottom_sheet': 'Bottom Sheet',
                'full_screen': 'Full Screen'
            };
            preview.typeIndicator.textContent = typeMap[fields.messageType.value] || 'Modal';
        }
    }

    function isValidHexColor(color) {
        return /^#[0-9A-Fa-f]{6}$/.test(color);
    }

    function getContrastColor(hexColor) {
        // Remove # if present
        const hex = hexColor.replace('#', '');

        // Convert to RGB
        const r = parseInt(hex.substr(0, 2), 16);
        const g = parseInt(hex.substr(2, 2), 16);
        const b = parseInt(hex.substr(4, 2), 16);

        // Calculate luminance
        const luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;

        return luminance > 0.5 ? '#000000' : '#FFFFFF';
    }

    function escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
})();
