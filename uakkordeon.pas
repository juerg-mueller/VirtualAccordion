unit UAkkordeon;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type
  TAkkordeon = class(TForm)
    cbxTranspose: TComboBox;
    Label1: TLabel;
    gbMidi: TGroupBox;
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
  private
    procedure RegenerateMidi;

  public

  end;

var
  Akkordeon: TAkkordeon;

implementation

{$R *.lfm}

uses
{$ifdef mswindows}
  Midi,
{$else}
  UMidi, urtmidi,
{$endif}
  UAmpel;

procedure InsertList(Combo: TComboBox; arr: array of string);
var
  i: integer;
begin
  for i := 0 to Length(arr)-1 do
    Combo.AddItem(arr[i], nil);
end;

procedure TAkkordeon.FormCreate(Sender: TObject);
begin
  MakeBlackArray;
  cbxVertikal.OnChange := cbxVertikalChange;
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

end.

