# os-backup-generator

Opensimulator in-world script to create daily, weekly and annual backups of regions, by invoking simulator console commands from an in-world prim. It creates oar, terrain and xml backups.

The backups rotate, so there will only be 7 daily backups and 52 weekly backups at most. Yearly backups are fully dated and created on the 31st Dec, and never overwrite each other. It is up to the administrator to prune these.

Requires the following OSSL functions to be enabled:
        osConsoleCommand        # GOD mode function!
        osReplaceString         # should be enabled by default

The OSSL function `osConsoleCommand` is a GOD level command. The owner of the script must be enabled as a god on the grid. See http://opensimulator.org/wiki/OsConsoleCommand for details. If you are able to set yourself as a GOD, then you should consider creating backups of the database instead as it is much more efficient. See this page on the opensimulator wiki: http://opensimulator.org/wiki/Backups

If you cannot access the database for some reason but can still attain GOD mode (not sure how that is done without access to the database), this script may be the answer for you. Also, oars, xml's and terrain files are easier to restore (generally speaking, loading an oar is sufficient).

The script is configured through a config notecard named 'config' (because I have no imagination). The notecard can contain instructions, one per line:

1. Any line starting with a # is a comment and is ignored
```
# this is a comment and is ignored
```

2. A line enclosed in square brackets is echoed to the owner during startup.
```
[This will be echoed to the owner]
```

3. Lines in the form Region=xxx specify a region to be backed up. There may be multiple regions defined this way:
```
Region=My Region Name With Spaces In It
Region=Secondary Region
Region=Tertiary Region
```

4. A line in the form Path=xxx defines a path where the backups will be stored. This is a relative path from the simulator's bin directory. The path may (and probably should) contain a %r component, which will be replaced by the name of the region when the backups are made.
```
Path=oar/repos/%r/
```

Note the path must end in a trailing slash, and the folders must already exist with the following sub-folders for each region:
```
        Daily
        Weekly
        Yearly

        e.g. (using the Path variable above):
        oar/repos/MyRegionName/Daily
        oar/repos/MyRegionName/Weekly
        oar/repos/MyRegionName/Yearly
```

5. A line in the form BackupHour=nnn defines at which hour the backup is performed. The default is 14 (2PM).
```
BackupHour=14
```

The backups follow this procedure:
1. Backups begin at 2PM daily or as set by 'BackupHour'.
2. A daily backup is made with a filename in the following format filename:
```
        01-Monday.oar
        02-Tuesday.oar
```
        etc.
        At the beginning of the next week, these are overwritten.
3. A weekly backup is made every monday in the following format filename:
```
        06-02.oar // week #6 (of 52), falling Feb (month 02)
        07-02.oar // week #7 (of 52), falling Feb (month 02)
```
        There can be 52 of these, then they start overwriting each other.

4. An annual backup is made on the 31st December with the following format filename:
```
        2025-12-31-14:02:15.oar   // year-month-day-hour-minute-second.oar
```
        These do not overwrite each other.

Note that oar files have no prefix. Terrain files are prefixed with `terrain_` (and have `.r32` extension, and xml files have an `xml_` prefix and `.xml` extension.

At the end of the backup, the script will calculate how many seconds until 2PM and set a timer event to trigger another backup at that time.

When the script is first run, the config card is loaded and a backup immediately takes place, then the timer is set for the next backup. If the script is reset prior to 2PM (or whichever hour you have set), it is possible there will be another backup the same day. This will overwrite the daily and weekly backups created earlier in the day, but if it is December 31st, a second yearly backup is created - the filename will be different from the earlier backup so it is not overwritten.

You should check the region console for any error messages. Note the script must be run in a region hosted by the simulator running the regions to be backed up. If a region is hosted on a different simulator, it must have it's own backup schedule run on a region hosted by that simulator.
