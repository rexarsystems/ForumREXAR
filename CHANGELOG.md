# Changelog

## 2.0 update (November 2026)

- **Phone notifications (Web Push):** members turn them on per device in their data page and choose the kinds (private messages, replies in followed topics, mentions, quotes, likes). They arrive even with the forum closed and open the right page when tapped. Notifications are encrypted for each device and signed with the forum's own key, made automatically on first start in the data folder and kept in the control-panel backup. The director can turn the feature off in the settings. On iPhone and iPad, members add the forum to the home screen first (iOS 16.4 or later); the forum needs https.
- **Dark mode is saved in the member's account,** so it comes back after logging in again, on any device. Link pills, link cards and quotes inside posts with their own colours now show correctly in dark mode.
- **Abjel** font added to the post fonts (SIL Open Font License, by Obaid), and TTF/OTF fonts are now sent compressed.

- **Fast Arabic-aware search:** posts are kept in a full-text index (SQLite FTS5) that ignores diacritics and hamza forms and finds words with or without the article ("ال", "وال", "بال"...). Searching one million posts went from about 2 seconds to 50 ms. The index is built once at the first start after the update and follows every new, edited or deleted post by itself.
- **Link cards:** a link written alone on its line shows as a card with the page picture, site, title and description; GitHub repositories get their own card. Pages are read once in the background (http/https only, public addresses only, size and time limits) and saved, so nobody waits. A switch in the settings turns cards off.
- **Links:** web addresses written as plain text are now clickable, and links to other sites open in a new tab.
- **Ads for guests only:** a new audience shows an advert to visitors who are not logged in.
- **Member card:** the trace box shows the flag of the IP country next to the masked IP and opens the connection log.
- A member who did not choose a country no longer shows a flag (it used to fall back to the Saudi flag).
- **Dark mode** in deep navy colours, from a moon button in the member card, on computers and phones. Posts that set their own colours keep the contrast their writer chose, and pictures keep their real colours.
- **Faster big forums:** member lookups use an index, a topic page reads only the posts it shows, and the active topics page lists the latest topics (as many as set in the control panel). Measured with one million posts: a 20,000-reply topic opens in 80 ms instead of 21 seconds.
- **Lower memory use** and a compact data file.
- English interface: staff descriptions, the busiest-time line and the default chat rooms are now translated.

- **Drafts:** what members type in a new topic, the quick reply, a topic or reply edit, or a private message is saved in their browser 1.5 seconds after they stop typing. Coming back offers to restore or ignore it. Drafts last 7 days, at most 20 are kept, and they are deleted once the text is posted or when the member logs out.
- **Leave-page confirmation** when a page has unsent text.
- **Connection log** and **login-attempts log** in each member's data page, with masked IP addresses and the country. Lines older than 60 days are deleted automatically.

## 2.0

- **Layout choice:** members can show the home page forums as the classic list or as boxes, on computers and phones.
- **Forum options menu** on each forum box: its supervisor and deputy, copy the forum link, your topics in the forum, and the archive.
- **Posts in an embedded SQLite database:** much lower memory use and fast start-up on large forums; existing data moves over automatically.
- **Deleted items:** delete and restore topics and replies, with a trash page for the director.
- **Ads:** an advert in the header (text or image) with a link, an end date and an audience.
- **Languages:** the whole interface, emails and chat can be translated with XML language packs; automatic right-to-left / left-to-right layout; visitors can choose their language.
- **Plugins:** declarative XML plugins and themes, with a plugin guide.
- Many fixes and smaller improvements.
