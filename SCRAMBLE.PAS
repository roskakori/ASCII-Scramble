

(* SetObjects: aufsplitten in SetShip, SetEnemies, SetBullets *)


program Scramble;
uses Crt, Dos;

const
  ESC = #27;

  (*$IFDEF CO80*)
  sx = 80;                             (* game screen dimension *)
  sy = 23;
  ScreenMode = CO80;
  (*$ELSE*)
  sx = 40;
  sy = 23;
  ScreenMode = CO40;
  (*$ENDIF*)

  MaxEnemy  = sx div 2;                (* max. numbers of game objects *)
  MaxBullet = sx div 2;

  MinBombRatio = 3;
  MaxBombRatio = 1;

  available    = 0;                    (* status values *)
  waiting      = 1;
  flying       = 2;
  flyingFast   = 3;
  exploding    = 9;
  explodingEnd =25;

  MaxLaserTemp = 10;                   (* laser constants *)
  MinLaserSpeed = 3;
  MaxLaserSpeed = 8;

  MaxFuel      = 200;                  (* fuel constants *)
  FuelDiv      = 20;

  MinShipSpeed = 5;                    (* ship speed constants *)
  MaxShipSpeed = 2;
  MinMissileSpeed = 3;                 (* missile speed range *)
  MaxMissileSpeed = 1;
  MinBombSpeed    = 8;
  MaxBombSpeed    = 3;
  MinRocketSpeed  = 5;                 (* enemy speed constants *)
  MaxRocketSpeed  = 2;

  MinScrollSpeed = 8;
  MaxScrollSpeed = 2;


type

  BulletType = ( Missile, Bomb );
  EnemyType  = ( Base, Rocket, Ufo, Comet,
                 verSeeker, horSeeker, Robot );

  BulletRec = record                   (* bullet record *)
      btype : BulletType;
      x, y  : byte;
      status: byte;
      speed : byte;                    (*   speed constant *)
      spdCtr: byte;                    (*   speed counter *)
      backgr: word;
    end;

  EnemyRec = record                    (* enemy record *)
      etype : EnemyType;
      x, y  : byte;                    (*   position *)
      status: byte;
      toHit : byte;                    (*   hits to kill enemy left *)
      points: word;                    (*   points scored when hit *)
      speed : byte;                    (*   speed constant *)
      spdCtr: byte;                    (*   speed counter *)
      backgr: word;                    (*   stores background char *)
    end;

var
  UserBreak    : boolean;
  GamePaused   : boolean;
  GameOver     : boolean;
  ShipCrashed  : boolean;

  ScrollSpeed   : byte;
  ScrollCounter : byte;

  scr       : array[1..sy, 1..sx] of word;
  ScreenBase: pointer;
  UpdateInfo: boolean;                 (* update score display *)

  ShipX, ShipY: byte;                  (* ship position *)
  TopY, HillY : byte;
  TopActive   : boolean;
  MinHillY, MaxHillY,                  (* hill/top limits *)
  MinTopY,  MaxTopY: byte;

  Bullet: array[1..MaxBullet] of BulletRec;
  Enemy : array[1..MaxEnemy ] of EnemyRec;

  BombCounter: byte;
  BombRatio  : byte;

  MoveCounter : LongInt;

  Score       : LongInt;               (* points scored *)
  Fuel        : word;                  (* ship fuel *)
  oldFuel     : word;
  ShipsLeft   : byte;
  ShipSpeed   : byte;                  (* ship speed *)
  ShipCounter : byte;
  ShipBackgr1,
  ShipBackgr2 : word;

  LaserTemp   : byte;                  (* laser temperature *)
  oldLaser    : byte;
  LaserSpeed  : byte;                  (* laser cool-down ratio *)
  LaserCounter: byte;

  MissileSpeed: byte;                  (* bullet default speed *)
  BombSpeed   : byte;

  RocketSpeed,                         (* enemy default speed *)
  UfoSpeed,
  CometSpeed:   byte;
  (*
  ** game objects
  *)
  goShipBack,                          (* player *)
  goShipFront,
  goBullet,
  goBomb,

  goRocket,                            (* enemies *)
  goBase,
  goUfo,

  goExplosion1,
  goExplosion2,

  goHillUp,                            (* landscape *)
  goHillDown,
  goHillFloor,

  goSpace    : word;

  (*
  ** colors
  *)
  ColorStd,
  ColorInv,
  ColorLit: byte;


(*
**
** Init
**
*)
procedure Init;
begin
  ColorStd := TextAttr;
  ColorInv := (ColorStd shr 4) + (ColorStd and 7) shl 4;
  ColorLit := ColorStd xor 8;

  goShipBack  := 35 + ColorInv shl 8;
  goShipFront := 62 + ColorLit shl 8;
  goBullet    := 111 + ColorStd shl 8;
  goBomb      := 118 + ColorStd shl 8;

  goRocket    := 65 + ColorLit shl 8;
  goBase      := 84 + ColorInv shl 8;
  goUfo       :=  2 + ColorLit shl 8;

  goExplosion1 := 43 + ColorStd shl 8;
  goExplosion2 := 42 + ColorStd shl 8;


  goHillUp    := 47 + ColorStd shl 8;
  goHillDown  := 92 + ColorStd shl 8;
  goHillFloor := 95 + ColorStd shl 8;

  goSpace     := 32 + ColorStd shl 8;

  TextMode( ScreenMode );

end;


(*
**
** TitleScreen
**
*)
procedure TitleScreen;

   procedure WriteCtr( dy: ShortInt; s: string );
   begin
     GotoXY( ( sx-length(s) ) div 2, 1+(sy div 2)+dy );
     Write( s );
   end;

var
  key: char;
begin
  ClrScr;
  ScreenBase := ptr( $b800, 0);
  WriteCtr( -(sy div 2), 'kill-bill-productions present:' );
  WriteCtr( -4, '*** ASCII-SCRAMBLE ***' );
  WriteCtr( -3, '                  v0.5' );
  WriteCtr(  1, '(W) by Tommy-Saftw”rx in 1994' );
  WriteCtr(  3, 'This is FREEWARE!' );

(*$IFDEF TEST*)
  key := 'x';
(*$ELSE*)
  key := ReadKey;
(*$ENDIF*)
  UserBreak := ( key = ESC );
end;

(*
** GameScreen
*)
procedure GameScreen;
var
  i  : byte;
  s: string;
begin
  Move( scr, ScreenBase^, sizeof( scr ) );
  if UpdateInfo then begin
      UpdateInfo := false;
      GotoXY( 1, sy+1 );

      Str( Score:MaxLaserTemp, s ) ;
      s := 'SCORE: ' + s + '  SHIPS: ';
      for i := 1 to ShipsLeft do
        s := s + '>';
      WriteLn( s, ' ' );

      s := 'LASER: ';
      for i := 1 to LaserTemp do
        s := s + '>';
      for i := LaserTemp+1 to MaxLaserTemp do
        s := s + ':';
      s := s + '  FUEL : ';
      for i := 1 to (Fuel div FuelDiv) do
        s := s + '>';
      for i := 1+(Fuel div FuelDiv) to (MaxFuel div FuelDiv) do
        s := s + ':';
      Write( s );

    end;
end;

(*
** InitGame
*)
procedure InitGame;
begin
  ClrScr;
  GameOver := false;

  ShipsLeft   := 3;
  ShipSpeed   := MinShipSpeed;
  LaserSpeed  := MinLaserSpeed;
  BombRatio   := MinBombRatio;
  Score       := 0;
  MoveCounter := 0

end;

(*
** InitLife
*)
procedure InitLife;
var
  i, j: byte; (* loop vars *)
begin

  ScrollSpeed := MinScrollSpeed;
  ScrollCounter := 0;

  ShipCrashed := false;                (* ship vars *)
  ShipX       := sx div 5;
  ShipY       := sy div 2;
  ShipBackgr1 := goSpace;
  ShipBackgr2 := goSpace;
  Fuel        := 200;                  (* init fuel *)
  oldFuel     := Fuel;
  LaserTemp   := 0;                    (* init laser *)
  oldLaser    := LaserTemp;
  BombRatio   := 0;                    (* init bomb *)
  BombCounter := BombRatio;

  MissileSpeed := MinMissileSpeed;     (* bullet speed *)
  BombSpeed    := MinBombSpeed;

  RocketSpeed  := MinRocketSpeed;      (* enemy speeds *)

  for i := 1 to MaxBullet do
    Bullet[i].status := available;
  for i := 1 to MaxEnemy do
    Enemy[i].status := available;


end;
(*
**
** SetupLevel
**
*)
procedure SetupLevel;
var
  i, j: byte;
begin
  MinHillY := sy-(sy div 3);
  MaxHillY := sy;
  MinTopY  := 1;
  MaxTopY  := sy div 5;

  HillY := MaxHillY;
  TopY  := 0;

  TopActive := true;

  UpdateInfo := true;

  for i := 1 to sy do
    for j := 1 to sx do
      scr[i, j] := goSpace;
  for i := 1 to sx do
    scr[HillY, i] := goHillFloor;

end;

(*
** LaunchBullet
*)
procedure LaunchBullet( bt: BulletType );
var
  i: byte;
begin
  i := 1;                            (* search for free bullet *)
  while (i<=MaxBullet) and (Bullet[i].status<>available) do
    inc(i);
  if i <= MaxBullet then
    with Bullet[i] do begin
        x      := ShipX;
        y      := ShipY;
        status := flying;
        btype  := bt;
        case btype of
          Missile: begin
                     x := ShipX+2;
                     speed := MissileSpeed;
                   end;
          Bomb   : speed := BombSpeed;
        end;
        backgr := scr[y, x];
      end;
end;

(*
** LaunchEnemy
*)
procedure LaunchEnemy( et: EnemyType; nx, ny: byte );
var
  i: byte;
begin
  i := 1;                            (* search for free enemy *)
  while (i<=MaxEnemy) and (Enemy[i].status<>available) do
    inc(i);
  if i <= MaxEnemy then
    with Enemy[i] do begin
        x      := nx;
        y      := ny;
        backgr := scr[y, x];
        etype  := et;
        status := flying;
        case etype of
          Base  : begin
                    ToHit  := 1;
                    Points := 1;
                    speed  := 0;
                  end;
          Rocket: begin
                    ToHit  := 1;
                    Points := 2;
                    speed  := RocketSpeed;
                    status := waiting;
                  end;
        end;
        spdCtr := speed;
      end;
end;

(*
** HitEnemy
*)
procedure HitEnemy( i: byte );
begin
  with Enemy[i] do begin
      dec( ToHit );
      if ( ToHit = 0 ) then begin
          if Points <> 0 then begin
              Score := Score + Points;
              UpdateInfo := true;
            end;
          status := available;
        end;
    end;
end;

(*
** MoveShip
*)
procedure MoveShip;

var
  key: char;
  i  : byte;
begin
  if KeyPressed then begin

      key := UpCase( ReadKey );
      case Key of
        ESC: begin                     (* abort game *)
               UserBreak := true;
             end;
        'P': repeat                    (* pause key *)
               key := UpCase( ReadKey );
             until key = 'P';
        #0 : begin
               dec(Fuel);
               key := ReadKey;
               case key of             (* move Ship *)
                 #72: if ShipY > 1 then dec(ShipY);
                 #80: if ShipY < sy then inc(ShipY);
                 #75: if ShipX > 1 then dec(ShipX);
                 #77: if ShipX < (word(sx)*3 div 4) then inc(ShipX);
               else
                 inc(Fuel);
               end;
             end;
        ' ': begin                     (* launch missile(s) & bomb *)
               LaunchBullet( Missile );
               if BombCounter = 0 then begin
                   LaunchBullet( Bomb );
                   BombCounter := BombRatio;
                 end
               else
                  dec( BombCounter );
             end;
      end;

    end;
end;

(*
** ScrollScreen
*)
procedure ScrollScreen;
var
  i: byte;
begin
  for i := 1 to sy do
    Move(scr[i, 2], scr[i, 1], (sx-1)*2);

  for i := 1 to MaxBullet do           (* scroll bullets *)
    with Bullet[i] do
      if status <> available then
        if x = 1 then
          status := available
        else
          if (btype <> Bomb) or (status<>flying) then
            dec( x );

  for i := 1 to MaxEnemy do            (* scroll enemies *)
    with Enemy[i] do
      if status <> available then begin
        if x = 1 then
          status := available
        else
          dec( x );
        end;
end;


(*
**
** ClrObjects
**
*)
procedure ClrObjects;
var
  i: byte;
begin
  scr[ ShipY, ShipX ]   := ShipBackgr1;(* clear ship *)
  scr[ ShipY, ShipX+1 ] := ShipBackgr2;

  for i := 1 to MaxBullet do           (* clear bullets *)
    with Bullet[i] do
      if status <> available then
        scr[y, x] := backgr;

  for i := 1 to MaxEnemy do           (* clear enemies *)
    with Enemy[i] do
      if status <> available then
        scr[ y, x ] := backgr;

end;


(*
**
** MoveObjects
**
*)
procedure MoveObjects;
var
  i: byte;
  ix, iy: integer; (* enemy position, converted to integer *)
begin
  for i := 1 to MaxBullet do           (* bullets *)
    with Bullet[i] do
      if status = flying then
        if spdCtr = 0 then begin
            case btype of
              Missile: if ( x = sx ) then
                         status := explodingEnd
                       else
                         inc( x );
              Bomb   : inc( y );

            end; (*case*)
            spdCtr := speed;
          end
        else
          dec( spdCtr );

  for i := 1 to MaxEnemy do             (* enemies *)
    with Enemy[i] do
      if ( status <> available )
         and ( status < exploding )
      then if ( spdCtr = 0 ) then begin
          ix := x; iy := y;
          case etype of
            Base  : (* just look *);
            Rocket: case status of
                      waiting:
                        if ( ( abs(ix-ShipX) - abs(iy-ShipY) ) <= 2 )
                           and ( ix-ShipX < 2 )
                           and ( iy-ShipY > 0 )
                        then
                          status := flying;
                      flying:
                        begin
                          dec(y);
                          if y = 0 then
                            status := available;
                        end;
                    end;
          end; (*case*)
          spdCtr := speed;
        end
      else
        if speed > 0 then
          dec( spdCtr );

end;

(*
**
** SetObjects
**
*)
procedure SetObjects;
var
  i: byte;
begin
  for i := 1 to MaxBullet do
    with Bullet[i] do
      if status <> available then
        backgr := scr[ y, x ];

  for i := 1 to MaxEnemy do
    with Enemy[i] do
      if status <> available then
        backgr := scr[ y, x ];

  scr[ ShipY, ShipX ]   := goShipBack;
  scr[ ShipY, ShipX+1 ] := goShipFront;

  for i := 1 to MaxBullet do
    with Bullet[i] do begin
        if status >= exploding then begin
            if status = explodingEnd then begin
                status := available;
                scr[y, x] := backgr;
              end
            else begin
                if (status-exploding) and 4 = 4 then
                  scr[y, x] := goExplosion1
                else
                  scr[y, x] := goExplosion2;
                inc( status );
              end;
          end
        else if status = flying then
          case btype of
            Missile: scr[ y, x ] := goBullet;
            Bomb   : scr[ y, x ] := goBomb;
          end;
    end;

  for i := 1 to MaxEnemy do
    with Enemy[i] do
      if (status <> available) then
        if status = exploding then
          scr[y,x] := backgr
        else
          case etype of
            Base  : scr[ y, x ] := goBase;
            Rocket: scr[ y, x ] := goRocket;
          end;

end;

(*
** GetBackgr
*)
procedure GetBackgr;
var
  i: byte;
begin
  ShipBackgr1 := scr[ShipY, ShipX];    (* get ship background *)
  ShipBackgr2 := scr[ShipY, ShipX+1];

  for i := 1 to MaxBullet do           (* get bullet background *)
    with Bullet[i] do
      if status <> available then
         backgr := scr[ y, x ];

  for i := 1 to MaxEnemy do            (* get enemy background *)
    with Enemy[i] do
      if status <> available then
        backgr := scr[ y, x ];

end;

(*
** SetBullets
*)
procedure SetBullets;
var
  i: byte;
begin
  for i := 1 to MaxBullet do
    with Bullet[i] do begin
        if status >= exploding then begin
            if status = explodingEnd then begin
                status := available;
                scr[y, x] := backgr;
              end
            else begin
                if (status-exploding) and 4 = 4 then
                  scr[y, x] := goExplosion1
                else
                  scr[y, x] := goExplosion2;
                inc( status );
              end;
          end
        else if status = flying then
          case btype of
            Missile: scr[ y, x ] := goBullet;
            Bomb   : scr[ y, x ] := goBomb;
          end;
    end;
end;

(*
** SetShip
*)
procedure SetShip;
begin
  scr[ ShipY, ShipX ]   := goShipBack;
  scr[ ShipY, ShipX+1 ] := goShipFront;
end;

(*
** SetEnemies
*)
procedure SetEnemies;
var
  i: byte;
begin
  for i := 1 to MaxEnemy do
    with Enemy[i] do
      if (status <> available) then
        if status = exploding then
          scr[y,x] := backgr
        else
          case etype of
            Base  : scr[ y, x ] := goBase;
            Rocket: scr[ y, x ] := goRocket;
          end;

end;


(*
**
** SetScreenColumn
**
*)
procedure SetScreenColumn;
var
  i     : byte;
  rndNum: word;
  wd    : word;
begin
  if (TopY > 0) or TopActive  then begin
      if TopY > 0 then
        scr[TopY, sx] := goSpace;
      scr[ TopY+1, sx] := goSpace;
      if TopActive then begin
          wd := goHillFloor;
          rndNum := Random(10);
          case rndNum of
            1..3: if TopY > MinTopY then begin
                      wd := goHillUp;
                    end;
            4..6: if TopY < MaxTopY then begin
                      inc( TopY );
                      wd := goHillDown;
                    end;
          end; (*case*)
        end
      else begin
          wd := goHillUp;
        end;
      if TopY > 0 then
        scr[ TopY,sx ] := wd;
      if wd = goHillUp then
        dec( TopY );
    end;

  scr[HillY, sx] := goSpace;
  wd := goHillFloor;
  rndNum := Random(10);
  case rndNum of
    1,2: if  HillY > MinHillY then begin (* move hill up *)
           dec(HillY);
           wd := goHillUp;
         end;
    3,4: if  HillY < sy then begin       (* move hill down *)
           wd := goHillDown;
         end;
  end;

  for i := MinHillY-1 to HillY-1 do
    scr[i, sx] := goSpace;
  for i := Hilly to sy do
    scr[i, sx] := goSpace;
  if wd = goHillFloor then
    scr[HillY, sx] := wd
  else
    scr[HillY+1, sx] := wd;

  if wd = goHillDown then
    inc(HillY);

  if wd = goHillFloor then begin
      rndNum := random(10);
      case rndNum of
        1,2: LaunchEnemy( Base, sx, HillY );
        3  : begin
               LaunchEnemy( Rocket, sx, HillY );
             end;
      end;
    end;

end;


(*
**
** CheckPlayer
**
*)
procedure CheckPlayer;
begin
  if ( (Fuel div FuelDiv) <> (oldFuel div FuelDiv) )
       or ( LaserTemp <> oldLaser )
  then begin
    UpdateInfo := true;
    oldFuel := Fuel;
    oldLaser := LaserTemp;
  end;
  if (Fuel = 0) then
    ShipCrashed := true;

end;


(*
**
** CheckHits
**
*)
procedure CheckHits;
var
  i, j: byte;
  enemyFound: boolean;
  wd: word;
begin
  for i := 1 to MaxBullet do
    with Bullet[i] do
      if status = flying then begin
                 wd := scr[y,x];
          if (wd <> goSpace)
             and ( (wd <> goHillFloor) or (btype = Bomb) )
          then begin
              status := exploding;
              j := 1; enemyFound := false;
              while ( j <= MaxEnemy ) and not enemyFound do
                if (Enemy[j].x = x) and (Enemy[j].y = y) then
                  enemyFound := true
                else
                  inc( j );
              if enemyFound then
                HitEnemy( j );
            end;
      end;
end;

(*
**
** DoNextMove
**
*)
procedure DoNextMove;
begin

  ClrObjects;

  MoveShip;
  MoveObjects;

  if ScrollCounter = 0 then begin
      ScrollCounter := ScrollSpeed;
      ScrollScreen;
      SetScreenColumn;
    end;
  dec(ScrollCounter);

  GetBackgr;

  SetEnemies;
  CheckHits;
  CheckPlayer;
  SetBullets;
  SetShip;

  GameScreen;

end;

begin

  Init;

  repeat
    TitleScreen;

    if not UserBreak then begin

        InitGame;
        repeat

          InitLife;
          SetupLevel;
          repeat
            DoNextMove;
          until ShipCrashed or UserBreak;

        until GameOver or UserBreak;

      end;

  until UserBreak;

end.