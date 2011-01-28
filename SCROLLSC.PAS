unit ScrollSc;

(**********************************************************)
(**)                                                    (**)
(**) INTERFACE                                          (**)
(**)                                                    (**)
(**********************************************************)
uses Display;

procedure ScrollScreen;
procedure SetScreenColumn;

function  DoScrolling: boolean;
function  currScrollSpeed: speedType;


(**********************************************************)
(**)                                                    (**)
(**) IMPLEMENTATION                                     (**)
(**)                                                    (**)
(**********************************************************)
uses Global, GameObjs, Player, Enemies;

(*$IFDEF NO_ENEMIES*)
  (*$DEFINE NO_BASE*)
  (*$DEFINE NO_ROCKET*)
  (*$DEFINE NO_COMET*)
  (*$DEFINE NO_UFO*)
  (*$DEFINE NO_BASE*)
(*$ENDIF*)
const
  BuildingWidth = 5;                   (* width of buildings in robot city *)

(*
** currScrollSpeed
*)
function  currScrollSpeed: speedType;
begin
  if ScrollStatus then
    currScrollSpeed := ScrollSpeed[Difficulty]
  else
    currScrollSpeed := DontMove;
end;

(*
** ScrollScreen
*)
(*$F+*)
procedure ScrollObj( go: GameObjPtr );
begin
  if ( go^.GetScroll and (go^.parent=NIL) ) then
    go^.DecX;
end;
(*$F-*)

procedure ScrollScreen;
var
  i : byte;
  nd: GOLNodePtr;

begin
  for i := 1 to sy do
    Move(scr[i, 2], scr[i, 1], (sx-1)*2);

  EnemyList.DoProc( ScrollObj );
  EnemyBulletList.DoProc( ScrollObj );
  MiscList.DoProc( ScrollObj );

end;


(*
**
** SetScreenColumn
**
*)
procedure SetScreenColumn;
var
  enmRnd, enmYRnd: word;

procedure NewBase;                     (* set new base *)
begin
  (*$IFNDEF NO_BASE*)
  EnemyList.Append( New( BasePtr, Init( HillY )))
  (*$ENDIF*)
end;

procedure NewRocket;                   (* set new rocket *)
begin
  (*$IFNDEF NO_ROCKET*)
  EnemyList.Append( New( SeekerUpPtr, Init( sx, HillY )))
  (*$ENDIF*)
end;

procedure NewSeeker;                   (* set new seeker (down) *)
begin
  (*$IFNDEF NO_ROCKET*)
  EnemyList.Append( New( SeekerDownPtr, Init( sx, TopY+1 ) ) );
  (*$ENDIF*)
end;


procedure NewComet;                    (* set new comet *)
begin
  (*$IFNDEF NO_COMET*)
  if LastUfoOrComet = 0 then begin
      EnemyList.Append( New( CometPtr, Init( enmYRnd )));
      LastUfoOrComet := 5;
    end;
  (*$ENDIF*)
end;

procedure NewUfo;                      (* set new Ufo *)
begin
  (*$IFNDEF NO_UFO*)
  if LastUfoOrComet = 0 then begin
      EnemyList.Append( New( UfoPtr, Init( enmYRnd )));
      LastUfoOrComet := 5;
    end;
  (*$ENDIF*)
end;


(*
** SetScreenColum, main
*)
var
  i     : integer;
  hillRnd, topRnd: word;
  wd    : word;
  s     : string;
  ch    : char;

  setHillEnemy, setTopEnemy: boolean;

begin
  if LastUfoOrComet > 0 then
    dec( LastUfoOrComet );

  if GameScene = RobotCity then begin            (* create random numbers *)
      topRnd  := MinTopY +Random(MaxTopY-MinTopY+1);
      hillRnd := MinHillY+Random(MaxHillY-MinHillY+1);
    end
  else begin
      topRnd  := Random(10);
      hillRnd := Random(10);
    end;
  enmRnd  := Random(100);
  enmYRnd := 2+MaxTopY+Random(MinHillY-MaxTopY-2);

  if GameScene <>  RobotCity then begin          (** draw standard levels **)
      if TopY < MinTopY then
        wd := goHillDown
      else if TopY > MaxTopY then
        wd := goHillUp
      else begin
          wd := goHillFloor;
          case topRnd of
            1..3: if TopY > MinTopY then begin
                      wd := goHillUp;
                    end;
            4..6: if TopY < MaxTopY then begin
                      wd := goHillDown;
                    end;
          end; (*case*)
        end;

      if wd=goHillDown then
        inc( TopY );

      if wd<>goHillDown then
        setScr( sx, TopY+1, goSpace );

      if TopY > 0 then
        setScr(sx, TopY, wd);
      if wd = goHillUp then
        dec( TopY )
      else if wd = goHillDown then
        setScr( sx, TopY-1, goSpace );

      setScr( sx, TopY-1+ord(wd=goHillUp), goHillSolid );

      setTopEnemy := (wd=goHillFloor);          (* set-enemy flag *)

      if HillY < MinHillY then                   (* check hill ranges *)
        wd := goHillDown
      else if HillY > MaxHillY then
        wd := goHillUp
      else begin
          wd := goHillFloor;                     (* ranges ok: *)
          case hillRnd of
            1,2: if  HillY > MinHillY then begin (* move hill up *)
                   wd := goHillUp;
                 end;
            3,4: if  HillY < MaxHillY then begin (* move hill down *)
                   wd := goHillDown;
                 end;
          end;
        end;
      if wd = goHillUp then                      (* adjust HillY *)
        dec( HillY );

      if wd = goHillDown then                    (* set hill & space *)
        setScr( sx, HillY, goSpace );
      if wd = goHillFloor then begin
          setScr( sx, HillY, wd);
        end
      else begin
          setScr(sx, HillY+1, wd);
        end;

      if wd = goHillDown then                    (* set soild hill *)
        inc(HillY) ;
      setScr( sx, HillY+1+ord(wd=goHillUp), goHillSolid );

      setHillEnemy := (wd=goHillFloor);          (* set-enemy flag *)
    end
  else begin                                     (*** draw ROBOT CITY ***)
      setTopEnemy  := true;
      setHillEnemy := true;
      if SceneMoveNum <= sx+((sy-RobotTopY))+3 then begin
          if SceneMoveNum > sx then begin
              if TopY > RobotTopY then
                topRnd := TopY-1
              else if TopY < RobotTopY then
                topRnd := TopY+1
              else
                topRnd := TopY;
              hillRnd := topRnd+7;
            end
          else begin
              if ( (SceneMoveNum >= RobotX)          (* draw robot body *)
                   and (SceneMoveNum <= RobotX+RobotSizeX-1) )
              then begin
                  for i := 1 to RobotSizeY do begin
                      s := RobotStr[i];
                      ch := s[RobotSizeX+RobotX-SceneMoveNum];
                      case ch of
                        '`': (* do nufin *);
                        ' ': setScr( sx, sy+i-RobotSizeY-1, goSpace );
                      else
                        setScr( sx, sy+i-RobotSizeY-1, go(ch,ColorStd) );
                      end;
                    end;
                end;

              topRnd  := RobotTopY;
              hillRnd := sy-1;
              setTopEnemy  := false;
              setHillEnemy := false;
            end;
        end
      else if (SceneMoveNum mod BuildingWidth > 0) then begin
          topRnd := TopY;
          hillRnd := HillY;
        end;

      if SceneMoveNum > sx-1 then begin
          for i := 1 to topRnd do                (* draw top building *)
            setScr( sx, i, goCity );
          for i := topRnd+1 to TopY do
            setScr( sx, i, goSpace );

          for i := hillRnd+1 to sy do            (* draw floor building *)
            setScr( sx, i, goCity );
          for  i := HillY to hillRnd do
            setScr( sx, i, goSpace );
        end;

      TopY  := topRnd;
      HillY := hillRnd;

    end;

  if setHillEnemy then                 (* add enemies *)
    if enmRnd < 20 then                (*   standard enemies *)
      NewBase
    else if enmRnd < 30 then
      NewRocket;

  case GameScene of                (* scene depending enemies *)
    RocketYard, RocketCave:
      begin
        if (enmRnd > 40) and (enmRnd<50) and setHillEnemy then
          NewRocket;
      end;
    CometField:
      begin
        if (enmRnd>40) and (enmRnd<80) then
          NewComet;
      end;
    UfoHangar:                         (*   ufo hangar *)
      begin
        if  (SceneMoveNum>sx) then begin
            if ((enmRnd>40) and (enmRnd<60)) then
              NewUfo
            else if ((enmRnd>60) and (enmRnd<80)) then
              NewSeeker;
          end
        else if SceneMoveNum = sx then begin
            MinTopY  := MaxTopY;
            MinHillY := MaxHillY;
          end
        else if SceneMoveNum = 1 then begin
            DisableScrolling;
            EnemyList.Append( New( FighterPtr, Init ) )
        end
      end;
    RobotCity: begin                   (*   robot city *)
        if (SceneMoveNum > sx+10) then begin
          if (enmRnd > 40) and (enmRnd<60) then
            NewSeeker;
          end;
        if (SceneMoveNum = RobotX+9) then begin
            Robot := New( RobotPtr, Init );
            EnemyList.Append( Robot );
          end
      end;
  end; (*case*)

end;

function DoScrolling: boolean;
var
  doIt: boolean;
begin
  doIt := (ScrollCounter=0);
  if doIt then
    ScrollCounter := ScrollSpeed[Difficulty]
  else
    dec( ScrollCounter );
  DoScrolling := doIt and ScrollStatus;
end;

(*
** Initialisation
*)
begin
end.