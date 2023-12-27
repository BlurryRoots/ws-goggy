# goggy

Tool to help with porting GOG game bundles to GNU/Linux. The example port is a DOS-Box macos port of Theme Hospital.

## Overview

### Install

To setup goggy, tell it to install itself via:

```bash
goggy install
```

It will prompt you for administrator rights, to be able to write to the /opt directory.

### Example 'Theme Hospital'

Download the MacOS package file from the GOG website. At this time this would be `theme_hospital_enUS_1_0_3_33062.pkg`. Let's assume we stash the package at `/opt/goggy/cache`, we can prepare it to be used with goggy like:

```bash
goggy unpack /opt/goggy/cache/theme_hospital_enUS_1_0_3_33062.pkg
```

After unpacking, let's check for available games via:

```bash
goggy list
```

This should give you something like:

```bash
"Theme Hospital" ("1207659026")
```

Which is the name and ID of the package, as defined by the kind folks at GOG.

To start the game in single player mode, we may call:

```bash
goggy play 1207659026 single
```

## Acknowledgement

Thanks everybody at GOG for your incredible work of porting, preserving and re-publishing so many great games.
