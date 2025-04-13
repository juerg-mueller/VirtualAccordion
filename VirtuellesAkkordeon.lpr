program VirtuellesAkkordeon;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  {$ifdef mswindows}
   midi,
  {$else}
   RtMidi, UMidi, Urtmidi,
  {$endif}
  Interfaces, // this includes the LCL widgetset
  Forms, UAmpel, UAkkordeon, UFormHelper, Ujson, UMyMemoryStream;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TAkkordeon, Akkordeon);
  Application.CreateForm(TAmpel, Ampel);
  Application.Run;
end.

