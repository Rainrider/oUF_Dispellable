# oUF_Dispellable

This is an element for the unitframe framework oUF ([Curse](https://www.curseforge.com/wow/addons/ouf) / [WoWI](http://www.wowinterface.com/downloads/info9994-oUF.html)).  
It does nothing by itself and requires layout support to do its magic.

## Description

oUF_Dispellable provides functionality to highlight debuffs dispellable by the player. It can display either a texture 
colored by the debuff type, or an icon representing the found dispellable debuff, or both.

It enables and disables itself automatically based on whether the player can dispel or not and keeps an always updated 
list of the dispel spells available to the player. It also keeps track of self-dispels like [Grimoire: Imp](http://www.wowdb.com/spells/111859) 
and [Cleansed by Flame](http://www.wowdb.com/spells/205625) to only highlight the player frame when only those are known.

## How to use (for layout authors)

The element is fully documented and follows the current oUF guidelines for documentation. Please take a look at the code 
for details and examples. You could also consult the [wiki](https://github.com/Rainrider/oUF_Dispellable/wiki).

Please consider making oUF_Dispellable optional for your users. The easiest way is to distribute it with your layout as a 
separate addon and use something like `if not IsAddOnLoaded('oUF_Dispellable') then return end` before calling its 
functionality. Users can then opt-out of using it by just uninstalling it without having to edit your code. This way 
they can also update oUF_Dispellable themselves, without you having to release a new version of your layout just to pick 
some minor changes.

If you are a layout user and oUF_Dispellable didn't come together with your layout despite the layout supporting it, just 
install it as a normal addon.

## Issues

If you have any problems using oUF_Dispellable, please open an issue at [GitHub](https://github.com/Rainrider/oUF_Dispellable/issues). 
Remember to first search if there is an existing issue concerning your problem.

## License

Please read the included [LICENSE](https://github.com/Rainrider/oUF_Dispellable/blob/main/LICENSE).
