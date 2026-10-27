# ACE (AntiCheatExpert) Uninstaller
### Latest Version - October 2026
I got tired of this Tencent kernel anticheat living on my PC, even after the games that use it have been deleted long time ago. So, this batchfile script was made to make the uninstallation process easier and hassle-free. 

This script should also help you resolve any bugs/conflicts with the ACE anticheat by doing a clean uninstall, and forcing ACE to do a fresh re-install when you run your affected games again.

The main reasons I made this script were:
1. Older scripts I found on the internet haven't kept up with removing the latest ACE updates. For example:
      - ACE-ADVT Drivers (more advanced/newer version)
      - ACE-CORE10xx and ACE-CORE20xx Services
      - AntiCheatExpert Protection
      - Multiple Registry Keys related to AntiCheatExpert
2. Tencent will likely keep adding new stuff to ACE in the future which this script is designed to catch and remove.
3. The older scripts I was using failed to remove the latest ACE drivers and services that have been added.
4. Removing ACE-BASE and ACE-GAME are no longer enough to fully clear your system.
5. This script supports removal for all known Folders, Registry Keys, User/KERN Services and System32 Drivers related to AntiCheatExpert.
6. This script supports a separate Scan Only Mode and two different ACE removal methods. For different use cases.

If I find more stuff about ACE in the future. This script would be kept updated. _Hopefully._\
If you have any trouble with the script or have questions, feel free to raise an issue. I'll try and reach back.

## Download and Usage Steps
1. Download the latest `ace_uninstall.bat` script file from the [Releases Page](https://github.com/anujkoranga2402/ace-anticheat-uninstaller/releases).
2. Right-click on `ace_uninstall.bat` file and Run as Administrator. *It cannot work without Administrator permissions.*
3. Follow the displayed options and their descriptions to use according to your needs. 
   - Scan Mode
   - Full Auto Mode
   - Confirm before Delete Mode
4. Enjoy!

> [!NOTE]
> This script should work for all latest (and hopefully future) ACE versions of every kind.

> [!TIP]
> Use `Scan Mode` first. Then `Confirm before Delete Mode` for best control over what's being deleted.

> [!WARNING]
> This script uses **currently known filename regex** used by Tencent to find ACE installations.\
> _This means it **COULD** flag similarly-named items that are unrelated to AntiCheatExpert._\
> \
> Use `Scan` and `Confirm before Delete` functions to make sure it's finding and deleting the correct files.\
> I bear no responsibility in case of unintended deletions! Use `Scan Mode` first ALWAYS, if unsure.
