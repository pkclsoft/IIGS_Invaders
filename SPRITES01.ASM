;...............................................................
;
; Sprites library.
; ~~~~~~~~~~~~~~~~
;................................................................

         absaddr on
         keep sprites

;................................................................
;
; ITable
; ~~~~~~
; Initialise the line start table, which contains the address in
; memory that each super hires line starts.  (Note we are talking
; about the pixel map here.  The SCB's we shall leave to
; Quickdraw II unless it appears to be too slow also.
;................................................................


ITable   start

         using GLData

         ldx   #0
         lda   #$2000
ITloop   sta   Lstart,x
         inx
         inx
         clc
         adc   #$00a0
         cpx   #199*2
         bne   ITloop
         rts
         end

;................................................................
;
; LOffset
; ~~~~~~~
; LOffset determines the address in memory that the sprite starts
; at for a particular line of the sprite.
;
; The formula is as follows :
;
;        LineOffset = Lstart[Line number] + (Xcoordinate / 2)   (2 bytes)
;
;     where Lstart[Line number] is one entry in the Lstart table
;     pointing to the first byte of the appropriate line on the
;     super hires screen.
;
; LOffset is passed two parameters via the stack, in order :
;
;        Line Number : Y coordinate on the screen.              (2 bytes)
;        Pixel       : X coordinate on the screen.              (2 bytes)
;................................................................


LOffset  start

         using GLData

         ply                            ;Preserve return address.

         pla                            ;Get Line number from stack.

         asl   a                        ;Produce index into Lstart.
         tax                            ;Put into index register.
         pla                            ;Get the x coordinate.
         lsr   a                        ;Divide by two.
         clc                            ;Prepare for addition
         adc   Lstart,x                 ;Produce result value.
         pha                            ;Put the result on the stack.
         phy
         rts
         end

;................................................................
;
; DLine.
; ~~~~~~
; DLine will put one line of the sprite on the screen.
;
; It comes in four versions as follows :
;
;   DLine      : Does a direct transfer, no funny business.
;   DLineCol   : Does collision detection as well.
;   DLineAND   : AND's the pattern onto the screen.
;   DLineOR    : OR's the pattern onto the screen.
;
; The last two are used when we want to preseve the background in detail
; around the shape.  Special patterns are needed for these to work.
;................................................................

DLine    start

         using GLData
         using SHData
         using MAData

         lda   Addr                     ;Get source address.
         sta   3                        ;Store it in DP for speed in
;                                        the actual transfer.

         lda   SCOffset                 ;Put the screen address in the DP
         sta   6                        ;also.  Note it is a long word
         ldy   #$01                     ;pointing to bank $01.
         sty   8


         lda   SWidth                   ;Get sprites width in bytes.
         lsr   a                        ;Multiply by two as we are transfering
         tay                            ;a word at a time.

DLLoop   lda   (3)                      ;Get a word.
         sta   [6]                      ;Store it.

         inc   6                        ;Increment pointers.
         inc   6
         inc   3
         inc   3

         dey                            ;Decrement word counter.
         bne   DLLoop                   ;If unfinished, go back.

         rts

         end

;................................................................
;
; DLineCol.
; ~~~~~~~~~
; Handles collision detection by OR'ing the contents of the screen
; (before drawing) with SCOLISN, thus if anything was there, SCOLISN
; will be non-zero after the transfer.
;................................................................

DLineCol start

         using GLData
         using SHData
         using MAData

         lda   Addr                     ;Get source address.
         sta   3                        ;Store it in DP for speed in
;                                        the actual transfer.

         lda   SCOffset                 ;Put the screen address in the DP
         sta   6                        ;also.  Note it is a long word
         ldy   #$01                     ;pointing to bank $01.
         sty   8


         lda   SWidth                   ;Get sprites width in bytes.
         lsr   a                        ;Multiply by two as we are transfering
         tay                            ;a word at a time.


DLLoop   lda   [6]                      ;Get current screen contents.
         tsb   SColisn                  ;OR and STORE it at SColisn
         lda   (3)                      ;Get shape value.
         sta   [6]                      ;Store it.

         inc   6                        ;Increment pointers.
         inc   6
         inc   3
         inc   3

         dey
         bne   DLLoop

         rts

         end

;................................................................
;
; DLineAND.
; ~~~~~~~~~
; AND the pattern with the current contents of the screen before
; storing it.
;................................................................

DLineAND start

         using GLData
         using SHData
         using MAData

         lda   Addr                     ;Get source address.
         sta   3                        ;Store it in DP for speed in
;                                        the actual transfer.

         lda   SCOffset                 ;Put the screen address in the DP
         sta   6                        ;also.  Note it is a long word
         ldy   #$01                     ;pointing to bank $01.
         sty   8


         lda   SWidth                   ;Get sprites width in bytes.
         lsr   a                        ;Multiply by two as we are transfering
         tay                            ;a word at a time.

DLLoop   lda   (3)                      ;Get pattern data.
         and   [6]                      ;AND it.
         sta   [6]                      ;Store it.

         inc   6                        ;Increment pointers.
         inc   6
         inc   3
         inc   3

         dey
         bne   DLLoop

         rts

         end

;................................................................
;
; DLineOR.
; ~~~~~~~~
; OR the pattern with the current contents of the screen before
; storing it.
;................................................................


DLineOR  start

         using GLData
         using SHData
         using MAData

         lda   Addr                     ;Get source address.
         sta   3                        ;Store it in DP for speed in
;                                        the actual transfer.

         lda   SCOffset                 ;Put the screen address in the DP
         sta   6                        ;also.  Note it is a long word
         ldy   #$01                     ;pointing to bank $01.
         sty   8


         lda   SWidth                   ;Get sprites width in bytes.
         lsr   a                        ;Multiply by two as we are transfering
         tay                            ;a word at a time.


DLLoop   lda   (3)                      ;Get pattern data.
         eor   [6]                      ;Exclusive or it.
         sta   [6]                      ;Store it.

         inc   6                        ;Increment pointers.
         inc   6
         inc   3
         inc   3

         dey
         bne   DLLoop

         rts

         end

;................................................................
;
; DRSprite.
; ~~~~~~~~
; DRSprite will draw a sprite on the SHR screen in 320*200 mode.
; It takes two parameters from the caller, which are passed
; via the stack, as follows :
;
;        Xcoordinate : X position on the SHR screen.            (2 bytes)
;        Ycoordinate : Y position on the SHR screen.            (2 bytes)
;
; A Sprite Record uses the following format :
;
;        Height   : Word sized integer, number of pixels high.  (2 bytes)
;        Width    : Word sized integer, width in bytes.         (2 bytes)
;        Image    : Pointer to Sprite image.                    (4 bytes)
;        Collin   : Line on which to do collision detection.    (2 bytes)
;        Colisn   : Flag indicating if a collision occured.     (2 bytes)
;        Mask     : Flag indicating if masking is to be used.   (2 bytes)
;................................................................

DRSprite start

         using MAData
         using SHData

         plx                            ;Preserve return address.

         stz   SColisn                  ;Zero collision flag.
         lda   SImage                   ;Get image address.
         sta   Addr                     ;Save it.

         pla                            ;Get the Y coordinate.
         sta   Line                     ;Set initial value of Line.
         sta   Ycoord                   ;Save for end of loop check.

         pla                            ;Get the X coordinate.
         sta   Xcoord                   ;Save it.

         phx                            ;Put return address back on stack.

mloop    lda   Line                     ;Get current line being drawn on.
         cmp   #199                     ;Make sure we aren't drawing below
         bpl   findraw                  ;the physical screen.

         lda   Xcoord                   ;Set up parms for LOffset call.
         pha
         lda   Line
         pha
         jsr   LOffset                  ;Calculate screen address.
         pla                            ;Get result.
         sta   SCOffset

         lda   Smask                    ;Are we masking to the screen ?
         beq   notmask                  ; No.  Do normal transfer.
         cmp   #1                       ; Yes. AND mask this call ?
         beq   doand                    ;      Yes.
         jsr   DLineOR                  ;      No.  OR mask this call.
         bra   mloopchk                 ;           Go on with loop.

doand    jsr   DLineAND                 ;Call up AND routine.
         bra   mloopchk                 ;Go on with loop.

notmask  lda   SCollin                  ;Collision detection on this line ?
         bne   donorm                   ; No.  Do normal transfer.
         jsr   DLineCol                 ; Yes. Do collision detection.
         bra   mloopchk                 ;      Go on with loop.

donorm   jsr   DLine                    ;Normal transfer.

mloopchk lda   Addr                     ;Increment Addr to point at the
         clc                            ;next lines peice of data.
         adc   SWidth
         sta   Addr

         dec   SCollin                  ;Decrement collision line counter.

         inc   Line                     ;Move down the screen one line.
         lda   Line                     ;Now check if we have drawn all of
         sec                            ;the shape.
         sbc   Ycoord
         cmp   SHeight
         bne   mloop                    ; No.  More to go.
findraw  rts                            ; Yes. Return back to caller.

         end

GLData   data

Lstart   ds    199*2                    ;Table of screen line addresses.

         end

MAData   data

Addr     ds    2                        ;Temorary pointer to current data.
Line     ds    2                        ;Current line being drawn on.
Xcoord   ds    2                        ;Xcoordinate of sprite.
Ycoord   ds    2                        ;Ycoordinate of sprite.
SCOffset ds    2                        ;Memory location of screen.

         end
