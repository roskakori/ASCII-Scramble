(*
** Global.PAS
**
** unit for ASCSCRAM.PAS
**
** updated: 13-Dec-94
** created:  8-Sep-94
**
*)
unit Global;

(**********************************************************)
(**)                                                    (**)
(**) INTERFACE                                          (**)
(**)                                                    (**)
(**********************************************************)
uses Crt;

const
  MaxFuel      = 500;                  (* fuel constants *)
  FuelDiv      = MaxFuel div 10;

  ShootNormal = 1;                     (* shoot levels *)
  ShootDouble = 2;
  ShootWing   = 3;

  UpdScore  =  1;                       (* values for UpdateInfo *)
  UpdFuel   =  2;
  UpdExtra  =  4;
  UpdLife   =  8;
  UpdLevel  = 16;
  UpdAll    = UpdScore or UpdFuel or UpdExtra or UpdLife or UpdLevel;

  DelayTime = 30;            (* time to wait after every move [ms] *)

  ESC = #27;
  SPC = #32;
  CR  = #13;


  RocketYard = 1;                      (* level IDs *)
  RocketCave = 2;
  CometField = 3;
  UfoHangar  = 4;
  RobotCity  = 5;

  SceneNum = 5; LevelNum = 4;
  LevelName: array[1..LevelNum] of string =
             ( 'EASY  ', 'NORMAL', 'TRICKY', 'HARD' );
  SceneName: array[1..SceneNum] of string =
             ( 'ROCKET BASE', 'ROCKET CAVE', 'COMET FIELD',
               'UFO HANGAR ', 'ROBOT CITY ' );

                                       (* scroll speed *)
  ScrollSpeed: array[1..LevelNum] of byte = ( 8,6,4,4 );

var

  UserBreak    : boolean;
  AbortGame    : boolean;
  GamePaused   : boolean;
  GameOver     : boolean;
  ShipCrashed  : boolean;

  TopY, HillY : byte;
  MinHillY, MaxHillY,                  (* hill/top limits *)
  MinTopY,  MaxTopY: byte;

  BombCounter: byte;

  SceneMoveNum : LongInt;
  SceneLength  : word;

  GameLevel   : word;                  (* GameLevel, e.g. "HARD#3" *)
  GameScene   : byte;                  (* GameScene e.g. "COMETS" *)
  Difficulty  : word;                  (* same as GameLevel, max. LevelNum *)

  Score       : LongInt;               (* points scored *)
  Fuel        : word;                  (* ship fuel *)
  oldFuel     : word;                  (*   used by UpdateInfo *)
  ShipsLeft   : byte;                  (* lifes *)

  LifeScore   : LongInt;               (* score that must be reached to get *)
                                       (*   an extra life *)
  AutoExtra     : boolean;             (* flag: automatic extra activation *)
  ExtraCounter  : byte;                (* extra activation bar counter *)
  ExtraRatio    : byte;                (* enenmies to shoot until extra *)
  ExtraRatioCtr : byte;                (*   counter to check if enough *)
                                       (*   enemies have been shot *)

  ShipSpeedIdx  : byte;                (* extras: ship speed *)
  ShootDelayIdx : byte;                (*   shoot delay *)
  SmartBombs    : byte;                (*   smart bombs *)
  ShootLevel    : byte;                (*   normal/twice/wing *)
  Shield        : word;                (*   shield duration *)

  ShootDelayCtr : byte;

  ScrollStatus  : boolean;             (* flag: true = scroll screen *)
  (*$IFDEF TEST*)
  oldMaxAvail:  LongInt;               (* remember memory free at start *)
  (*$ENDIF*)

  LastUfoOrComet: byte;                (* to avoid too narrow objetcs *)

  scrollTimerFlag: boolean;

procedure FlushKeyboard;
procedure EnableScrolling;
procedure DisableScrolling;
procedure RestoreTimerHandler;

(**********************************************************)
(**)                                                    (**)
(**) IMPLEMENTATION                                     (**)
(**)                                                    (**)
(**********************************************************)
uses Dos;

var
  oldTimerHandler: pointer;

(*
** FlushKeyboard
*)
procedure FlushKeyboard;
var
  key: char;
begin
  while KeyPressed do
    key := ReadKey;
end;

(*
** Enable/DiableScrolling
*)
procedure EnableScrolling;
begin
  ScrollStatus := true;
end;

procedure DisableScrolling;
begin
  ScrollStatus := false;
end;

(*
** ScrollTimerHandler
*)
(*$F+*)
procedure ScrollTimerHandler; interrupt;
begin
  ScrollTimerFlag := true;
end;
(*$F-*)

(*
** RestoreTimerHandler
*)
procedure RestoreTimerHandler;
begin
  SetIntVec( $1C, oldTimerHandler );
end;


(*
** Initialisation
*)
begin
  GameLevel := 2;                      (* set default game level *)
  Difficulty := GameLevel;
  AutoExtra := false;                  (* disable autom. extra activation *)

  (* install scrollTimer-handler *)
  GetIntVec( $1C, oldTimerHandler );
  SetIntVec( $1C, Addr(ScrollTimerHandler) );
  (*$IFDEF TEST*)
  oldMaxAvail := MaxAvail;
  (*$ENDIF*)
end.