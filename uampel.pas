unit UAmpel;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  {$ifdef FPC}
  lcltype, LCLIntf, lcl,
  {$endif}
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, syncobjs, ExtCtrls,
  StdCtrls;

type
  TMidiInData = record
    DeviceIndex: integer;
    Status, Data1, Data2: byte;
    Timestamp: Int64;
  end;

  TMouseEvent = record
    P: TPoint;
    Pitch: byte;
    Row_, Index_: integer;
    Key: word;
    Velocity: byte;

    procedure Clear;
  end;

  TAmpel = class;
  TMidiInBuffer = class;

  TAmpelEvents = class
  private
    frmAmpel: TAmpel;
    MouseEvents: array [0..64] of TMouseEvent;
    FUsedEvents: integer;

    procedure DoAmpel(Index: integer; On_: boolean);
  public
    CriticalAmpel: syncobjs.TCriticalSection;

    constructor Create(Ampel: TAmpel);
    destructor Destroy; override;
    procedure NewEvent(Event: TMouseEvent);
    procedure EventOff(const Event: TMouseEvent);
    procedure GetKeyEvent(Key: integer; var Event: TMouseEvent);
    procedure CheckMovePoint(const P: TPoint; Down: boolean);
    procedure SendMidiOut(const Status, Data1, Data2: byte);
    function  Paint(Row, Index: integer): boolean;
    procedure AllEventsOff;
    function IsOn(Row: integer; Index: integer): boolean;

    property UsedEvents : integer read FUsedEvents;
  end;

  TMidiInBuffer = class
    Critical: syncobjs.TCriticalSection;
    Head, Tail: word;
    Buffer: array [0..1023] of TMidiInData;
    public
      constructor Create;
      destructor Destroy; override;
      function Empty: boolean;
      function Get(var rec: TMidiInData): boolean;
      function Put(const rec: TMidiInData): boolean;
  end;

  { TAmpel }

  TAmpel = class(TForm)
    cbxScrollBar: TCheckBox;
    Label1: TLabel;
    procedure FormPaint(Sender: TObject);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormCreate(Sender: TObject);

    procedure Timer1Timer(Sender: TObject);
  private
    lastTime: TDateTime;
    MidiInBuffer: TMidiInBuffer;

    function MakeMouseDown(const P: TPoint): TMouseEvent;

  public
    AmpelEvents: TAmpelEvents;
    Timer1: TTimer;
    KnopfGroesse: integer;
    OffsetX, OffsetY: integer;
    function KnopfRect(Row: byte {0..4}; index: byte {0..19}): TRect;
    procedure PaintAmpel(Row: byte {0..4}; index: integer {0..19}; On_: boolean);
    procedure OnMidiInData(aDeviceIndex: LongInt; aStatus, aData1, aData2: byte; aTimestamp: Int64);
    procedure cbxVertikal(Sender: TObject);

  end;

// Diskant: 5 Reihen à 20 Tasten

var
  Ampel: TAmpel;

function NoteToMidi(const Ton: string): byte;
procedure MakeBlackArray;


implementation

{$R *.lfm}

uses
{$ifdef MSWINDOWS}
  Midi,
{$else}
  UMidi, urtmidi,
{$endif}
  UAkkordeon;

const
  KnopfCount = 20;

type
  TArr = array [0..KnopfCount-1] of boolean;
  TBlackArray = array [0..4] of TArr;

  TZeile = array [0..KnopfCount-1] of string;
  TDiskant = array[0..4] of TZeile;

  TMidiZeile = array [0..KnopfCount-1] of byte;
  TMidiDiskant = array [0..4] of TMidiZeile;

const
  Diskant : TDiskant =
     (('', 'cis', 'e', 'g', 'ais', 'cis+', 'e+', 'g+', 'ais+', 'cis++', 'e++', 'g++', 'ais++', 'cis+++', 'e+++', 'g+++', 'ais+++', 'cis++++', '', ''),
      ('d', 'f', 'gis', 'h', 'a++', 'd+', 'f+', 'gis+', 'h+', 'd++', 'f++', 'gis++', 'h++', 'd+++', 'f+++', 'gis+++', 'h+++', '', '', ''),
      ('', 'dis', 'fis', 'a', 'c+', 'dis+', 'fis+', 'a+', 'c++', 'dis++', 'fis++', 'a++', 'c+++', 'dis+++', 'fis+++', 'a+++', 'c++++', '', '', ''),
      ('', 'cis', 'e', 'g', 'ais', 'cis+', 'e+', 'g+', 'ais+', 'cis++', 'e++', 'g++', 'ais++', 'cis+++', 'e+++', 'g+++', 'ais+++', 'cis++++', '', ''),
      ('d', 'f', 'gis', 'h', 'a++', 'd+', 'f+', 'gis+', 'h+', 'd++', 'f++', 'gis++', 'h++', 'd+++', 'f+++', 'gis+++', 'h+++', '', '', '')
     );
var
  BlackArr : TBlackArray;
  MidiDiskant : TMidiDiskant;

const
  Leiter : array [0..11] of string = ('c', 'cis', 'd', 'dis', 'e', 'f', 'fis', 'g', 'gis', 'a', 'ais', 'h');
  black: set of byte = [1, 3, 6, 8, 10];
  grundTon = 36;

procedure TAmpel.FormCreate(Sender: TObject);
begin
  MidiInBuffer := TMidiInBuffer.Create;
  AmpelEvents := TAmpelEvents.Create(self);
  KnopfGroesse := 52;
  cbxVertikal(nil);
  cbxScrollBar.OnChange := cbxVertikal;
  Timer1 := TTimer.Create(self);
  Timer1.name := 'Timer1';
  Timer1.interval:= 1;
  Timer1.OnTimer := Timer1Timer;
end;

procedure TAmpel.cbxVertikal;
begin
  Label1.Visible := Akkordeon.cbxVertikal.Checked;
  cbxScrollBar.Visible := Akkordeon.cbxVertikal.Checked;
  if Akkordeon.cbxVertikal.Checked then
  begin
    Height := 1200;
    Width := 360;
    OffsetX := 20;
    OffsetY := 50;
  end else begin
    Height := 360;
    Width := 1200;
    OffsetX := 60;
    OffsetY := 40;
  end;
  if cbxScrollBar.Checked and Akkordeon.cbxVertikal.Checked then
    VertScrollBar.Range := Height-5
  else
    VertScrollBar.Range := 0;
  invalidate;
end;

function TAmpel.KnopfRect(Row: byte {0..4}; index: byte {0..19}): TRect;
var
  rect: TRect;
  Knopf: integer;
  Abstand: integer;
begin
  Abstand := round(KnopfGroesse*1.1);
  if Akkordeon.cbxVertikal.Checked then
    Index := 19 - Index;
  result := TRect.Create(0, 0, KnopfGroesse, KnopfGroesse);
  result.Offset(round(Index*Abstand), round(Row*Abstand*sqrt(3)/2));
  if Row in [1, 3] then
    result.Offset(-Abstand div 2, 0);
  result.Offset(OffsetX, OffsetY);
  if Akkordeon.cbxVertikal.Checked then
  begin
    rect.Left := result.Top;
    rect.Right := result.Bottom;
    rect.Top := result.Left;
    rect.Bottom := result.Right;
    result := rect;
  end;
end;

procedure TAmpel.FormPaint(Sender: TObject);
var
  k, i, l: integer;
begin
  canvas.Pen.Color := $ffffff;
  for i := 0 to 4 do
  begin
    l := 18;
    if i in [1, 3] then
      inc(l);
    for k := 0 to l do
    begin
      if BlackArr[i, k] then
        canvas.Brush.Color := $00
      else
        canvas.Brush.Color := $007f7f;
        if MidiDiskant[i, k] > 0 then
          PaintAmpel(i, k, AmpelEvents.IsOn(i, k));
    end;

  end;
//  writeln('canvas');
end;


procedure TAmpel.FormMouseUp(Sender: TObject; Button: TMouseButton;  Shift: TShiftState; X, Y: Integer);
var
  Q: TPoint;
begin
  Q.X := X;
  Q.Y := Y;

  AmpelEvents.CheckMovePoint(Q, false);
end;

procedure TAmpel.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
begin
  P.X := X;
  P.Y := Y;
  MakeMouseDown(P);
end;

procedure TAmpel.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  Q: TPoint;
begin
  if not (ssLeft in Shift) then
    exit;

  Q.X := X;
  Q.Y := Y;
  AmpelEvents.CheckMovePoint(Q, true);
end;

function TAmpel.MakeMouseDown(const P: TPoint): TMouseEvent;
var
  Row, Index: byte;
  Event: TMouseEvent;
  l: integer;
begin
  Event.Clear;
  Event.P := P;
  Event.Row_ := -1;
  Event.Index_ := 0;
  result := Event;

  for Row := 0 to 4 do
  begin
    l := 18;
    if Row in [1, 3] then
      l := 19;
    for Index := 0 to l do
      if (MidiDiskant[Row, Index] > 0) and
         KnopfRect(Row, Index).Contains(Event.P) then
      begin
        Event.Row_ := Row;
        Event.Index_ := Index;
        break;
      end;
    if Event.Row_ >= 0 then
    begin
      if not AmpelEvents.IsOn(Row, Index) then
      begin
        Event.Pitch := MidiDiskant[Row, Index];
        AmpelEvents.NewEvent(Event);
      end;
      break;
    end;
  end;
end;

procedure TAmpel.PaintAmpel(Row: byte {0..4}; index: integer {0..19}; On_: boolean);
var
  rect: TRect;
  s: string;
  l, m: integer;
begin
//  writeln('print');
  rect := KnopfRect(Row, index);
  if not On_ then
  begin
    if BlackArr[row, index] then
      canvas.Brush.Color := $0000
    else
      canvas.Brush.Color := $007f7f;
  end else
  if BlackArr[row, index] then
    canvas.Brush.Color := $ffff00
  else
    canvas.Brush.Color := $00ff00;

  canvas.Ellipse(rect);
  if Akkordeon.cbxAnzeigen.Checked then
  begin
    Canvas.Font.Color := $ffffff;
    s := Leiter[MidiDiskant[Row, Index] mod 12];
    l := Canvas.TextWidth(s);
    m := KnopfGroesse - 2*Canvas.Font.Size;
    Canvas.TextOut(rect.left + (KnopfGroesse-l) div 2, rect.Top + m div 2, s);
  end;
end;

procedure TAmpel.OnMidiInData(aDeviceIndex: LongInt; aStatus, aData1, aData2: byte; aTimestamp: Int64);
var
  t: int64;
  channel, ch, cmd: byte;
  rec: TMidiInData;
begin
  t := trunc(Now*24000*3600);
  lastTime := t;

  with rec do
  begin
    DeviceIndex := aDeviceIndex;
    Status := aStatus;
    Data1 := aData1;
    Data2 := aData2;
    Timestamp := t; // ms
  end;
  MidiInBuffer.Put(rec);
end;


procedure TAmpel.Timer1Timer(Sender: TObject);
var
  Event: TMouseEvent;
  Data: TMidiInData;
begin
  while MidiInBuffer.Get(Data) do
  begin
    if ((Data.Status shr 4) = 12) and (Data.Data2 = 0) then
      MidiOutput.Send(MicrosoftIndex, Data.Status, Data.Data1, Data.Data2)
    else
    if (Data.Status shr 4) in [8, 9] then
    begin
      Event.Clear;
      Event.Pitch := Data.Data1;
      Event.Row_ := -1;
      Event.Index_ := -1;
      Event.Velocity := Data.Data2;

      if (Data.Status shr 4) = 9 then
        AmpelEvents.NewEvent(Event)
      else
      if (Data.Status shr 4) = 8 then
        AmpelEvents.EventOff(Event);
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TMouseEvent.Clear;
begin
  P.X := -1;
  P.Y := -1;
  Row_ := 0;
  Index_ := -1;
  Key := 0;
  Pitch := 0;
  Velocity := 0;
end;

constructor TAmpelEvents.Create(Ampel: TAmpel);
begin
  frmAmpel := Ampel;
  CriticalAmpel := TCriticalSection.Create;
  FUsedEvents := 0;
end;

destructor TAmpelEvents.Destroy;
begin
  CriticalAmpel.Free;

  inherited;
end;

procedure TAmpelEvents.SendMidiOut(const Status, Data1, Data2: byte);
var
  s: string;
  i: integer;
begin
  SendMidi(Status, Data1, Data2);
{  s :=  Leiter[Data1 mod 12];
  for i:= (grundTon div 12)+1 to (Data1 div 12) do
    s := s + '''';
  writeln(Status, '  ', Data1, '  ', Data2, '  ', s); }
end;

procedure TAmpelEvents.NewEvent(Event: TMouseEvent);
var
  i, k: integer;
begin
  if UsedEvents >= High(MouseEvents) then
    exit;

  if Event.Row_ < 0 then
  begin
    for i := 0 to 4 do
      for k := 0 to 19 do
      begin
        if Event.row_ >= 0 then
          break;
        if MidiDiskant[i, k] = Event.Pitch then
        begin
          Event.row_ := i;
          Event.index_ := k;
          //writeln('row ', i, '  index ', k);
          break;
        end;
      end;
  end;
  CriticalAmpel.Acquire;
  try
    for i := 0 to UsedEvents-1 do
      if (MouseEvents[i].Row_ = Event.Row_) and
         (MouseEvents[i].Index_ = Event.Index_) then
        if (MouseEvents[i].Pitch = 0) or
           ((MouseEvents[i].Velocity > 0) and (Event.Velocity > 0)) then
          exit;
//      writeln('down  ', Event.row_, '  ', Event.index_);
      MouseEvents[UsedEvents] := Event;
      inc(fUsedEvents);
      DoAmpel(UsedEvents-1, true);
  finally
    CriticalAmpel.Release;
  end;
end;

procedure TAmpelEvents.DoAmpel(Index: integer; On_: boolean);
begin
  with MouseEvents[Index] do
  begin
    frmAmpel.PaintAmpel(Row_, Index_, On_);
    if On_ then
      SendMidiOut($90, Pitch, 120)
    else
      SendMidiOut($80, Pitch, 64)
  end
end;

procedure TAmpelEvents.EventOff(const Event: TMouseEvent);
var
  i, j: integer;
  r: integer;
begin
  CriticalAmpel.Acquire;
  try
    r := -1;
    for i := 0 to UsedEvents-1 do
      if (MouseEvents[i].Row_ = Event.Row_) and (MouseEvents[i].Index_ = Event.Index_) then
      begin
        r := i;
        break;
      end;

    if r = -1 then
      for i := 0 to UsedEvents-1 do
        if (MouseEvents[i].Pitch = Event.Pitch) and (Event.Pitch > 0) then
        begin
          r := i;
          break;
        end;

    if r >= 0 then
    begin
      DoAmpel(i, false);
      for j := r+1 to UsedEvents-1 do
        MouseEvents[j-1] := MouseEvents[j];
      dec(fUsedEvents);
    end;
  finally
    CriticalAmpel.Release;
  end;
end;

procedure TAmpelEvents.AllEventsOff;
var
  i: integer;
begin
  for i := 0 to UsedEvents-1do
    EventOff(MouseEvents[0]);
end;


procedure TAmpelEvents.GetKeyEvent(Key: integer; var Event: TMouseEvent);
var
  i: integer;
begin
  CriticalAmpel.Acquire;
  try
    Event.Clear;
    for i := 0 to UsedEvents-1 do
      if (MouseEvents[i].Key = Key) then
      begin
        Event := MouseEvents[i];
        break;
      end;
  finally
    CriticalAmpel.Release;
  end;
end;

procedure TAmpelEvents.CheckMovePoint(const P: TPoint; Down: boolean);
var
  i, Index: integer;
  distance: double;
  Event: TMouseEvent;
  rect: TRect;
  Cont: boolean;
begin
  Index := -1;
  CriticalAmpel.Acquire;
  try
    if UsedEvents > 0 then
    begin
      distance := P.Distance(MouseEvents[0].P);
      Index := 0;
      for i := 1 to UsedEvents-1 do
        if distance > P.Distance(MouseEvents[i].P) then
        begin
          Index := i;
          distance := P.Distance(MouseEvents[i].P);
        end;
    end;

    cont := false;
    if Index >= 0 then
    begin
      Event := MouseEvents[index];
      rect := frmAmpel.KnopfRect(Event.Row_, Event.index_);
      cont := rect.Contains(P);
    end;
  finally
    CriticalAmpel.Release;
  end;

  if (Index >= 0) then
  begin
    if not cont or not Down then
    begin
      EventOff(Event);
//      writeln('up ', Event.row_, '  ', Event.index_);
    end;
  end else
  if Down then
    frmAmpel.MakeMouseDown(P);
end;

function TAmpelEvents.IsOn(Row: integer; Index: integer): boolean;
var
  i: integer;
begin
  result := false;
  i := 0;
  while i < UsedEvents do
  begin
    if (MouseEvents[i].Row_ = Row) and (MouseEvents[i].Index_ = Index) then
    begin
      result := true;
      break;
    end;
    inc(i);
  end;
end;

function TAmpelEvents.Paint(Row, Index: integer): boolean;
begin
  result := IsOn(Row, Index);
  Ampel.PaintAmpel(Row, Index, result);
end;


function TonIndex(const Ton: string; var plus: integer): integer;
var
  s: string;
begin
  s := Ton;
  plus := 0;
  while (Length(s) > 0) and (s[Length(s)] = '+') do
  begin
    SetLength(s, Length(s)-1);
    inc(plus);
  end;

  result := 11;
  while (result >= 0) and (s <> Leiter[result]) do
    dec(result);
end;

function NoteToMidi(const Ton: string): byte;
var
  res, plus: integer;
begin
  res := TonIndex(Ton, plus);
  result := 0;
  if res >= 0 then
    result := grundTon + res + plus*12;
end;

procedure Transpose;
var
  t, i, k: integer;
  s: string;
  n: byte;
begin
  s := '0';
  t := Akkordeon.cbxTranspose.ItemIndex;
  if t >= 0 then
    s := Akkordeon.cbxTranspose.Items[t];

  t := StrToIntDef(s, 0);
  for i := 0 to 4 do
    for k := 0 to 19 do
    begin
      n := NoteToMidi(Diskant[i, k]);
      if n > 0 then
        MidiDiskant[i, k] := n + t;
    end;
end;

procedure MakeBlackArray;
var
  i, k: integer;
  b: boolean;
  Note: byte;
begin
  Transpose;
  for i := 0 to 4 do
    for k := 0 to 19 do
    begin
      Note := MidiDiskant[i, k];
      b := (Note mod 12) in black;
      BlackArr[i, k] := b;
    end;
end;

////////////////////////////////////////////////////////////////////////////////

constructor TMidiInBuffer.Create;
begin
  Critical := TCriticalSection.Create;
  Head := 0;
  Tail := 0;
  FillChar(Buffer, sizeof(Buffer), 0);
end;

destructor TMidiInBuffer.Destroy;
begin
  Critical.Free;
end;

function TMidiInBuffer.Empty: boolean;
begin
  result := Tail = Head;
end;

function TMidiInBuffer.Get(var rec: TMidiInData): boolean;
begin
  result := false;
  Critical.Acquire;
  try
    result := not Empty;
    if result then
    begin
      rec := Buffer[Tail];
      Tail := (Tail + 1) mod Length(Buffer);
    end;
  finally
    Critical.Release;
  end;
end;

function TMidiInBuffer.Put(const rec: TMidiInData): boolean;
var
  oldHead: word;
begin
  result := false;
  Critical.Acquire;
  try
    oldHead := Head;
    Head := (Head + 1) mod Length(Buffer);
    if Empty then
      Tail := (Tail + 1) mod Length(Buffer);

    Buffer[oldHead] := rec;
    result := true;
  finally
    Critical.Release;
  end;
end;


initialization


end.

