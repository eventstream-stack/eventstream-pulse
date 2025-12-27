/**
 * Pulse Message Live Preview
 * Real-time preview of message styling in phone mockup
 */

(function() {
    'use strict';

    // Wait for DOM ready
    document.addEventListener('DOMContentLoaded', function() {
        // Only run on PulseMessage change form (check for title field as indicator)
        if (!document.querySelector('#id_title')) {
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
            buttonColor: document.querySelector('#id_button_color'),
            buttonTextColor: document.querySelector('#id_button_text_color')
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

        // Skip preview updates if panel doesn't exist
        if (!preview.message) {
            console.log('Preview panel not found - skipping preview initialization');
            return;
        }

        // Set up event listeners on all form fields
        Object.values(fields).forEach(field => {
            if (field) {
                field.addEventListener('input', () => updatePreview(fields, preview));
                field.addEventListener('change', () => updatePreview(fields, preview));
            }
        });

        // Also listen for color picker changes (they have _picker suffix)
        ['background_color', 'title_color', 'body_color', 'button_color', 'button_text_color'].forEach(fieldName => {
            const picker = document.querySelector('#id_' + fieldName + '_picker');
            if (picker) {
                picker.addEventListener('input', () => updatePreview(fields, preview));
                picker.addEventListener('change', () => updatePreview(fields, preview));
            }
        });

        // Initial preview update
        updatePreview(fields, preview);

        console.log('Preview initialized successfully');
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

        // Update background color
        if (preview.message) {
            const bgColor = fields.bgColor?.value;
            preview.message.style.backgroundColor = bgColor || '#FFFFFF';
        }

        // Update title color
        if (preview.title) {
            const titleColor = fields.titleColor?.value;
            preview.title.style.color = titleColor || '#1a1a1a';
        }

        // Update body color - auto-calculate if not set
        if (preview.body) {
            const bodyColor = fields.bodyColor?.value;
            const bgColor = fields.bgColor?.value || '#FFFFFF';
            if (bodyColor) {
                preview.body.style.color = bodyColor;
            } else {
                // Auto-calculate readable body color based on background
                const contrastBase = getContrastColor(bgColor);
                // Use slightly muted version for body (not pure black/white)
                preview.body.style.color = contrastBase === '#000000' ? '#444444' : '#CCCCCC';
            }
        }

        // Update button colors
        if (preview.button) {
            const buttonBgColor = fields.buttonColor?.value;
            const buttonTxtColor = fields.buttonTextColor?.value;

            preview.button.style.backgroundColor = buttonBgColor || '#007AFF';

            // Use explicit button text color if set, otherwise calculate contrast
            if (buttonTxtColor) {
                preview.button.style.color = buttonTxtColor;
            } else if (buttonBgColor) {
                preview.button.style.color = getContrastColor(buttonBgColor);
            } else {
                preview.button.style.color = '#FFFFFF';
            }
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

    function getContrastColor(hexColor) {
        if (!hexColor || hexColor.length < 7) return '#FFFFFF';

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
