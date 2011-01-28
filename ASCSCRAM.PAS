(*
** ASCII-Scramble
**
** a silly shoot'em up game in textmode
**
** (W) by Tommy-Saftw”rx in 1994
**
** updated: 31-Dec-94, Version 1.04
** created: 28-Aug-94
**
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