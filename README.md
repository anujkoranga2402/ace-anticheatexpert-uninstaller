# ACE (AntiCheatExpert) Uninstaller Latest
I got kinda tired of this Tencent kernel anticheat living on my PC, even after the games that use it have been deleted long time ago. So this script was made to make the uninstallation process easier and hassle-free.

The main reasons I made this script were:
1. Older scripts I found on the internet haven't kept up with the latest ACE updates.
      > For example: ACE-ADVT and ACE-CORExxxxxxx drivers, as well as "AntiCheatExpert Protection" service.
2. Tencent will likely keep adding new stuff to ACE in the future which this script is designed to catch and remove, and older scripts I saw don't even find.
3. Supports removal for all known Folders, Registry Keys, Usermode Services and Kernel Drivers related to AntiCheatExpert.
4. Supports separate Scan Mode and two different ACE removal methods. Read explanations.
5. If I find more stuff about ACE in the future. This script would be kept updated. Hopefully.

> [!NOTE]
> This script should work for all latest (and hopefully future) ACE versions. Supports selective options for removal.

> [!IMPORTANT]
> The script `ace_uninstall.bat` file must be run as Administrator, otherwise it won't work.

> [!TIP]
> Use `Scan` Mode first. Then `Confirm before Delete` Mode for best control over what's being deleted.

> [!WARNING]
> This script uses currently **known regex** to find ACE installations.
> _It could flag **similar named** items that are unrelated to ACE._
> Use `Scan` and `Confirm before Delete` functions to make sure it's finding and deleting the correct files.
> I take no responsibility in case of unintended deletions. Use `Scan` mode first ALWAYS if unsure.

If you have any trouble with the script, feel free to raise an issue. I'll try and reach back.
