(*
** GameObjs.PAS
**
** unit used by ASCSCRAM.PAS (ASCII-Scramble)
**
** updated:  4-Oct-94
** created:  8-Sep-94
*)

unit GameObjs;

(**********************************************************)
(**)                                                    (**)
(**) INTERFACE                                          (**)
(**)                                                    (**)
(**********************************************************)
uses
  Display;

const
  removeMe     = 98;                   (* status values *)
  killMe       = 99;
  waiting      =  1;
  flying       =  2;
  flyingFast   =  3;
  Crashing     =  9;
  exploding    = 10;
  explodingEnd = 26;

  DontMove = -1;                       (* speed constant for no moving *)

  MaxAnimCh = 4;                       (* max. phases of animation *)

type
  GameObjPtr   = ^GameObj;

  ChildNodePtr = ^ChildNode;
  ChildNode    = record
      item: GameObjPtr;
      next: ChildNodePtr;
    end;

  GameObj    = object
      x, y        : PosType;           (* position *)
      status      : byte;              (* object status *)
      objType     : byte;              (* object type *)
      speed       : speedType;         (* speed (speed counter reset) *)
      speedCounter: speedType;         (* speed counter (move, if 0) *)
      backGrCh    : word;              (* screen char, object overwrote *)
      parent      : GameObjPtr;        (* parent object *)
      children    : ChildNodePtr;      (* first entry of child list *)
      GetScroll   : boolean;           (* flag: true=scroll with screen *)
      GetHits     : byte;              (* hits left/to score *)
      AnimCh      : array[1..MaxAnimCh+1] of word; (* animated screen char *)
      AnimSpeed   : speedType;         (* speed if animation *)
      AnimIdx     : byte;              (* index for AnimCh *)
      AnimCtr     : speedType;         (* counter for AnimSpeed *)
      Color       : byte;              (* color *)

      constructor Init(nx,ny: PosType; st: byte);
      destructor  Done; virtual;

      procedure SetXY( nx, ny: PosType);         (* set position *)
      procedure SetX( nx: PosType );
      procedure SetY( ny: PosType );
      procedure SetStatus( ns: byte );           (* set status *)
      procedure SetType( ty: byte );             (* set object type *)
      procedure SetSpeed( ns: speedType );
      procedure SetParent( pa: GameObjPtr );     (* set parent object *)
      procedure SetScroll;                       (* enable/disable scrolling *)
      procedure SetHits( nh: byte );             (* set hits *)
      procedure ClrScroll;
      procedure CheckXYRange; virtual;           (* check for out of screen *)

      procedure IncX;
      procedure DecX;
      procedure IncY;
      procedure DecY;

      procedure Display;
      procedure SetDisplay( ds: string; dc: byte );
      procedure SetAnimSpeed( as: speedType );
      procedure Clear;
      procedure ReadBackGrCh;

      procedure HitIt( hits: byte ); virtual;
      procedure MoveIt; virtual;

      function GetX: PosType;
      function GetY: PosType;
      function GetSpeed: speedType;
      function GetStatus: byte;
      function GetType: byte;
      function GetBackgrCh: word;
      function PosIsEqual( go: GameObj ): boolean; virtual;
      function DoMove: boolean; virtual;

    end;

  (*
  ** game object procedure
  ** (used with GOList.DoProc)
  *)
  GameObjProc = procedure (go: GameObjPtr );

  GOLNodePtr = ^GOLNode;
  GOLNode    = record
      Item      : GameObjPtr;
      prev, next: GOLNodePtr;
    end;

  GOList = object
      First: GOLNodePtr;               (* shows to first entry in list *)
      last : GOLNodePtr;

      constructor Init;
      destructor  Done; virtual;

      procedure   Append( item: GameObjPtr );
      procedure   Remove( nd: GOLNodePtr );
      procedure   RemoveItem( item: GameObjPtr );

      procedure   DoProc( proc: GameObjProc);
      procedure   DoProcBackwd( Proc: GameObjProc );

      function    findItemNode( item: GameObjPtr ): GOLNodePtr;
    end;

var
  PlayerList,                          (* ship, smart bomb effect *)
  BulletList,                          (* missiles & bombs *)
  EnemyList,                           (* tanks, rockets, .. *)
  EnemyBulletList,                     (* commets, robot *)
  MiscList: GOList;                    (* explosions, f/x, .. *)

  ItemNum   : word;
  (*$IFDEF TEST*)                      (* GOList status vars *)
  MaxItemNum: word;
  MinMemFree: LongInt;
  (*$ENDIF*)

procedure DoWithAllChildren( go: GameObjPtr; proc: GameObjProc );

(**********************************************************)
(**)                                                    (**)
(**) IMPLEMENTATION                                     (**)
(**)                                                    (**)
(**********************************************************)
uses Crt;

(*
**-------------------------------------
** misc. procs & funcs
**-------------------------------------
*)
procedure DoWithAllChildren( go: GameObjPtr; proc: GameObjProc );
var
  nxtChild: ChildNodePtr;
begin
  nxtChild := go^.children;
  with nxtChild^ do
    while nxtChild <> NIL do begin
        Proc( item );
        nxtChild := next;
      end;
end;

(*
**-------------------------------------
** methods for GameObj
**-------------------------------------
*)
constructor GameObj.Init(nx,ny: PosType; st: byte);
var
  i: byte;
begin
      x := nx; y   := ny;
      status       := st;
      objType      := 0;
      speed        := DontMove;
      speedCounter := speed;
      parent       := NIL;
      children     := NIL;
      GetScroll    := false;
      GetHits      := 0;
      backgrCh     := goNufin;
      for i := 1 to MaxAnimCh do
        AnimCh[i] := 0;
      AnimIdx      := 1;
      AnimSpeed    := 1;
      AnimCtr      := 0;
end;

destructor  GameObj.Done;
var
  nxtChild, prvChild: ChildNodePtr;
begin
  nxtChild := children;                (* remove children list *)
  while (nxtChild <> NIL) do begin     (* but NOT children themselfes! *)
      prvChild := nxtChild;
      nxtChild := nxtChild^.next;
      Dispose( prvChild );
    end;
  children := NIL;
end;

procedure GameObj.SetXY( nx, ny: PosType);
begin
  x := nx; y := ny;
end;

procedure GameObj.SetX( nx: PosType );
begin
  x := nx;
end;

procedure GameObj.SetY( ny: PosType );
begin
  y := ny;
end;

procedure GameObj.SetStatus( ns: byte );
var
  nxtChild: ChildNodePtr;
begin
  nxtChild := children;
  while nxtChild <> NIL do begin
      nxtChild^.item^.SetStatus( ns );
      nxtChild := nxtChild^.next;
    end;
  status := ns;
end;

procedure GameObj.SetType( ty: byte );
begin
  objType := ty;
end;

procedure GameObj.SetSpeed( ns: speedType );
begin
  speed        := ns;
  speedCounter := ns;
end;

procedure GameObj.SetParent( pa: GameObjPtr );
var
  newChildNode: ChildNodePtr;
  lastChild   : ChildNodePtr;
begin
  GetScroll := pa^.GetScroll;
  status := pa^.status;
  parent := pa;
  with pa^ do begin
      newChildNode := New( ChildNodePtr );
      if (newChildNode <> NIL) then with newChildNode^ do begin
          item := @self;
          next := NIL;
          if pa^.children = NIL then
            pa^.children := NewChildNode
          else begin
              lastChild := pa^.children;
              while lastChild^.next <> NIL do
                lastChild := lastChild^.next;
              lastChild^.next := newChildNode;
            end;
        end;
    end;
end;

procedure GameObj.SetDisplay( ds: string; dc: byte );
var
  i: byte;
begin
  for i := 1 to length(ds) do
    AnimCh[i] := ord(ds[i]) + dc shl 8;
  AnimCh[i+1] := 0;
  AnimIdx := 1;
  AnimCtr := 0;
end;

procedure GameObj.SetAnimSpeed( as: speedType );
begin
  AnimSpeed := as;
  if AnimCtr > as then
    AnimCtr :=as-1;
end;

procedure GameObj.SetScroll;
begin
  GetScroll := true;
end;

procedure GameObj.ClrScroll;
begin
  GetScroll := false;
end;

procedure GameObj.SetHits( nh: byte );
begin
  GetHits := nh;
end;

procedure GameObj.IncX;
begin
  x := x+1;
end;

procedure GameObj.DecX;
begin
  x := x-1;
end;

procedure GameObj.IncY;
begin
  y := y+1;
end;

procedure GameObj.DecY;
begin
  y := y-1;
end;

procedure GameObj.Display;
var
  dispCh: word;
begin
  dispCh := AnimCh[ AnimIdx ];
  if AnimCtr = 0 then begin
      AnimCtr := AnimSpeed;
      inc( AnimIdx );
      if AnimCh[ AnimIdx ] = 0 then
        AnimIdx := 1;
    end
  else
    dec( AnimCtr );
  if dispCh <> goNufin then
    setScr(GetX, GetY, dispCh );
end;

procedure GameObj.Clear;
begin
  if backgrCh <> goNufin then
    setScr(GetX, GetY, backGrCh);
end;

procedure GameObj.CheckXYRange;
begin
  if ( ((parent = NIL) and ((x<-1) or (x>sx) )) ) then
    SetStatus( removeMe );
end;

procedure GameObj.ReadBackGrCh;
begin
  BackGrCh := getScr(GetX, GetY);
end;

procedure GameObj.MoveIt;
begin
  (* do nufin*);
end;

procedure GameObj.HitIt( hits: byte );
begin
  (* do nufin*);
end;

function GameObj.GetX: PosType;
begin
  if (parent = NIL) then
    GetX := x
  else
    GetX := parent^.x + x;
end;

function GameObj.GetY: PosType;
begin
  if (parent = NIL) then
    GetY := y
  else
    GetY := parent^.y + y;
end;

function GameObj.GetStatus: byte;
begin
    GetStatus := status
end;

function GameObj.GetType: byte;
begin
  GetType := objType;
end;

function GameObj.GetSpeed: speedType;
begin
  GetSpeed:= speed;
end;

function GameObj.GetBackgrCh: word;
begin
  GetBackgrCh := getScr(GetX,GetY);
end;


function GameObj.DoMove: boolean;
begin
  if speedCounter = 0 then begin
      speedCounter := speed;
      DoMove       := true;
    end
   else begin
      if speed <> DontMove then
        dec(speedCounter);
      DoMove := false;
    end
end;

function GameObj.PosIsEqual( go: GameObj ): boolean;
begin
  PosIsEqual := (x=go.GetX) and (y=go.GetY);
end;

(*
**-------------------------------------
** methods for GOList (GameObjectList)
**-------------------------------------
*)

(*
** GOList.Init
*)
constructor GOList.Init;
begin
  First := NIL;
  Last  := NIL;
  ItemNum    := 0;
  (*$IFDEF TEST*)
  MaxItemNum := 0;
  MinMemFree := MaxAvail;
  (*$ENDIF*)
end;

(*
** GOList.Done
*)
destructor GOList.Done;
var
  nd: GOLNodePtr;
begin
  while (first <> NIL) do
    Remove( first );
end;

(*
** GOList.Append
*)
procedure GOList.Append( item: GameObjPtr );
var
  nd: GOLNodePtr;
begin
  New(nd);
  if (nd <> NIL) then begin

      nd^.item   := item;
      if (first = NIL) then
        first := nd;
      last^.next := nd;
      nd^.prev   := last;
      nd^.next   := NIL;
      last       := nd;

      inc(ItemNum);
      (*$IFDEF TEST*)
      if ItemNum > MaxItemNum then
        MaxItemNum := ItemNum;
      if MaxAvail < MinMemFree then
        MinMemFree := MaxAvail;
      (*$ENDIF*)

    end
  else
    Dispose( item, Done );
end;

(*
** GOList.findItem
*)
function GOList.findItemNode( item: GameObjPtr ): GOLNodePtr;
var
  nd     : GOLNodePtr;
  ndFound: GOLNodePtr;
begin
  nd := first; ndFound := NIL;
  while (nd <> NIL) and ( ndFound = NIL ) do begin
      if ( item = nd^.item ) then
        ndFound := nd;
      nd := nd^.next;
    end;
  findItemNode := ndFound;
end;

(*
** GOList.RemoveItem
*)
procedure GOList.RemoveItem( item: GameObjPtr );
var
  nd: GOLNodePtr;
begin
  nd := findItemNode( item );
  Remove( nd );
end;


(*
** GOList.Remove
*)
procedure GOList.Remove( nd: GOLNodePtr );
var
  oldParent: GameObjPtr;
begin
  if ( nd <> NIL ) then begin

      if (nd = first) then begin
          first       := nd^.next;
          if first<>NIL then
            first^.prev := NIL;
        end;
      if (nd = last) then begin
          last       := nd^.prev;
          if last <> NIL then
            last^.next := NIL;
        end;
      if ( nd^.prev <> NIL ) then
        nd^.prev^.next := nd^.next;
      if ( nd^.next <> NIL ) then
        nd^.next^.prev := nd^.prev;
      nd^.prev := NIL; nd^.next := NIL;
      Dispose( nd^.item, Done );
      nd^.item := NIL;
      Dispose( nd );
      dec(ItemNum);
    end;
end;

(*
** GOList.DoProc
*)
procedure GOList.DoProc( Proc: GameObjProc );
var
  nd: GOLNodePtr;
begin
  nd := first;
  while (nd <> NIL) do begin
      Proc( nd^.item );
      nd := nd^.next;
    end;
end;

(*
** GOList.DoProcBkwd
*)
procedure GOList.DoProcBackwd( Proc: GameObjProc );
var
  nd: GOLNodePtr;
begin
  nd := last;
  while (nd <> NIL) do begin
      Proc( nd^.item );
      nd := nd^.prev;
    end;
end;

begin
end.