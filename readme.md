**Dependencies**
- A *specific version* of Mythic Progbar. (https://github.com/MonsterTaerAttO/mythic_progbar/tree/master, This should be backwards compatible). It is added as a submodule, but as long as it is running (even if installed eternally) nobody gonna care.
- qb-core
- qb-target (Please make a PR if you want to add ox- support!)
- ps-disptach (Please make a PR if you want to add other callouts support!)

**Known Issues**
- There is a rare issue where qb-inventory will insist an item does not exist because qb-core update object does not fire correctly. Create an issue if this occurs.
- Mythic progbar will show an error for SendAlert if you do not have mythic_notify, which is not needed by this resource. You can ignore this error, as it does not prevent any code from running, and I do not want to edit a base resource.
- This resource was a bespoke resource created by xotikorukx for EncoreRP back in 2020 (RIP :() and converted to ESX. The code probably needs rewritten/refactored, but eh, it works.
- Images for the items 'steel', 'electricalscrap', 'metalscrap', 'nutsandbolts' are not included. I beleive steel and metal scrap are used by QB by defeault and should require no configuration other than balance. nuts and bolts are not used by ny default scripts, and this script provides a place to sell electrical scrap.
- Github changed the brackets [] into hypens ([dfs_cirme_acscappring]). You can just yoink dfs_crime_acscrapping folder into your resources directory if you install mythic_progbar seperately.
