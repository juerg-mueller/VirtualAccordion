program VirtuellesAkkordeon;

uses
  midi,
  Forms, UAmpel, UAkkordeon, UFormHelper;

{$R *.res}

begin
//  RequireDerivedFormResource:=True;
//  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TAkkordeon, Akkordeon);
  Application.CreateForm(TAmpel, Ampel);
  Application.Run;
end.

