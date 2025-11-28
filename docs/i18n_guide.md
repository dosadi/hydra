# Internationalization Guide

This guide covers internationalization (i18n) and localization (l10n) support for Hydra, preparing the codebase for multi-language user interfaces and global adoption.

## Overview

Internationalization is the process of designing software to support multiple languages and cultural contexts. Localization adapts the software for specific locales. This guide provides the framework for adding i18n support to Hydra's user interfaces.

## Current State

Hydra currently has minimal UI text and is primarily command-line and programmatic. However, future versions may include:

- GUI configuration tools
- Error messages and diagnostics
- Documentation and help systems
- User-facing status displays

## i18n Architecture

### Message Catalog System

#### GNU gettext Framework
Hydra will use GNU gettext for message internationalization:

```c
// Include gettext header
#include <libintl.h>
#include <locale.h>
#define _(string) gettext(string)
#define N_(string) string  // For message extraction

// Initialize locale support
void init_internationalization(void) {
    setlocale(LC_ALL, "");
    bindtextdomain("hydra", LOCALEDIR);
    textdomain("hydra");
}

// Usage in code
printf(_("Camera position updated to (%d, %d, %d)\n"),
       cam.x, cam.y, cam.z);
```

#### Message File Structure
```
po/
├── LINGUAS              # List of supported languages
├── POTFILES.in          # Files containing translatable strings
├── hydra.pot           # Template file (Portable Object Template)
├── de.po               # German translations
├── fr.po               # French translations
├── ja.po               # Japanese translations
└── zh_CN.po            # Chinese (Simplified) translations
```

### Build System Integration

#### Autotools Integration
```makefile
# Makefile.am additions
SUBDIRS = po

# Generate .pot file
hydra.pot: $(SOURCES)
    xgettext --keyword=_ --keyword=N_ --language=C \
             --add-comments --sort-output \
             -o $@ $(SOURCES)

# Install locales
install-data-local:
    for lang in $(LINGUAS); do \
        $(mkinstalldirs) $(DESTDIR)$(localedir)/$$lang/LC_MESSAGES; \
        $(INSTALL_DATA) po/$$lang.gmo \
                      $(DESTDIR)$(localedir)/$$lang/LC_MESSAGES/hydra.mo; \
    done
```

#### CMake Integration
```cmake
# CMakeLists.txt additions
find_package(Gettext REQUIRED)
find_package(Intl REQUIRED)

# Generate .pot file
gettext_create_pot(hydra.pot
    SOURCES ${SOURCES}
    POTFILES_SOURCE ${POTFILES}
)

# Create translations
foreach(lang ${LINGUAS})
    gettext_create_translations(hydra.pot
        LANGUAGES ${lang}
        ALL
    )
endforeach()
```

## String Extraction

### Source Code Preparation

#### Marking Translatable Strings
```c
// Good: Marked for translation
printf(_("Error: Invalid camera position\n"));

// Bad: Not marked for translation
printf("Error: Invalid camera position\n");

// Context-specific translations
printf(_("Camera: %s"), _("Position"));
printf(_("Light: %s"), _("Position"));

// Plural forms
printf(ngettext("Found %d voxel", "Found %d voxels", count), count);
```

#### Avoiding Common Pitfalls
```c
// Bad: Concatenated strings
printf(_("Error: ") + message);

// Good: Complete sentences
printf(_("Error: %s"), message);

// Bad: Variables in translatable strings
printf(_("Position: %d, %d, %d"), x, y, z);

// Good: Format strings only
_("Position: %d, %d, %d")
```

### Documentation Strings

#### Man Pages and Help Text
```bash
# Extract from help text
cat << EOF
_('Usage: hydra_viewer [OPTIONS] [FILE]\n')
_('Display 3D voxel graphics using Hydra FPGA accelerator\n')
_('\n')
_('Options:\n')
_('  -h, --help          Show this help message\n')
_('  -v, --version       Show version information\n')
EOF
```

#### Error Messages
```c
// Structured error messages
const char *error_messages[] = {
    N_("Success"),
    N_("Invalid parameter"),
    N_("Device not found"),
    N_("Permission denied"),
    N_("Out of memory"),
    // ...
};

fprintf(stderr, "%s: %s\n", _("hydra"), _(error_messages[error_code]));
```

## Translation Workflow

### For Developers

#### 1. Mark Strings for Translation
```c
// Add _() wrapper to user-visible strings
printf(_("Initializing Hydra graphics system...\n"));
```

#### 2. Update Message Template
```bash
# Regenerate .pot file
make update-po

# Or manually
xgettext --keyword=_ --keyword=N_ --language=C \
         --add-comments --sort-output \
         -o po/hydra.pot $(SOURCES)
```

#### 3. Commit Changes
```bash
git add po/hydra.pot
git commit -m "i18n: Update message template for new strings"
```

### For Translators

#### 1. Initialize Translation File
```bash
# Create new translation
msginit --locale=de --input=po/hydra.pot --output=po/de.po

# Or update existing translation
msgmerge --update po/de.po po/hydra.pot
```

#### 2. Edit Translation File
```po
# German translation example
msgid "Camera position updated"
msgstr "Kameraposition aktualisiert"

msgid "Error: Invalid parameter"
msgstr "Fehler: Ungültiger Parameter"

msgid "Found %d voxel"
msgid_plural "Found %d voxels"
msgstr[0] "%d Voxel gefunden"
msgstr[1] "%d Voxels gefunden"
```

#### 3. Compile Translation
```bash
# Generate binary .mo file
msgfmt po/de.po -o po/de.gmo

# Install for testing
sudo cp po/de.gmo /usr/share/locale/de/LC_MESSAGES/hydra.mo
```

## Cultural Adaptation

### Number Formatting
```c
// Locale-aware number formatting
#include <locale.h>
#include <monetary.h>

void print_memory_usage(size_t bytes) {
    char buffer[128];
    strfmon(buffer, sizeof(buffer), _("%n bytes"), (double)bytes);
    printf(_("Memory used: %s\n"), buffer);
}
```

### Date and Time
```c
// Localized date/time formatting
#include <time.h>

void print_timestamp(time_t timestamp) {
    char buffer[128];
    struct tm *tm = localtime(&timestamp);
    strftime(buffer, sizeof(buffer), _("%c"), tm);
    printf(_("Build time: %s\n"), buffer);
}
```

### Units and Measurements
```c
// Unit localization
const char *length_units[] = {
    N_("pixels"),    // en
    N_("pixels"),    // de (same)
    N_("píxeles"),   // es
    N_("pixels"),    // fr (same)
};

printf(_("%d %s"), width, _(length_units[locale_index]));
```

## Testing Internationalization

### Runtime Testing

#### Locale Testing
```bash
# Test different locales
export LANG=de_DE.UTF-8
./hydra_viewer --help

export LANG=fr_FR.UTF-8
./hydra_viewer --help

export LANG=ja_JP.UTF-8
./hydra_viewer --help
```

#### Fallback Testing
```bash
# Test missing translations
export LANG=xx_XX
./hydra_viewer --help  # Should show English fallback
```

### Build Testing

#### Translation Completeness
```bash
# Check for untranslated strings
msgfmt --check --verbose po/de.po

# Generate completeness report
for po in po/*.po; do
    echo "$(basename $po): $(msgfmt --statistics $po 2>&1)"
done
```

#### Integration Testing
```bash
# Test with different locales in CI
make test-i18n

# Validate message formatting
make test-locale
```

## Character Encoding

### UTF-8 Support
```c
// Ensure UTF-8 support
setlocale(LC_ALL, "");
bind_textdomain_codeset("hydra", "UTF-8");

// Handle Unicode strings
const char *unicode_messages[] = {
    N_("Français"),      // French
    N_("Deutsch"),       // German
    N_("日本語"),        // Japanese
    N_("Español"),       // Spanish
    N_("Русский"),       // Russian
};
```

### Encoding Detection
```c
// Detect system encoding
const char *encoding = nl_langinfo(CODESET);
if (strcmp(encoding, "UTF-8") != 0) {
    fprintf(stderr, _("Warning: System encoding is %s, not UTF-8\n"), encoding);
}
```

## Plural Forms

### Complex Plural Rules
```c
// Handle different plural forms
const char *voxel_messages[] = {
    N_("No voxels found"),           // 0
    N_("One voxel found"),           // 1
    N_("Two voxels found"),          // 2
    N_("Few voxels found"),          // 3-10 (some languages)
    N_("Many voxels found"),         // 11+ (some languages)
};

// Use ngettext for plurals
printf(ngettext("%d voxel found", "%d voxels found", count), count);
```

### Language-Specific Rules
```po
# Arabic (complex plural rules)
msgid "%d file"
msgid_plural "%d files"
msgstr[0] "لا توجد ملفات"
msgstr[1] "ملف واحد"
msgstr[2] "ملفان"
msgstr[3] "%d ملفات"
msgstr[4] "%d ملف"
msgstr[5] "%d ملف"
```

## Tool Integration

### IDE Support

#### Emacs
```elisp
;; po-mode for editing .po files
(require 'po-mode)
(add-to-list 'auto-mode-alist '("\\.po\\'" . po-mode))
```

#### Vim
```vim
" PO file editing support
autocmd BufRead,BufNewFile *.po set filetype=po
autocmd FileType po set spell
```

### Version Control

#### Git Configuration
```bash
# Ignore generated files
echo "*.mo" >> .gitignore
echo "*.gmo" >> .gitignore

# Track source files
git add po/*.po
git add po/hydra.pot
```

#### Translation Branches
```bash
# Create translation branch
git checkout -b i18n-updates

# Update translations
make update-po
git add po/
git commit -m "i18n: Update translations for v0.0.8"
```

## Quality Assurance

### Translation Quality

#### Consistency Checks
```bash
# Check for inconsistent translations
pocheck --inconsistent po/*.po

# Validate format strings
pocheck --printf po/*.po
```

#### Style Guidelines
- Use consistent terminology
- Maintain technical accuracy
- Follow locale-specific conventions
- Test in context of application

### Cultural Review
- Review translations with native speakers
- Test date/time/currency formatting
- Verify iconography and symbols
- Check text expansion/contraction

## Future Enhancements

### Advanced Features
- **Right-to-Left (RTL) Support:** For Arabic/Hebrew interfaces
- **Font Fallback:** Automatic font selection for missing glyphs
- **Dynamic Translation:** Runtime language switching
- **Translation Memory:** Reuse previous translations

### Integration Points
- **Qt Linguist:** For GUI application translations
- **Web Interface:** JavaScript i18n frameworks
- **Mobile Apps:** Platform-specific localization
- **Documentation:** Sphinx i18n for docs

## Resources

### Tools and Libraries
- **GNU gettext:** https://www.gnu.org/software/gettext/
- **intltool:** https://freedesktop.org/wiki/Software/intltool/
- **po-mode:** Emacs PO file editing
- **Gtranslator:** GNOME translation editor

### Documentation
- **GNU gettext Manual:** https://www.gnu.org/software/gettext/manual/
- **Locale Names:** https://www.localeplanet.com/
- **Unicode CLDR:** https://cldr.unicode.org/
- **W3C i18n:** https://www.w3.org/International/

### Communities
- **Translation Project:** https://translationproject.org/
- **GNOME i18n:** https://wiki.gnome.org/TranslationProject
- **KDE i18n:** https://l10n.kde.org/
- **Fedora i18n:** https://fedoraproject.org/wiki/I18N

---

**Document Version:** 1.0
**Last Updated:** 2025-11-28
**Status:** Framework prepared for future UI development
**Next Steps:** Implement when GUI components are added