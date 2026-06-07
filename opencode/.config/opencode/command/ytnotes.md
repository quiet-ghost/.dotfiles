---
description: Create saved Markdown notes from a YouTube URL using the current notes agent
---

Create saved Markdown notes from this YouTube request:

<user-request>
$ARGUMENTS
</user-request>

If the current agent is `sermon-notes`, use the sermon template.
If the current agent is `programming-notes`, use the programming template.
If the current agent is `general-notes`, use the general template.
If the user specifies `sermon`, use the sermon structure.
If the user specifies `programming`, use the programming structure.
Otherwise use the general YouTube notes structure.

Fetch the source with `youtube_fetch`, process transcript chunks incrementally for long videos, and save the Markdown note under `/home/ghost/personal/Notes/Imports/` unless the user explicitly gives another path.

Always use an absolute save path beginning with `/home/ghost/personal/Notes/Imports/`. Never write to `home/ghost/personal/Notes/Imports/` without the leading slash.
