# oUF_Dispelable

This is an element for the unitframe framework oUF ([Curse](https://www.curseforge.com/wow/addons/ouf) / [WoWI](http://www.wowinterface.com/downloads/info9994-oUF.html)).  
It does nothing by itself and requires layout support to do its magic.

## Description

oUF_Dispelable provides functionality to highlight debuffs dispelable by the player. It can display either a texture 
colored by the debuff type, or an icon representing the found dispelable debuff, or both.

It enables and disables itself automatically based on whether the player can dispel or not and keeps an always updated 
list of the dispel spells available to the player. It also keeps track of self-dispels like [Grimoire: Imp](http://www.wowdb.com/spells/111859) 
and [Cleansed by Flame](http://www.wowdb.com/spells/205625) to only highlight the player frame when only those are known.

## How to use (for layout authors)

The element is fully documented and follows the current oUF guidelines for documentation. Please take a look at the code 
for details and examples. You could also consult the [wiki](https://github.com/Rainrider/oUF_Dispelable/wiki).

## How to install

If you are a layout author, here are some options how to distribute oUF_Dispelable with your layout:

  - unzip the whole embedded package into your layout's folder and load `libs\LibStub\LibStub.lua`,  
    `libs\LibPlayerSpells-1.0\lib.xml` and `oUF_Dispelable.lua` from your .toc file in that order.  
    While this is the simplest option, you will have to keep your copy updated manually.
  - if you are using git for source control management, you could use gitmodules to pull oUF_Dispelable and it's dependencies.
  - you could use some automated packaging for distribution like [packager](https://github.com/BigWigsMods/packager). Once set up, this is the best solution.

Please consider making oUF_Dispelable optional for your users. The easiest way is to distribute it with your layout as a 
separate addon and use something like `if not IsAddOnLoaded('oUF_Dispelable') then return end` before calling its 
functionality. Users can then opt-out of using it by just uninstalling it without having to edit your code. This way 
they can also update oUF_Dispelable themselves, without you having to release a new version of your layout just to pick 
some minor changes.

If you are a layout user and oUF_Dispelable didn't come together with your layout despite the layout supporting it, just 
install it as a normal addon.

## Issues

If you have any problems using oUF_Dispelable, please open an issue at [Github](https://github.com/Rainrider/oUF_Dispelable/issues). 
Remember to first search if there is an open/closed issue concerning your problem.

## License

Please read the included LICENSE.
