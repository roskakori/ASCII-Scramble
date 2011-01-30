(*
** ASCII-Scramble, a shoot'em up for MS DOS text mode using only
** ASCII characters.
**
** possible conditional defines:
** =============================
** TEST        create test version (lots of special features...)
** NO_EXPL     no explosions (after enemies shot/bullet hit background/...)
** NO_BASE     no base enemies
** NO_ROCKET   no rocket enemies
** NO_COMET    no comet enemies
** NO_UFO      no ufo enemies
** NO_ENEMIES  no base/rocket/comet/ufo enemies
**
** TODO:
** =====
** - enemy bullets target ship
** - ufo/comets avoid landscape
** - shooting base
**
*)

(*
** Copyright (c) 1994-2011 Thomas Aglassinger
** All rights reserved.
**
** Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are met:
**
**    * Redistributions of source code must retain the above copyright notice,
**      this list of conditions and the following disclaimer.
**    * Redistributions in binary form must reproduce the above copyright
**      notice, this list of conditions and the following disclaimer in the
**      documentation and/or other materials provided with the distribution.
**    * Neither the name of Thomas Aglassinger nor the names of his
**      contributors may be used to endorse or promote products derived from
**      this software without specific prior written permission.
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
** AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
** IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
** ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
** LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
** CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
** SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
** INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
** CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
** ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
** POSSIBILITY OF SUCH DAMAGE.
*)
program ASCII_Scramble;
uses Crt, Dos,
     Global, GameObjs, Display, GamePlay, Player,
     Screens, HiScore;


(*
** main program
*)
var
  pos: byte;       (* pos. in hiscore table *)
begin

  repeat

    TitleScreen;

    if not UserBreak then begin

        InitGame;
        repeat

          InitPlayer;
          InitLife;

          repeat
            DoNextMove;
          until ShipCrashed or UserBreak;

          CleanupLife;


        until GameOver or AbortGame;

        if not AbortGame then begin
            pos := CheckHiScore(Score);
            if pos <> 0 then
              EnterHiScore(pos);
          end;

      end;

  until UserBreak;

  RestoreScreen;
  (*$IFDEF TEST*)
  (* FIXME: Figure out what this was supposed to do. *)
  (*QuitInfo;*)
  (*$ENDIF*)

end.