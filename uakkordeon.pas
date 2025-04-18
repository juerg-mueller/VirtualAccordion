unit UAkkordeon;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, UAmpel;

type

  { TAkkordeon }

  TAkkordeon = class(TForm)
    cbxNotenansicht: TComboBox;
    cbxTranspose: TComboBox;
    cbxInstruments: TComboBox;
    cbxAnsicht: TComboBox;
    Label1: TLabel;
    gbMidi: TGroupBox;
    Label4: TLabel;
    lblKeyboard: TLabel;
    Label17: TLabel;
    cbxMidiOut: TComboBox;
    cbxMidiInput: TComboBox;
    btnReset: TButton;
    btnResetMidi: TButton;
    Label2: TLabel;
    Label5: TLabel;
    procedure cbxMidiOutChange(Sender: TObject);
    procedure cbxMidiInputChange(Sender: TObject);
    procedure cbTransInstrumentKeyPress(Sender: TObject; var Key: Char);
    procedure cbTransInstrumentKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure cbTransInstrumentKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure btnResetMidiClick(Sender: TObject);
    procedure btnResetClick(Sender: TObject);

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure cbxInstrumentsChange(Sender: TObject);
    procedure FormClick(Sender: TObject);
    procedure cbxAnzeigenClick(Sender: TObject);
    procedure cbxAnsichtChange(Sender: TObject);
    procedure cbxTransposeChange(Sender: TObject);
    procedure cbxNotenansichtChange(Sender: TObject);
  private
    procedure RegenerateMidi;
   procedure InitInstruments;

  public

  end;


type
  TArr = array [0..KnopfCount-1] of boolean;
  TBlackArray = array [0..4] of TArr;

  TZeile = array [0..KnopfCount-1] of string;
  TDiskant = array[0..4] of TZeile;

const
  black: set of byte = [1, 3, 6, 8, 10];
  grundTon = 36;

  Tonleiter : array [0..11] of string = ('C', 'Dis', 'D', 'Dis', 'E', 'F', 'Fis', 'G', 'Gis', 'A', 'Ais', 'H');
  Tonleiter_: array [0..11] of string = ('c', 'cis', 'd', 'dis', 'e', 'f', 'fis', 'g', 'gis', 'a', 'ais', 'h');
  Tonleiter2: array [0..11] of string = ('C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'G#', 'A', 'Bb', 'B');

var
  Akkordeon: TAkkordeon;

  BlackArr : TBlackArray;
  MidiDiskant : TMidiDiskant;

  MidiInstruments: array of TMidiDiskant;


function NoteToMidi(const Ton: AnsiString): byte;
procedure MakeBlackArray;


implementation

{$ifdef fpc}
  {$R *.lfm}
{$else}
  {$R *.dfm}
{$endif}

uses
  Ujson, UMyMemoryStream,
{$ifdef mswindows}
  Midi;
{$else}
  UMidi, urtmidi;
{$endif}

type
  PDiskant = ^TDiskant;
  TDiskantArr = array [0..5] of PDiskant;

const
  C_Griff_Europe: TDiskant = (
    ('Cis', 'E', 'G', 'Ais', 'Cis+', 'E+', 'G+', 'Ais+', 'Cis++', 'E++', 'G++', 'Ais++', 'Cis+++', 'E+++', 'G+++', 'Ais+++', 'Cis++++', 'E++++', ''),
    ('C', 'Dis', 'Fis', 'A', 'C+', 'Dis+', 'Fis+', 'A+', 'C++', 'Dis++', 'Fis++', 'A++', 'C+++', 'Dis+++', 'Fis+++', 'A+++', 'C++++', 'Dis++++', 'Fis++++'),
    ('D', 'F', 'Gis', 'H', 'D+', 'F+', 'Gis+', 'H+', 'D++', 'F++', 'Gis++', 'H++', 'D+++', 'F+++', 'Gis+++', 'H+++', 'D++++', 'F++++', ''),
    ('Cis', 'E', 'G', 'Ais', 'Cis+', 'E+', 'G+', 'Ais+', 'Cis++', 'E++', 'G++', 'Ais++', 'Cis+++', 'E+++', 'G+++', 'Ais+++', 'Cis++++', 'E++++', 'G++++'),
    ('Dis', 'Fis', 'A', 'C+', 'Dis+', 'Fis+', 'A+', 'C++', 'Dis++', 'Fis++', 'A++', 'C+++', 'Dis+++', 'Fis+++', 'A+++', 'C++++', 'Dis++++', 'Fis++++', '')
   );

  C_Griff_2: TDiskant = (
    ('F', 'Gis', 'H', 'D+', 'F+', 'Gis+', 'H+', 'D++', 'F++', 'Gis++', 'H++', 'D+++', 'F+++', 'Gis+++', 'H+++', 'D++++', 'F++++', 'Gis++++', 'A++++'),
    ('Dis', 'Fis', 'A', 'C+', 'Dis+', 'Fis+', 'A+', 'C++', 'Dis++', 'Fis++', 'A++', 'C+++', 'Dis+++', 'Fis+++', 'A+++', 'C++++', 'Dis++++', 'Fis++++', ''),
    ('E', 'G', 'Ais', 'Dis+', 'E+', 'G+', 'Ais+', 'Dis++', 'E++', 'G++', 'Ais++', 'Dis+++', 'E+++', 'G+++', 'Ais+++', 'Dis++++', 'E++++', 'G++++', ''),
    ('D', 'F', 'Gis', 'H', 'D+', 'F+', 'Gis+', 'H+', 'D++', 'F++', 'Gis++', 'H++', 'D+++', 'F+++', 'Gis+++', 'H+++', 'D++++', 'F++++', 'Gis++++'),
    ('Dis', 'Fis', 'A', 'C+', 'Dis+', 'Fis+', 'A+', 'C++', 'Dis++', 'Fis++', 'A++', 'C+++', 'Dis+++', 'Fis+++', 'A+++', 'C++++', 'Dis++++', 'Fis++++', '')
   );

  D_Griff_1: TDiskant = (
    ('C', 'Dis', 'Fis', 'A', 'C+', 'Dis+', 'Fis+', 'A+', 'C++', 'Dis++', 'Fis++', 'A++', 'C+++', 'Dis+++', 'Fis+++', 'A+++', 'C++++', 'Dis++++', ''),
    ('H', 'D', 'F', 'Gis', 'H', 'D+', 'F+', 'Gis+', 'H+', 'D++', 'F++', 'Gis++', 'H++', 'D+++', 'F+++', 'Gis+++', 'H+++', 'D++++', 'F++++'),
    ('Cis', 'E', 'G', 'Ais', 'Cis+', 'E+', 'G+', 'Ais+', 'Cis++', 'E++', 'G++', 'Ais++', 'Cis+++', 'E+++', 'G+++', 'Ais+++', 'Cis++++', 'E++++', ''),
    ('C', 'Dis', 'Fis', 'A', 'C+', 'Dis+', 'Fis+', 'A+', 'C++', 'Dis++', 'Fis++', 'A++', 'C+++', 'Dis+++', 'Fis+++', 'A+++', 'C++++', 'Dis++++', 'Fis++++'),
    ('D', 'F', 'Gis', 'H', 'D+', 'F+', 'Gis+', 'H+', 'D++', 'F++', 'Gis++', 'H++', 'D+++', 'F+++', 'Gis+++', 'H+++', 'D++++', 'F++++', '')
   );

  D_Griff_2: TDiskant = (
    ('Dis', 'Fis', 'A', 'C+', 'Dis+', 'Fis+', 'A+', 'C++', 'Dis++', 'Fis++', 'A++', 'C+++', 'Dis+++', 'Fis+++', 'A+++', 'C++++', 'Dis++++', 'Fis++++', ''),
    ('Cis', 'E', 'G', 'Ais', 'Cis+', 'E+', 'G+', 'Ais+', 'Cis++', 'E++', 'G++', 'Ais++', 'Cis+++', 'E+++', 'G+++', 'Ais+++', 'Cis++++', 'E++++', 'G++++'),
    ('D', 'F', 'Gis', 'H', 'D+', 'F+', 'Gis+', 'H+', 'D++', 'F++', 'Gis++', 'H++', 'D+++', 'F+++', 'Gis+++', 'H+++', 'D++++', 'F++++',''),
    ('C', 'Dis', 'Fis', 'A', 'C+', 'Dis+', 'Fis+', 'A+', 'C++', 'Dis++', 'Fis++', 'A++', 'C+++', 'Dis+++', 'Fis+++', 'A+++', 'C++++', 'Dis++++', 'Fis++++'),
    ('Cis', 'E', 'G', 'Ais', 'Cis+', 'E+', 'G+', 'Ais+', 'Cis++', 'E++', 'G++', 'Ais++', 'Cis+++', 'E+++', 'G+++', 'Ais+++', 'Cis++++', 'E++++', '')
   );

  B_Griff_Bajan: TDiskant = (
    ('E', 'G', 'Ais', 'Dis+', 'E+', 'G+', 'Ais+', 'Dis++', 'E++', 'G++', 'Ais++', 'Dis+++', 'E+++', 'G+++', 'Ais+++', 'Dis++++', 'E++++', 'G++++', ''),
    ('D', 'F', 'Gis', 'H', 'D+', 'F+', 'Gis+', 'H+', 'D++', 'F++', 'Gis++', 'H++', 'D+++', 'F+++', 'Gis+++', 'H+++', 'D++++', 'F++++', 'Gis++++'),
    ('Dis', 'Fis', 'A', 'C+', 'Dis+', 'Fis+', 'A+', 'C++', 'Dis++', 'Fis++', 'A++', 'C+++', 'Dis+++', 'Fis+++', 'A+++', 'C++++', 'Dis++++', 'Fis++++', ''),
    ('Dis', 'E', 'G', 'Ais', 'Dis+', 'E+', 'G+', 'Ais+', 'Dis++', 'E++', 'G++', 'Ais++', 'Dis+++', 'E+++', 'G+++', 'Ais+++', 'Dis++++', 'E++++', 'G++++'),
    ('D', 'F', 'Gis', 'H', 'D+', 'F+', 'Gis+', 'H+', 'D++', 'F++', 'Gis++', 'H++', 'D+++', 'F+++', 'Gis+++', 'H+++', 'D++++', 'F++++', '')
   );

  B_Griff_Finnish: TDiskant = (
    ('D', 'F', 'Gis', 'H', 'D+', 'F+', 'Gis+', 'H+', 'D++', 'F++', 'Gis++', 'H++', 'D+++', 'F+++', 'Gis+++', 'H+++', 'D++++', 'F++++', ''),
    ('Dis', 'E', 'G', 'Ais', 'Dis+', 'E+', 'G+', 'Ais+', 'Dis++', 'E++', 'G++', 'Ais++', 'Dis+++', 'E+++', 'G+++', 'Ais+++', 'Dis++++', 'E++++', 'G++++'),
    ('Dis', 'Fis', 'A', 'C+', 'Dis+', 'Fis+', 'A+', 'C++', 'Dis++', 'Fis++', 'A++', 'C+++', 'Dis+++', 'Fis+++', 'A+++', 'C++++', 'Dis++++', 'Fis++++', ''),
    ('D', 'F', 'Gis', 'H', 'D+', 'F+', 'Gis+', 'H+', 'D++', 'F++', 'Gis++', 'H++', 'D+++', 'F+++', 'Gis+++', 'H+++', 'D++++', 'F++++', 'Gis++++'),
    ('E', 'G', 'Ais', 'Dis+', 'E+', 'G+', 'Ais+', 'Dis++', 'E++', 'G++', 'Ais++', 'Dis+++', 'E+++', 'G+++', 'Ais+++', 'Dis++++', 'E++++', 'G++++', '')
   );

  Arr: TDiskantArr = (@C_Griff_Europe, @C_Griff_2, @B_Griff_Bajan, @B_Griff_Finnish, @D_Griff_1, @D_Griff_2);

  str: array [0..5] of string = ('C-Griff Europe', 'C-Griff 2', 'B-Griff Bajan', 'B-Griff Finnish', 'D-Griff 1', 'D-Griff 2');

procedure InsertList(Combo: TComboBox; arr: array of string);
var
  i: integer;
begin
  for i := 0 to Length(arr)-1 do
    Combo.AddItem(arr[i], nil);
end;

procedure TAkkordeon.FormClick(Sender: TObject);
begin
  Ampel.Show();
end;

procedure TAkkordeon.FormCreate(Sender: TObject);
begin
  InitInstruments;
  cbxInstruments.OnChange := cbxInstrumentsChange;
end;

procedure TAkkordeon.FormDestroy(Sender: TObject);
begin
  MidiInput.CloseAll;
end;

procedure TAkkordeon.cbxMidiOutChange(Sender: TObject);
begin
  if cbxMidiOut.ItemIndex >= 0 then
  begin
    if MicrosoftIndex >= 0 then
      MidiOutput.Close(MicrosoftIndex);
    if cbxMidiOut.ItemIndex = 0 then
      MicrosoftIndex := -1
    else
      MicrosoftIndex := cbxMidiOut.ItemIndex-1;

    OpenMidiMicrosoft;
  end;
end;

procedure TAkkordeon.cbxTransposeChange(Sender: TObject);
begin
  cbxInstrumentsChange(Sender);
end;

procedure TAkkordeon.cbxNotenansichtChange(Sender: TObject);
begin
  Ampel.Invalidate;
end;

procedure TAkkordeon.cbxMidiInputChange(Sender: TObject);
begin
  MidiInput.CloseAll;
  if cbxMidiInput.ItemIndex > 0 then
    MidiInput.Open(cbxMidiInput.ItemIndex - 1);
end;

procedure TAkkordeon.btnResetMidiClick(Sender: TObject);
var
  sIn, sOut: string;
  i: integer;
begin
  sIn := cbxMidiInput.Text;
  sOut := cbxMidiOut.Text;
  ResetMidiOut;
  RegenerateMidi;
  if sIn <> cbxMidiInput.Text then
  begin
    i := cbxMidiInput.Items.IndexOf(sIn);
    if i >= 0 then
    begin
      cbxMidiInput.ItemIndex := i;
      cbxMidiInputChange(Sender);
    end;
  end;
  if sOut <> cbxMidiOut.Text then
  begin
    i := cbxMidiOut.Items.IndexOf(sOut);
    if i >= 0 then
    begin
      cbxMidiOut.ItemIndex := i;
      cbxMidiOutChange(Sender);
    end;
  end;
end;

procedure TAkkordeon.cbTransInstrumentKeyDown(Sender: TObject; var Key: Word;  Shift: TShiftState);
begin
  //
end;

procedure TAkkordeon.cbTransInstrumentKeyPress(Sender: TObject; var Key: Char);
begin
  //
end;

procedure TAkkordeon.cbTransInstrumentKeyUp(Sender: TObject; var Key: Word;  Shift: TShiftState);
begin
  //
end;

procedure TAkkordeon.btnResetClick(Sender: TObject);
begin
  ResetMidiOut;
  Ampel.AmpelEvents.AllEventsOff;
end;

procedure TAkkordeon.FormShow(Sender: TObject);
begin
  RegenerateMidi;
  MidiInput.OnMidiData := Ampel.OnMidiInData;
  Ampel.Caption := cbxInstruments.Text;
end;

procedure TAkkordeon.RegenerateMidi;
begin
  MidiOutput.GenerateList;
  MidiInput.GenerateList;

  cbxMidiOut.Clear;
  InsertList(cbxMidiOut, MidiOutput.DeviceNames);
  cbxMidiOut.Items.Insert(0, '');
  OpenMidiMicrosoft;
  cbxMidiOut.ItemIndex := MicrosoftIndex + 1;
  cbxMidiInput.Visible := Length(MidiInput.DeviceNames) > 0;
  lblKeyboard.Visible := cbxMidiInput.Visible;
  if cbxMidiInput.Visible then
  begin
    cbxMidiInput.Clear;
    InsertList(cbxMidiInput, MidiInput.DeviceNames);
    cbxMidiInput.Items.Insert(0, '');
    cbxMidiInput.ItemIndex := 0;
    cbxMidiInputChange(nil);
  end;
end;

procedure TAkkordeon.cbxAnzeigenClick(Sender: TObject);
begin
  Ampel.Invalidate;
end;

procedure TAkkordeon.cbxAnsichtChange(Sender: TObject);
begin
  Ampel.cbxAnsichtChange(sender);
end;

function TonIndex(const Ton: string; var plus: integer): integer;
var
  s: string;
begin
  s := Ton;
  plus := 0;
  while (Length(s) > 0) and (s[Length(s)] in ['+', '''']) do
  begin
    SetLength(s, Length(s)-1);
    inc(plus);
  end;

  result := 11;
  while (result >= 0) and (s <> Tonleiter_[result]) do
    dec(result);
end;

function NoteToMidi(const Ton: AnsiString): byte;
var
  res, plus: integer;
begin
  res := TonIndex(Ton, plus);
  result := 0;
  if res >= 0 then
    result := grundTon + res + plus*12;
end;

procedure TrasposeMidiDiskant(t: integer);
var
  i, k: integer;
begin
  for i := 0 to 4 do
    for k := 0 to KnopfCount-1 do
    begin
      if MidiDiskant[i, k] > 0 then
        inc(MidiDiskant[i, k], t);
    end;
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
  TrasposeMidiDiskant(t);
end;

procedure MakeBlackArray;
var
  i, k: integer;
  b: boolean;
  Note: byte;
begin
  for i := 0 to 4 do
    for k := 0 to KnopfCount-1 do
    begin
      Note := MidiDiskant[i, k];
      b := (Note mod 12) in black;
      BlackArr[i, k] := b;
    end;
end;

procedure TAkkordeon.cbxInstrumentsChange(Sender: TObject);
var
  i: integer;
begin
  i := cbxInstruments.ItemIndex;
  if i >= 0 then begin
    MidiDiskant := MidiInstruments[cbxInstruments.ItemIndex];
    Transpose;
    MakeBlackArray;
    Ampel.Caption := cbxInstruments.Text;
    Ampel.Invalidate;
  end;
end;

procedure TAkkordeon.InitInstruments;
const
  Path = 'Instrumente/';
var
  i, k, j,l ,p: integer;
  root, Node, NodeList: Tjson;
  b, t: byte;
  name, s: AnsiString;
  Stream: TMyMemoryStream;

  SR      : TSearchRec;
  DirList : array of string;
  Diskant: TDiskant;
begin
  for j := 0 to Length(arr)-1 do
  begin
    Diskant := arr[j]^;
    for i := 0 to 4 do
      for k := 0 to KnopfCount-1 do
        MidiDiskant[i, k] := NoteToMidi(LowerCase(Diskant[i, k]));
    SetLength(MidiInstruments, length(MidiInstruments)+1);
    MidiInstruments[length(MidiInstruments)-1] := MidiDiskant;
    cbxInstruments.Items.Add(str[j]);
  end;
{
  Stream := TMyMemoryStream.Create;
  Stream.WriteString('const');
  Stream.writeln;
  for j := 0 to Length(MidiInstruments)-1 do
  begin
    Stream.WriteString('  ' + cbxInstruments.Items[j] + ': TDiskant = (');
    Stream.writeln;
    for i := 0 to 4 do
    begin
      stream.WriteString('    (');
      for k := 0 to KnopfCount-1 do begin
        t := MidiInstruments[j, i, k];
        s := '';
        if t > 0 then begin
          s := Tonleiter[t mod 12];
          p := (t-grundTon) div 12;
          for l := 1 to p do
            s := s + '+';
        end;
        stream.WriteString('''' + s + '''');
        if k < KnopfCount-1 then
          stream.WriteString(', ');
      end;
      stream.WriteString(')');
      if i < 4 then
        stream.WriteString(',');
      stream.writeln;
    end;
    stream.WriteString('   );');
    stream.writeln;
    stream.writeln;
  end;
  stream.SaveToFile('Diskant.pas');
  stream.free;
  }


  SetLength(DirList, 0);
  if FindFirst(Path + '*.json', faNormal, SR) = 0 then
  begin
    repeat
      SetLength(DirList, length(DirList)+1);
      DirList[length(DirList)-1] := SR.Name;
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;

  for j := 0 to Length(DirList)-1 do
    if TjsonParser.LoadFromJsonFile(Path + DirList[j], root) then
    begin
      Node := Root.FindInList('Description');

      if Node <> nil then
        name := Node.Value;

      Node := Root.FindInList('Mapping');
      if (Node <> nil) and (Length(Node.List) = 5) then
      begin
        for i := 0 to 4 do
        begin
          NodeList := Node.List[i];
          for k := 0 to KnopfCount-1 do
          begin
            s := '';
            if k < Length(NodeList.List) then
              s := NodeList.List[k].Value;
            MidiDiskant[i, k] := NoteToMidi(s);
          end;
        end;
        cbxInstruments.Items.Add(name);
        i := Length(MidiInstruments);
        SetLength(MidiInstruments, i+1);
        MidiInstruments[i] := MidiDiskant;
      end;
    end;
  SetLength(DirList, 0);

  cbxInstruments.ItemIndex := 0;
  MidiDiskant := MidiInstruments[0];
  Transpose;
  MakeBlackArray;
end;


end.

