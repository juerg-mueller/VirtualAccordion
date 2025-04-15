program VirtuellesAkkordeon;

uses
  midi,
  Forms, UAmpel, UAkkordeon, UFormHelper;

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TAkkordeon, Akkordeon);
  Application.CreateForm(TAmpel, Ampel);
  Application.Run;
end.

