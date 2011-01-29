ASCII-Scramble
==============

ASCII-Scramble is a shot'em up for MS DOS text mode using only ASCII
characters.


COPYRIGHT
---------

Copyright (c) 1994, Thomas Aglassinger. All rights reserved. Distributed
under the BSD license.

Visit <https://github.com/roskakori/ASCII-Scramble> to obtain the source
code. Use Turbo Pascal 5.5 or later to compile.


INTRODUCTION
------------

Do you like games with gorgeous graphics, flashy colors and impressive
sound? Well, then this game is not for you.


FEATURES
--------

* uses only ascii chars (7 bit) for display
* uses only 3 different colors for display
  (depending on the color of your dos prompt)
* no sound
* EXE file needs less than 40k
* needs only about 10k of memory at run time
* runs at usable speed even with XTs


HARDWARE REQUIREMENTS
---------------------

Should run on anything that supports a 80x86 compatible CPU and an MS DOS
compatible operating system such as Windows.

Actually, ASCII-Scramble was developed using an Olivetti M15 (year of
construction: 1986; hardware: 8088, CMOS version; 2 floppy devices; 512K
ram) and Turbo Pascal 5.5.

The current version works only with a 40x25 color display (video memory at
$b800), so it won't run with a hercules monochrome adaptor.


INSTALLATION AND START
----------------------

Just copy all files of this distribution to your game directory.

To run ASCII-Scramble under MS DOS, "cd" to the installation folder and
run:

  ASCSCRAM

To run ASCII-Scramble under Windows, open the installation folder in the
explorer and double click ASCSCRAM.BAT.

To switch to full screen under Windows, press ALT + ENTER.


BACKGROUND STORY
----------------

In 2156, an alien race attacked to human space empire and destroyed all
human military forces within just a few days. As a last effort, the human
race puts all it effort into assembling a unique space ship with a single
objective: attack the enemy's home planet! So you... aw, you get the idea.


GAME OBJECTIVE
--------------

Shoot at everything that obviously scores points!


CONTROLS
--------

Use cursor keys to move your ship, space bar to fire
missiles and bombs, enter to activate extra under extra
cursor. "B" activates a smart bomb, if any available.
Pressing "P" will pause game until "P" is pressed again. ESC
will abort game.


EXTRAS
------

When you've shot a certain amount of enemies, an extra symbol ("$") will
appear. Pick it up, and the extra cursors jumps to the next extra. possible
extras are:

    SPEED : increases ship speed
    SHOOT : increases reload ratio of ship gun
    BOMB  : adds a smart bomb
            (your ship can carry up to nine smart bombs)
    DOUBLE: increases power of your ship gun
    WING  : adds two wings to your ship, which will also fire
            (better shot)
    SHIELD: makes ship immune to enemy & bullet collision
            for a short time (ship blinks)

After a crash, your speed and reload ratio just decreases instead of being
reset completely.

ENEMIES
-------

 T  : fuel storage; Shoot it to tank your ship; 1 shot
      required
 A  : rocket, moving upwards; 1 or 2 shots required

 V  : rocket, moving downwards; 1 or 2 shots required

 X  : enemy bullet; indestructible

O=- : comet; indestructible

 /[
<O= : ufo; 5 shots required
 \[

At end of scene 4 and 5, special enemies will await you.

HINT: Always shoot at the highlighted characters of an object!


VERSION HISTORY
---------------

Version 1.1, 2011-01-29

* First public release.
* Changed license from freeware to BSD license.
* Cleaned up documentation.
* Added batch file to run game from Windows.

Version 1.04, 1994-12-31

* Initial release distributed to a couple of mates.
