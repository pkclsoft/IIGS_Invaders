
         keep     sound
         mload    Sound.macros

GenRand  start

         using    SndData

         ldx      #$00ff

GRLoop1  phx
         PushWord #0
         _Random
         pla
         plx

         and      #$00ff
         bne      NotZero
         inc      a

NotZero  sep      #$20
         longa    off
         sta      RandWave,x
         rep      #$20
         longa    on
         dex
         cpx      #$ffff
         bne      GRLoop1

         rts

         end

CopyWave start

         using    SndData

         PushLong #SineWave
         PushWord #SineAddr*256
         PushWord #WaveLen
         _WriteRamBlock

         PushLong #RandWave
         PushWord #RandAddr*256
         PushWord #WaveLen
         _WriteRamBlock

         rts

         end

PlayFire start

         using    SndData

         lda      #SineAddr
         sta      AWaveAdd
         sta      BWaveAdd

         PushWord #0
         PushWord #64
         _AllocGen
         pla                            ;Get Generator number;

         pha                            ;Save it.
         pha                            ;Now put it on for NoteON.
         PushWord #FireSemi
         PushWord #150                   ;Volume
         PushLong #InstRec
         _NoteOn

         PushWord #FireSemi
         _NoteOff

         rts

         end

PlayExpl start

         using    SndData

         lda      #RandAddr
         sta      AWaveAdd
         sta      BWaveAdd

         PushWord #0
         PushWord #64
         _AllocGen
         pla                            ;Get Generator number;

         pha                            ;Save it.
         pha                            ;Now put it on for NoteON.
         PushWord #ExplSemi
         PushWord #150                   ;Volume
         PushLong #InstRec
         _NoteOn

         PushWord #ExplSemi
         _NoteOff

         rts

         end

PlayCann start

         using    SndData

         lda      #RandAddr
         sta      AWaveAdd
         sta      BWaveAdd

         PushWord #0
         PushWord #64
         _AllocGen
         pla                            ;Get Generator number;

         pha                            ;Save it.
         pha                            ;Now put it on for NoteON.
         PushWord #CannSemi
         PushWord #150                   ;Volume
         PushLong #InstRec
         _NoteOn

         PushWord #CannSemi
         _NoteOff

         rts

         end

PlayBomb start

         using    SndData

         lda      #RandAddr
         sta      AWaveAdd
         sta      BWaveAdd

         PushWord #0
         PushWord #64
         _AllocGen
         pla                            ;Get Generator number;

         pha                            ;Save it.
         pha                            ;Now put it on for NoteON.
         PushWord #BombSemi
         PushWord #150                   ;Volume
         PushLong #InstRec
         _NoteOn

         PushWord #BombSemi
         _NoteOff

         rts

         end

SndData  data

RandWave ds       257

Sinewave dc       i1'1,1,2,3,4,6,7,8,9,11,12,13'
         dc       i1'14,15,17,18,19,20,21,23,24,25,26,27'
         dc       i1'29,30,31,32,33,34,36,37,38,39,40,41'
         dc       i1'42,44,45,46,47,48,49,50,51,52,53,54'
         dc       i1'55,56,57,58,59,60,61,62,63,64,65,66'
         dc       i1'67,68,69,70,70,71,72,73,74,75,75,76'
         dc       i1'77,78,79,79,80,81,81,82,83,84,84,85'
         dc       i1'85,86,87,87,88,88,89,90,90,91,91,92'
         dc       i1'92,93,93,93,94,94,95,95,95,96,96,96'
         dc       i1'97,97,97,97,98,98,98,98,98,99,99,99'
         dc       i1'99,99,99,99,99,99,99,99,99,99,99,99'
         dc       i1'99,99,99,99,99,99,99,99,98,98,98,98'
         dc       i1'97,97,97,97,96,96,96,95,95,95,94,94'
         dc       i1'93,93,93,92,92,91,91,90,90,89,88,88'
         dc       i1'87,87,86,85,85,84,84,83,82,81,81,80'
         dc       i1'79,79,78,77,76,75,75,74,73,72,71,70'
         dc       i1'70,69,68,67,66,65,64,63,62,61,60,59'
         dc       i1'58,57,56,55,54,53,52,51,50,49,48,47'
         dc       i1'46,45,44,42,41,40,39,38,37,36,35,33'
         dc       i1'32,31,30,29,28,26,25,24,23,22,20,19'
         dc       i1'18,17,15,14,13,12,11,9,8,7,6,4'
         dc       i1'3,2,1,1'

WaveLen  gequ     256
SineAddr gequ     0
RandAddr gequ     1

BombSemi gequ     13
CannSemi gequ     0
ExplSemi gequ     32
FireSemi gequ     109

InstRec  dc       i1'100'               ;First segment.
         dc       i1'0,127'
         dc       i1'10'                ;Second segment.
         dc       i1'100,0'
         dc       i1'20'                ;Third segment.
         dc       i1'80,2'
         dc       i1'30'                ;Fourth segment.
         dc       i1'30,1'
         dc       i1'0'                 ;Fifth segment.
         dc       i1'0,0'
         dc       i1'0'                 ;Sixth segment.
         dc       i1'0,0'
         dc       i1'0'                 ;Seventh segment.
         dc       i1'0,0'
         dc       i1'0'                 ;Eighth segment.
         dc       i1'0,0'
         dc       i1'3'                 ;Release segment.
         dc       i1'32'                ;Priority increment.
         dc       i1'2'                 ;Pitch Bend Range.
         dc       i1'127'               ;Vibrato depth.
         dc       i1'200'               ;Vibrato speed.
         dc       i1'0'                 ;Not used.
         dc       i1'1'                 ;<A> wave count.
         dc       i1'1'                 ;<B> wave count.

AWave    dc       i1'127'               ;Top key for wave.
AWaveAdd dc       i1'0'                 ;High byte of waveform address.
         dc       i1'0'                 ;Size of the waveform.
         dc       i1'0'                 ;DOC mode byte.
         dc       i2'0'                 ;Relative Pitch ?

BWave    dc       i1'127'               ;Top key for wave.
BWaveAdd dc       i1'0'                 ;High byte of waveform address.
         dc       i1'0'                 ;Size of the waveform.
         dc       i1'0'                 ;DOC mode byte.
         dc       i2'0'                 ;Relative Pitch ?

         end
