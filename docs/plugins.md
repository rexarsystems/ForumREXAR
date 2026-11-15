# ForumREXAR Plugin and Translation Guide

A ForumREXAR plugin is a single XML file, with no JavaScript or Go code. You declare what it shows and where, and the forum checks it and runs it safely.

This guide is for developers and AI agents. Every ForumREXAR forum also serves it at `/static/docs/plugin-guide.en.md`, with the Arabic original at `/static/docs/plugin-guide.md`. Ready-made examples are in [../plugins/examples](../plugins/examples).

## Start in five minutes

1. Create a file named `hello_box.xml`, encoded in UTF-8.
2. Put the example below in it.
3. In the control panel open `admin?tab=plugins`, then upload the file.
4. A plugin is always installed disabled, so click the enable button.
5. Open the home page and you will see the box.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<plugin schema_version="1.0">
    <id>hello_box</id>
    <name>Welcome box</name>
    <version>1.0.0</version>
    <min_rexar_version>1.0.0</min_rexar_version>
    <api_version>1</api_version>
    <author>Your name</author>
    <description>Shows a welcome message above the home page forums.</description>
    <icon>👋</icon>
    <hook>HOME_ABOVE_FORUMS</hook>
    <settings>
        <setting key="message" type="string" label="Welcome text" default="Welcome!" max_len="100"/>
    </settings>
    <template><![CDATA[
<div class="vb-bottom-box">
    <div class="vb-box-header">Welcome</div>
    <div class="vb-box-body">{{index .settings "message"}}</div>
</div>
]]></template>
</plugin>
```

## Plugin file elements

| Element | Required | Rule |
| --- | --- | --- |
| `schema_version` on `plugin` | Yes | The value `1.0` |
| `id` | Yes | Lowercase English letters, digits and `_`, 3 to 50 characters |
| `name` | Yes | Up to 100 characters, without `<` or `>` |
| `version` | Yes | Like `1.0.0`; an update must be newer |
| `min_rexar_version` | Yes | The oldest version the plugin runs on; `1.0.0` is the lowest |
| `api_version` | Yes | The value `1` |
| `author` | Yes | Up to 80 characters |
| `description` | Yes | Up to 300 characters |
| `icon` | No | A short symbol, up to 16 characters |
| `hook` with `template` | For a box | Where it shows, and its template |
| `data_source` | No | One or more data sources, separated by commas |
| `settings` | No | Up to 10 settings |
| `theme` | No | A theme that changes the colors |
| `actions` | No | Up to 10 member actions |
| `page_title` with `page_template` | For a page | The plugin's own page |

A plugin must have at least one of: a box, a theme or a page. The largest file size is 256KB.

The ids `forum_stats`, `who_is_online`, `live_chat` and `forum_preview` are reserved.

Start the id with your name, like `saleh_top_box`, so it does not clash. Before publishing, make sure it is not used in the [plugins section](https://forum.rexar.net/f.aspx?resources=1): the first to publish an id owns it there.

## Where plugins show

| Name | Place | Context |
| --- | --- | --- |
| `HEADER_BELOW` | Below the header of forum pages | None |
| `PAGE_BOTTOM` | At the bottom of the page, above the bottom bar | None |
| `SIDEBAR_BOTTOM` | At the bottom of the side menu | None |
| `HOME_ABOVE_FORUMS` | Above the home page forums | None |
| `HOME_BELOW_FORUMS` | Below the home page forums | None |
| `FORUM_TOP` | At the top of a forum page | Forum |
| `FORUM_BOTTOM` | At the bottom of a forum page | Forum |
| `TOPIC_TOP` | At the top of a topic | Topic |
| `TOPIC_BOTTOM` | At the bottom of a topic | Topic |
| `POST_AUTHOR_BELOW` | Below the author card of every post | Member |
| `PROFILE_BOTTOM` | At the bottom of the profile | Member |

Plugins never show in the control panel or on the install page. Only `SIDEBAR_BOTTOM` reaches the live chat. Up to five enabled plugins are allowed in one place.

## Templates

A template is Go html/template inside `<![CDATA[ ... ]]>`, and the forum escapes values automatically.

| What you read | Syntax |
| --- | --- |
| A setting | `{{index .settings "key"}}` |
| A data list | `{{range .data.latest_topics}} ... {{end}}` |
| A field of a row | `{{index . "title"}}` |
| A setting inside range | `{{index $.settings "key"}}` |
| A statistic | `{{index .data.forum_stats "members_count"}}` |
| Page context | `{{index .context "username"}}` |
| A vote result | `{{index .storage.poll "yes"}}` |
| Member records | `{{range .storage.ideas}} ... {{end}}` |

Only these functions are allowed: `index`, `len`, `eq`, `ne`, `lt`, `le`, `gt`, `ge`, `and`, `or` and `not`.

Limits:

- `{{if}}`, `{{range}}` and `{{with}}` are allowed; `range` only over `.data` and `.storage`, nested 2 deep at most.
- No `range` inside `with`.
- No variables like `{{$x := ...}}`, and no `define`, `template` or `block`.
- No fixed text inside the braces like `{{"text"}}`; write text outside them. Strings inside are only for comparison functions and `index`.
- A plugin's output is limited to 32KB, and its rendering to 200ms.

### Allowed tags

`div` `span` `p` `strong` `b` `em` `i` `u` `br` `hr` `ul` `ol` `li` `table` `thead` `tbody` `tr` `th` `td` `a` `img` `h3` `h4` `button` `textarea` `input` `label`

### Attributes

| Attribute | Rule |
| --- | --- |
| `class` | `vb-bottom-box`, `vb-box-header` and `vb-box-body`, or names starting with `st-plugin-` |
| `href` on `a` | Starts with `/f.aspx` or `https://` |
| `src` on `img` | Starts with `/static/` only |
| `alt`, `width` and `height` | On `img` |
| `target` | `_blank` only |
| `title`, `dir` and `align` | Allowed |
| `colspan` and `rowspan` | On `td` and `th` |

Not allowed: `id`, `style`, every `on...` attribute and any `data-` attribute other than the interaction tools below; nor `script`, `form`, `iframe` and `style` as tags.

## Data sources

Data is public, at a guest's level: no staff forums, no hidden topics, no emails or IP addresses. It refreshes about every 30 seconds, and a box is cached for up to 60 seconds. The number of rows comes from a setting named `limit`, 5 by default and 20 at most.

| Source | Fields |
| --- | --- |
| `top_posters` | `rank` `id` `username` `role_color` `posts_count` `avatar_url` `profile_url` |
| `latest_topics` | `id` `title` `url` `author` `author_url` `forum_name` `forum_url` `replies_count` `views_count` |
| `newest_members` | `id` `username` `role_color` `avatar_url` `profile_url` |
| `forum_stats` | `topics_count` `posts_count` `members_count` `online_members` `online_guests` |

`forum_stats` is a single value read with `index`; the others are lists read with `range`.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<plugin schema_version="1.0">
    <id>guide_latest_box</id>
    <name>Latest topics</name>
    <version>1.0.0</version>
    <min_rexar_version>1.0.0</min_rexar_version>
    <api_version>1</api_version>
    <author>Your name</author>
    <description>Shows the latest topics with the number of members.</description>
    <hook>HOME_BELOW_FORUMS</hook>
    <data_source>latest_topics,forum_stats</data_source>
    <settings>
        <setting key="limit" type="int" label="Number of topics" default="5" min="1" max="20"/>
    </settings>
    <template><![CDATA[
<div class="vb-bottom-box">
    <div class="vb-box-header">Latest topics</div>
    <div class="vb-box-body">
        {{range .data.latest_topics}}<a href="{{index . "url"}}">{{index . "title"}}</a>{{end}}
        <p>Members: {{index .data.forum_stats "members_count"}}</p>
    </div>
</div>
]]></template>
</plugin>
```

## Page context

A plugin reads the current page's data from `.context`:

| Context | Fields |
| --- | --- |
| Member | `id` `username` `role_color` `role_title` `avatar_url` `profile_url` `posts_count` |
| Topic | `id` `title` `url` `author` `author_url` `forum_name` `forum_url` `replies_count` `views_count` |
| Forum | `id` `name` `description` `url` `topics_count` `posts_count` |

```xml
<?xml version="1.0" encoding="UTF-8"?>
<plugin schema_version="1.0">
    <id>guide_author_badge</id>
    <name>Top poster badge</name>
    <version>1.0.0</version>
    <min_rexar_version>1.0.0</min_rexar_version>
    <api_version>1</api_version>
    <author>Your name</author>
    <description>A badge under the author when they pass a number of posts.</description>
    <hook>POST_AUTHOR_BELOW</hook>
    <settings>
        <setting key="min_posts" type="int" label="Minimum posts" default="100" min="1" max="100000"/>
    </settings>
    <template><![CDATA[
{{if ge (index .context "posts_count") (index .settings "min_posts")}}
<div class="vb-bottom-box"><div class="vb-box-header">Featured member</div></div>
{{end}}
]]></template>
</plugin>
```

## Settings

Settings show to the administrator in the control panel, and their values are checked on save.

| Type | Attributes |
| --- | --- |
| `string` | `max_len` up to 250, with no `<` or `>` in the value |
| `int` | `min` and `max` are required |
| `bool` | `default` is `true` or `false` |
| `color` | A color like `#1a2b3c`, shown as a color picker |
| `select` | `<option value="..." label="..."/>` elements inside the setting |

Every setting needs `key`, `type`, `label` and `default`. The key is lowercase letters, digits and `_`, 2 to 30 characters.

## Themes

The `<theme>` element holds CSS that changes colors and fonts, and it can use color settings as `var(--setting-key)`.

Allowed properties: `color`, `background`, `background-color`, `background-image`, `border` and its kinds, `border-radius`, `outline-color`, `box-shadow`, `text-shadow`, `text-decoration-color`, `font-family`, `font-weight`, `font-style`, `caret-color` and `accent-color`, plus CSS variables like `--startimes-blue`.

Allowed functions: `rgb`, `rgba`, `hsl`, `hsla`, `linear-gradient`, `radial-gradient` and `var`.

Not allowed: `url()`, `@import` and any `@` rule; `position`, `display`, `opacity`, `width` and layout properties; `::before`, `::after` and attribute selectors `[...]`.

Allowed pseudo-classes: `:hover`, `:focus`, `:active`, `:visited`, `:root`, `:first-child` and `:last-child`.

Only one theme works at a time, and it never applies to the control panel. The administrator has a preview button before enabling it.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<plugin schema_version="1.0">
    <id>guide_green_theme</id>
    <name>Green theme</name>
    <version>1.0.0</version>
    <min_rexar_version>1.0.0</min_rexar_version>
    <api_version>1</api_version>
    <author>Your name</author>
    <description>Turns the forum headers green.</description>
    <settings>
        <setting key="primary" type="color" label="Main color" default="#047857"/>
    </settings>
    <theme><![CDATA[
:root { --startimes-blue: var(--setting-primary); }
.table-columns-header, .table-columns-header th, .vb-box-header {
    background: var(--setting-primary) !important;
}
]]></theme>
</plugin>
```

## Interaction

The developer declares actions, and the forum runs them. Every action needs a signed-in member.

| Attribute | `vote` | `entry` (text) |
| --- | --- | --- |
| `id` | Required | Required |
| `options` | Required, up to 20 options | Not allowed |
| `max_len` | Not allowed | 200 by default, 500 at most |
| `max_entries` | Not allowed | 100 by default, 500 at most |
| `cooldown` | Seconds, 30 by default, 3 at least | The same |

The option `total` is reserved for the sum of votes. When `max_entries` is passed, the oldest record is deleted. The data lives in its own file of up to 2MB; it stays when the plugin is updated and is deleted with the plugin. The administrator has a button to clear the data, and a "Manage records" button to delete one text a member wrote without clearing the rest.

### Interface tools

| Attribute | Tag | Purpose |
| --- | --- | --- |
| `data-plugin-action` | `button` | The action's name |
| `data-plugin-value` | `button` | The vote option |
| `data-plugin-field` | `button` | The field the button sends |
| `data-plugin-input` | `input` and `textarea` | The field's name |
| `data-plugin-status` | `div`, `span` and `p` | Where the success or error message shows |
| `data-plugin-open` | `button` | Opens a window |
| `data-plugin-close` | `button` | Closes the window |
| `data-plugin-modal` | `div` | The window; its first child is the content |

The values of these attributes are English letters, digits, `_` and `-`, up to 40 characters. `input` may only be of type `text`, and `button` never submits a form. The allowed field attributes are `placeholder`, `maxlength` and `rows`.

### The plugin's page

Its link is `/f.aspx?plugin=ID`. The page knows the visitor through `.viewer.logged_in` and `.viewer.username`, and their vote through `{{index .viewer.votes "poll"}}`. Boxes are shared by all visitors, so they do not know the current visitor.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<plugin schema_version="1.0">
    <id>guide_poll_page</id>
    <name>Poll and ideas</name>
    <version>1.0.0</version>
    <min_rexar_version>1.0.0</min_rexar_version>
    <api_version>1</api_version>
    <author>Your name</author>
    <description>A poll on the home page and a page for members' ideas.</description>
    <hook>HOME_ABOVE_FORUMS</hook>
    <actions>
        <action id="poll" type="vote" options="yes,no" cooldown="5"/>
        <action id="ideas" type="entry" max_len="300" max_entries="200" cooldown="30"/>
    </actions>
    <template><![CDATA[
<div class="vb-bottom-box">
    <div class="vb-box-header">Do you like the forum?</div>
    <div class="vb-box-body">
        <button data-plugin-action="poll" data-plugin-value="yes">Yes ({{index .storage.poll "yes"}})</button>
        <button data-plugin-action="poll" data-plugin-value="no">No ({{index .storage.poll "no"}})</button>
        <button data-plugin-open="about">Details</button>
        <a href="/f.aspx?plugin=guide_poll_page">Ideas</a>
        <span data-plugin-status="box"></span>
        <div data-plugin-modal="about">
            <div>
                <p>Your vote counts once, and you can change it.</p>
                <button data-plugin-close="about">Close</button>
            </div>
        </div>
    </div>
</div>
]]></template>
    <page_title>Members' ideas</page_title>
    <page_template><![CDATA[
<div class="vb-bottom-box">
    <div class="vb-box-header">Members' ideas</div>
    <div class="vb-box-body">
        {{if .viewer.logged_in}}
        <textarea data-plugin-input="ideas" maxlength="300" rows="3" placeholder="Write your idea"></textarea>
        <button data-plugin-action="ideas" data-plugin-field="ideas">Send</button>
        <span data-plugin-status="page"></span>
        {{end}}
        {{range .storage.ideas}}
        <p><a href="{{index . "profile_url"}}">{{index . "username"}}</a>: {{index . "text"}}</p>
        {{end}}
    </div>
</div>
]]></page_template>
</plugin>
```

The fields of `.storage` records: `id`, `username`, `profile_url`, `text` and `time`; the latest 50 records are shown.

## Updating

Upload a file with the same `id` and a higher `version`, choosing "Update an installed plugin to a newer version". The plugin goes back to disabled for review, and keeps its settings and data.

When rendering fails 5 times in a row, the plugin is disabled automatically and the reason shows in the control panel. Setting `REXAR_SAFE_MODE=1` in the environment turns off all plugins.

## Translation files

The whole forum interface is translated with one XML file per language. The Arabic text itself is the key of each phrase, so there are no numbers or codes to learn, and any phrase you leave untranslated shows in Arabic.

1. Download the blank template from `/translation-template.xml` (or from the plugins page: "Blank translation template"). It holds only the interface phrases, with no data from any forum.
2. Edit the file's header: the language code, its name, its direction, the version and your name.
3. Write the translation inside `<text>` beside each `<ar>`, and leave `<ar>` as it is.
4. Try the file on your forum: control panel, then `admin?tab=languages`, then "Import a new language".
5. Publish it in the plugins section with "New plugin". After review it shows in "Translation files" with your name and how much is translated.

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
| `author` | The translator's name, shown as "Translation: name" in the plugins section and the control panel |

### Translation rules

- Keep the value markers `%s` and `%d` in the same number and order. A translation that changes them is ignored and the Arabic phrase shows.
- Do not put HTML code or links in a translation; a file that has them is refused.
- A phrase ending with `#` and a word, like `من#sender`, is the same word in a different place, so translate it for that place.
- A partial translation is fine; administrators see how much is translated before downloading.
- A file can be up to 4MB, with up to 20000 phrases.
- When a new forum version comes out, download the template again to see the new phrases.

## Common rejection messages

| Message | Cause and fix |
| --- | --- |
| `forbidden HTML tag` | A tag that is not allowed; check the list of tags |
| `disallowed CSS class` | Put `st-plugin-` before the class name |
| `attribute "style" is forbidden` | No `style` in a template; use `<theme>` |
| `forbidden template function` | A function that is not allowed; check the list of functions |
| `direct string literal` | Move the text outside `{{ }}` |
| `custom template variables` | Remove the variables and use `index` |
| `a href must start with` | Links start with `/f.aspx` or `https://` |
| `img src must start with /static/` | Images come from the site's own files only |
| `unsupported or unknown <hook>` | Wrong place name; check the table |
| `property ... is not allowed in <theme>` | A CSS property that is not allowed |
| `requires ForumREXAR version` | The forum is older than `min_rexar_version` |
| `must be newer` (or `يجب أن يكون أحدث`) | Raise `version` before updating |

## Instructions for AI agents

When you create a plugin, follow these rules:

1. Output one complete XML file in UTF-8, and write no JavaScript, and no CSS outside `<theme>`.
2. Use only the elements and names listed here; do not guess data names or places that are not listed.
3. Put templates and themes inside `<![CDATA[ ... ]]>`.
4. Make the `id` unique in lowercase, and start the version at `1.0.0`.
5. For styling use `vb-bottom-box`, `vb-box-header` and `vb-box-body` to match the forum's look.
6. If the user asks for something unsupported, tell them about the limit instead of trying to work around it.
7. After uploading, read the rejection message, fix that exact cause only, then try again.
