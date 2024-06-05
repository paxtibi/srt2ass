program srt2assa;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes,
  SysUtils,
  srt2assa.application,
  srt2assa.model,
  srt2assa.mediainfo, lib.assa;

var
  Application: TSrtToAssApplication;
begin
  Application := TSrtToAssApplication.Create(nil);
  Application.Title := 'SRT 2 ASSA';
  Application.Run;
  Application.Free;
end.
