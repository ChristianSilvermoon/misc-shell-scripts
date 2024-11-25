# Miscellaneous Shell Scripts

Random scripts I've written over time that don't particularlly warrant their own Repository.

# Scripts

## avscripts
Script of `ffmpeg` incantations to reduce the amount of required memorization-typing.

## dualsense-menu
Script that provides an interactive menu for some [dualsensectl](https://github.com/nowrep/dualsensectl) features

## ps5triggers
Script that makes manipulating the Adaptive Triggers with [dualsensectl](https://github.com/nowrep/dualsensectl) convenient.

Examples:

```bash
# Set
ps5triggers b.gcn # Gamecube-esque clicky triggers

# Set while another program is running
ps5triggers b.depth-vibe your-game-here
```

## v
Universal "View" script

- Lists contents of directories
- Lists contents of archive files
- Attempts to display images
- `ffprobe`s videos and audio
- Plays video/audio in [Terminology](https://www.enlightenment.org/about-terminology.md)
- Displays ODF files with `pandoc` and `bat`
- Uses `file -b` otherwise

## web-link-handler
Script to act as a default web browser.

**INTENDED TO BE EDITED BY END USER**

Opens Steam Links in Steam by default
Opens Youtube Links in FreeTube by default
Uses `firefox` otherwise

Rules can be defined using the the `$RULES` Associative Array

Behaviors for Rules can be defined using the case statement.

Any rule name that starts with `BLOCK_` will be ignored by default, and a desktop notification sent.
This may be useful if you wish to prevent certain links from opening.

