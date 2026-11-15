# Translating ForumREXAR

The whole forum interface — pages, emails, chat, notices and the control panel — is translated with **one XML file per language**. The Arabic text is the key of each phrase, so there are no numbers or codes to learn. Any phrase you leave untranslated simply shows in Arabic.

When the language is a left-to-right one, the forum flips its whole layout from right-to-left automatically.

## Get started

1. Download the blank template from your forum at `/translation-template.xml` (or from the control panel). It holds only the interface phrases, with no data from any forum. You can also start from the complete English pack: [../languages/en.xml](../languages/en.xml).
2. Edit the file's header: the language code, its name, its direction, the version and your name.
3. Write the translation inside `<text>` next to each `<ar>`, and leave `<ar>` as it is.
4. Try it on your forum: **Control panel → Languages → Import a new language**.
5. Share it with others on https://forum.rexar.net, or send it as a pull request to the [languages](../languages) folder of this repository.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<language code="fr" name="Français" dir="ltr" version="1.0" author="Your name">
  <phrase>
    <ar>ابحث</ar>
    <text>Rechercher</text>
  </phrase>
  <phrase>
    <ar>منذ %d دقيقة</ar>
    <text>il y a %d min</text>
  </phrase>
</language>
```

| Attribute | What it needs |
| --- | --- |
| `code` | The language code in lowercase English letters, like `fr` or `pt-br` (up to 12 characters) |
| `name` | The language's own name, like `Français` |
| `dir` | `ltr` for left-to-right languages, `rtl` for right-to-left ones such as Persian and Urdu |
| `version` | Like `1.0` or `1.0.0`; raise it with every update |
| `author` | The translator's name, shown as "Translation: name" in the control panel |

## Rules

- Keep the value markers `%s` and `%d` in the same number and order. A translation that changes them is ignored and the Arabic phrase shows.
- Do not put HTML code or links in a translation; a file that has them is refused.
- A phrase ending with `#` and a word, like `من#sender`, is the same word used in a different place, so translate it for that place.
- A partial translation is fine; administrators see how much is translated before using it.
- A file can be up to 4 MB, with up to 20,000 phrases.
- When a new forum version comes out, download the template again to see the new phrases.

## Choosing the language

- **The director** sets the forum's language in **Control panel → Languages**.
- When the director allows it, **visitors and members** can pick their own language from the side menu. A member's choice is saved with their membership; emails and system notices follow it too.
