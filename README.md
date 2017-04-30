# MaSuperCarte
French job interview project

## Installation
- Copy sources,
- Install CocoaPods,
- `pod install` from the project folder,
- Run MaSuperCarte.xcworkspace.

## Version
3 (0) for 'Etape 3'

## Comments
Dragging the map now automatically update the address search bar following a defined address format.
If no address is found, then it is the default coordinate's placemark's qualified name which is set.

I also removed the "current position when clearing search bar" feature for a better user experience.

Finally, I changed the geocoding functions to send the results through completion handlers.
