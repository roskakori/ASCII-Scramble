(*
** High score functions
*)
unit HiScore;

(**********************************************************)
(**)                                                    (**)
(**) INTERFACE                                          (**)
(**)                                                    (**)
(**********************************************************)
uses Dos, Crt,
     Global, Display;

const
  HSnameLen  = 10;
  HSentryLen = HSnameLen + 11 + 2 + 10;
  HSnum      = 10;
  HSfname    = 'ASCSCRAM.HIS';

  HStitleY   = 2;
  HSlistY    = 6;
  HSlistStep = 1;

type
  HSentryRec = record
      name : string[HSnameLen];
      score: LongInt;
      day  : word;
      month: word;
      year : word;
    end;

var
  HSentry: array[1..LevelNum, 1..HSnum] of HSentryRec;

procedure HighScoreScreen;

function CheckHiScore(newscore: LongInt): byte;
procedure EnterHiScore(pos: byte);


procedure ReadHiScores;
procedure WriteHiScores;

procedure WriteHSentry(i,j: byte);

(**********************************************************)
(**)                                                    (**)
(**) IMPLEMENTATION                                     (**)
(**)                                                    (**)
(**********************************************************)

var
  HSfile : file of HSentryRec;

procedure GetToday( var year, month, day: word );
var
  dow: word;
begin
  GetDate( year, month, day, dow );
end;


(*
** HSy
*)
function HSy(i: byte): byte;
begin
  HSy := HSlistY+(i-1)*HSlistStep;
end;


(*
** WriteHSentry
*)
procedure WriteHSentry(i,j: byte);
const
  dateStr: array[1..12] of string =
    ( 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' );
begin
  with HSentry[i,j] do begin
      GotoXY( HSnameLen + (sx-HSentryLen) div 2, HSy(j) );
      Write( Score: 11 );
      Write( day:4, '-' );
      if month <= 12 then
        Write( dateStr[month] )
      else
        Write( 'SUX' );
      Write('-', year );
      GotoXY( (sx-HSentryLen) div 2, HSy(j) );
      Write( name );
    end;
end;

(*
** ReadHiScores
*)
procedure ReadHiScores;
var
  i,j: byte;   (* loop vars *)
  y,m,d: word; (* store date *)
begin
  GetToday(y,m,d);                     (* init hiscores *)
  for i := 1 to LevelNum do
    for j := 1 to HSnum do
      with HSentry[i,j] do begin
          name  := 'none';
          score := 0;
          year  := y; month := m; day := d;
        end;
  Assign( HSfile, HSfname );           (* read hiscores *)
  (*$I-*)
  Reset( HSfile );
  (*$I+*)
  if IOResult <> 0 then begin
      WriteMessage('Creating hiscore table');
      WriteHiScores;
    end
  else begin
      for i := 1 to LevelNum do
        for j := 1 to HSnum do begin
            Read( HSfile, HSentry[i,j] );
          end;
      Close( HSfile );
    end;

end;

(*
** WriteHiScores
*)
procedure WriteHiScores;
var
  i,j: byte;
begin
  Assign( HSfile, HSfname );
  Rewrite( HSfile );
  if IOResult = 0 then begin
      for i := 1 to LevelNum do
        for j := 1 to HSnum do
          Write( HSfile, HSentry[i,j] );
      Close( HSfile );
    end
  else
    WriteMessage('Error writing hiscores');
end;

(*
** HighScoreScreen
*)
procedure HighScoreScreen;
var
  i: byte;
begin
  ClrScr;
  WriteCtr( HStitleY, '^H** high scores **^S' );
  for i := 1 to HSnum do begin
      WriteHSentry( Difficulty, i );
    end;
end;

(*
** CheckHiScore
*)
function CheckHiScore(newscore: LongInt): byte;
var
  pos: byte;
  i  : byte;       (* loop var *)
begin
  pos := HSnum;
  while (newscore > HSentry[Difficulty,pos].score) and (pos>0) do
    dec( pos );
  inc(pos);

  for i := HSnum-1 downto pos do
    HSentry[Difficulty, i+1] := HSentry[Difficulty, i];

  if pos > HSnum then
    pos := 0
  else with HSentry[Difficulty, pos] do begin
      name := '';
      score := newscore;
      GetToday( year, month, day );
    end;

  CheckHiScore := pos;

end;


(*
** EnterHiScore
*)
procedure EnterHiScore(pos: byte);
var
  PlName: string;
  enter : boolean;
  key   : char;
begin
  HighScoreScreen;
  enter := false;

  while not enter do begin

      TextAttr := ColorLit;
      WriteHSentry( Difficulty, pos );
      TextAttr := ColorStd;

      key := ReadKey;

      with HSentry[Difficulty, pos] do
        case key of
            #8 : if length(name) >= 1 then begin
                     name := Copy(name,1,length(name)-1);
                     GotoXY(1,WhereY);
                     ClrEol;
                   end;
            #13: enter := true;
            #27: begin
                   enter := true;
                   name := 'anonymous'
                 end;
            else
              if (key>=' ') and (key<=#127) then
                if length(name) < HSnameLen then
                  name := name + key;
              end;
          end;

  WriteHiScores;

end;




(*
** Initialisation
*)
begin
end.
