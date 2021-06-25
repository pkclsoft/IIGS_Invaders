;................................................................
;
; Invade.
; ~~~~~~~
; A space invaders game for the Apple //GS.
;................................................................

         absaddr  on
         keep     invade

         mload    invade.macro          ;Get macro's

boot     start
         jmp      main                  ;Start things off.
         end

;................................................................
;
; System Data Definitions
; ~~~~~~~~~~~~~~~~~~~~~~~
;................................................................

TDData   data

handle   ds       4                     ;Handle to direct page memory block.
userid   ds       2                     ;The programs user id.
dpage    ds       2                     ;Actual direct page address.

Qparams  dc       i4'$0'                ;ProDOS 16 QUIT parameters.
         dc       i'$0000'

Event    anop                           ;Event manager record.
Ewhat    ds       2                     ;The event type.
Emsg     ds       4                     ;Type specific details.
Ewhen    ds       4                     ;Time of occurrence.
Ewhere   ds       4                     ;Mouse location at event time.
Emods    ds       2                     ;Modifiers.

ToolRec  dc       i2'2'
         dc       i2'8'                 ;Load sound manager.
         dc       i2'0'
         dc       i2'25'                ;Note Synthesizer.
         dc       i2'0'

         end

;................................................................
;
; Startup
; ~~~~~~~
; Startup will start up all of the required tools, and get a
; user id for this program for the duration of it's execution.
;................................................................

Startup  start

         using    TDData

         _TLStartUp                     ;Start the Tool Locator.

         pha
         _MMStartUp                     ;Start the Memory Manager.

         pla                            ;Get our user id.
         sta      userid

         _MTStartUp                     ;Start the Miscellaneous Tools.

         PushLong #$00000000            ;Reserve 4 pages of direct page
         PushLong #$00000500            ;memory for both Quickdraw (3 pages)
         lda      userid                ;the Event Manager (1 page),
         pha                            ;and the note synthesizer (1 page).
         PushWord #$c005
         PushLong #$00000000

         _Newhandle                     ;Allocate the block.

         pla                            ;Get the handle back from the
         sta      0                     ;stack.
         sta      handle
         pla
         sta      2
         sta      handle+2
         lda      [0]                   ;Get the actual address of the
         sta      dpage                 ;first direct page and save it.

         pha
         pea      $0000
         pea      $0000
         lda      userid
         pha

         _QDStartUp                     ;Start Quickdraw II.

         lda      dpage                 ;Tell the Event Manager about it's
         clc                            ;direct page.
         adc      #$300
         pha
         pea      $0014                 ;Twenty queue entries.
         pea      $0000                 ;Min X for mouse.
         pea      $0140                 ;Max X.
         pea      $0000                 ;Min Y.
         pea      $0001                 ;Max Y.
         lda      userid                ;Who we are.
         pha

         _EMStartUp                     ;Start the Event Manager.

         _IMStartUp                     ;Start up the IntMath toolset.

         pea      $0000                 ;Get current tick counter, to
         pea      $0000                 ;use a a seed to the random
         _GetTick                       ;number generator.  This should
         _SetRandSeed                   ;give us a new set each time we
;                                        start the program up.

         jsr      GenRand               ;Generate random waveform.

         pea      ToolRec|-16
         pea      ToolRec
         _LoadTools

         lda      dpage                 ;Tell the Sound Manager about it's
         clc                            ;direct page.
         adc      #$400
         pha
         _SoundStartUp                  ;Start the Sound Manager.

         jsr      CopyWave              ;Copy the waves to the DOC.

         pea      150
         pea      0
         pea      0
         _NSStartUp                     ;Start the note synthesizer.

         rts

         end

;................................................................
;
; Shutdown
; ~~~~~~~~
; Shutdown will shut down all of the tools started in Startup. It
; will then quit the program by executing the Prodos 16 Quit call.
;................................................................

Shutdown start

         using    TDData

         _GrafOff                       ;Turn off the graphics screen.
         _NSShutDown                    ;Note synthesizer.
         _SoundShutDown                 ;Sound Manager.
         _IMShutdown                    ;IntMath.
         _EMShutDown                    ;Event Manager.
         _QDShutDown                    ;Quick Draw II
         _MTShutDown                    ;Miscellaneous tools.

         lda      handle+2
         pha
         lda      handle
         pha

         _DisposeHandle                 ;Deallocate memory block.

         lda      userid
         pha

         _MMShutDown                    ;Memory Manager.
         _TLShutDown                    ;Tool Locator.

         _Quit    QParams               ;Quit back to ProDOS.
         end

;................................................................
;
; Main
; ~~~~
; This is the main loop for the game.  It makes a call to MOVEM
; which actually takes care of the animation of any active sprites
; and colision detection.
;
; The main loop will not end until the quit flag is set when in
; 'demo' mode.
;................................................................


Main     start

         using    TDData
         using    SHData
         using    GMData

         phk                            ;Make sure data bank is the
         plb                            ;same as program bank.

         jsr      Startup               ;Startup the GS tools.
         jsr      ITable                ;Initialise the SHR line table.
         lda      #3
         sta      ships                 ;Number of canons at start.
         jsr      InitDemo

Mloop    lda      quit                  ;Time to quit ?
         beq      notquit               ; No.
         lda      state                 ; Possibly, see if in demo mode.
         beq      finoff                ;  In demo mode, so quit.
notquit  lda      pauseflg              ;Are we in pause ?
         bne      Mskip                 ; Yes.

         lda      state
         beq      demoent
         jsr      Movem                 ;Animate the sprites. (Do the real work)
         jsr      initmisl              ;Check the fire button.
         bra      Mskip

demoent  anop

Mskip    pea      $0000                 ;Make call to event manager.
         pea      $ffff
         pea      Event|-16
         pea      Event
         _GetNextEvent
         pla
         beq      Mloop                 ;No events, goto start of loop.

         lda      Ewhat                 ;Get event type.
         cmp      #1
         bne      Mloop
         jsr      mousedn
         bra      Mloop

finoff   jmp      Shutdown              ;Finish off.

         end

;................................................................
;
; InitMisl.
; ~~~~~~~~~
; Checks the joystick button.  If pressed it will attempt to
; activate the missile.
;................................................................

InitMisl start

         using    SHData
         using    TDData

         lda      $e0c061               ;Get button value.
         and      #$00ff                ;Make it 8 bits wide.
         cmp      #128                  ;Is the button down ?
         bmi      alrdyfrd              ; No.

         lda      MissSt                ; Yes. Now see if the missile is
         cmp      #3                    ;      is already active.
         bne      alrdyfrd              ; Active already.

         lda      #4                    ; Not active, so activate it.
         sta      MissSt

         lda      canonx                ;Initialise it's coordinates.
         clc
         adc      #9
         sta      MissCx
         lda      #162
         sta      MissCy
         jsr      PlayFire              ;Play the firing sound.

alrdyfrd rts

         end

InitGame start

         using    GMData
         using    SHData

         stz      noaliens              ;There are aliens on the screen.
         stz      score                 ;Zero score.
         stz      score+2
         stz      bonus                 ;No bonus yet.
         stz      quit                  ;Not time to quit.
         stz      pauseflg              ;Not pausing.
         lda      #3
         sta      ships                 ;Three ships at start.
         lda      #1
         sta      state                 ;Play mode.
         lda      #35
         sta      starty                ;Starting Y-coord of top row.

         jsr      drawbar               ;Draw the menu bar.
         jsr      ICoord                ;Initialise game variables.
         jsr      DRCN                  ;Draw the canon.
         jsr      IBarrier              ;Draw the barriers.

         rts

         end

InitDemo start

         using    GMData

         stz      score                 ;Zero Score.
         stz      score+2
         stz      bonus                 ;No bonus yet.
         stz      quit                  ;Not time to quit.
         stz      pauseflg              ;Not pausing.
         stz      state                 ;Demo mode.
         lda      ships                 ;Check # of remaining ships.
         beq      leaveit               ; None, dont redraw the bar, leave
;                                         the last score up.

         jsr      drawbar               ;Redraw the bar.

leaveit  jsr      title                 ;Draw the title text.

         rts

         end

GMData   data

score    ds       4                     ;current score
bonus    ds       2                     ;current mother bonus
ships    ds       2                     ;number of ships left

quit     ds       2                     ;quit flag.
pauseflg ds       2                     ;pause flag.

state    ds       2                     ;0 - demo.
;                                       ;1 - in game play.

starty   ds       2                     ;Starting Y coord for aliens.

         end
