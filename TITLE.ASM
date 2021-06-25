         keep     title
         mload    title.macros

title    start

         using    DEMOS
         using    BARData
         using    SHData
         using    titdata

         pea      0
         pea      0
         pea      0
         _SetColorEntry

         pea      0
         _SetSolidPenPat

         pea      ScrnRect|-16
         pea      ScrnRect
         _PaintRect

         lda      #APPLEW
         sta      SWidth
         lda      #APPLEH
         sta      SHeight

         lda      DemPnt+8
         sta      SImage
         lda      DemPnt+10
         sta      SImage+2

         lda      #$ffff
         sta      SCollin
         stz      SMask

         lda      #112
         pha
         lda      #20
         pha

         jsr      DRSprite

         lda      #IIGSW
         sta      SWidth
         lda      #IIGSH
         sta      SHeight

         lda      DemPnt+12
         sta      SImage
         lda      DemPnt+14
         sta      SImage+2

         lda      #$ffff
         sta      SCollin
         stz      SMask

         lda      #156
         pha
         lda      #33
         pha

         jsr      DRSprite

         lda      #INVADW
         sta      SWidth
         lda      #INVADH
         sta      SHeight

         lda      DemPnt
         sta      SImage
         lda      DemPnt+2
         sta      SImage+2

         lda      #$ffff
         sta      SCollin
         stz      SMask

         lda      #120
         pha
         lda      #75
         pha

         jsr      DRSprite

         lda      #ERSW
         sta      SWidth
         lda      #ERSH
         sta      SHeight

         lda      DemPnt+4
         sta      SImage
         lda      DemPnt+6
         sta      SImage+2

         lda      #$ffff
         sta      SCollin
         stz      SMask

         lda      #118+INVADW*2
         pha
         lda      #75
         pha

         jsr      DRSprite

         pea      8
         _SetForeColor
         pea      0
         _SetBackColor

         pea      0
         pea      bymsg|-16
         pea      bymsg
         _StringWidth
         lda      #320
         sec
         sbc      1,s
         lsr      a
         plx
         pha
         pea      105
         _MoveTo

         pea      bymsg|-16
         pea      bymsg
         _DrawString

         rts

         end

titdata  data

bymsg    dc       i1'byend-bys'
bys      dc       c'Copyright 1988, by Peter Easdown.'
byend    anop

r1       dc       i1'r1end-r1s'
r1s      dc       c' = 200'
r1end    anop

r2       dc       i1'r2end-r2s'
r2s      dc       c' = 150'
r2end    anop

r3       dc       i1'r3end-r3s'
r3s      dc       c' = 100'
r3end    anop

r4       dc       i1'r4end-r4s'
r4s      dc       c' =  50'
r4end    anop

         end
