# Miscellaneous Shell Scripts

Random scripts I've written over time that don't particularlly warrant their own Repository.

# BASH Scripts

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

# v
Universal "View" script

- Lists contents of directories
- Lists contents of archive files
- Attempts to display images
- `ffprobe`s videos and audio
- Plays video/audio in [Terminology](https://www.enlightenment.org/about-terminology.md)
- Displays ODF files with `pandoc` and `bat`
- Uses `file -b` otherwise
