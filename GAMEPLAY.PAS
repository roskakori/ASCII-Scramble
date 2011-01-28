unit GamePlay;

(**********************************************************)
(**)                                                    (**)
(**) INTERFACE                                          (**)
(**)                                                    (**)
(**********************************************************)
uses Dos,
     Global, GameObjs, Display, Player, Enemies,
     Screens, ScrollSc;

procedure DoNextMove;
procedure InitGame;
procedure InitLife;
procedure CleanupLife;

(*$IFDEF TEST*)
procedure QuitInfo;
(*$ENDIF*)

(**********************************************************)
(**)                                                    (**)
(**) IMPLEMENTATION                                     (**)
(**)                                                    (**)
(**********************************************************)
uses Crt;

const
  MinTopPercent : array[1..LevelNum] of byte = ( 0,25,50, 70);
  MaxTopPercent : array[1..LevelNum] of byte = (25,50,80,100);
  MinHillPercent: array[1..LevelNum] of byte = (40,60,85,100);
  MaxHillPercent: array[1..LevelNum] of byte = ( 0,25,50, 80);

(*
** InitGame
*)
procedure InitGame;
begin
  ClrScr;
  GameOver  := false;
  AbortGame := false;

  Score            := 0;
  ShipsLeft        := 2;

  ShipSpeedIdx     := 1;               (* reset extras *)
  ShootDelayIdx    := 1;
  ShootLevel       := 1;

  LifeScore        := 100;             (* get extra life at 100 points *)

  RobotTopY := sy-RobotSizeY-RobotHeadSizeY-2;

  SceneMoveNum     := 0;
  (*$IFDEF TEST*)
  GameLevel        := 1;
  GameScene        := RobotCity;
  AutoExtra        := true;
  SceneLength      := sx + 40;
  (*$ELSE*)
  GameScene        := RocketYard;
  SceneLength      := sx + 120;
  (*$ENDIF*)
end;

(*
** UpdateLevel;
*)
procedure UpdateLevel;
begin
  if SceneMoveNum = 0 then begin

      EnableScrolling;

      SceneMoveNum := SceneLength;
      inc( GameScene );                          (* inc. scene/level *)
      if GameScene > SceneNum then begin
          GameScene := 1;
          inc( GameLevel );
        end;
      if GameLevel <= LevelNum then              (* set difficulty *)
        Difficulty := GameLevel
      else
        Difficulty := LevelNum;

      Randomize;
      RandSeed :=                                (* set random seed *)
        GameLevel*SceneNum*SceneLength+SceneMoveNum;

      MinHillY := sy-(word(MinHillPercent[Difficulty])*(sy div 2) div 100);
      MaxHillY := sy-(word(MaxHillPercent[Difficulty])*(sy div 2) div 100);
      MinTopY  := (word(MinTopPercent[Difficulty])*(sy div 4) div 100);
      MaxTopY  := (word(MaxTopPercent[Difficulty])*(sy div 4) div 100);

      case GameScene of
        RocketYard: begin              (* rocket yard *)
            MinTopY :=  0;             (*   no top *)
            MaxTopY :=  0;
          end;
        CometField: begin              (* comet field *)
            MinTopY :=  0;             (*   no top *)
            MaxTopY :=  0;
          end;
        UfoHangar: begin               (* ufo hangar *)
            MinTopY := MaxTopY;        (*   flat top *)
          end;
        RobotCity: begin               (* robot city *)
            inc( MinTopY );            (*   adjust top & hill *)
            inc( MaxTopY );
            dec( MinHillY );
            dec( MaxHillY );
          end;
      end;

      LastUfoOrComet := 5;

      ExtraRatio    := GameLevel+2;    (* set extra ratio *)
      ExtraRatioCtr := ExtraRatio div 2;

      UpdateInfo := UpdateInfo or UpdLevel;

    end
  else
    dec( SceneMoveNum );

end;

(*
** InitLife
*)
procedure InitLife;
const
  GetReadyTxt = '** GET READY! **';
var
  i, j: byte; (* loop vars *)
  key : char;
begin

  ScrollCounter := 0;

  ExtraCounter := 0;                   (* reset ExtraCounter *)
  ShootDelayCtr := 0;

  SceneMoveNum := 0;                   (* set level data *)
  dec( GameScene );
  UpdateLevel;

  HillY := sy;
  TopY  := 0;

  for i := 1 to sy do                  (* clear screen array *)
    for j := 1 to sx do
      setScr(j, i, goSpace );
  for i := 1 to sx do                  (* draw floor *)
    setScr( i,HillY, goHillFloor );

  UpdateInfo := UpdAll;
  GameScreen;                          (* display "Get Ready" *)
  GotoXY( (sx-length(GetReadyTxt)) div 2, sy div 2 );
  Write( GetReadyTxt );
  FlushKeyboard;
  (*$IFNDEF TEST*)
  i := 0;
  while ( i<10 ) and not KeyPressed do begin
      inc(i);
      Delay(200);
    end;
  FlushKeyboard;
  (*$ENDIF*)

  GameScreen;
end;


(*
**
** ClrObjects
**
*)
(*$F+*)
procedure ClrObj( go: GameObjPtr );
begin
  with go^ do begin
      Clear;
      CheckXYRange;
    end;
end;
(*$F-*)

procedure ClrObjects( var list: GOList );
var
  nd, nd_nxt: GOLNodePtr;
  nd_child, nd_child_nxt : GOLNodePtr;
  expl: GameObjPtr;
begin
  nd := list.first;
  while (nd<>NIL) do
    with nd^.item^ do begin
        nd_nxt := nd^.next;
        Clear;
        CheckXYRange;
        if ( (GetStatus = removeMe) or (GetStatus = killMe) ) then begin
            if nd^.item^.children <> NIL then
              CheckXYRange;
            if GetStatus = killMe then
              expl := AddExplosion( GetX, GetY, GetScroll );
            list.Remove( nd );
          end;
        nd := nd_nxt;
      end;
end;

(*
** MoveObj
*)
(*$F+*)
procedure MoveObj( go: GameObjPtr );
begin
  if go^.DoMove then
    go^.MoveIt;
end;
(*$F-*)

(*
** DisplayObj
*)
(*$F+*)
procedure DisplayObj( go: GameObjPtr );
begin
  go^.Display;
end;
(*$F-*)

(*
** GetObjBackgr
*)
(*$F+*)
procedure GetObjBackgr( go: GameObjPtr );
begin
  go^.ReadBackgrCh;
end;
(*$F-*)


(*
**
** CheckPlayer
**
*)
procedure CheckPlayer;
begin
  if ( (Fuel div FuelDiv) <> (oldFuel div FuelDiv) )
  then begin
    UpdateInfo := UpdFuel;
    oldFuel := Fuel;
  end;
  if (Fuel = 0) then
    ShipCrashed := true;
end;

(*
** CheckHits
*)
procedure CheckHits;
var
  expl  : GameObjPtr;                (* new explosion *)

  procedure ExplodeObj( go: GameObjPtr );
  var
    nxtChild: ChildNodePtr;
  begin
    nxtChild := go^.children;
    while nxtChild <> NIL do
      with nxtChild^.item^ do begin
          ExplodeObj( nxtChild^.item );
          nxtChild := nxtChild^.next;
        end;
    with go^ do begin
        expl := AddExplosion( GetX, GetY, true );
        if GetStatus <> killMe then
          SetStatus( removeMe )
      end;
  end;

var
  nd_bul, nd_enm: GOLNodePtr;          (* bullet/enenmy node *)
  bkch  : word;                        (* background char *)
  nxtChild: ChildNodePtr;
begin
  nd_bul := BulletList.first;
  while (nd_bul <> NIL) do with nd_bul^.item^ do begin
      nd_enm := EnemyList.first;
      bkch := getScr( GetX, GetY );
      if GetStatus < Exploding then begin

          if ( (bkch = goShipBody)
                    or (bkch = goShipFront)
                    or (bkch = goShipBody)
                    or (bkch = goShipWing)
                    or (bkch = goShipShield)
                    or (bkch = goExplosion1)
                    or (bkch = goExplosion2)
                  ) then begin
                (* do nufin; ignore these cases *)
            end
          else if ( (bkch = goHillUp)
                    or (bkch = goHillDown)
                    or (bkch = goCity) )
          then
            ExplodeObj( nd_bul^.item )
          else begin
              while (nd_enm <> NIL) do
                with nd_enm^.item^ do begin
                    if nd_bul^.item^.PosIsEqual( nd_enm^.item^ ) then begin
                        HitIt( nd_bul^.item^.GetHits );
                        nd_bul^.item^.SetStatus( removeMe );
                      end;
                    nd_enm := nd_enm^.next;
                  end;
              if GetStatus<>removeMe then
                if ( (objType=Bomb) and (bkch=goHillFloor) ) then
                  ExplodeObj( nd_bul^.item )
                else if ( (bkch<>goSpace) and (bkch<>goExtra)
                          and (bkch<>goHillFloor) )
                then
                  SetStatus( removeMe );
            end;
        end;
      nd_bul := nd_bul^.next;
    end;
end;

(*
** CheckShipObjHit
*)
(*$F+*)
procedure CheckShipObjHit( go: GameObjPtr );
var
  bkch: word;
  nd  : GOLNOdePtr;
  hitBackgr  : boolean;
  hitAnything: boolean;
begin
  with go^ do begin
      bkch := GetBackgrCh;
      hitBackgr := ( ( (bkch=goHillFloor) and (GetY<=MaxTopY) )
                     or (bkch=goHillUp)
                     or (bkch=goHillDown)
                     or (bkch=goCity) );
      hitAnything := hitBackgr;
      if (not hitBackgr) then begin
          if ( (bkch=goSpace)
               or (bkch=goMissile)
               or (bkch=goBomb) )
          then begin
            (* do nufin *)
            end
          else if bkch = goExtra then begin
              NextExtra;
              nd := EnemyBulletList.first;
              while (nd<>NIL) do begin
                  if PosIsEqual( nd^.item^ ) then begin
                      nd^.item^.SetStatus( removeMe );
                      nd := NIL;
                    end
                  else
                    nd := nd^.next;
                end;
            end
          else
            hitAnything := (Shield = 0) and (bkch<>goHillFloor);
        end;
      if hitAnything then
        if ShipBody^.GetStatus = flying then
          ShipBody^.SetStatus( Crashing );
    end;
end;
(*$F-*)

(*
**
** DoNextMove
**
*)
procedure DoNextMove;
begin

  ScrollTimerFlag := false;            (* reset scroll timer *)

  ClrObjects( MiscList );
  ClrObjects( PlayerList );
  ClrObjects( BulletList );
  ClrObjects( EnemyBulletList );
  ClrObjects( EnemyList );

  EnemyList.DoProc( MoveObj );         (* move enemies *)
  EnemyBulletList.DoProc( MoveObj );

  CheckHits;

  BulletList.DoProc( MoveObj );        (* move player & bullets *)
  PlayerList.DoProc( MoveObj );
  MiscList.DoProc( MoveObj );


  if DoScrolling and (ShipBody^.GetStatus<Exploding) then begin      (* scroll screen *)

      CheckHits;

      ScrollScreen;
      SetScreenColumn;


      UpdateLevel;

    end;

  EnemyList.DoProcBackwd( GetObjBackgr );
  EnemyBulletList.DoProcBackwd( GetObjBackgr );
  BulletList.DoProcBackwd( GetObjBackgr );
  PlayerList.DoProcBackwd( GetObjBackgr );
  MiscList.DoProcBackwd( GetObjBackgr );

  EnemyList.DoProcBackwd( DisplayObj );
  EnemyBulletList.DoProcBackwd( DisplayObj );

  CheckHits;
  PlayerList.DoProc( CheckShipObjHit );

  BulletList.DoProcBackwd( DisplayObj );
  PlayerList.DoProcBackwd( DisplayObj );
  MiscList.DoProcBackwd( DisplayObj );

  while not ScrollTimerFlag do         (* wait for timer interrupt *)
    (* nufin *) ;

  GameScreen;

end;

(*
** CleanupLife
*)
procedure CleanupLife;
begin
  PlayerList.Done;                     (* clear lists *)
  BulletList.Done;
  EnemyBulletList.Done;
  EnemyList.Done;
  MiscList.Done;

  if ShipsLeft = 0 then begin          (* decr. lifes *)
      GameOver := true;
      GameOverScreen;
    end
  else
    dec( ShipsLeft );

end;

(*$IFDEF TEST*)
(*
** QuitInfo
**
** display info about memory & object usage,
** check for lost memory;
*)
procedure QuitInfo;
begin
  WriteLn( 'max.items  used: ', MaxItemNum );
  WriteLn( 'min.memory left: ', MinMemFree );
  WriteLn( 'max.memory used: ', oldMaxAvail-MinMemFree );
  if MaxAvail <> oldMaxAvail then
    WriteLn( 'WARNING: ', oldMaxAvail-MaxAvail, ' bytes of memory lost.', #7 );
end;
(*$ENDIF*)

(*
** Initialisation
*)
begin
  PlayerList.Init;
  BulletList.Init;
  EnemyBulletList.Init;
  EnemyList.Init;
  MiscList.Init;
end.