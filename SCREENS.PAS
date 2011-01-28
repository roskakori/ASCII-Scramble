(*
** Screen functions
*)
unit Screens;

(**********************************************************)
(**)                                                    (**)
(**) INTERFACE                                          (**)
(**)                                                    (**)
(**********************************************************)
uses Dos, Crt,
     Global, Display, GameObjs, HiScore;

procedure RestoreScreen;
procedure TitleScreen;
procedure GameScreen;
procedure GameOverScreen;

(**********************************************************)
(**)                                                    (**)
(**) IMPLEMENTATION                                     (**)
(**)                                                    (**)
(**********************************************************)

(*
** RestoreScreen
*)
procedure RestoreScreen;
begin
  RestoreTimerHandler;                 (* restore timer interrupt *)
  TextAttr := oldTextAttr;             (* restore color & screen *)
  (*$IFDEF TEST*)
  TextMode( CO80 );
  (*$ELSE*)
  TextMode( oldTextMode );
  (*$ENDIF*)
  ClrScr;
end;


(*
**
** TitleScreen
**
*)
procedure TitleScreen;
var
  sy2: byte;                 (* contains (sy div 2) *)
  gsx: byte;                 (* x-pos. of game setup display *)

  procedure displayTitleScreen;
  begin

    ClrScr;

    WriteCtr( sy2-6, '^H*** ASCII-SCRAMBLE ***^S' );
    WriteCtr( sy2-5, '                  v1.1' );
    WriteCtr( sy2-2, '(c) thomas aglassinger 1994, 2011' );
    WriteCtr( sy2-1, 'distributed under bsd license' );


    WriteCtr( sy2+1, '^Hgame setup:^S' );
    WriteColXY( gsx, sy2+4, '^I H ^S hi-score table' );
    WriteCtr( sy2+6, '^I SPACE ^S start game' );

    WriteCtr( sy  , '^Hgame controls:^S' );
    WriteCtr( sy+1, '^I CURSOR ^S move   ^I B ^S bomb ' );
    WriteCtr( sy+2, '^I SPACE ^S  fire   ^I P ^S pause' );
    WriteCtr( sy+3, '^I ENTER ^S  extra  ^IESC^S abort' );
  end;

const
  OffOn: array[0..1] of string = ( 'OFF', 'ON ' );
var
  key, key1: char;
begin
  sy2 := sy div 2;
  gsx := (sx-22) div 2;

  if GameLevel > LevelNum then
    GameLevel := LevelNum;
  displayTitleScreen;

  repeat
    Difficulty := GameLevel;
    WriteColXY( gsx, sy2+2, '^I D ^S difficulty: '+LevelName[GameLevel]+'  ' );
    WriteColXY( gsx, sy2+3, '^I A ^S auto-extra: '+OffOn[ord(AutoExtra)] );
    key := ReadKey;
    case upcase( key ) of
      'D': if GameLevel = 4 then
             GameLevel := 1
           else
             inc( GameLevel );
      'A': autoextra := not autoextra;
      'H': begin
             HighScoreScreen;
             key1 := ReadKey;
             displayTitleScreen;
           end;
    end;
    UserBreak := ( key = ESC );
  until UserBreak or (key=' ');
end;

(*
** GameScreen
*)
procedure GameScreen;
var
  i  : byte;
  s: string;

  procedure SetExtraColor( i: byte );
  begin
    if i=ExtraCounter then
      TextAttr := ColorInv
    else
      TextAttr := ColorStd;
  end;

  procedure WriteSpace( extra: byte );
  begin
    if ( ( (extra=ExtraCounter) or (extra=ExtraCounter+1) )
         and (ExtraCounter>0)
       )
    then
      TextAttr := ColorInv
    else
      TextAttr := ColorStd;
    Write( ' ' );
    if extra=ExtraCounter+1 then
      TextAttr := ColorStd;

  end;

const
  ShootStr: array[1..3] of string = ( 'DOUBLE', ' WING ', '      ' );

begin
  Move( scr, ScreenBase^, sizeof( scr ) );
  if UpdateInfo > 0 then begin

      if (UpdateInfo and UpdScore) >0 then begin

          GotoXY( 2, sy+1 );
          Str( Score:(MaxFuel div FuelDiv), s ) ;
          s := 'SCORE: ' + s;
          Write( s );
        end;

      if (UpdateInfo and UpdLife) >0 then begin

          GotoXY( 21, sy+1 );
          s := 'SHIPS : ';
          for i := 1 to ShipsLeft do
            s := s + '>';
          Write( s, ' ' );
        end;

      if (UpdateInfo and UpdFuel) >0 then begin

          GotoXY( 2, sy+2 );
          s := 'FUEL : ';
          for i := 1 to (Fuel div FuelDiv) do
            s := s + '>';
          for i := 1+(Fuel div FuelDiv) to (MaxFuel div FuelDiv) do
            s := s + ':';
          Write( s );
        end;

      if ( UpdateInfo and UpdLevel ) >0 then begin

          GotoXY( 21, sy+2 );
          s := Levelname[Difficulty];
          if GameLevel = LevelNum then
            s := s+ '  ';
          if GameLevel > LevelNum then begin
              s := s+'#';
              if GameLevel <= LevelNum+9 then
                s := s+chr( 48+GameLevel-LevelNum+1 )
              else
                s := s+'?';
            end;
          Write( s, ': ', SceneName[GameScene] );

        end;

      if (UpdateInfo and UpdExtra) >0 then begin
          GotoXY(1, sy+3);
          WriteSpace(1);
          Write( 'SPEED:', ShipSpeedIdx );
          WriteSpace(2);
          Write( 'SHOOT:', ShootDelayIdx );
          WriteSpace(3);
          Write( 'BOMBS:', SmartBombs );
          WriteSpace(4);
          Write( ShootStr[ShootLevel] );
          WriteSpace(5);
          Write( 'SHIELD' );
          WriteSpace(6);
        end;

      GotoXY( 1, sy+1 );
      UpdateInfo := 0;

    end;
end;


(*
**
** GameOverScreen
**
*)
procedure GameOverScreen;
var
  i: byte;
begin
  if not AbortGame then begin

      WriteCtr( sy div 2 -1, '/***********\' );
      WriteCtr( sy div 2   , '* GAME OVER *' );
      WriteCtr( sy div 2 +1, '\***********/' );

      (*$IFNDEF TEST*)
      Delay( 500 );
      FlushKeyBoard;
      i := 1;
      repeat
        Delay( 100 );
      until (i=25) or KeyPressed;
      (*$ENDIF*)

    end;

  FlushKeyBoard;

end;



(*
** Initialisation
*)
begin
  ReadHiScores;
end.
