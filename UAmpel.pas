unit UAmpel;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  {$ifdef FPC}
  lcltype, LCLIntf, lcl,
  {$endif}
  Types, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, syncobjs, ExtCtrls,
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
    procedure NewEvent(Event: TMouseEvent; UsePitch: boolean);
    function AddMouseEvent(Event: TMouseEvent): boolean;
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
    procedure FormPaint(Sender: TObject);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);

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
    function KnopfRect(Row: byte {0..4}; index: byte {0..18}): TRect;
    procedure PaintAmpel(Row: byte {0..4}; index: integer {0..18}; On_: boolean);
    procedure OnMidiInData(aDeviceIndex: LongInt; aStatus, aData1, aData2: byte; aTimestamp: Int64);
    procedure cbxAnsichtChange(Sender: TObject);

  end;

// Diskant: 5 Reihen à 19 Tasten

const
  KnopfCount = 19;


type
  TMidiZeile = array [0..KnopfCount-1] of byte;
  TMidiDiskant = array [0..4] of TMidiZeile;

var
  Ampel: TAmpel;

implementation

{$ifdef fpc}
  {$R *.lfm}
{$else}
  {$R *.dfm}
{$endif}

uses
{$ifdef MSWINDOWS}
  Midi,
{$else}
  UMidi, urtmidi,
{$endif}
  UAkkordeon;

procedure TAmpel.FormCreate(Sender: TObject);
begin
  Color := $7f7f7f;
  MidiInBuffer := TMidiInBuffer.Create;
  AmpelEvents := TAmpelEvents.Create(self);
  KnopfGroesse := 52;
  cbxAnsichtChange(nil);
  Timer1 := TTimer.Create(self);
  Timer1.name := 'Timer1';
  Timer1.interval:= 1;
  Timer1.OnTimer := Timer1Timer;
end;

procedure TAmpel.cbxAnsichtChange;
begin
  if Akkordeon.cbxAnsicht.ItemIndex > 0 then
  begin
    Height := 1250;
    Width := 360;
    OffsetX := 20;
    OffsetY := 50;
  end else begin
    Height := 360;
    Width := 1250;
    OffsetX := 60;
    OffsetY := 40;
  end;
  invalidate;
end;

function TAmpel.KnopfRect(Row: byte {0..4}; index: byte {0..KnopfCount-1}): TRect;
var
  rect: TRect;
  Knopf: integer;
  Abstand: integer;
begin
  Abstand := round(KnopfGroesse*1.1);
  if Akkordeon.cbxAnsicht.ItemIndex = 1 then
  begin
    if row in [0,2,4] then
      Index := 17 - Index
    else
      Index := 18 - Index;
  end else
  if Akkordeon.cbxAnsicht.ItemIndex = 2 then
  begin
    row := 4 - row;
  end;
  result := TRect.Create(0, 0, KnopfGroesse, KnopfGroesse);
  result.Offset(round(Index*Abstand), round(Row*Abstand*sqrt(3)/2));
  if Row in [1, 3] then
    result.Offset(-Abstand div 2, 0);
  result.Offset(OffsetX, OffsetY);
  if Akkordeon.cbxAnsicht.ItemIndex > 0 then
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
  for i := 0 to 4 do
  begin
    l := KnopfCount-2;
    if i in [1, 3] then
      inc(l);
    for k := 0 to l do
    begin
      if MidiDiskant[i, k] > 0 then
      begin
        PaintAmpel(i, k, AmpelEvents.IsOn(i, k));
      end;
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
    l := KnopfCount-2;
    if Row in [1, 3] then
      inc(l);
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
        AmpelEvents.NewEvent(Event, false);
      end;
      break;
    end;
  end;
end;

procedure TAmpel.PaintAmpel(Row: byte {0..4}; index: integer {0..18}; On_: boolean);
var
  rect: TRect;
  s: string;
  t: byte;
  l, m, p: integer;
begin
//  writeln('print');
  rect := KnopfRect(Row, index);
  if not On_ then
  begin
    if BlackArr[row, index] then
      canvas.Brush.Color := $0000
    else
      canvas.Brush.Color := $efefef;
  end else
  if BlackArr[row, index] then
    canvas.Brush.Color := $ffff00
  else
    canvas.Brush.Color := $00ff00;

  canvas.Pen.Color := canvas.Brush.Color;
  canvas.Ellipse(rect);
  if Akkordeon.cbxNotenansicht.ItemIndex > 0 then
  begin
    if canvas.Brush.Color = $efefef then
      Canvas.Font.Color := 0
    else
      Canvas.Font.Color := $ffffff;
    t := MidiDiskant[Row, Index];
    if Akkordeon.cbxNotenansicht.ItemIndex in [1, 2] then
    begin
      s := Tonleiter2[t mod 12];
      if Akkordeon.cbxNotenansicht.ItemIndex = 1 then
        s := s + IntToStr(t div 12);
    end else begin
      s := Tonleiter[t mod 12];
      p := (t-grundTon) div 12;
      for l := 1 to p do
        s := s + '''';
    end;
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
        AmpelEvents.NewEvent(Event, true)
      else
      if (Data.Status shr 4) = 8 then
        AmpelEvents.EventOff(Event);
    end;
  end;
end;

procedure TAmpel.FormResize(Sender: TObject);
begin
{$ifdef FPC}
  if Akkordeon.cbxAnsicht.ItemIndex > 0 then
  begin
    KnopfGroesse := round(Width/6.2);
    OffsetX := KnopfGroesse;
    OffsetY := round(KnopfGroesse * 0.75);
  end else begin
    KnopfGroesse := round(Height/6.2);
    OffsetY := round(KnopfGroesse / 1.6);
    OffsetX := round(KnopfGroesse * 0.75);
  end;
{$else}
  if Akkordeon.cbxAnsicht.ItemIndex > 0 then
  begin
    KnopfGroesse := round(Width/6.9);
    OffsetX := KnopfGroesse;
    OffsetY := round(KnopfGroesse * 0.75);
  end else begin
    KnopfGroesse := round(Height/6.9);
    OffsetY := round(KnopfGroesse / 1.6);
    OffsetX := round(KnopfGroesse * 0.75);
  end;
{$endif}
  Font.Size := round(KnopfGroesse / 3.6);
  Invalidate;
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

function TAmpelEvents.AddMouseEvent(Event: TMouseEvent): boolean;
var
  j: integer;
begin
  result := true;
  CriticalAmpel.Acquire;
  try
    for j := 0 to UsedEvents-1 do
      if (MouseEvents[j].Row_ = Event.Row_) and
         (MouseEvents[j].Index_ = Event.Index_) then
        result := false;
    if result then
    begin
      MouseEvents[UsedEvents] := Event;
      inc(fUsedEvents);
      DoAmpel(UsedEvents-1, true);
    end;
  finally
    CriticalAmpel.Release;
 end;

end;

procedure TAmpelEvents.NewEvent(Event: TMouseEvent; UsePitch: boolean);
var
  i, j, k: integer;
  u, w: integer;
  ok: boolean;
begin
//  writeln('new event');
  if UsedEvents >= High(MouseEvents) then
    exit;

  if UsePitch then
  begin
    u := 0;
    w := 4;
    if Akkordeon.cbxUnterdrueckung.ItemIndex = 2 then
      w := 2;
    if Akkordeon.cbxUnterdrueckung.ItemIndex = 1 then
      u := 2;
    for i := u to w do
      for k := 0 to 18 do
      begin
        if MidiDiskant[i, k] = Event.Pitch then
        begin
          Event.row_ := i;
          Event.index_ := k;
//        writeln('down  ', Event.row_, '  ', Event.index_);
          AddMouseEvent(Event);
        end;
    end;
  end else
    AddMouseEvent(Event);
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
begin
  CriticalAmpel.Acquire;
  try
    for i := UsedEvents-1 downto 0 do
      if (MouseEvents[i].Pitch = Event.Pitch) then
      begin
        DoAmpel(i, false);
        for j := i to UsedEvents-2 do
          MouseEvents[j] := MouseEvents[j+1];
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

