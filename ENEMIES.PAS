(*
** Enemies.PAS
**
** unit used by ASCSCRAM.PAS (ASCII-Scramble)
**
** updated:  9-Oct-94
** created:  8-Sep-94
*)

unit Enemies;

(**********************************************************)
(**)                                                    (**)
(**) INTERFACE                                          (**)
(**)                                                    (**)
(**********************************************************)
uses
  Global, GameObjs, Display;

const
  BulletSpeed : array[1..LevelNum] of speedType = (3,2,1,1);
  CometSpeed  : array[1..LevelNum] of speedType = (6,4,2,1);
  UfoSpeed    : array[1..LevelNum] of speedType = (8,7,6,5);
    UfMvSpeed : array[1..LevelNum] of speedType = (2,2,1,1);
    UfShSpeed : array[1..LevelNum] of speedType = (15,10,7,6);
  SeekerSpeed : array[1..LevelNum] of speedType = (6,5,4,3);
    SeMvSpeed : array[1..LevelNum] of speedType = (3,2,1,1);
  FighterSpeed: array[1..LevelNum] of speedType = (6,5,4,3);
    FiMvSpeed : array[1..LevelNum] of speedType = (4,3,2,1);
    FiShSpeed : array[1..LevelNum] of speedType = (20,16,12,10);
  RobotSpeed  : array[1..LevelNum] of speedType = (8,7,6,5);
    RoMvSpeed : array[1..LevelNum] of speedType = (20,15,11,7);
    RoShSpeed : array[1..LevelNum] of speedType = (20,16,12,10);
  MaxEnemyShoot = 3;
  NoShoot       = 99;
type
  ShootRec = record
      dx, dy: PosType;
    end;
  ShootArr = array[1..MaxEnemyShoot] of ShootRec;

const
  FighterShoot: ShootArr = ( (dx:0;dy:-2), (dx:-1;dy:0), (dx:0;dy:2) );
  RobotShoot  : ShootArr = ( (dx:-2;dy:-2), (dx:-3;dy:0), (dx:-2;dy:2) );
  UfoShoot    : ShootArr = ( (dx:NoShoot;dy:0), (dx:-2;dy:0), (dx:NoShoot;dy:0) );

type
  EnemyPtr = ^EnemyObj;
  EnemyObj = object( GameObj )

      GetPoints  : byte;               (* points to score when killed *)

      constructor Init( nx, ny: PosType; st: byte; points: byte; hits: byte );
      destructor  Done; virtual;

      procedure   MoveIt; virtual;
      procedure   HitIt( hits: byte ); virtual;

    end;

  EnemyBulletPtr = ^EnemyBulletObj;
  EnemyBulletObj = object( GameObj )

      constructor Init( nx, ny: PosType );
      procedure   MoveIt; virtual;

    end;


  extdEnemyPtr = ^extdEnemyObj;
  extdEnemyObj = object( EnemyObj )

      MoveSpeed  : speedType;          (* speed to adjust pos. to player *)
      MoveCtr    : speedType;
      ShootPos   : ShootArr;           (* delta pos. of bullets *)
      ShootSpeed : speedType;          (* speed to shoot again *)
      ShootCtr   : speedType;
      GetAdjustX : boolean;            (* flag: true=adjust pos. in X/Y-dir.*)
      GetAdjustY : boolean;

      constructor Init( nx, ny: PosType; st: byte; points: byte; hits: byte;
                        mvSp: speedType; shSp: speedType );
      destructor  Done; virtual;

      procedure   SetShoot( sa: ShootArr );
      (*$IFDEF hugo*)
      procedure   SetMoveSpeed( ms: speedType );
      procedure   SetShootSpeed ( ss: speedType );
      (*$ENDIF*)
      procedure   MoveIt; virtual;

      procedure EnableAdjustX;         (* adjust pos. to player *)
      procedure EnableAdjustY;

    end;

  BasePtr = ^BaseObj;
  BaseObj = object( EnemyObj )

      constructor Init(ny: PosType);

      procedure   HitIt( hits: byte ); virtual;

    end;

  CometPtr = ^CometObj;
  CometObj = object ( EnemyObj )

      constructor Init( ny: PosType );

      procedure MoveIt; virtual;
      procedure CheckXYRange; virtual;

    end;

  UfoPtr = ^UfoObj;
  UfoObj = object ( extdEnemyObj )

      constructor Init( ny: PosType );

      procedure MoveIt; virtual;
      procedure CheckXYRange; virtual;

    end;

  SeekerPtr = ^SeekerObj;
  SeekerObj = object ( EnemyObj )

      MoveSpeed: speedType;
      MoveCtr  : speedtype;
      AdjustX: boolean;

      constructor Init( nx, ny: PosType );
      procedure   MoveIt; virtual;

    end;

  SeekerDownPtr = ^SeekerDownObj;
  SeekerDownObj = object ( SeekerObj )

      constructor Init( nx, ny: PosType );

    end;

  SeekerUpPtr = ^SeekerUpObj;
  SeekerUpObj = object ( SeekerObj )

      constructor Init( nx, ny: PosType );

    end;

  FighterPtr = ^FighterObj;
  FighterObj = object ( extdEnemyObj )

      constructor Init;
      destructor  Done; virtual;

      procedure MoveIt; virtual;
      procedure CheckXYRange; virtual;

    end;

  RobotPtr = ^RobotObj;
  RobotObj = object ( extdEnemyObj )

      HeadDy     : PosType;  (* rel. pos to default head pos. *)
      HeadMoveDir: byte;     (* direction of head movement: 0=down, 1=up *)
      HeadMoveCtr: PosType;

      constructor Init;
      destructor  Done; virtual;

      procedure MoveIt; virtual;
      procedure CheckXYRange; virtual;

    end;

const
  RobotX         = 5;
  RobotHeadSizeX = 6;                  (* robot sizes *)
  RobotHeadSizeY = 6;
  RobotSizeX     = 9;
  RobotSizeY     = 12;
  RobotNeck      = '````'+RobotNeckCh1+RobotNeckCh2+RobotNeckCh3+' `';
  RobotStr: array[1..RobotSizeY] of string =
            ( RobotNeck,
              RobotNeck,               (* '`' stands for: skip char *)
              RobotNeck,
              RobotNeck,
              RobotNeck,
              '<\__/O\ `',
              '< ___/I `',
              '</ `[=] `',
              '```/__] `',
              '```H `H `',
              '```H `H `',
              '``<O><O> ' );

var
  RobotTopY: PosType;
  Robot    : RobotPtr;

(**********************************************************)
(**)                                                    (**)
(**) IMPLEMENTATION                                     (**)
(**)                                                    (**)
(**********************************************************)
uses Crt,
     Player;

const
  SeekerUp   = 1;                      (* seeker types *)
  SeekerDown = 2;

  HeadMoveDown = 0;                    (* robot head move directions *)
  HeadMoveUp   = 1;
  HeadMoveWait = 2;


function sc: PosType;
begin
  if ScrollStatus then
    sc := ScrollSpeed[Difficulty]
  else
    sc := SeekerSpeed[Difficulty];
end;

(*
**-------------------------------------
** MakeBigEnemy
**-------------------------------------
*)
procedure MakeBigEnemy( var list: GOList; mainObj: EnemyPtr;
                        sx, sy: byte; mx, my: byte; bs: string );
var
  i, j: byte;
  idx : byte;
  subObj : GameObjPtr;
begin
  for i := 1 to sx do
    for j := 1 to sy do begin
        idx := 1+(i-1)+sx*(j-1);
        if ( (bs[idx] <> '`')                    (* dummy object *)
             and ( (i<>mx) or (j<>my) )
           )
        then begin                               (* sub object *)
            subObj := New( GameObjPtr,
              Init( i-mx, j-my, flying ) );
            with subObj^ do begin
                SetParent( mainObj );
                SetDisplay( bs[idx], ColorStd );
              end;
            list.Append( subObj );
          end;
      end;
end;

(*
**-------------------------------------
** methods for EnemyObj
**-------------------------------------
*)
constructor EnemyObj.Init( nx, ny: PosType; st: byte; points: byte; hits: byte );
begin
  GameObj.Init( nx, ny, st );
  GetPoints   := points;
  SetHits( hits );
end;

destructor EnemyObj.Done;
var
  extra: GameObjPtr;
begin
  GameObj.Done;

  if status = killMe then begin        (* enemie got killed? *)

      Score := Score + GetPoints;      (* Y-> incr. score *)
      UpdateInfo := UpdateInfo or UpdScore;
      if Score >= LifeScore then begin (*     get extra life? *)
          if ShipsLeft < 10 then       (*     Y-> incr. lifes *)
            inc( ShipsLeft );
          case LifeScore of            (*         calc next LifeScore *)
            100: LifeScore :=  250;
            250: LifeScore :=  500;
          else
            inc( LifeScore, 500 );
          end;
          UpdateInfo := UpdateInfo or UpdLife;
        end;

      if ExtraRatioCtr = 0 then begin  (*     create extra *)
          ExtraRatioCtr := ExtraRatio;
          extra := New( GameObjPtr, Init( GetX, GetY, flying ) );
          extra^.SetDisplay( ExtraCh, ColorInv );
          extra^.SetAnimSpeed( 5 );
          extra^.SetScroll;
          EnemyBulletList.Append( extra );
        end
      else
        dec( ExtraRatioCtr );

    end;
end;

procedure EnemyObj.HitIt( hits: byte );
var
  toHit: byte;
begin
  if parent = NIL then begin
      if GetHits > hits then
        SetHits( GetHits-hits )
      else
        SetStatus( killMe );
    end
  else
    parent^.HitIt( hits );
end;

procedure EnemyObj.MoveIt;
begin
  GameObj.MoveIt;
end;

(*
**-------------------------------------
** methods for EnemyBulletObj
**-------------------------------------
*)
constructor EnemyBulletObj.Init( nx, ny: PosType );
begin
  GameObj.Init( nx, ny, flying );
  SetSpeed( BulletSpeed[Difficulty] );
  SetDisplay( 'xX', ColorStd );
  SetAnimSpeed(3);
  SetScroll;
end;

procedure EnemyBulletObj.MoveIt;
var
  bkch: word;
begin
  GameObj.MoveIt;
  if parent = NIL then begin
      if speedCounter <> DontMove then
        DecX;
      bkch := GetBackgrCh;
      if ( (bkch <> goNufin)
           and (bkch <> goSpace)
           and (bkch <> goHillFloor) )
      then
        SetStatus( removeMe )
    end;
end;

(*
**-------------------------------------
** methods for extdEnemyObj
**-------------------------------------
*)
constructor extdEnemyObj.Init( nx, ny: PosType; st: byte;
                               points: byte; hits: byte;
                               mvSp: speedType; shSp: speedType );
begin
  EnemyObj.Init( nx, ny, st, points, hits );
  MoveSpeed  := mvSp; MoveCtr  := MoveSpeed;
  ShootSpeed := shSp; ShootCtr := ShootSpeed;
  GetAdjustX := false;
  GetAdjustY := false;
end;

destructor extdEnemyObj.Done;
begin
  EnemyObj.Done;
end;

procedure extdEnemyObj.MoveIt;
var
  i: byte;
  bullet: EnemyBulletPtr;
begin
  EnemyObj.MoveIt;
  if ( (MoveSpeed <> DontMove)         (* adjust position to player *)
       and (GetStatus = flying) )
  then
    if MoveCtr = 0 then begin
        MoveCtr := MoveSpeed;
        if GetAdjustX then
          if GetX < ShipBody^.GetX then
            IncX
          else if GetX > ShipBody^.GetX then
            DecX;
        if GetAdjustY then
          if GetY > ShipBody^.GetY then
            DecY
          else if GetY < ShipBody^.GetY then
            IncY;
      end
    else
      dec( MoveCtr );
  if ShootSpeed <> DontMove then       (* fire enemy bullets *)
    if ShootCtr = 0 then begin
        ShootCtr := ShootSpeed;
        for i := 1 to MaxEnemyShoot do
          with ShootPos[i] do
            if (dx <> NoShoot) then begin
                bullet := New( EnemyBulletPtr, Init( x+dx, y+dy ) );
                EnemyBulletList.Append( bullet );
              end;
      end
    else
      dec( ShootCtr );
end;

procedure extdEnemyObj.EnableAdjustX;
begin
  GetAdjustX := true;
end;

procedure extdEnemyObj.EnableAdjustY;
begin
  GetAdjustY := true;
end;

procedure extdEnemyObj.SetShoot( sa: ShootArr );
begin
  ShootPos := sa;
end;

(*
**-------------------------------------
** methods for BaseObj
**-------------------------------------
*)
constructor BaseObj.Init(ny: PosType);
begin
  EnemyObj.Init(sx, ny, flying, 1, 1);
  SetDisplay( 'T', ColorInv );
  SetAnimSpeed(10);
  SetScroll;
end;

procedure BaseObj.HitIt( hits: byte );
begin
  EnemyObj.HitIt( hits );
  if GetStatus = killMe then begin
      Fuel := Fuel + 20 + 5*(LevelNum-Difficulty);
      if Fuel > MaxFuel then
        Fuel := MaxFuel;
      UpdateInfo := UpdateInfo + UpdFuel;
    end;
end;

(*
**-------------------------------------
** methods for CometObj
**-------------------------------------
*)
constructor CometObj.Init(ny: PosType);
var
  co: EnemyPtr;
begin
  EnemyObj.Init( sx, ny, flying, 0, 100 );
  SetDisplay( 'O', ColorStd );
  SetSpeed( CometSpeed[ Difficulty ] );
  SetScroll;
  MakeBigEnemy( EnemyBulletList, @self, 3,1,1,1, 'O=-' );
end;

procedure CometObj.MoveIt;
begin
  DecX;
end;

procedure CometObj.CheckXYRange;
begin
  if (GetX<-3) or (GetX>sx+3) then
    GameObj.CheckXYRange;
end;

(*
**-------------------------------------
** methods for UfoObj
**-------------------------------------
*)
constructor UfoObj.Init(ny: PosType);
var
  co: EnemyPtr;
begin
  extdEnemyObj.Init( sx, ny, flying, 5, 5,
                     UfMvSpeed[Difficulty], UfShSpeed[Difficulty] );

  SetDisplay( '<', ColorLit );
  SetSpeed( UfoSpeed[ Difficulty ] );
  SetScroll;
  SetShoot( UfoShoot );
  EnableAdjustY;
  MakeBigEnemy( EnemyList, @self, 3,3,1,2, '`/['+
                                           '<O='+
                                           '`\[' );
end;

procedure UfoObj.MoveIt;
begin
  extdEnemyObj.MoveIt;
  DecX;
end;

procedure UfoObj.CheckXYRange;
begin
  if (GetX<-3) or (GetX>sx+3) then
    GameObj.CheckXYRange;
end;

(*
**-------------------------------------
** methods for SeekerObj
**-------------------------------------
*)
constructor SeekerObj.Init(nx, ny: PosType);
var
  co: EnemyPtr;
begin
  AdjustX := ( (GameLevel>=3) or (GameScene>=UfoHangar) );
  EnemyObj.Init( nx, ny, waiting, 2+ord(AdjustX), 1+ord(Difficulty>=3) );
  SetSpeed( SeekerSpeed[ Difficulty ] );
  SetScroll;
  MoveSpeed := SeMvSpeed[Difficulty];
  MoveCtr   := MoveSpeed;
end;

procedure SeekerObj.MoveIt;
var
  bkch: word;
  dx, dy: PosType;
  mlX, mlY: PosType;
  mldiv: PosType;
  sc : SpeedType;
begin
  EnemyObj.MoveIt;
  bkch := GetBackgrCh;
  if ( ( (bkch=goHillFloor) and (y<MaxTopY) )
       or (bkch=goHillUp) or (bkch=goHillDown)
       or (bkch=goCity)
     )
  then
    SetStatus( removeMe )
  else begin
      if ScrollStatus then
        sc := ScrollSpeed[Difficulty]
      else
        sc := DontMove;
      dx := GetX-ShipBody^.GetX-1;
      dy := GetY-ShipBody^.GetY;
      if GetType = SeekerDown then
        dy := -dy;
      mlX := dx*sc+ScrollCounter;
      mlY := dy*SeekerSpeed[Difficulty];
      if (GetStatus = waiting) then begin
          if mlX <= mlY then begin
              SetStatus( flying );
              SetSpeed( SeekerSpeed[Difficulty] );
            end;
        end
      else if GetStatus = flying then begin
          if GetType = SeekerDown then
            IncY
          else
            DecY;
          if AdjustX then
            if MoveCtr = 0 then begin
                if (dy=0) or (sc=DontMove) then begin
                    if dx > 0 then
                      DecX
                    else if dx < 0 then
                      IncX
                  end
                else if dy > 0 then begin
                    mldiv := (mlx*10) div mly;
                    if mldiv < 10 then
                      IncX
                    else if mldiv > 10 then
                      DecX;
                  end;
                MoveCtr := MoveSpeed;
              end
            else
              dec( MoveCtr );
        end;
    end;
end;

(*
**-------------------------------------
** methods for SeekerDownObj
**-------------------------------------
*)
constructor SeekerDownObj.Init(nx, ny: PosType);
var
  co: EnemyPtr;
begin
  SeekerObj.Init( nx, ny );
  SetDisplay( 'V', ColorLit );
  SetType( SeekerDown );
end;


(*
**-------------------------------------
** methods for SeekerUpObj
**-------------------------------------
*)
constructor SeekerUpObj.Init(nx, ny: PosType);
var
  co: EnemyPtr;
begin
  SeekerObj.Init( nx, ny );
  SetDisplay( 'A', ColorLit );
  SetType( SeekerUp );
end;

(*
**-------------------------------------
** methods for FighterObj
**-------------------------------------
*)
constructor FighterObj.Init;
var
  co: EnemyPtr;
begin
  extdEnemyObj.Init( sx, sy div 2, flying, 25,
    (*$IFDEF TEST*)
    1,
    (*$ELSE*)
    5+5*Difficulty,
    (*$ENDIF*)
    FiMvSpeed[Difficulty], FiShSpeed[Difficulty] );
  SetDisplay( '<', ColorLit );
  SetSpeed( FighterSpeed[ Difficulty ] );
  SetScroll;
  EnableAdjustY;
  SetShoot( FighterShoot );

  co := New( EnemyPtr, Init( 2, -2, GetStatus, 0, 0 ) );
  co^.SetDisplay( '<', ColorLit );
  co^.SetParent( @self );
  EnemyList.Append( co );
  co := New( EnemyPtr, Init( 2,  2, GetStatus, 0, 0 ) );
  co^.SetDisplay( '<', ColorLit );
  co^.SetParent( @self );
  EnemyList.Append( co );
  MakeBigEnemy( EnemyBulletList, @self,
                6,7,1,4,
                '```/>`'+
                '```=>`'+
                '`_/H\`'+
                '`_OII>'+
                '``\H/`'+
                '```=>`'+
                '```\>`');
end;

destructor FighterObj.Done;
begin
  extdEnemyObj.Done;
  EnableScrolling;
end;

procedure FighterObj.MoveIt;
begin
  extdEnemyObj.MoveIt;
  if GetX > sx-10 then
    DecX;
end;

procedure FighterObj.CheckXYRange;
begin
end;

(*
**-------------------------------------
** methods for RobotObj
**-------------------------------------
*)
constructor RobotObj.Init;
var
  rx, ry: PosType;           (* robot position *)
  i     : byte;              (* loop var *)
  co    : EnemyBulletPtr;    (* help pointer to created robot mouth *)
  coDisp: string;
begin
  HeadDy := 0;
  HeadMoveCtr := 0;
  HeadMoveDir := HeadMoveUp;
  rx := sx+5;                                    (* robot position *)
  ry := sy-RobotSizeY+RobotHeadSizeY-4;
  extdEnemyObj.Init( rx, ry, flying, 50,         (* main robot head *)
    (*$IFDEF TEST*)
    1,
    (*$ELSE*)
    2+3*Difficulty,
    (*$ENDIF*)
    RoMvSpeed[Difficulty], RoShSpeed[Difficulty] );
  SetDisplay( 'Oo', ColorLit );
  SetAnimSpeed(4);
  SetSpeed( RobotSpeed[ Difficulty ] );
  SetScroll;
  SetShoot( RobotShoot );
  (*$IFNDEF NO_HEAD*)
  MakeBigEnemy( EnemyBulletList, @self,
                RobotHeadSizeX, RobotHeadSizeY, 3, 4,
                '``/\``'+             (* NOTE: "`" stands for: skip char *)
                '`/U \`'+
                '/_   >'+
                '```  I'+
                '\_   >'+
                '``\ /`' );
  coDisp := '_';
  if GameLevel >= 2 then
    coDisp := coDisp + '__[';
  if GameLevel > LevelNum then
    coDisp[3] := '[';
  for i := 1 to 2 do begin            (* robot mouth *)
      co := New( EnemyBulletPtr, Init( -i, 0 ) );
      EnemyBulletList.Append( co );
      with co^ do begin
          SetDisplay( coDisp, ColorStd );
          SetAnimSpeed( 35-5*Difficulty );
          SetScroll;
          SetParent( @self );
        end;
    end;
  (*$ENDIF*)
end;

destructor RobotObj.Done;
begin
  EnemyObj.Done;
  EnableScrolling;
  Robot := NIL;
end;

procedure RobotObj.MoveIt;
var
  enmRnd : byte;
  enmXRnd: PosType;
  SkDnPtr: SeekerDownPtr;
  SkUpPtr: SeekerupPtr;
begin
  extdEnemyObj.MoveIt;
  if SceneMoveNum <= 1 then            (* disable scrolling *)
    DisableScrolling;
  if not ScrollStatus then begin
      enmRnd  := Random(100);          (* set seekers *)
      if enmRnd < 10+Difficulty*10 then begin
          (*$IFNDEF NO_ROCKET*)
          enmXRnd := 2+Random( sx-RobotX-10);
          SkDnPtr := New( SeekerDownPtr, Init( enmXRnd, TopY+1 ) );
          SkDnPtr^.SetStatus( flying );
          EnemyList.Append( SkDnPtr );
          enmXRnd := 2+Random( sx-RobotX-10);
          SkUpPtr := New( SeekerUpPtr, Init( enmXRnd, HillY ) );
          SkUpPtr^.SetStatus( flying );
          EnemyList.Append( SkUpPtr );
          (*$ENDIF*)
        end;

      if HeadDy=0 then                 (* move head *)
        begin
          HeadMoveDir := HeadMoveUp;   (*   calc new directxion *)
          HeadMoveCtr := 2+Random( RobotHeadSizeY-2 );
        end
      else if (HeadDy=RobotHeadSizeY-1) then begin
          HeadMoveDir := HeadMoveDown;
          HeadMoveCtr := 2+Random( RobotHeadSizeY-2 );
        end;
      if (HeadMoveCtr=0) then begin
          HeadMoveDir := Random(3);
          HeadMoveCtr := 2+Random( RobotHeadSizeY-2 );
          if HeadMoveDir = HeadMoveWait then
            inc( HeadMoveCtr, 15-Difficulty*3 );
        end;
      if HeadMoveDir = HeadMoveUp then begin     (* move up/down *)
          DecY;
          inc( HeadDy );
        end
      else if HeadMoveDir = HeadMoveDown then begin
          IncY;
          dec( HeadDy );
        end;
      dec( HeadMoveCtr )
    end;
end;

procedure RobotObj.CheckXYRange;
begin
end;

begin
end.