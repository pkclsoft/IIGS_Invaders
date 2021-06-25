
         keep     drsprites
         mload    drsprites.macro

;...............................................................
;
; ICoord.
; ~~~~~~~
; Will initialise the coordinates of all sprites for start of game
; play, plus all other game specific variables.
;................................................................

ICoord   start

         using    GMData
         using    SHData

         stz      SHIndx                ;Aliens start on first image.
         lda      #cols                 ;There are 'cols' columns of aliens.
         sta      rgtcol
         lda      #1                    ;The leftmost column is number one.
         sta      lftcol
         sta      dirctn                ;Moving to the left.

         ldx      noaliens              ;Any left ?
         bne      dontchng              ; No, dont change canon, etc then.
         sta      canonx                ;The canon starts at X=1.
         lda      #3                    ;Missile status is OFF.
         sta      MissSt
         sta      Mothers               ;Mother status is OFF.
         stz      CNIndx                ;Canon starts with shape 0.

dontchng stz      noaliens              ;There are still aliens on the screen.
         stz      OneLeft
         lda      #10
         sta      LastCntr

         lda      #1
         ldx      #0                    ;Start initialisation loop.
ICloop   pha                            ;Save current x coordinate.
         txy
         txa
         asl      a
         tax
         pla
         sta      Row1x,x               ;Initialise this columns X coordinate.
         sta      Row2x,x
         sta      Row3x,x
         sta      Row4x,x

         pha
         clc
         lda      starty              ;Initialise this columns Y coordinates.
         sta      Row1y,x
         adc      #20
         sta      Row2y,x
         adc      #20
         sta      Row3y,x
         adc      #20
         sta      Row4y,x
         adc      #12                   ;The aliens bombs should start just
         sta      BombSY,x              ;below the fourth row.

         lda      #$0004                ;Set all alien status' to NORMAL.
         sta      Row1s,x
         sta      Row2s,x
         sta      Row3s,x
         sta      Row4s,x

         sta      Colnum,x              ;Set number in current column to 4.

         lda      #$0003                ;Set bomb status to OFF.
         sta      BombSt,x

         pla

         clc                            ;Move X to next column.
         adc      #30
         tyx
         inx
         cpx      Rgtcol                ;All columns done ?
         bne      ICloop                ; No. Go back.

         jsr      UPPos                 ;Do an initial draw of the sprites.

         rts

         end

;................................................................
;
; UPPos.
; ~~~~~~
; Will redraw all aliens based on their current coordinates. Calls
; are made to chkstat for each alien to see if it is exploding, so
; the correct sprites will be drawn.
;................................................................

UPPos    start

         using    SHData

         jsr      setbomby              ;Set the bomb Y coords.

         ldx      #0                    ;Start at the first column.
redo     phx
         jsr      strtbomb              ;Start some bombs off.
         lda      Colnum,x              ;Any left in this column ?
         beq      nouser                ; No. User doesn't get any time then.
         jsr      dojoy                 ; Yes. Process joystick.
         jsr      domissl               ;      Process missile.
         jsr      domother              ;      Process mother ship.
nouser   plx
redo1    lda      Row1x,x               ;Get X of current alien.
         sta      xpos
         lda      Row1y,x               ;Get Y of current alien.
         sta      ypos
         jsr      chkstat               ;Check it's status.
         bcs      nodraw                ;If gone or exploding, dont draw it.
         jsr      drwalien              ;Draw the alien.
nodraw   txa
         clc
         adc      #20                   ;Move down a row.
         tax
         cpx      #80                   ;Past bottom row ?
         bmi      redo1                 ; No, do next in this column.
         sec
         sbc      #78                   ; Yes, move to next column, top row.
         tax
         cpx      #20                   ;Finished all ?
         bmi      redo                  ; No, do this column.
         rts                            ; Yes, return.

         end
;................................................................
;
; StrtBomb.
; ~~~~~~~~~
; Checks the status of the bomb for the current column.  If not
; dropping, a random number is generated.  If the number is suitable,
; the bomb is activated.
;
; If the bomb is already active, it is animated.
;................................................................

strtbomb start

         using    SHData

         phx                            ;Save current alien index.
         lda      BombSt,x              ;Get current columns bomb status.
         cmp      #3                    ;Is it active ?
         bne      dropping              ; Yes, go and animate it.
         lda      Colnum,x              ;Get number of aliens in this column.
         beq      dontactv              ; None left, so dont activate.
         pea      $0000
         _Random                        ;Get a random number.
         pla

         plx                            ;Get alien index back again.
         phx                            ;Save it.
         and      #$000f                ;Strip off unwanted bits.
         cmp      #14                   ;Is rand number 14 or 15 ?
         bmi      dontactv              ; No, dont activate it.

         inc      BombSt,x              ;Activate the bomb.
         lda      BombSY,x              ;Set up bombs start coords.
         sta      BombCy,x
         lda      Row1x,x
         clc
         adc      #10
         sta      BombCx,x

dontactv plx                            ;Restore alien index.
         rts

dropping lda      BombSt,x              ;Get bomb status.
         cmp      #4                    ;Is it exploding ?
         bmi      explode               ; Yes. Handle that.
         lda      BombCx,x              ; No. Get current coords.
         sta      xpos
         lda      BombCy,x
         inc      a
         inc      a
         inc      a
         sta      BombCy,x
         sta      ypos                  ;Move down 3 lines.

         jsr      DRBS                  ;Draw the bomb.
         plx
         lda      BombCy,x              ;Get bombs height.
         cmp      #182                  ;Reached the bottom ?
         bpl      strtexpl              ; Yes, start an explosion.
         lda      BombSt,x              ; No, increment it's status.
         inc      a
         cmp      #8                    ; Loopback time ?
         bne      itsok                 ;  No.
         lda      #4                    ;  Yes, reset status.
itsok    sta      BombSt,x
         lda      SColisn               ;Did bomb hit something ?
         beq      nohit                 ; No, skip.
strtexpl lda      BombCx,x              ; Yes, start explosion.
         dec      a                     ; Alter coords for explosion size.
         dec      a
         sta      BombCx,x
         lda      BombCy,x
         clc
         adc      #1
         sta      BombCy,x
         stz      BombSt,x              ; Set bomb status to start of explosion.
         cmp      #160                  ; Below the barriers ?
         bmi      Bang                  ;  No, exit.
         lda      BombCx,x              ;  Yes, impact with canon ?
         inc      a
         inc      a
         inc      a
         cmp      canonx
         bmi      Bang                  ;    No, exit.
         sec
         sbc      #20
         cmp      canonx
         bpl      Bang                  ;    No, exit.
         jsr      shiphit               ;    Yes. Handle canon explosion.
Bang     jsr      PlayBomb
nohit    rts

explode  lda      BombCx,x              ;Get bombs coords.
         sta      xpos
         lda      BombCy,x
         sta      ypos
         jsr      DRBM                  ;Mask out explosion area.
         plx
         phx
         jsr      DRBX                  ;Draw explosion.
         plx
         phx
         lda      ypos                  ;Move down a bit.
         clc
         adc      #6
         sta      ypos

         jsr      DRBM                  ;Mask out some more for the rest of
         plx                            ;the explosion.
         phx
         jsr      DRBX                  ;Draw the rest of the explosion.
         plx
         inc      BombSt,x              ;Increment bomb status.
         rts

         end

;................................................................
;
; ShipHit.
; ~~~~~~~~
; Called when the users canon is hit by an enemy bomb.
;................................................................

shiphit  start

         using    GMData
         using    SHData
         using    CNXS
         using    BARD

         lda      #CNXSW                ;Get canon explosion parameters.
         sta      SWidth
         lda      #CNXSH
         sta      SHeight

         ldx      #0
         ldy      #3                    ;Three images of explosion.
exlp     lda      canonx                ;Is X odd ?
         ror      a
         bcc      evenx                 ; No, it's even.

         lda      CNXSPnt2,x            ;Set up ODD shape parms.
         sta      SImage
         lda      CNXSPnt2+2,x
         sta      SImage+2
         bra      skipover

evenx    lda      CNXSPnt1,x            ;Set up EVEN shape parms.
         sta      SImage
         lda      CNXSPnt1+2,x
         sta      SImage+2

skipover sty      ypos                  ;Save indexes in useful spot.
         stx      xpos
         lda      canonx                ;Get coords for explosion.
         pha
         lda      #170
         pha

         lda      #$ffff                ;No Collision detection.
         sta      SCollin

         stz      Smask                 ;No masking.

         jsr      DRSprite              ;Draw the sprite.

         ldx      #$ffff                ;Small delay loop.
xdlp     dex
         bne      xdlp

         ldx      xpos                  ;Get and increment indexes
         inx
         inx
         inx
         inx
         ldy      ypos                  ;All three runs done ?
         beq      final                 ; Yes.
         cpx      #12                   ; No. Third shape in this run ?
         bmi      exlp                  ;  No, draw next shape.
         ldx      #0                    ; Yes, start with first shape again.
         dey                            ; Next run.
         phy
         phx
         jsr      PlayCann
         plx
         ply
         bra      exlp                  ; Start next run.
final    cpx      #16                   ;Ensure at end of third run.
         bmi      exlp                  ;No, finish it.

         lda      #118                  ;Set up coords for little ships in
         ldx      ships                 ;menu bar.
         clc
xlop     adc      #12
         dex
         bne      xlop

         pha                            ;Turn mouse off while drawing on
         pea      0                     ;menu bar.

         _HideCursor

         lda      #EXW                  ;Get little explosion parms.
         sta      SWidth
         lda      #10
         sta      SHeight

         lda      BARCPnt+4             ;Set up little explosion pointers.
         sta      SImage
         lda      BARCPnt+6
         sta      SImage+2

         lda      #$ffff                ;No collision detection.
         sta      SCollin

         stz      SMask                 ;No masking.

         jsr      DRSprite              ;Draw the little explosion in menu bar.

         _InitCursor                    ;Re-activate mouse.

         dec      ships                 ;Decrease the number of ships left.

         rts

         end

;................................................................
;
; DrwAlien.
; ~~~~~~~~~
; Looks at the alien index, and calls the correct sprite routine
; to draw the alien.
;................................................................

drwalien start

         using    SHData

         phx
         cpx      #20                   ;Row 1 ?
         bpl      notr1                 ; No.
         jsr      DRAT                  ; Yes, draw top type.
         bra      findrw
notr1    cpx      #40                   ;Row 2 ?
         bpl      notr2                 ; No, draw bottom type.
         jsr      DRAM                  ; Yes, draw middle type.
         bra      findrw
notr2    jsr      DRAB

findrw   plx
         rts

         end

;................................................................
;
; ChkStat.
; ~~~~~~~~
; Checks the status of an alien (pointed to by X register).
; If exploding, it's explosion is drawn.  If ok, then returns
; with carry clear.  If exploding or dead, carry is set.
;................................................................

chkstat  start

         using    GMData
         using    SHData

         lda      Row1s,x               ;Get status of alien.
         cmp      #$4                   ;Is it ok ?
         beq      notexpl               ; Yes, return.
         cmp      #$3                   ; No, is it already dead ?
         beq      deactiv               ;  Yes, no explosion.

         inc      a                     ;  No, increment status.
         sta      Row1s,x
         cmp      #$3                   ;  Dead now ?
         beq      nodraw                ;   Yes, skip.

         phx                            ;   No, draw explosion.
         jsr      DREX
         plx

nodraw   sec                            ;Alien is exploding.
         rts

deactiv  sec                            ;Alien is dead.
         rts

notexpl  lda      Row1y,x               ;Get aliens Y coord.
         cmp      #180                  ;Has it reached the bottom ?
         bmi      StilAbov              ; No.
         stz      Ships                 ; Yes. Game over.
StilAbov clc                            ;Alien is ok.
         rts

         end

;................................................................
;
; Movem.
; ~~~~~~
; This is the main entry point from the main event loop.  It moves
; all of the aliens.
;................................................................

Movem    start

         using    SHData
         using    GMData

Morethn1 lda      dirctn                ;Get current direction.
         bne      MM1                   ; Move right.
         jsr      Moveml                ;Move left.
         bra      MM2
MM1      jsr      Movemr                ;Move right.

MM2      lda      OneLeft
         beq      Grtr1
         dec      LastCntr
         bne      Grtr1
         lda      #10
         sta      LastCntr
         jsr      Movemd
Grtr1    jsr      UPPos                 ;Update positions.
         ldx      SHIndx                ;Get Shape index for aliens and
         inx                            ;increase.
         cpx      #$4
         bne      MM3
         ldx      #$0

MM3      stx      SHIndx                ;Save new index.

         lda      ships                 ;Get number of ships.
         bne      notfin                ; Some left, continue game.
         jsr      InitDemo              ; None left, start demo mode.
         bra      samefrm               ;Exit.

notfin   lda      noaliens              ;Any aliens left ?
         beq      samefrm               ; Yes, continue with this frame.
         jsr      InitScrn              ; No, bring up a new frame.

samefrm  rts                            ;Return to main event loop.

         end

;................................................................
;
; MovemR.
; ~~~~~~~
; Moves all aliens right one pixel.
;................................................................

Movemr   start

         using    SHData

         ldx      #78                   ;Start at top of array.
MMloop   inc      Row1x,x               ;Move one right.
         dex                            ;Go to next alien.
         dex
         bpl      MMloop                ;Continue loop.

         lda      rgtcol                ;Get rightmost columns X coordinate
         dec      a                     ;and check to see if it has reached
         asl      a                     ;the edge of the screen.
         tax
         lda      Row1x,x
         cmp      #290
         bne      MMend                 ;Not at edge.
         stz      dirctn                ;At edge, change direction and
         jsr      Movemd                ; move down one line.

MMend    rts                            ;exit.

         end

;................................................................
;
; MovemL.
; ~~~~~~~
; Move all aliens left one pixel.
;................................................................

Moveml  start

         using    SHData

         ldx      #78                   ;Start at top of array.
MMloop2  dec      Row1x,x               ;Move it left one.
         dex
         dex
         bpl      MMloop2               ;Complete ?

         lda      lftcol                ;Get x coord of leftmost column, and
         dec      a                     ;check to make sure it hasnt reached
         asl      a                     ;the edge of the screen.
         tax
         lda      Row1x,x
         cmp      #2
         bne      MMend2                ;Not at the edge.
         inc      dirctn                ;At the edge, change direction and
         jsr      Movemd                ;move them down one pixel.

MMend2   rts

         end

;................................................................
;
; MovemD.
; ~~~~~~~
; Moves all aliens down one pixel.
;................................................................

Movemd   start

         using    SHData

         ldx      #78                   ;Start at top of array.
MMloop3  inc      Row1y,x               ;Move down one.
         dex
         dex
         bpl      MMloop3               ;Complete ?

         rts

         end

;................................................................
;
; Dispatch.
; ~~~~~~~~~
; A common entry point for any alien drawing calls.  It will only
; call up the drawing routines if there are some aliens left to
; draw.
;................................................................

Dispatch start

         using    SHData

         lda      noaliens              ;Any left ?
         bne      dontdraw              ; No, don't draw.

         jmp      DRSprite              ; Yes, draw this alien.

dontdraw pla                            ;Get return address.
         plx                            ;Get rid of unwanted parameters.
         plx
         pha                            ;Put return address back.

         rts                            ;Return to caller as if the sprite had
;                                        been drawn.

         end

;................................................................
;
; DRAB.
; ~~~~~
; Draws a bottom alien.
;................................................................

DRAB     start

         using    SHData
         using    ABS

         lda      #ABSW                 ;Get Shape dimensions.
         sta      SWidth
         lda      #ABSH
         sta      SHeight

         lda      SHIndx                ;Determine shape pointer.
         asl      a
         asl      a
         tax
         lda      ABSPnt,x
         sta      SImage
         lda      ABSPnt+2,x
         sta      SImage+2

         lda      xpos                  ;Get shapes coords.
         pha
         lda      ypos
         pha

         lda      #$ffff                ;No collision detection.
         sta      SCollin

         stz      SMask                 ;No masking.

         jsr      Dispatch              ;Dispatch to the drawer.

         clc                            ;Return.
         rts

         end

;................................................................
;
; DRAM.
; ~~~~~
; Draws a middle alien.
;................................................................

DRAM     start

         using    SHData
         using    AMS

         lda      #AMSW                 ;Get shape dimensions.
         sta      SWidth
         lda      #AMSH
         sta      SHeight

         lda      SHIndx                ;Determine shape pointer.
         asl      a
         asl      a
         tax
         lda      AMSPnt,x
         sta      SImage
         lda      AMSPnt+2,x
         sta      SImage+2

         lda      xpos                  ;Get coords.
         pha
         lda      ypos
         pha

         lda      #$ffff                ;No collision detection.
         sta      SCollin

         stz      SMask                 ;No masking.

         jsr      Dispatch              ;Draw the alien.

         clc
         rts

         end

;................................................................
;
; DRCN.
; ~~~~~
; Draws the canon.
;................................................................

DRCN     start

         using    SHData
         using    CNS
         using    MIS

         lda      #CNSW                 ;Get canon dimensions.
         sta      SWidth
         lda      #CNSH
         sta      SHeight

         lda      CNIndx                ;Determine shape pointer, based on
         asl      a                     ;whether it is on an ODD or EVEN
         asl      a                     ;X coordinate.
         tax

         lda      canonx
         ror      a
         bcc      evenx

         lda      CNSPnt2,x
         sta      SImage
         lda      CNSPnt2+2,x
         sta      SImage+2
         bra      goover

evenx    lda      CNSPnt1,x
         sta      SImage
         lda      CNSPnt1+2,x
         sta      SImage+2

goover   lda      canonx                ;Get canon coords.
         pha
         lda      #170
         pha

         lda      #$ffff                ;No collision detection.
         sta      SCollin

         stz      SMask                 ;No masking.

         jsr      DRSprite              ;Draw the canon.

         rts

         end

;................................................................
;
; DRMO.
; ~~~~~
; Draws the mother ship.
;................................................................

DRMO     start

         using    SHData
         using    MOS

         lda      #MOSW                 ;Get mother ship dimensions.
         sta      SWidth
         lda      #MOSH
         sta      SHeight

         lda      Mothers               ;Get mothership index.
         sec
         sbc      #4
         asl      a
         asl      a
         tax

         lda      motherx               ;Determine pointer to image, depending
         ror      a                     ;on the X coord.
         bcc      evenx

         lda      MOSPnt2,x
         sta      SImage
         lda      MOSPnt2+2,x
         sta      SImage+2
         bra      goover

evenx    lda      MOSPnt1,x
         sta      SImage
         lda      MOSPnt1+2,x
         sta      SImage+2

goover   lda      motherx               ;Get mothers coords.
         pha
         lda      #17
         pha

         lda      #$ffff                ;No collision detection.
         sta      SCollin

         stz      SMask                 ;No masking.

         jsr      Dispatch              ;Draw it.

         rts

         end

;................................................................
;
; DRMS.
; ~~~~~
; Draws a missile.
;................................................................

DRMS     start

         using    SHData
         using    MIS

         lda      #MISW                 ;Get missile dimensions.
         sta      SWidth
         lda      #MISH
         sta      SHeight

         lda      MissCx                ;Determine pointer, dependant upon the
         ror      a                     ;missiles X coordinate.
         bcs      evenx

         lda      MISPnt2
         sta      SImage
         lda      MISPnt2+2
         sta      SImage+2
         bra      goover

evenx    lda      MISPnt1
         sta      SImage
         lda      MISPnt1+2
         sta      SImage+2

goover   lda      MissCx                ;Get missile coords.
         pha
         lda      MissCy
         pha

         lda      #$0000                ;Collision detection on top line of
         sta      SCollin               ; image.

         stz      SMask                 ;No masking.

         jsr      DRSprite              ;Draw it.

         rts

         end

;................................................................
;
; DRBS.
; ~~~~~
; Draws a bomb.
;................................................................

DRBS     start

         using    SHData
         using    BMS

         lda      #BMSW                 ;Get bomb dimensions.
         sta      SWidth
         lda      #BMSH
         sta      SHeight

         lda      BombSt,x              ;Determine it's index.
         sec
         sbc      #4
         asl      a
         asl      a
         tay

         lda      xpos                  ;Determine pointer based on ODDity of
         ror      a                     ;X coord of bomb.
         bcc      evenx

         tyx
         lda      BMSPnt2,x
         sta      SImage
         lda      BMSPnt2+2,x
         sta      SImage+2
         bra      goover

evenx    tyx
         lda      BMSPnt1,x
         sta      SImage
         lda      BMSPnt1+2,x
         sta      SImage+2

goover   lda      xpos                  ;Get coords.
         pha
         lda      ypos
         pha

         lda      #10                   ;Collision detection on line 10 of
         sta      SCollin               ; image.

         stz      SMask                 ;No masking.

         jsr      DRSprite              ;Draw it.

         rts

         end

;................................................................
;
; DRMX.
; ~~~~~
; Draws a missile explosion.
;................................................................

DRMX     start

         using    SHData
         using    MXS

         lda      MissSt                ;Get missile image index.
         asl      a
         asl      a
         tax

         lda      #MXSW                 ;Get missile explosion dimensions.
         sta      SWidth
         lda      #MXSH
         sta      SHeight

         lda      MissCx                ;Determine pointer based on X coord.
         ror      a
         bcs      evenx

         lda      MXSPnt2,x
         sta      SImage
         lda      MXSPnt2+2,x
         sta      SImage+2
         bra      goover

evenx    lda      MXSPnt1,x
         sta      SImage
         lda      MXSPnt1+2,x
         sta      SImage+2

goover   lda      xpos                  ;Get coords.
         pha
         lda      ypos
         pha

         lda      #$ffff                ;No collision detection. (Too late for
         sta      SCollin               ; that)

         lda      #2                    ;Use masking to draw image within a
         sta      SMask                 ; background that has been prepared by
;                                       ; DRMM (see below).

         jsr      DRSprite              ;Draw it.

         rts

         end

;................................................................
;
; DRMM.
; ~~~~~
; Masks a missile explosion.
;................................................................

DRMM     start

         using    SHData
         using    MXS

         lda      MissSt                ;Determine missile image index.
         asl      a
         asl      a
         tax

         lda      #MXSW                 ;Get dimensions of explosion mask.
         sta      SWidth
         lda      #MXSH
         sta      SHeight

         lda      MissCx                ;Determine pointer.
         ror      a
         bcs      evenx

         lda      MMSPnt2,x
         sta      SImage
         lda      MMSPnt2+2,x
         sta      SImage+2
         bra      goover

evenx    lda      MMSPnt1,x
         sta      SImage
         lda      MMSPnt1+2,x
         sta      SImage+2

goover   lda      xpos                  ;Get coords.
         pha
         lda      ypos
         pha

         lda      #$ffff                ;No collision detection.
         sta      SCollin

         lda      #1                    ;Mask out an area so that when the
         sta      SMask                 ;explosion is draw, it doesn't take
;                                        out an ugly square block.

         jsr      DRSprite

         rts

         end

;................................................................
;
; DRBX.
; ~~~~~
; Draws a bomb explosion.
;................................................................

DRBX     start

         using    SHData
         using    MXS

         lda      BombSt,x              ;Get bomb image index.
         asl      a
         asl      a
         tay

         lda      #MXSW                 ;Get bomb explosion dimensions.
         sta      SWidth
         lda      #MXSH
         sta      SHeight

         lda      xpos                  ;Determine pointer.
         ror      a
         bcc      evenx

         tyx
         lda      MXSPnt2,x
         sta      SImage
         lda      MXSPnt2+2,x
         sta      SImage+2
         bra      goover

evenx    tyx
         lda      MXSPnt1,x
         sta      SImage
         lda      MXSPnt1+2,x
         sta      SImage+2

goover   lda      xpos                  ;Get coords.
         pha
         lda      ypos
         pha

         lda      #$ffff                ;No collision detection.
         sta      SCollin

         lda      #2                    ;Use masking to draw image within a
         sta      SMask                 ; background that has been prepared by
;                                       ; DRMM (see below).

         jsr      DRSprite

         rts

         end

;................................................................
;
; DRBM.
; ~~~~~
; Masks a bomb explosion.
;................................................................

DRBM     start

         using    SHData
         using    MXS

         lda      BombSt,x              ;Get bomb image index.
         asl      a
         asl      a
         tay

         lda      #MXSW                 ;Get masks dimensions.
         sta      SWidth
         lda      #MXSH
         sta      SHeight

         lda      xpos                  ;Determine pointer.
         ror      a
         bcc      evenx

         tyx
         lda      MMSPnt2,x
         sta      SImage
         lda      MMSPnt2+2,x
         sta      SImage+2
         bra      goover

evenx    tyx
         lda      MMSPnt1,x
         sta      SImage
         lda      MMSPnt1+2,x
         sta      SImage+2

goover   lda      xpos
         pha
         lda      ypos
         pha

         lda      #$ffff                ;No collision detection.
         sta      SCollin

         lda      #1                    ;Mask out an area so that when the
         sta      SMask                 ;explosion is draw, it doesn't take
;                                        out an ugly square block.

         jsr      DRSprite

         rts

         end

;................................................................
;
; DRAT.
; ~~~~~
; Draws a top alien.
;................................................................

DRAT     start

         using    SHData
         using    ATS

         lda      #ATSW                 ;Get aliens dimensions.
         sta      SWidth
         lda      #ATSH
         sta      SHeight

         lda      SHIndx                ;Determine pointer.
         asl      a
         asl      a
         tax
         lda      ATSPnt,x
         sta      SImage
         lda      ATSPnt+2,x
         sta      SImage+2

         lda      xpos                  ;Get coords.
         pha
         lda      ypos
         pha

         lda      #$ffff                ;No collision detection.
         sta      SCollin

         stz      SMask                 ;No masking.

         jsr      Dispatch              ;Draw it.

         clc
         rts

         end

;................................................................
;
; DRBA.
; ~~~~~
; Draws a barrier.
;................................................................

DRBA     start

         using    SHData
         using    BAS

         lda      #BASW                 ;Get dimensions.
         sta      SWidth
         lda      #BASH
         sta      SHeight

         lda      BASPnt                ;Get pointer.
         sta      SImage
         lda      BASPnt+2
         sta      SImage+2

         lda      xpos                  ;Get coords.
         pha
         lda      ypos
         pha

         lda      #$ffff                ;No collision detection.
         sta      SCollin

         stz      SMask                 ;No masking.

         jsr      DRSprite

         rts

         end

;................................................................
;
; DREX.
; ~~~~~
; Draws an alien exploding.
;................................................................

DREX     start

         using    SHData
         using    EXS

         lda      Row1s,x               ;Get alien status/image index.
         asl      a
         asl      a
         tax

         lda      #EXSW                 ;Get explosion dimensions.
         sta      SWidth
         lda      #EXSH
         sta      SHeight

         lda      xpos                  ;Determine pointer.
         ror      a
         bcc      evenx

         lda      EXSPnt2,x
         sta      SImage
         lda      EXSPnt2+2,x
         sta      SImage+2
         bra      goover

evenx    lda      EXSPnt1,x
         sta      SImage
         lda      EXSPnt1+2,x
         sta      SImage+2

goover   lda      xpos                  ;Get coordinates.
         pha
         lda      ypos
         pha

         lda      #$ffff                ;No collision detection.
         sta      SCollin

         stz      SMask                 ;No Masking.

         jsr      Dispatch              ;Draw it.

         rts

         end

;................................................................
;
; DRMOX.
; ~~~~~
; Draws the mother ship exploding.
;................................................................

DRMOX    start

         using    SHData
         using    MOXS

         lda      Mothers               ;Get mothers status/image index.
         asl      a
         asl      a
         tax

         lda      #MOXSW                ;Get dimensions.
         sta      SWidth
         lda      #MOXSH
         sta      SHeight

         lda      Motherx               ;Determine pointer.
         ror      a
         bcc      evenx

         lda      MOXSPnt2,x
         sta      SImage
         lda      MOXSPnt2+2,x
         sta      SImage+2
         bra      goover

evenx    lda      MOXSPnt1,x
         sta      SImage
         lda      MOXSPnt1+2,x
         sta      SImage+2

goover   lda      motherx               ;Get coordinates.
         pha
         lda      #17
         pha

         lda      #$ffff                ;No collision detection.
         sta      SCollin

         stz      SMask                 ;No masking.

         jsr      Dispatch              ;Draw it.

         rts

         end

;................................................................
;
; IBarrier.
; ~~~~~~~~~
; Draws the four shelters/barriers on the screen.
;................................................................

Ibarrier start

         using    SHData
         using    BAS

         lda      #125                  ;Y coord is 125.
         sta      ypos

         lda      #20                   ;Start at X = 20.
IBloop   sta      xpos                  ;Preserve it.
         pha

         jsr      DRBA                  ;Draw a barrier.

         pla                            ;Get the X value back.

         clc                            ;Add 80 to it for next barrier.
         adc      #80
         cmp      #340                  ;All done ?
         bne      IBloop                ; No. Do next one.

         rts

         end

;................................................................
;
; DoMother.
; ~~~~~~~~~
; If mother is inactive, then get a random number to see if it
; should be activated.
;
; I mother is already active, then animate it.
;................................................................

domother start

         using    SHData
         using    GMData

         lda      Mothers               ;Get mother ships status.
         cmp      #3                    ;Dead ?
         bne      moving                ; No.  Animate it.

         pea      $0000                 ; Yes, get a random number.
         _Random
         pla

         and      #$ffff                ;Enforce a 16 bit number.
         cmp      #1000                 ;Is it in the range 1000 < X < 1100 ?
         bmi      dontactv              ; No. Dont activate.
         cmp      #1100                 ; Maybe.
         bpl      dontactv              ; No, dont activate.

         lda      #288                  ; Yes, initialise coordinates.
         sta      Motherx
         lda      #4                    ;Start up mother ship.
         sta      Mothers
         lda      #-1                   ;Set initial direction to leftwards.
         sta      Motherd
         lda      #100                  ;Set initial bonus.
         sta      bonus
         stz      colore                ;Set background colour.
dontactv rts

explode  jsr      DRMOX                 ;Draw mother ship explosion.
         inc      Mothers               ;Increment mother ships status.
         rts

moving   cmp      #4                    ;Is the mother ship exploding ?
         bmi      explode               ; Yes.  Draw explosion.
         jsr      DRMO                  ; No. Draw mother ship.
         lda      Mothers               ;Get mother ships status.
         inc      a                     ;Increment to next image.
         cmp      #9                    ;Last image ?
         bne      itsok                 ; No. Skip.
         lda      #4                    ; Yes, set to first image.
itsok    sta      Mothers               ;Save new status.
         lda      Motherx               ;Get X coord.
         clc                            ;Move one pixel in the correct
         adc      Motherd               ;direction.
         cmp      #-1                   ;At left of screen ?
         bne      notleft               ; No, check right.
TurnOff  lda      #2                    ; Yes, set status to clear mother from
         sta      Mothers               ;screen.
         stz      bonus                 ;Zero score.
         stz      colore                ;Set background to black.
         bra      nomove                ;Dont move the mother ship.
notleft  cmp      #289                  ;At right of screen ?
         bpl      TurnOff               ; Yes, shutdown mother ship.

         sta      Motherx

nomove   pea      $0000                 ;Get a random number.
         _Random
         pla

         cmp      #1000                 ;Within the range 500 < X < 1000 ?
         bpl      nochange
         cmp      #500
         bmi      nochange
         lda      #1
         cmp      Motherd
         bne      savedir
         lda      #-1
savedir  sta      Motherd
         lda      colore
         clc
         adc      #$0301
         sta      colore

         lda      #100
         clc
         adc      bonus
         sta      bonus
         cmp      #0600
         bne      nochange

         stz      Mothers
         stz      colore
         stz      bonus

nochange lda      colore

         pea      0
         pea      0
         pha
         _SetColorEntry

         rts

         end

domissl  start

         using    SHData
         using    MIS

         lda      MissSt
         cmp      #3
         beq      notfired
         cmp      #4
         beq      firing
         inc      a
         sta      MissSt
         cmp      #3
         beq      notfired
         lda      MissCx
         dec      a
         sta      xpos
         lda      MissCy
         dec      a
         dec      a
         sta      ypos
         jsr      DRMM
         jsr      DRMX
         rts

firing   lda      MissCy
         cmp      #21
         bpl      stilfire
         lda      #$ffff
         sta      MissSt
         rts

stilfire dec      a
         dec      a
         dec      a
         sta      MissCy
         jsr      DRMS
         lda      SColisn
         beq      notfired
         lda      #$ffff
         sta      MissSt
         jsr      detalien
         jsr      PlayExpl
notfired rts

         end


dojoy    start

         using    SHData

         pea      $0000
         pea      $0000
         pea      $0000
         pea      $0000
         pea      $0000
         pea      $0000
         pea      $0000
         pea      $fb1e
         _FWEntry
         pla
         ply
         ply
         ply

         and      #$00ff
         cmp      #80
         bpl      notleft
         lda      canonx
         beq      noanim
         dec      a
         sta      canonx
         bra      finpad

notleft  cmp      #160
         bmi      finpad
         lda      canonx
         cmp      #299
         beq      finpad
         inc      a
         sta      canonx

finpad   jsr      DRCN

         ldx      CNIndx
         inx
         cpx      #$4
         bne      im
         ldx      #$0

im       stx      CNIndx

noanim   rts

         end

detalien start

         using    SHData
         using    GMData

         ldx      #0
         lda      MissCy
         cmp      #35
         bpl      notmoth
         lda      MissCx
         cmp      Motherx
         bmi      notalien
         sec
         sbc      #30
         cmp      Motherx
         bpl      notalien
         stz      Mothers
         lda      bonus
         jsr      addscore
         lda      #1000
         jsr      addscore
         stz      bonus
         rts

notmoth  ldy      #0
coloop   lda      MissCx
         cmp      Row1x,x
         bmi      notalien
         lda      Row1x,x
         clc
         adc      #24
         cmp      MissCx
         bpl      gotcol
         inx
         inx
         iny
         cpy      #10
         bne      coloop

notalien rts

gotcol   phy
         ldy      #0
rowloop  lda      MissCy
         cmp      Row1y,x
         bmi      notal2
         lda      Row1y,x
         clc
         adc      #12
         cmp      MissCy
         bpl      gotrow
         clc
         txa
         adc      #20
         tax
         iny
         cpy      #4
         bne      rowloop

notal2   ply
         rts

gotrow   lda      Row1S,x
         cmp      #4
         bne      notal2
         lda      #$ffff
         sta      Row1S,x
         stx      LastIndx

         cpy      #0
         bne      notone
         lda      #200
notone   cpy      #1
         bne      nottwo
         lda      #150
nottwo   cpy      #2
         bne      notthree
         lda      #100
notthree cpy      #3
         bne      notfour
         lda      #50
notfour  clc
         adc      bonus

         jsr      addscore

         ply
         tya
         asl      a
         tax
         dec      Colnum,x
         bne      stilsome
         tya
         inc      a
         cmp      lftcol
         bne      chkrgt
         inc      lftcol
chklft   lda      lftcol
         cmp      #11
         beq      nomore
         dec      a
         asl      a
         tax
         lda      Colnum,x
         bne      gotlft
         inc      lftcol
         bra      chklft

chkrgt   cmp      rgtcol
         bne      gotrgt
         dec      rgtcol
chkrgtl  lda      rgtcol
         beq      nomore
         dec      a
         asl      a
         tax
         lda      Colnum,x
         bne      gotrgt
         dec      rgtcol
         bra      chkrgtl

nomore   lda      starty
         clc
         adc      #3
         sta      starty
         inc      noaliens
         rts

gotlft   anop
gotrgt   lda      lftcol
         cmp      rgtcol
         bne      stilsome
         lda      Colnum,x
         cmp      #2
         bpl      stilsome
         inc      OneLeft
         ldx      #78
fndlst   lda      Row1s,x
         cmp      #4
         beq      SaveX
         dex
         dex
         bra      fndlst
SaveX    stx      LastIndx
stilsome jsr      setbomby

         rts

         end

setbomby start

         using    SHData

         lda      #0
         tay
stby     tax
stby1    lda      Row1s,x
         cmp      #4
         bne      nothere
         lda      Row1y,x
         tay
nothere  txa
         clc
         adc      #20
         cmp      #80
         bmi      stby
         sec
         sbc      #80
         tax
         tya
         clc
         adc      #12
         sta      BombSY,x
         ldy      #0
         inx
         inx
         cpx      #20
         bmi      stby1

         rts

         end

addscore start

         using    GMData

         clc
         adc      score+2
         bcc      nocarry
         inc      score
nocarry  sta      score+2

         jsr      doscore

         rts

         end

doscore  start

         using    GMData
         using    SHData
         using    SCRData

         lda      score
         pha
         lda      score+2
         pha
         pea      scrs|-16
         pea      scrs
         pea      6
         pea      0
         _Long2Dec

         pea      60
         pea      9
         _MoveTo

         pea      scrtxt|-16
         pea      scrtxt
         _DrawString

         rts

         end


SCRData  data

scrtxt   dc       i1'scrend-scrs'
scrs     dc       C'       '
scrend   anop

bontxt   dc       i1'bonend-bons'
bons     dc       c'Bonus : '
bonstr   dc       c'      '
bonend   anop

         end

SHData   data

cols     equ      10

SHeight  ds       2
SWidth   ds       2
SImage   ds       4
SCollin  ds       2
SColisn  ds       2
SMask    ds       2

SHIndx   ds       2
CNIndx   ds       2
xpos     ds       2
ypos     ds       2
incval   ds       2

lftcol   ds       2
rgtcol   ds       2
dirctn   ds       2
canonx   ds       2

Row1x    ds       10*2                  ;X coords for aliens.
Row2x    ds       10*2
Row3x    ds       10*2
Row4x    ds       10*2
Row5x    ds       10*2

Row1y    ds       10*2                  ;Y coords for aliens.
Row2y    ds       10*2
Row3y    ds       10*2
Row4y    ds       10*2
Row5y    ds       10*2

Row1s    ds       10*2                  ;Status for aliens.
Row2s    ds       10*2
Row3s    ds       10*2                  ;3    - Dont draw.
Row4s    ds       10*2                  ;0..2 - Exploding.
Row5s    ds       10*2                  ;4    - Normal.

Colnum   ds       10*2

BombSY   ds       10*2                  ;Initial Y value for bomb.

BombCx   ds       10*2
BombCy   ds       10*2
BombSt   ds       10*2                  ;Bomb status.
;                                        3    - none.
;                                        4..6 - dropping.
;                                        0..2 - Exploding.

MissCx   ds       2
MissCy   ds       2
MissSt   ds       2                     ;Missile status.
;                                        3    - not fired.
;                                        4    - firing.
;                                        0..2 - Exploding.

Motherx  ds       2
Motherd  ds       2
Mothers  ds       2                     ;Mother status.
;                                        3    - Inactive.
;                                        4..8 - Moving.
;                                        0..2 - Exploding.

colore   ds       2

noaliens ds       2

LastIndx ds       2                     ;Pointer to last alien on screen.
OneLeft  ds       2                     ;Flag. 1 - Only one alien left.
;                                              0 - More than one left.
LastCntr ds       2

         end
