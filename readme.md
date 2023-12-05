**Dependencies**
- A *specific version* of Mythic Progbar. (https://github.com/MonsterTaerAttO/mythic_progbar/tree/master, This should be backwards compatible)
- qb-core
- qb-target (Please make a PR if you want to add ox- support!)

There is a rare issue where qb-inventory will insist an item does not exist because qb-core update object does not fire correctly. Create an issue if this occurs.

Mythic progbar will show an error for SendAlert if you do not have mythic_notify, which is not needed by this resource. You can ignore this error, as it does not prevent any code from running.

This resource was a bespoke resource created by xotikorukx for EncoreRP (RIP :() and converted to ESX. The code probably needs rewritten, but eh, it works.

Images for the items 'steel', 'electricalscrap', 'metalscrap', 'nutsandbolts' are not included. I beleive steel and metal scrap are used by QB by defeault and should require no configuration other than balance. nuts and bolts are not used by ny default scripts, and this script provides a place to sell electrical scrap.

mythic_progbar (use this one!!! https://github.com/MonsterTaerAttO/mythic_progbar/tree/master) is required for this resource. It is added as a submodule, but as long as it is running (even if installed eternally) nobody gonna care. If you download acscrapping as a zip you will need to manually download the linked mythic progbar.
