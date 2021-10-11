program Gestima;

uses
  Forms,
  Gim01 in 'Gim01.pas' {Fmain},
  Gim02 in 'Gim02.pas',
  Gim05 in 'Gim05.pas' {FAide};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFmain, Fmain);
  Application.CreateForm(TFAide, FAide);
  Application.Run;
end.
