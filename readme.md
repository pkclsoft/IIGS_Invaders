# GS Invaders v1.0

## Designed and written by Peter C. Easdown, PKCLSoft, Australia

I wrote this game back in 1989 when I was wanting to create something new for my Apple IIGS.  It's all written
in ORCA/M Assembler, but uses sprites that I created with a simple editor created with TML Pascal (I've also
made the code for that editor available on Githib after porting it to ORCA/Pascal).

screenshot1

This was originally put up on AOL from memory as shareware.  Needless to say I made $0 from it.  But it was fun to make.
I'm putting the code up here for posterity.

## Line Endings
The text and source files in this repository originally used CR line endings, as usual for Apple II text files, but they have been converted to use LF line endings because that is the format expected by Git. If you wish to move them to a real or emulated Apple II and build them there, you will need to convert them back to CR line endings.

If you wish, you can configure Git to perform line ending conversions as files are checked in and out of the Git repository. With this configuration, the files in your local working copy will contain CR line endings suitable for use on an Apple II. To set this up, perform the following steps in your local copy of the Git repository (these should be done when your working copy has no uncommitted changes):

1. Add the following lines at the end of the `.git/config` file:
```
[filter "crtext"]
	clean = LC_CTYPE=C tr \\\\r \\\\n
	smudge = LC_CTYPE=C tr \\\\n \\\\r
```

2. Add the following line to the `.git/info/attributes` file, creating it if necessary:
```
* filter=crtext
```

3. Run the following commands to convert the existing files in your working copy:
```
rm .git/index
git checkout HEAD -- .
```

Alternatively, you can keep the LF line endings in your working copy of the Git repository, but convert them when you copy the files to an Apple II. There are various tools to do this.  One option is `udl`, which is [available][udl] both as a IIGS shell utility and as C code that can be built and used on modern systems.

Another option, if you are using the [GSPlus emulator](https://apple2.gs/plus/) is to host your local repository in a directory that is visible on both your host computer, and the emulator via the excellent [Host FST](https://github.com/ksherlock/host-fst).

[udl]: http://ftp.gno.org/pub/apple2/gs.specific/gno/file.convert/udl.114.shk

## File Types
In addition to converting the line endings, you will also have to set the files to the appropriate file types before building on a IIGS.

So, once you have the files from the repository on your IIGS (or emulator), within the ORCA/M shell, execute the following command:

    filetype minv src 6

## Building
To build the GS Invaders, make sure you have the repo present in the same folder on your GS.
You will need the ORCA/M environment present.
To build it, just execute the "minv" script. 

    minv

## Executing
Just run the generated "invaders" file.  Note that the mouse is used to start/stop a game and that a joystick is needed
to play it.  It would be great if someone wanted to enhance the game to allow the mouse to be used during play.


### Shareware Notice (now defunct, but preserved for nostalgic reasons)

This program ~~is~~__was__ Shareware.  This means that you may copy it, and distribute it at no cost to you.  It also means that you may not charge anyone you give a copy to for anything other than the act of copying it.

~~You are however obliged to send US$5 (made out to Peter C. Easdown) to the author (shown at the top of this page) if you decide to use it.~~  The author also requests that this documentation be distributed unchanged along with the Executable file.

~~Those people who register with the author by sending in the US$5 (made out to Peter C. Easdown) will be advised immediately of any updates to the program, and will be entitled to support from the author in the case of any problems.~~

Should anyone have any problem or suggestions relating to GS Invaders please don't hesitate to ~~contact me through the Post at the address supplied above~~ __find the bug in the code and send a pull request__.

## About GS Invaders

This game is a GS implementation of the original Space Invaders.  It is played using the joystick, and manipulated using the mouse.

Note: __It would be nice to add the ability to actually play with the mouse as well.  Pull requests are welcome.__

This was written back in late 1986, and ~~I am only now (July 91) getting around to releasing it~~__was released in July 1991__, simply because no one else ha~~s~~__d__ yet.  It was written more as a bit of fun than anything, when the best we had was SeaStrike and it's like.

I hope you like it.  

## Playing GS Invaders

When the game starts, the title screen will come up, with the score bar at the top of the screen.

In the score bar, you will see three buttons, PLAY, QUIT, and PAUSE.

Clicking on PLAY when the title screen is up, will commence play.  Otherwise it does nothing.

Clicking on QUIT when the title screen is up, will quit the program back to your launcher.  Clicking on QUIT during play will abort the game, and bring the title screen back.

Clicking on PAUSE when the title screen is up, will do nothing other than toggle the highlighting of the PAUSE button.  During play, PAUSE will freeze the game until the PAUSE button is clicked on again.

### Game Play

Once the action has started, the game plays true to the original, except for two things....

### The Mothership

When the mother ship appears, the screen background will change to a dark reddish colour.  While the mothership is present this will remain.  If you shoot the mother ship, it will continue until another mother ship appears.

While the background is non-black you will score extra points for each invader shot.

The mother ship may change direction at whim,  and each time it does, the background becomes a brighter red.  The will continue until: a) You shoot the mother ship. b) It dissapears. c) It turns too many times.

The brighter the red, the more bonus points you get.

### The Last Invader

When there is only one invader left on the screen, it does not simply walk horizontaly.  It begins travelling at a diagonal towards the bottom of the screen.

Enjoy!
