# goggy

Tool to help with porting GOG game bundles to GNU/Linux. The example port is a DOS-Box macos port of Theme Hospital.

## Overview

### Use as plugin

Nothing particular to be done, *ws* will install and init goggy.

### Manual setup

To setup goggy, tell it to setup via:

```bash
goggy setup
```

You may also specify a custom root directory via:

```bash
goggy setup -d /some/custom/root
```

It will prompt you for administrator rights, to be able to write to the /opt directory.

If you'd like to purge goggy from the system again, call:

```bash
goggy purge
```

To retain goggy's config files, use:

```bash
goggy purge -R
```

### Example 'Theme Hospital'

Download the MacOS package file from the GOG website. At this time this would be `theme_hospital_enUS_1_0_3_33062.pkg`. Let's assume we stash the package at `${HOME}/Downloads`, we can prepare it to be used with goggy like:

```bash
goggy install ${HOME}/Downloads/theme_hospital_enUS_1_0_3_33062.pkg
```

After unpacking, let's check for available games via:

```bash
goggy list
```

This should give you something like:

```bash
1207659026 "Theme Hospital"
```

Which is the name and ID of the package, as defined by the kind folks at GOG.

To start the game in single player mode, we may call:

```bash
goggy play 1207659026 single
```

To list all available game specific modes, check:

```bash
goggy play 1207659026 help
```

## Acknowledgement

Thanks everybody at GOG for your incredible work of porting, preserving and re-publishing so many great games.
