---
description: Load vcs-detect skill to determine jj vs git before VCS commands
---

Load the `vcs-detect` skill and use it to help with the user request.

First, invoke the skill tool to load the vcs-detect skill:

```
skill({ name: 'vcs-detect' })
```

Then follow the skill instructions to complete the request.

<user-request>
$ARGUMENTS
</user-request>
