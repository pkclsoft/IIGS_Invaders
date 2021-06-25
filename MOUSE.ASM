         keep     mouse
         mload    mouse.macros

drawbar  start

         using    GMData
         using    BARData
         using    SHData
         using    BARD

         pea      $0001
         _SetSolidPenPat

         pea      BarRect|-16
         pea      BarRect
         _PaintRect

         pea      $000e
         _SetSolidPenPat

         pea      0
         pea      1
         _MoveTo

         pea      0
         pea      11
         _LineTo

         pea      318
         pea      11
         _LineTo

         _HideCursor

         lda      RESTPnt
         sta      SImage
         lda      RESTPnt+2
         sta      SImage+2

         lda      #RESTW
         sta      SWidth
         lda      #10
         sta      SHeight

         pea      220
         pea      0

         lda      #$ffff
         sta      SCollin

         stz      Smask

         jsr      DRSprite

         lda      QUITPnt
         sta      SImage
         lda      QUITPnt+2
         sta      SImage+2

         lda      #QUITW
         sta      SWidth
         lda      #10
         sta      SHeight

         pea      250
         pea      0

         lda      #$ffff
         sta      SCollin

         stz      Smask

         jsr      DRSprite

         lda      PAUSPnt
         sta      SImage
         lda      PAUSPnt+2
         sta      SImage+2

         lda      #PAUSEW
         sta      SWidth
         lda      #10
         sta      SHeight

         pea      280
         pea      0

         jsr      DRSprite

         lda      BARCPnt
         sta      SImage
         lda      BARCPnt+2
         sta      SImage+2

         lda      #CNW
         sta      SWidth
         lda      #10
         sta      SHeight

         ldx      #3
         stx      ships
         lda      #130
shploop  pha
         sta      xpos
         stx      ypos
         pea      0

         lda      #$ffff
         sta      SCollin

         stz      Smask

         jsr      DRSprite

         lda      xpos
         clc
         adc      #12
         ldx      ypos
         dex
         bne      shploop

         pea      1
         _SetBackColor

         pea      4
         _SetForeColor

         pea      9
         pea      9
         _MoveTo

         pea      scoremsg|-16
         pea      scoremsg
         _DrawString

         _InitCursor

         rts

         end

mousedn  start

         using    GMData
         using    TDData
         using    SHData
         using    BARD

         lda      Ewhere
         cmp      #11
         bpl      notone

         lda      Ewhere+2
         cmp      #250
         bmi      notquit
         cmp      #274
         bpl      notquit
         jmp      doquit1
notquit  cmp      #280
         bmi      notpause
         cmp      #310
         bmi      pause
notpause cmp      #220
         bmi      notone
         cmp      #245
         bpl      notone
         lda      state
         cmp      #1
         beq      notone
         jsr      restart
notone   rts

pause    lda      pauseflg
         bne      finpause

         inc      pauseflg

         _HideCursor

         lda      PAUSPnt+4
         sta      SImage
         lda      PAUSPnt+6
         sta      SImage+2

         lda      #PAUSEW
         sta      SWidth
         lda      #10
         sta      SHeight

         pea      280
         pea      0

         jsr      DRSprite

         _ShowCursor

         _ObscureCursor

         rts

finpause _HideCursor
         lda      PAUSPnt
         sta      SImage
         lda      PAUSPnt+2
         sta      SImage+2

         lda      #PAUSEW
         sta      SWidth
         lda      #10
         sta      SHeight

         pea      280
         pea      0

         jsr      DRSprite

         stz      pauseflg

         _ShowCursor

         _ObscureCursor

         rts

doquit1  _HideCursor

         ldx      #3
dql      phx
         lda      QUITPnt+4
         sta      SImage
         lda      QUITPnt+6
         sta      SImage+2

         lda      #QUITW
         sta      SWidth
         lda      #10
         sta      SHeight

         pea      250
         pea      0

         lda      #$ffff
         sta      SCollin

         stz      Smask

         jsr      DRSprite

         ldx      #$7fff
xloop    dex
         bne      xloop

         lda      QUITPnt
         sta      SImage
         lda      QUITPnt+2
         sta      SImage+2

         lda      #QUITW
         sta      SWidth
         lda      #10
         sta      SHeight

         pea      250
         pea      0

         lda      #$ffff
         sta      SCollin

         stz      Smask

         jsr      DRSprite

         ldx      #$7fff
xl       dex
         bne      xl

         plx
         dex
         bpl      dql

         inc      quit

         lda      #1
         cmp      state
         bne      notgame
         jsr      InitDemo
notgame  rts

         end

restart  start

         using    GMData
         using    BARData
         using    SHData
         using    BARD

         _HideCursor

         ldx      #3
dql      phx
         lda      RESTPnt+4
         sta      SImage
         lda      RESTPnt+6
         sta      SImage+2

         lda      #RESTW
         sta      SWidth
         lda      #10
         sta      SHeight

         pea      220
         pea      0

         lda      #$ffff
         sta      SCollin

         stz      Smask

         jsr      DRSprite

         ldx      #$7fff
xloop    dex
         bne      xloop

         lda      RESTPnt
         sta      SImage
         lda      RESTPnt+2
         sta      SImage+2

         lda      #RESTW
         sta      SWidth
         lda      #10
         sta      SHeight

         pea      220
         pea      0

         lda      #$ffff
         sta      SCollin

         stz      Smask

         jsr      DRSprite

         ldx      #$7fff
xl       dex
         bne      xl

         plx
         dex
         bpl      dql

         _ShowCursor
         _ObscureCursor

         pea      0
         _SetSolidPenPat

         pea      ScrnRect|-16
         pea      ScrnRect
         _PaintRect

         stz      pauseflg

         jsr      InitGame

         rts

         end

InitScrn start

         using    BARData

         pea      0
         _SetSolidPenPat

         pea      ScrnRect|-16
         pea      ScrnRect
         _PaintRect

         jsr      ICoord                ;Initialise game variables.
         jsr      IBarrier              ;Draw the barriers.

         rts

         end

BARData  data

BarRect  dc       I2'0,2,10,319'

ScrnRect dc       I2'13,0,199,319'

scoremsg dc       I1'endscr-sscr'
sscr     dc       C'Score : 0'
endscr   anop

         end
