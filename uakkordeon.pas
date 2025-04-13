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
    cbxTranspose: TComboBox;
    cbxInstruments: TComboBox;
    Label1: TLabel;
    gbMidi: TGroupBox;
    Label4: TLabel;
    lblKeyboard: TLabel;
    Label17: TLabel;
    cbxMidiOut: TComboBox;
    cbxMidiInput: TComboBox;
    btnReset: TButton;
    btnResetMidi: TButton;
    cbxAnzeigen: TCheckBox;
    cbxVertikal: TCheckBox;
    Label2: TLabel;
    Label3: TLabel;
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
    procedure FormChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure cbxAnzeigenChange(Sender: TObject);
    procedure cbxVertikalChange(Sender: TObject);
    procedure cbxInstrumentsChange(Sender: TObject);
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
  Diskant : TDiskant =
     (('', 'cis', 'e', 'g', 'ais', 'cis+', 'e+', 'g+', 'ais+', 'cis++', 'e++', 'g++', 'ais++', 'cis+++', 'e+++', 'g+++', 'ais+++', 'cis++++', '', ''),
      ('d', 'f', 'gis', 'h', 'a++', 'd+', 'f+', 'gis+', 'h+', 'd++', 'f++', 'gis++', 'h++', 'd+++', 'f+++', 'gis+++', 'h+++', '', '', ''),
      ('', 'dis', 'fis', 'a', 'c+', 'dis+', 'fis+', 'a+', 'c++', 'dis++', 'fis++', 'a++', 'c+++', 'dis+++', 'fis+++', 'a+++', 'c++++', '', '', ''),
      ('', 'cis', 'e', 'g', 'ais', 'cis+', 'e+', 'g+', 'ais+', 'cis++', 'e++', 'g++', 'ais++', 'cis+++', 'e+++', 'g+++', 'ais+++', 'cis++++', '', ''),
      ('d', 'f', 'gis', 'h', 'a++', 'd+', 'f+', 'gis+', 'h+', 'd++', 'f++', 'gis++', 'h++', 'd+++', 'f+++', 'gis+++', 'h+++', '', '', '')
     );

  black: set of byte = [1, 3, 6, 8, 10];
  grundTon = 36;

  Tonleiter : array [0..11] of string = ('c', 'cis', 'd', 'dis', 'e', 'f', 'fis', 'g', 'gis', 'a', 'ais', 'h');

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
{$ifdef mswindows}
  Midi;
{$else}
  UMidi, urtmidi, Ujson;
{$endif}



procedure InsertList(Combo: TComboBox; arr: array of string);
var
  i: integer;
begin
  for i := 0 to Length(arr)-1 do
    Combo.AddItem(arr[i], nil);
end;

procedure TAkkordeon.FormCreate(Sender: TObject);
begin
  InitInstruments;
//  cbxInstrumentsChange(Sender);
  cbxVertikal.OnChange := cbxVertikalChange;
  cbxInstruments.OnChange := cbxInstrumentsChange;
end;

procedure TAkkordeon.FormDestroy(Sender: TObject);
begin
  MidiInput.CloseAll;
end;

procedure TAkkordeon.FormChange(Sender: TObject);
begin
  MakeBlackArray;
  Ampel.invalidate;
  Ampel.Show;
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

procedure TAkkordeon.cbxAnzeigenChange(Sender: TObject);
begin
  Ampel.Invalidate;
end;

procedure TAkkordeon.cbxVertikalChange(Sender: TObject);
begin
  Ampel.cbxVertikal(sender);
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
  while (result >= 0) and (s <> Tonleiter[result]) do
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
    for k := 0 to KnopfCount-1 do
    begin
      if MidiDiskant[i, k] > 0 then
        inc(MidiDiskant[i, k], t);
    end;
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
    Ampel.Invalidate;
  end;
end;

procedure TAkkordeon.InitInstruments;
const
  Path = 'Instrumente/';
var
  i, k, j: integer;
  root, Node, NodeList: Tjson;
  b: byte;
  name, s: AnsiString;

  SR      : TSearchRec;
  DirList : array of string;
begin
  for i := 0 to 4 do
    for k := 0 to KnopfCount-1 do
      MidiDiskant[i, k] := NoteToMidi(Diskant[i, k]);
  SetLength(MidiInstruments, 1);
  MidiInstruments[0] := MidiDiskant;

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

  MidiDiskant := MidiInstruments[0];
  Transpose;
  MakeBlackArray;
end;


end.

