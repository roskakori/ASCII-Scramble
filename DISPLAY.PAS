(*
** Display.PAS
**
** unit for ASCII-Scramble
** contains display functions, game objects display codes
**
** updated: 14-Dec-94
** created:  8-Sep-94
*)
unit Display;

(**********************************************************)
(**)                                                    (**)
(**) INTERFACE                                          (**)
(**)                                                    (**)
(**********************************************************)
uses Crt,
     Global;

const
  (*$IFDEF CO80*)
  sx = 80;                             (* game screen dimension *)
  (*$IFDEF LN50*)
  sy = 47;
  ScreenMode = CO80+Font8x8;
  (*$ELSE*)
  sy = 22;
  ScreenMode = CO80;
  (*$ENDIF*)
  (*$ELSE*)
  sx = 40;
  sy = 22;
  ScreenMode = CO40;
  (*$ENDIF*)


const
  (*
  ** game images, chars
  *)
  ShipBodyCh   = '#';                  (* player *)
  ShipShieldCh = ' ';
  ShipFrontCh  = '>';
  ShipWingCh   = '>';
  ExtraCh      = '$';                  (* extra *)

  MissileNormalCh = 'o';               (* shoot *)
  MissileDoubleCh = '8';
  BombCh          = 'v';

  ExplosionCh1 = '*';                  (* explosion *)
  ExplosionCh2 = '+';

  HillUpCh    = '/';                   (* landscape *)
  HillDownCh  = '\';
  HillFloorCh = '_';
  CityCh      = ':';

  (*$IFDEF TEST*)
  HillSolidCh = 'X';
  SpaceCh     = ':';
  (*$ELSE*)
  HillSolidCh = #0;
  SpaceCh     = ' ';
  (*$ENDIF*)

  NufinCh = #33;

  RobotNeckCh1 = '[';                  (* robot neck *)
  RobotNeckCh2 = '=';
  RobotNeckCh3 = ']';
var
  (*
  ** game objects images
  *)
  goShipBody,                          (* player *)
  goShipFront,
  goShipWing,
  goShipShield,

  goMissile,                           (* bullets *)
    goMissileNormal,
    goMissileDouble,
  goBomb,

  goRocket,                            (* enemies *)
  goBase,
  goUfo,

  goRobotNeck1,                        (* robot neck *)
  goRobotNeck2,
  goRobotNeck3,

  goExplosion1,
  goExplosion2,

  goHillUp,                            (* landscape *)
  goHillDown,
  goHillFloor,
  goCity,
  goHillSolid,

  goNufin,                             (* don't change display ID *)

  goExtra,                             (* extra *)

  goSpace    : word;

  (*
  ** colors
  *)
  ColorStd,
  ColorInv,
  ColorLit: byte;

  oldTextMode: byte;
  oldTextAttr: byte;

  scr       : array[1..sy, 1..sx] of word;

  ScrollCounter : byte;

  ScreenBase: pointer;
  UpdateInfo: byte;                    (* update score & co. display *)


type
  PosType   = integer;                 (* position type *)
  speedType = shortInt;                (* speed type *)


procedure setScr(x,y: PosType; wd: word);
function  getScr(x,y: PosType): word;
function  go( ch: char; col: byte ): word;

procedure WriteColXY( x,y: byte; s: string );
procedure WriteCtr( y: byte; s: string );

procedure WriteMessage(msg: string);

(**********************************************************)
(**)                                                    (**)
(**) IMPLEMENTATION                                     (**)
(**)                                                    (**)
(**********************************************************)

(*
** set/getScr: set/get a screen char
*)
procedure setScr(x,y: PosType; wd: word);
begin
  if (x>0) and (x<=sx) and (y>0) and (y<=sy) then
    scr[y,x] := wd;
end;

function getScr(x,y: PosType): word;
begin
  if (x>0) and (x<=sx) and (y>0) and (y<=sy) then
    getScr := scr[y,x]
  else
    getScr := goHillSolid;
end;

(*
** go: convert ch & col to display-ch
*)
function go( ch: char; col: byte ): word;
begin
  go := ord(ch) + word(col) shl 8;
end;



(*
** WriteColXY
*)
procedure WriteColXY( x,y: byte; s: string );
var
  i: byte;                   (* loop var *)
begin
  GotoXY(x,y);                         (* set cursor *)

  for i := 1 to length(s) do           (* write string *)
    if s[i] <> '^' then                (* is next char a '^'? *)
      Write( s[i] )                    (* N-> write it to screen *)
    else begin                         (* Y-> set color *)
        inc(i);
        case s[i] of
          'S': TextAttr := ColorStd;   (*     standard color *)
          'I': TextAttr := ColorInv;   (*     invers color *)
          'H': TextAttr := ColorLit;   (*     highlighted color *)
        end;
      end;
end;

(*
** WriteCtr
**
** write string to screen, adjusting it to center;
** supports also '^S' and '^I' to change color in string
*)
procedure WriteCtr( y: byte; s: string );
var
  i        : byte;                     (* loop var *)
  colCmdNum: byte;                     (* num. of '^' found in s *)
begin
  colCmdNum := 0;                      (* calc num of '^' in s *)
  for i := 1 to length(s) do
    if s[i] = '^' then
      inc(colCmdNum);

  WriteColXY( (sx-length(s)+2*colCmdNum) div 2, y, s );
end;


procedure WriteMessage(msg: string);
var
  key: char;
begin
  if length(msg) >= (sx-5) then
    msg := copy(msg,1,sx-8) + '..';
  GotoXY(1,sy+2);
  TextAttr := ColorInv;
  Write(msg);
  ClrEol;
  GotoXY(sx-5,sy+2);
  Write( '[CR]' );
  TextAttr := ColorStd;
  key := ReadKey;
end;

(*
** Initialisation
*)
begin
  oldTextAttr := TextAttr;             (* remember screen data *)
  oldTextMode := LastMode;
  if LastMode = Mono then
    ScreenBase := ptr($b000, 0)
  else
    ScreenBase := ptr($b800, 0);

  ColorStd := TextAttr;
  ColorInv := (ColorStd shr 4) + (ColorStd and 7) shl 4;
  ColorLit := ColorStd xor 8;

  goShipBody   := go( ShipBodyCh,   ColorInv );
  goShipShield := go( ShipShieldCh, ColorInv );
  goShipFront  := go( ShipFrontCh,  ColorLit );
  goShipWing   := goShipFront;

  goMissileNormal := go( MissileNormalCh, ColorStd );
  goMissileDouble := go( MissileDoubleCh, ColorStd );
  goBomb          := go( BombCh, ColorStd );

  goExtra := go( ExtraCh, ColorInv );

  goExplosion1 := go( ExplosionCh1, ColorStd );
  goExplosion2 := go( ExplosionCh2, ColorStd );

  goHillUp    := go( HillUpCh   , ColorStd );
  goHillDown  := go( HillDownCh , ColorStd );
  goHillFloor := go( HillFloorCh, ColorStd );
  goCity      := go( CityCh     , ColorInv );

  goRobotNeck1 := go( RobotNeckCh1, ColorStd );
  goRobotNeck2 := go( RobotNeckCh2, ColorStd );
  goRobotNeck3 := go( RobotNeckCh3, ColorStd );

  (*$IFDEF TEST*)
  goHillSolid := go( HillSolidCh, ColorLit );
  goSpace     := go( SpaceCh    , ColorStd );
  (*$ELSE*)
  goHillSolid := go( HillSolidCh, 0 );
  goSpace     := go( SpaceCh, ColorStd );
  (*$ENDIF*)

  goNufin     := go( NufinCh, ColorInv );

  TextMode( ScreenMode );
end.
