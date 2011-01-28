unit Player;

(**********************************************************)
(**)                                                    (**)
(**) INTERFACE                                          (**)
(**)                                                    (**)
(**********************************************************)
uses
  Global, GameObjs, Display;
const
  Front = 0;                           (* ship object types *)
  Body  = 1;
  Wing  = 2;

  Missile = 0;                         (* bullet object types *)
  Bomb    = 1;
type

  BulletPtr = ^BulletObj;              (* bullet object *)
  BulletObj = object( GameObj)

      constructor Init(nx, ny: PosType; bulletType: byte; hits: byte);

      procedure   MoveIt; virtual;

    end;

  ShipPtr = ^ShipObj;                  (* ship object *)
  ShipObj = object( GameObj )

      constructor Init(nx, ny: PosType; shipType: byte);
      procedure   MoveIt; virtual;
      function    PosIsEqual( go: GameObj ): boolean; virtual;

    end;

  ExplPtr = ^ExplObj;                  (* explosion object *)
  ExplObj = object( GameObj )

      constructor Init(nx, ny: PosType; scroll: boolean );

      procedure MoveIt; virtual;

    end;

var
  ShipBody, ShipGun,
  ShipWing1, ShipWing2: ShipPtr;


procedure InitPlayer;
procedure NextExtra;

function AddExplosion(x, y: PosType; scroll: boolean ):GameObjPtr;

(**********************************************************)
(**)                                                    (**)
(**) IMPLEMENTATION                                     (**)
(**)                                                    (**)
(**********************************************************)
uses Crt;


procedure ActivateExtra; forward;
procedure DoSmartBomb;   forward;
procedure CheckShoot;    forward;

const
  BombRatio = 1;                  (* missiles to fire to envoke one bomb *)

  MissileSpeed = 0;                    (* bullet speeds *)
  BombSpeed    = 4;

  MaxShipSpeedIdx  = 3;                (* ship speed *)
  ShipSpeed: array[1..MaxShipSpeedIdx] of speedType = (4,2,1);

  MaxShootDelayIdx = 3;                (* shoot delay *)
  ShootDelayArr: array[1..MaxShootDelayIdx] of speedType  = (7,4,2);

  MaxShootLevel    = 3;

(*
**-------------------------------------
** methods for ShipObj
**-------------------------------------
*)
constructor ShipObj.Init(nx, ny: PosType; shipType: byte);
begin
  GameObj.Init(nx, ny, flying);
  SetSpeed( ShipSpeed[ShipSpeedIdx] );
  SetType( shiptype );
  case shipType of
     Front: SetDisplay( ShipFrontCh, ColorStd );
     Body : SetDisplay( ShipBodyCh , ColorInv );
     Wing : SetDisplay( ShipWingCh , ColorStd );
  end;
  SetAnimSpeed(5);
end;

function ShipObj.PosIsEqual( go: GameObj ): boolean;
begin
  PosIsEqual := (GetX=go.GetX) and (GetY=go.GetY);
end;

procedure ShipObj.MoveIt;
var
  key: char;
  i  : byte;
  newBullet : BulletPtr;
  ShootPower: byte;                    (* 1 for normal, 2 for double/wing *)
  bkch      : word;                    (* current background screen char *)
  expl      : GameObjPtr;
  explRnd   : word;
begin
  if GetType = Body then begin
    if ShootDelayCtr > 0 then          (* decr. ShootDelayCtr *)
      dec( ShootDelayCtr );
    if Shield > 0 then begin           (* decr. Shield *)
        dec( Shield );
        if Shield = 0 then
          ShipBody^.SetDisplay( ShipBodyCh, ColorInv );
      end;
    if (Fuel=0) then begin             (* decr. Fuel, check for out of fuel *)
        if GetStatus = flying then
          SetStatus( Crashing );
      end
    else begin
        dec(Fuel);
        UpdateInfo := UpdateInfo or UpdFuel;
      end;
    if GetStatus = Crashing then begin
        bkch := GetBackgrCh;
        if ( ( (bkch<>goHillFloor) and (bkch<>goHillUp)
               and (bkch<>goHillDown) and (bkch<>goCity)
               and (bkch<>goHillSolid)
             ) or (GetY < MaxTopY )
           )
        then begin
            expl := AddExplosion( GetX, GetY, true );
            expl^.SetStatus( exploding+8+2*(GetY mod 4) );
            expl := AddExplosion( GetX+1, GetY, true );
            expl^.SetStatus( exploding+4+4*(GetY mod 3) );
            IncY;
          end
        else begin
            (*$IFDEF TEST*)
            SetStatus( ExplodingEnd-2 );
            (*$ELSE*)
            SetStatus( Exploding );
            (*$ENDIF*)
            DisableScrolling;
          end
      end
    else if GetStatus >= Exploding then begin
        for i := 1 to 5 do begin
            expl := AddExplosion( GetX+Random(6)-2, GetY+Random(5)-2, false );
            explRnd := Exploding + (Random( ExplodingEnd-Exploding ) div 2);
            if explRnd < GetStatus then
              explRnd := GetStatus-1;
            expl^.SetStatus( explRnd );
          end;
        if GetStatus=ExplodingEnd then
          ShipCrashed := true
        else
          SetStatus( GetStatus+1 );
      end
    else if KeyPressed then begin

        key := UpCase( ReadKey );
        case Key of
          ESC: begin                     (* abort game *)
                 AbortGame := true;
                 SetStatus( ExplodingEnd );
                 (*$IFDEF TEST*)
                 UserBreak := true;
                 (*$ENDIF*)
               end;
          'P': repeat                    (* pause key *)
                 key := UpCase( ReadKey );
               until key = 'P';
          #0 : begin
                 key := ReadKey;
                 case key of             (* move Ship *)
                   #72: if GetY > 1  then DecY;
                   #80: if GetY < sy then IncY;
                   #75: if GetX > 2  then DecX;
                   #77: if GetX < (word(sx)*3 div 4) then IncX;
                 else
                   inc(Fuel);
                 end;
               end;
          ' ': begin                     (* launch missile(s) & bomb *)
                 if ShootDelayCtr = 0 then
                   with ShipBody^ do begin
                       ShootDelayCtr := ShootDelayArr[ ShootDelayIdx ];
                       if ShootLevel < ShootDouble then ShootPower := 1
                                                   else ShootPower := 2;
                       newBullet :=
                         New( BulletPtr,
                              Init( GetX+1, GetY, Missile, ShootPower ));
                       BulletList.Append( newBullet );
                       if ShootLevel = ShootWing then begin
                           BulletList.Append( New( BulletPtr,
                               Init( GetX, GetY-1, Missile, 1 )));
                           BulletList.Append( New( BulletPtr,
                               Init( GetX, GetY+1, Missile, 1 )));
                         end;
                       bkch := GetBackgrch;
                       if (BombCounter = 1) then begin
                           if (bkch<>goHillFloor) then begin
                               BombCounter := BombRatio;
                               BulletList.Append( New( BulletPtr,
                                                       Init( GetX, GetY, Bomb,
                                                             ShootPower )));
                             end
                         end
                       else
                         dec( BombCounter );
                     end;
               end;
          CR : ActivateExtra;
          'B': DoSmartBomb;                      (* smartbomb *)
          'K': ShipBody^.SetStatus( Crashing );  (* crash ship *)
          (*$IFDEF TEST*)
          'X': NextExtra;
          'A': begin
                 ShipSpeedIdx  := MaxShipSpeedIdx;
                 ShootDelayIdx := MaxShootDelayIdx;
                 SmartBombs    := 9;
                 ShootLevel    := ShootWing;
                 CheckShoot;
                 UpdateInfo := UpdateInfo or UpdExtra;
               end;
          'S': begin
                 ShipSpeedIdx  := MaxShipSpeedIdx;
                 ShootDelayIdx := MaxShootDelayIdx;
                 SmartBombs    := 9;
                 ShootLevel    := ShootDouble;
                 CheckShoot;
                 UpdateInfo := UpdateInfo or UpdExtra;
               end;
          '+': SceneMoveNum := 0;
          '*': SceneMoveNum := sx+10;
          '.': begin
                 SceneMoveNum := SceneMoveNum;  (* break game to debug *)
               end;
          (*$ENDIF*)
        end;
        FlushKeyboard;
      end;
  end;
end;

(*
**-------------------------------------
** methods for BulletObj
**-------------------------------------
*)

(*
** BulletObj.Init
*)
constructor BulletObj.Init(nx, ny: PosType; bulletType: byte; hits: byte);
begin
  GameObj.Init( nx, ny, flying );
  SetType( bulletType );
  SetHits( hits );
  case bulletType of
    Missile: begin
               if GetHits = 1 then
                 SetDisplay( 'o', ColorStd )
               else
                 SetDisplay( '8', ColorStd );
               SetSpeed( MissileSpeed );
             end;
    Bomb   : begin
               SetDisplay( 'v', ColorStd );
               SetSpeed( BombSpeed );
             end;
  end;
end;


(*
** BulletObj.MoveIt
*)
procedure BulletObj.MoveIt;
begin
  case GetType of
    Missile: IncX;
    Bomb   : IncY;
  end;
end;


(*
**-------------------------------------
** methods for explosion object
**-------------------------------------
*)

(*
** ExplObj.Init
*)
constructor ExplObj.Init(nx, ny: PosType; scroll: boolean );
begin
  GameObj.Init( nx, ny, Exploding );
  SetDisplay( '*+', ColorStd );
  SetSpeed( 0 );
  SetAnimSpeed(1);
  GetScroll := scroll;
end;

procedure ExplObj.MoveIt;
begin
  if GetStatus = ExplodingEnd then
    SetStatus( removeMe )
  else
    SetStatus( GetStatus+1 );
end;

(*
** NextExtra
*)
procedure NextExtra;
begin
  inc( ExtraCounter );                 (* incr. extracounter *)
  if ExtraCounter = 6 then
    ExtraCounter := 1;
  if AutoExtra then                    (* automatic extra activation *)
    case ExtraCounter of
      1: if (ShipSpeedIdx <= ShootDelayIdx) then ActivateExtra;
      2: ActivateExtra
    end;
  UpdateInfo := UpdateInfo or UpdExtra;
end;

(*
** DoSmartBomb
*)
(*$F+*)
procedure HitWithSmartBomb( go: GameObjPtr );
begin
  go^.HitIt( 2 );
end;
(*$F-*)

procedure DoSmartBomb;
var
  expl: GameObjPtr;
begin
  if SmartBombs > 0 then begin
      EnemyList.DoProc( HitWithSmartBomb );      (* hit all enemies *)
      with ShipBody^ do begin                    (* display special f/x *)
          expl := AddExplosion(x+2,y-2, false);
          expl := AddExplosion(x+3,y  , false);
          expl := AddExplosion(x+2,y+2, false);
          expl := AddExplosion(x-1,y+2, false);
          expl := AddExplosion(x-2,y  , false);
          expl := AddExplosion(x-1,y-2, false);
        end;
      dec( SmartBombs );                         (* decr. num of smartbombs *)
      UpdateInfo := UpdateInfo or UpdExtra;
    end;
end;

(*
** CheckShoot
**
** set goMissile image, append wings if necessary
*)
procedure CheckShoot;
begin
  if ShootLevel > ShootNormal then
    goMissile := goMissileDouble;
  if ShootLevel = ShootWing then begin
      ShipWing1 := New( ShipPtr, Init( 0,-1, Wing ) );
      ShipWing2 := New( ShipPtr, Init( 0, 1, Wing ) );
      ShipWing1^.SetParent( ShipBody );
      ShipWing2^.SetParent( ShipBody );
      PlayerList.Append( ShipWing1 );
      playerList.Append( ShipWing2 );
    end;
end;

(*
** ActivateExtra
*)
procedure ActivateExtra;
begin
  case ExtraCounter of
    1: if ShipSpeedIdx < MaxShipSpeedIdx then begin        (* incr. speed *)
           inc( ShipSpeedIdx );
           ShipBody^.SetSpeed(ShipSpeed[ShipSpeedIdx]);
           UpdateInfo := UpdateInfo or UpdExtra;
           ExtraCounter := 0;
         end;
    2: if ShootDelayIdx < MaxShootDelayIdx then begin    (* incr. bullets *)
           inc( ShootDelayIdx );
           CheckShoot;
           UpdateInfo := UpdateInfo or UpdExtra;
           ExtraCounter := 0;
         end;
    3: if SmartBombs < 9 then begin              (* incr. smartbombs *)
           inc( SmartBombs );
           UpdateInfo := UpdateInfo or UpdExtra;
           ExtraCounter := 0;
         end;
    4: if ShootLevel < ShootWing then begin      (* incr. shootlevel *)
           inc( ShootLevel );
           CheckShoot;
           UpdateInfo := UpdateInfo or UpdExtra;
           ExtraCounter := 0;
         end;
    5: begin
         inc( Shield, 50 );
         ShipBody^.SetDisplay( ShipBodyCh+ShipShieldCh, ColorInv );
         ExtraCounter := 0;
       end;
  end;
end;


(*
**
** InitPlayer
**
*)
procedure InitPlayer;
begin
  ShipCrashed  := false;               (* ship vars *)
  Fuel         := MaxFuel;             (* init fuel *)
  oldFuel      := Fuel;
  BombCounter  := BombRatio;
  SmartBombs   := 0;
  ExtraCounter := 0;
  Shield       := 0;

  if ShipSpeedIdx>1  then dec(ShipSpeedIdx);
  if ShootDelayIdx>1 then dec(ShootDelayIdx);
  if ShootLevel>1    then dec(ShootLevel);

  ShipBody := New( ShipPtr, Init(sx div 5, sy div 2, Body));
  PlayerList.Append( ShipBody );
  ShipGun := New( ShipPtr, Init(1,0, Front));
  PlayerList.Append( ShipGun );
  ShipGun^.SetParent( ShipBody );

  goMissile := goMissileNormal;
  CheckShoot;
end;

(*
** AddExplosion
*)
function AddExplosion(x, y: PosType; scroll: boolean ):GameObjPtr;
var
  expl: GameObjPtr;
begin
  (*$IFNDEF NO_EXPL*)
  expl := New( ExplPtr, Init( x,y, scroll ) );
  MiscList.Append( expl );
  AddExplosion := expl;
  (*$ELSE*)
  AddExplosion := NIL;
  (*$ENDIF*)
end;


begin
end.