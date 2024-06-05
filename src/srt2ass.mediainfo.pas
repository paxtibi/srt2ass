unit srt2ass.mediainfo;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

type
  TMetadataInfoStreamKind =
    (
    Stream_General,
    Stream_Video,
    Stream_Audio,
    Stream_Text,
    Stream_Other,
    Stream_Image,
    Stream_Menu,
    Stream_Max);

type
  TMetadataInfo =
    (
    Info_Name,
    Info_Text,
    Info_Measure,
    Info_Options,
    Info_Name_Text,
    Info_Measure_Text,
    Info_Info,
    Info_HowTo,
    Info_Max);

type
  TMIInfoOption =
    (
    InfoOption_ShowInInform,
    InfoOption_Reserved,
    InfoOption_ShowInSupported,
    InfoOption_TypeOfValue,
    InfoOption_Max);

  { TMediaInfo }

  TMediaInfo = class
  protected
    FLibHandle: THandle;// = 0;
    FHandle: cardinal;

    // Unicode methods
    FMediaInfo_New: function(): THandle stdcall;
    FMediaInfo_Delete: procedure(Handle: THandle) stdcall;
    FMediaInfo_Open: function(Handle: THandle; File__: pwidechar): cardinal stdcall;
    FMediaInfo_Close: procedure(Handle: THandle) stdcall;
    FMediaInfo_Inform: function(Handle: THandle; Reserved: integer): pwidechar stdcall;
    FMediaInfo_GetI: function(Handle: THandle; StreamKind: TMetadataInfoStreamKind; StreamNumber: integer; Parameter: integer; KindOfInfo: TMetadataInfo): pwidechar stdcall; //Default: KindOfInfo=Info_Text,
    FMediaInfo_Get: function(Handle: THandle; StreamKind: TMetadataInfoStreamKind; StreamNumber: integer; Parameter: pwidechar; KindOfInfo: TMetadataInfo; KindOfSearch: TMetadataInfo): pwidechar stdcall; //Default: KindOfInfo=Info_Text, KindOfSearch=Info_Name
    FMediaInfo_Option: function(Handle: THandle; Option: pwidechar; Value: pwidechar): pwidechar stdcall;
    FMediaInfo_State_Get: function(Handle: THandle): integer stdcall;
    FMediaInfo_Count_Get: function(Handle: THandle; StreamKind: TMetadataInfoStreamKind; StreamNumber: integer): integer stdcall;

    // Ansi methods
    FMediaInfoA_New: function(): THandle stdcall;
    FMediaInfoA_Delete: procedure(Handle: THandle) stdcall;
    FMediaInfoA_Open: function(Handle: THandle; FileName: pansichar): cardinal stdcall;
    FMediaInfoA_Close: procedure(Handle: THandle) stdcall;
    FMediaInfoA_Inform: function(Handle: THandle; Reserved: integer): pansichar stdcall;
    FMediaInfoA_GetI: function(Handle: THandle; StreamKind: TMetadataInfoStreamKind; StreamNumber: integer; Parameter: integer; KindOfInfo: TMetadataInfo): pansichar stdcall; //Default: KindOfInfo=Info_Text
    FMediaInfoA_Get: function(Handle: THandle; StreamKind: TMetadataInfoStreamKind; StreamNumber: integer; Parameter: pansichar; KindOfInfo: TMetadataInfo; KindOfSearch: TMetadataInfo): pansichar stdcall; //Default: KindOfInfo=Info_Text, KindOfSearch=Info_Name
    FMediaInfoA_Option: function(Handle: THandle; Option: pansichar; Value: pansichar): pansichar stdcall;
    FMediaInfoA_State_Get: function(Handle: THandle): integer stdcall;
    FMediaInfoA_Count_Get: function(Handle: THandle; StreamKind: TMetadataInfoStreamKind; StreamNumber: integer): integer stdcall;
  protected
    function GetProcAddress(Name: PChar; var Addr: Pointer): boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function Load(LibPath: string): boolean;

    // Ansi methods
    procedure Delete();
    function Open(FileName: string): cardinal;
    procedure Close();
    function Inform(Reserved: integer): string;
    function GetI(StreamKind: TMetadataInfoStreamKind; StreamNumber: integer; Parameter: integer; KindOfInfo: TMetadataInfo): string;
    function Get(StreamKind: TMetadataInfoStreamKind; StreamNumber: integer; Parameter: string; KindOfInfo: TMetadataInfo; KindOfSearch: TMetadataInfo): string;
    function Option(aOption: string; Value: string): string;
    function State_Get(): integer;
    function Count_Get(StreamKind: TMetadataInfoStreamKind; StreamNumber: integer): integer;
  end;

implementation

{ TMediaInfo }
function TMediaInfo.GetProcAddress(Name: PChar; var Addr: Pointer): boolean;
begin
  Addr := System.GetProcAddress(FLibHandle, Name);
  Result := Addr <> nil;
end;

function TMediaInfo.Load(LibPath: string): boolean;
begin
  Result := False;

  if FLibHandle = 0 then
    FLibHandle := LoadLibrary(PChar(LibPath));

  if FLibHandle <> 0 then
  begin
    Self.GetProcAddress('MediaInfo_New', Pointer(FMediaInfo_New));
    Self.GetProcAddress('MediaInfo_Delete', Pointer(FMediaInfo_Delete));
    Self.GetProcAddress('MediaInfo_Open', Pointer(FMediaInfo_Open));
    Self.GetProcAddress('MediaInfo_Close', Pointer(FMediaInfo_Close));
    Self.GetProcAddress('MediaInfo_Inform', Pointer(FMediaInfo_Inform));
    Self.GetProcAddress('MediaInfo_GetI', Pointer(FMediaInfo_GetI));
    Self.GetProcAddress('MediaInfo_Get', Pointer(FMediaInfo_Get));
    Self.GetProcAddress('MediaInfo_Option', Pointer(FMediaInfo_Option));
    Self.GetProcAddress('MediaInfo_State_Get', Pointer(FMediaInfo_State_Get));
    Self.GetProcAddress('MediaInfo_Count_Get', Pointer(FMediaInfo_Count_Get));

    Self.GetProcAddress('MediaInfoA_New', Pointer(FMediaInfoA_New));
    Self.GetProcAddress('MediaInfoA_Delete', Pointer(FMediaInfoA_Delete));
    Self.GetProcAddress('MediaInfoA_Open', Pointer(FMediaInfoA_Open));
    Self.GetProcAddress('MediaInfoA_Close', Pointer(FMediaInfoA_Close));
    Self.GetProcAddress('MediaInfoA_Inform', Pointer(FMediaInfoA_Inform));
    Self.GetProcAddress('MediaInfoA_GetI', Pointer(FMediaInfoA_GetI));
    Self.GetProcAddress('MediaInfoA_Get', Pointer(FMediaInfoA_Get));
    Self.GetProcAddress('MediaInfoA_Option', Pointer(FMediaInfoA_Option));
    Self.GetProcAddress('MediaInfoA_State_Get', Pointer(FMediaInfoA_State_Get));
    Self.GetProcAddress('MediaInfoA_Count_Get', Pointer(FMediaInfoA_Count_Get));
    Result := True;


    self.FMediaInfoA_Option('Internet','No');
  end;
end;

constructor TMediaInfo.Create;
begin
  Load('MediaInfo');
  FHandle := FMediaInfoA_New();
end;

destructor TMediaInfo.Destroy;
begin
  if FLibHandle <> 0 then
  begin
    UnloadLibrary(FLibHandle);
  end;
  inherited Destroy;
end;

procedure TMediaInfo.Delete();
begin
  FMediaInfoA_Delete(FHandle);
end;

function TMediaInfo.Open(FileName: string): cardinal;
begin
  Result := FMediaInfoA_Open(FHandle, PChar(FileName));
end;

procedure TMediaInfo.Close();
begin
  FMediaInfoA_Close(FHandle);
end;

function TMediaInfo.Inform(Reserved: integer): string;
begin
  Result := FMediaInfoA_Inform(FHandle, Reserved);
end;

function TMediaInfo.GetI(StreamKind: TMetadataInfoStreamKind; StreamNumber: integer; Parameter: integer; KindOfInfo: TMetadataInfo): string;
begin
  Result := FMediaInfoA_GetI(FHandle, StreamKind, StreamNumber, Parameter, KindOfInfo);
end;

function TMediaInfo.Get(StreamKind: TMetadataInfoStreamKind; StreamNumber: integer; Parameter: string; KindOfInfo: TMetadataInfo; KindOfSearch: TMetadataInfo): string;
begin
  Result := FMediaInfoA_Get(FHandle, StreamKind, StreamNumber, PChar(Parameter), KindOfInfo, KindOfSearch);
end;

function TMediaInfo.Option(aOption: string; Value: string): string;
begin
  Result := FMediaInfoA_Option(FHandle, PChar(aOption), PChar(Value));
end;

function TMediaInfo.State_Get(): integer;
begin
  Result := FMediaInfoA_State_Get(FHandle);
end;

function TMediaInfo.Count_Get(StreamKind: TMetadataInfoStreamKind; StreamNumber: integer): integer;
begin
  Result := FMediaInfoA_Count_Get(FHandle, StreamKind, StreamNumber);
end;

end.
