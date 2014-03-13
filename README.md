spritesheetgen
==============

Utility for generating cocos2d compatible spritesheets. Currently only works on Mac OS X.

Usage
--------------

```
spritesheetgen INPUT_DIR OUTPUT_DIR TEXTURE_NAME
```

Program will traverse all image files (PNG and JPEG) in `INPUT_DIR folder`, place them on texture (power of 2 size, non-square) and write texture image to `OUTPUT_DIR/TEXTURE_NAME.png` as well as `OUTPUT_DIR/TEXTURE_NAME.plist` with sprite locations description.

Program will remove any transparent borders on input sprites, keeping sizes by correctly setting data in resulting plist file.
