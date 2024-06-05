unit srt2assa.application;

{$mode ObjFPC}{$H+}
{$ModeSwitch typehelpers}
{$ModeSwitch advancedrecords}
{$define DYNAMIC}

interface

uses
  Classes, SysUtils, CustApp, Types, Math, srt2assa.model, srt2assa.mediainfo, DateUtils, FPColorSpace, freetype;

type

  TOptions = record
    position: uint8;
    coordinate: TPoint;
    srtInput: TFileName;
    assaOutput: TFileName;
    fontSize: double;
    videoFile: TFileName;
    videoWidth: uint64;
    videoHeight: uint64;
    videoMargin: uint64;
  end;

  TAffineMatrix = array[0..2, 0..2] of single;

  { TAffineMatrixHelper }

  TAffineMatrixHelper = type helper for TAffineMatrix
    class function identity: TAffineMatrix; static;
    function translate(x, y: single): TAffineMatrix;
    function scale(x, y: single): TAffineMatrix;
    function shear(x, y: single): TAffineMatrix;
    function determinant: single;
    function inverse: TAffineMatrix;
    function combine(a: TAffineMatrix): TAffineMatrix;
    function transform(const r: TRect): TRect; overload;
    function transform(const p: TPoint): TPoint; overload;
    function transform(const p: TPointF): TPointF; overload;
  end;

  TParameter = record
    code: int32;
    short: string;
    long: string;
  end;

  TParameterList = array of TParameter;

  { TParameterListHelper }

  TParameterListHelper = type helper for TParameterList
    function append(code: int32; short, long: string): TParameterList;
    function find(aValue: string): TParameter;
  end;

type
  { TSrtToAssApplication }

  TSrtToAssApplication = class(TCustomApplication)
  protected
    FLog: Text;
    FFontManager: TFontManager;
    FOptions: TOptions;
    FDocument: TAssaDocument;
    FMediaInfo: TMediaInfo;
    FTokenCount: integer;
    FRighe: TSRTList;
    FAlignament: uint8;
    FParameters: TParameterList;
    function stringMetrics(fontId: integer; fontSize: double; aString: unicodestring): TPoint;
    procedure DoRun; override;
    procedure readSRT;
    procedure transform;
    procedure emitStylesSection();
    procedure emitEventsSection();
    procedure parseOptions;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp;
  end;

operator *(a1, a2: TAffineMatrix): TAffineMatrix;
operator +(a1, a2: TAffineMatrix): TAffineMatrix;
operator shl(a1, a2: TAffineMatrix): TAffineMatrix;
operator shl(r: TRect; a2: TAffineMatrix): TRect;


implementation

uses
  fpjson, jsonparser, lib.assa, {$IFDEF DYNAMIC}freetypehdyn{$ELSE}freetypeh{$ENDIF};

operator *(a1, a2: TAffineMatrix): TAffineMatrix;
var
  i: byte;
begin
  for i := 0 to 2 do
  begin
    Result[i, 0] := a1[i, 0] * a2[0, 0] + a1[i, 1] * a2[1, 0] + a1[i, 2] * a2[2, 0];
    Result[i, 1] := a1[i, 0] * a2[0, 1] + a1[i, 1] * a2[1, 1] + a1[i, 2] * a2[2, 1];
    Result[i, 2] := a1[i, 0] * a2[0, 2] + a1[i, 1] * a2[1, 2] + a1[i, 2] * a2[2, 2];
  end;

end;

operator +(a1, a2: TAffineMatrix): TAffineMatrix;
begin
  Result[0, 0] := a1[0, 0] + a2[0, 0];
  Result[0, 1] := a1[0, 1] + a2[0, 1];
  Result[0, 2] := a1[0, 2] + a2[0, 2];

  Result[1, 0] := a1[1, 0] + a2[1, 0];
  Result[1, 1] := a1[1, 1] + a2[1, 1];
  Result[1, 2] := a1[1, 2] + a2[1, 2];

  Result[2, 0] := a1[2, 0] + a2[2, 0];
  Result[2, 1] := a1[2, 1] + a2[2, 1];
  Result[2, 2] := a1[2, 2] + a2[2, 2];
end;

operator shl(a1, a2: TAffineMatrix): TAffineMatrix;
begin
  Result := a1 * a2;
end;

operator shl(r: TRect; a2: TAffineMatrix): TRect;
begin
  Result.TopLeft := a2.transform(Result.TopLeft);
  Result.BottomRight := a2.transform(r.BottomRight);
end;

{ TAffineMatrixHelper }

class function TAffineMatrixHelper.identity: TAffineMatrix;
const
  return: TAffineMatrix = (
    (1, 0, 0),
    (0, 1, 0),
    (0, 0, 1));
begin
  Result := return;
end;

function TAffineMatrixHelper.translate(x, y: single): TAffineMatrix;
begin
  Result := identity;
  Result[0, 2] := x;
  Result[1, 2] := y;
  Result := Result * Self;
end;

function TAffineMatrixHelper.scale(x, y: single): TAffineMatrix;
begin
  Result := identity;
  Result[0, 0] := x;
  Result[1, 1] := y;
end;

function TAffineMatrixHelper.shear(x, y: single): TAffineMatrix;
begin
  Result := identity;
  Result[0, 1] := y;
  Result[1, 0] := x;
end;

function TAffineMatrixHelper.determinant: single;
begin
  Result := self[0, 0] * (self[1, 1] * self[2, 2] - self[1, 2] * self[2, 1]) - self[0, 1] * (self[1, 0] * self[2, 2] - self[1, 2] * self[2, 0]) + self[0, 2] * (self[1, 0] * self[2, 1] - self[1, 1] * self[2, 0]);
end;

function TAffineMatrixHelper.inverse: TAffineMatrix;
var
  det: single;
begin
  det := 1 / determinant;
  Result[0, 0] := (self[1, 1] * self[2, 2] - self[2, 1] * self[1, 2]) * det;
  Result[0, 1] := -(self[0, 1] * self[2, 2] - self[2, 1] * self[0, 2]) * det;
  Result[0, 2] := (self[0, 1] * self[1, 2] - self[1, 1] * self[0, 2]) * det;
  Result[1, 0] := -(self[1, 0] * self[2, 2] - self[2, 0] * self[1, 2]) * det;
  Result[1, 1] := (self[0, 0] * self[2, 2] - self[2, 0] * self[0, 2]) * det;
  Result[1, 2] := -(self[0, 0] * self[1, 2] - self[1, 0] * self[0, 2]) * det;
  Result[2, 0] := (self[1, 0] * self[2, 1] - self[2, 0] * self[1, 1]) * det;
  Result[2, 1] := -(self[0, 0] * self[2, 1] - self[2, 0] * self[0, 1]) * det;
  Result[2, 2] := (self[0, 0] * self[1, 1] - self[1, 0] * self[0, 1]) * det;
end;

function TAffineMatrixHelper.combine(a: TAffineMatrix): TAffineMatrix;
begin
  Result := self * a;
end;

function TAffineMatrixHelper.transform(const r: TRect): TRect;
begin
  Result.TopLeft := transform(r.TopLeft);
  Result.BottomRight := transform(r.BottomRight);
end;

function TAffineMatrixHelper.transform(const p: TPoint): TPoint;
var
  v: array [0..2] of single = (0, 0, 0);
begin
  v[0] := p.X;
  v[1] := p.y;
  v[0] := self[0, 0] * v[0] + self[0, 1] * v[1] + self[0, 2] * v[2];
  v[1] := self[1, 0] * v[0] + self[1, 1] * v[1] + self[1, 2] * v[2];
  v[2] := self[2, 0] * v[0] + self[2, 1] * v[1] + self[2, 2] * v[2];
  Result.X := Trunc(v[0]);
  Result.y := Trunc(v[1]);
end;

function TAffineMatrixHelper.transform(const p: TPointF): TPointF;
var
  v: array [0..2] of single = (0, 0, 0);
begin
  v[0] := p.X;
  v[1] := p.y;
  v[0] := self[0, 0] * v[0] + self[0, 1] * v[1] + self[0, 2] * v[2];
  v[1] := self[1, 0] * v[0] + self[1, 1] * v[1] + self[1, 2] * v[2];
  v[2] := self[2, 0] * v[0] + self[2, 1] * v[1] + self[2, 2] * v[2];
  Result.X := v[0];
  Result.y := v[1];
end;

{ TParameterListHelper }

function TParameterListHelper.append(code: int32; short, long: string): TParameterList;
begin
  SetLength(Self, Length(self) + 1);
  Self[High(self)].code := code;
  Self[High(self)].short := short;
  Self[High(self)].long := long;
  Result := self;
end;

function TParameterListHelper.find(aValue: string): TParameter;
var
  idx: word;
begin
  Result.code := -1;
  for idx := Low(Self) to High(Self) do
  begin
    if (Self[idx].long = aValue) or (Self[idx].short = aValue) then
      Exit(Self[idx]);
  end;
end;

{ TSrtToAssApplication }

function TSrtToAssApplication.stringMetrics(fontId: integer; fontSize: double; aString: unicodestring): TPoint;
var
  render: TBaseStringBitMaps;
  index: integer;
begin
  Result.X := 0;
  Result.Y := 0;
  render := FFontManager.GetString(fontId, aString, fontSize);
  for index := 0 to render.Count - 1 do
  begin
    Result.x += render.Bitmaps[index]^.Width;
    Result.y := Max(Result.y, render.Bitmaps[index]^.Height);
  end;
end;

procedure TSrtToAssApplication.DoRun;
begin
  parseOptions;
  FRighe := TSRTList.Create(True);
  if FileExists(FOptions.srtInput) then
  begin
    AssignFile(Input, FOptions.srtInput);
    AssignFile(Output, FOptions.assaOutput);
    Reset(Input);
    Rewrite(Output);
    SetTextCodePage(Input, CP_UTF8);
    SetTextCodePage(Output, CP_UTF8);
  end;
  if FileExists(FOptions.videoFile) then
  begin
    FMediaInfo.Open(FOptions.videoFile);
  end;
  if FileExists(FOptions.videoFile) then
  begin
    FMediaInfo.Open(FOptions.videoFile);
    FOptions.videoWidth := FMediaInfo.Width(0);
    FOptions.videoHeight := FMediaInfo.Height(0);
  end
  else
  begin
    FOptions.videoWidth := 1920;
    FOptions.videoHeight := 1080;
  end;
  readSRT;
  transform;
  Writeln(Output, '[Script Info]');
  Writeln(Output, 'ScriptType: v4.00+');
  Writeln(Output, 'PlayResX: ', FOptions.videoWidth);
  Writeln(Output, 'PlayResY: ', FOptions.videoHeight);
  Writeln(Output, 'ScaledBorderAndShadow: yes');
  Writeln(Output, 'YCbCr Matrix: None');
  Writeln(Output, '');
  Writeln(Output, '[Aegisub Project Garbage]');
  Writeln(Output, 'Last Style Storage: Default');
  Writeln(Output, 'Audio File: ', FOptions.videoFile);
  Writeln(Output, 'Video File: ', FOptions.videoFile);
  emitStylesSection();
  emitEventsSection();
  Writeln(Output, '');
  Flush(Output);
  CloseFile(Output);
  CloseFile(Input);
  Terminate;
end;

procedure TSrtToAssApplication.readSRT;
var
  srt: TSRT = nil;
  step: integer = 0;
  line: utf8string;
  slice: rawbytestring;
  idx: integer;
begin
  step := 0;
  while not EOF(Input) do
  begin
    ReadLn(Input, line);
    if (Length(line) > 0) and (line[1] = #$EF) then
    begin
      line := copy(line, 4);
    end;
    if line = '' then
    begin
      step := 0;
      continue;
    end;
    case step of
      0: begin
        try
          srt := TSRT.Create;
          srt.start := 0;
          srt.stop := 0;
          srt.message := '';
          FRighe.Add(srt);
          srt.id := StrToInt(line);
          Inc(step);
        except
        end;
      end;
      1: begin
        line := Trim(line);
        line := StringReplace(line, ' --> ', '|', [rfReplaceAll]);
        idx := Pos('|', line);
        slice := Copy(line, 1, idx - 1);
        srt.start.parse(slice);
        slice := Copy(line, idx, Length(line));
        Delete(line, 1, idx);
        srt.stop.parse(line);
        step := 2;
      end;
      2: begin
        if srt.message <> '' then
          srt.message += '\N' + trim(line)
        else
          srt.message := trim(line);
      end;
    end;
  end;
end;


function map(x, in_min, in_max, out_min, out_max: double): double; inline;
begin
  Result := (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
end;

procedure TSrtToAssApplication.transform;

  function contaRighe(Text: string): integer; inline;
  var
    c: PChar;
  begin
    Result := 1;
    c := PChar(Text);
    while c^ <> #0 do
    begin
      case c^ of
        '\': begin
          if (c + 1)^ = 'N' then
          begin
            Inc(Result);
            Inc(c);
          end;
        end;
        #10: Inc(Result);
        #13: begin
          Inc(Result);
          if (c + 1)^ = #10 then
            Inc(c);
        end;
      end;
      Inc(c);
    end;
  end;

var
  event: TAssaEvent;
  srt: TSRT;
  index: integer;
  aspectRatio: double;
  r: TRect;
  style: TAssaStyle;
  size: TPoint;
  H: longint;
  margine: double;
  a: TAffineMatrix;
  center: TPointF;
  txt: utf8string;
begin
  a := TAffineMatrix.identity;
  aspectRatio := 1.0;
  FOptions.coordinate.X := FOptions.videoWidth div 2;
  if FileExists(FOptions.videoFile) then
  begin
    aspectRatio := FMediaInfo.AspectRatio(0);
    FOptions.videoMargin := FOptions.videoWidth div 100;
    if FOptions.videoWidth < FOptions.videoHeight then
    begin
      aspectRatio := 1 + aspectRatio;
      FOptions.videoMargin := FOptions.videoHeight div 64;
    end;
    margine := map(FOptions.videoWidth, 480, 1920, 0, 20);
  end;
  if FOptions.fontSize < 0 then
  begin
    if FOptions.videoWidth > FOptions.videoHeight then
    begin
      FOptions.fontSize := map(FOptions.videoWidth, 480, 1920, 23, 90);
    end
    else
    begin
      FOptions.fontSize := map(FOptions.videoHeight, 480, 1920, 23, 90);
    end;
  end;

  for style in FDocument.Styles do
  begin
    style.fontSize := FOptions.fontSize;
  end;

  for index := 0 to FRighe.Count - 1 do
  begin
    r := Rect(0, 0, Trunc(FOptions.videoWidth - margine * 2), 0);
    srt := FRighe[index];
    if ((srt.start - srt.stop) = 0) and (srt.message = '') then continue;
    txt := trim(StringReplace(srt.message, '\N', LineEnding, [rfReplaceAll]));
    size := stringMetrics(FDocument.Styles[1].fontId, FDocument.Styles[1].fontSize, unicodestring(txt));
    H := contaRighe(txt);
    while size.X > FOptions.videoWidth do
    begin
      size.X := size.X - FOptions.videoWidth;
      h += 1;
    end;
    size.Y := H * size.Y;
    r.bottom := r.Top + size.Y;
    case FOptions.position of
      0:
      begin
        center.x := r.Height / 2;
        center.y := size.Y / 2;
      end;
      1:
      begin
        center.x := FOptions.videoWidth / 2;
        center.y := FOptions.videoHeight / 2;
      end;
      2:
      begin
        center.x := FOptions.videoWidth / 2;
        center.y := FOptions.videoHeight - size.Y / 2;
      end;
      3: begin
        center.x := FOptions.coordinate.X;
        center.y := FOptions.coordinate.Y;
      end;
    end;

    event := srt;
    event.dialog.style := FDocument.Styles[0];
    a.translate(FOptions.videoWidth - r.Width - margine, FOptions.videoHeight / 2);
    center := a.transform(center);
    event.dialog.Text := Format('{\p1\pos(%d,%d)}m %d %d l %d %d l %d %d l %d %d', [trunc(center.x), trunc(center.y), R.Left, R.Top, R.Right, R.Top, R.Right, R.Bottom, R.Left, R.Bottom]);
    FDocument.Events.Add(event);
    event := srt;
    event.dialog.layer := 1;
    event.dialog.style := FDocument.Styles[1];
    event.dialog.marginV := 0;
    event.dialog.Text := Format('{\pos(%d, %d)}%s', [trunc(center.x), trunc(center.y), event.dialog.Text]);
    FDocument.Events.Add(event);
  end;
end;

procedure TSrtToAssApplication.emitStylesSection();
const
  booleanString: array [boolean] of string = ('0', '1');
var
  idx: integer;
begin
  DefaultFormatSettings.DecimalSeparator := '.';

  Writeln(Output, '');
  Writeln(Output, '[V4+ Styles]');
  Writeln(Output, 'Format:',
    Format(' %s', ['Name']), ',',
    Format(' %s', ['Fontname']), ',',
    Format(' %s', ['Fontsize']), ',',
    Format(' %s', ['PrimaryColour']), ',',
    Format(' %s', ['SecondaryColour']), ',',
    Format(' %s', ['OutlineColour']), ',',
    Format(' %s', ['BackColour']), ',',
    Format(' %s', ['Bold']), ',',
    Format(' %s', ['Italic']), ',',
    Format(' %s', ['Underline']), ',',
    Format(' %s', ['StrikeOut']), ',',
    Format(' %s', ['ScaleX']), ',',
    Format(' %s', ['ScaleY']), ',',
    Format(' %s', ['Spacing']), ',',
    Format(' %s', ['Angle']), ',',
    Format(' %s', ['BorderStyle']), ',',
    Format(' %s', ['BackColour']), ',',
    Format(' %s', ['Outline']), ',',
    Format(' %s', ['Shadow']), ',',
    Format(' %s', ['Alignment']), ',',
    Format(' %s', ['MarginL']), ',',
    Format(' %s', ['MarginR']), ',',
    Format(' %s', ['MarginV']), ',',
    Format(' %s', ['Encoding']), ',',
    Format(' %s', ['Shadow'])
    );
  for idx := 0 to FDocument.Styles.Count - 1 do
  begin
    with FDocument.Styles[idx] do
    begin
      Writeln(Output, 'Style: ', Name, ',', fontName, ',',
        Format('%f', [Fontsize]), ',',
        primary.toString, ',',
        secondary.toString, ',',
        Outline.toString, ',',
        shadow.toString, ',',
        integer(Bold), ',',
        integer(italic), ',',
        integer(underline), ',',
        integer(StrikeOut), ',',
        FloatToStr(ScaleX), ',',
        FloatToStr(ScaleY), ',',
        FloatToStr(Spacing), ',',
        FloatToStr(Angle), ',',
        BorderStyle.ToString, ',',
        FloatToStr(outline_w), ',',
        FloatToStr(shadow_w), ',',
        Alignment.ToString, ',',
        MarginLeft.ToString, ',',
        MarginRight.ToString, ',',
        MarginVertical.ToString, ',',
        booleanString[Encoding]
        );
    end;
    Flush(Output);
  end;
end;

procedure TSrtToAssApplication.emitEventsSection;
var
  idx: integer;
begin
  Writeln(Output, '');
  Writeln(Output, '[Events]');
  Writeln(Output, 'Format: ',
    'Layer', ',',
    'Start', ',',
    'End', ',',
    'Style', ',',
    'Name', ',',
    'MarginL', ',',
    'MarginR', ',',
    'MarginV', ',',
    'Effect', ',',
    'Text');
  for idx := 0 to FDocument.Events.Count - 1 do
  begin
    with FDocument.Events[idx] do
    begin
      Writeln(Output, 'Dialogue: ',
        Format('%d', [dialog.layer]), ',',
        Format('%s', [dialog.start.toString]), ',',
        Format('%s', [dialog.stop.toString]), ',',
        Format('%s', [dialog.Style.Name]), ',',
        Format('%s', [dialog.Name]), ',',
        Format('%d', [dialog.marginL]), ',',
        Format('%d', [dialog.marginR]), ',',
        Format('%d', [dialog.marginV]), ',',
        Format('%s', [dialog.effect]), ',',
        dialog.Text);
    end;
  end;
end;

procedure TSrtToAssApplication.parseOptions;
var
  idx: integer;
begin
  Writeln(FLog, '-i ', '-i'.GetHashCode);
  Writeln(FLog, '--input ', '--input'.GetHashCode);
  Writeln(FLog, '-o ', '-o'.GetHashCode);
  Writeln(FLog, '--output ', '--output'.GetHashCode);
  Writeln(FLog, '-m ', '-m'.GetHashCode);
  Writeln(FLog, '--multim-media ', '--multim-media'.GetHashCode);
  Writeln(FLog, '-p ', '-p'.GetHashCode);
  Writeln(FLog, '--position ', '--position'.GetHashCode);
  Writeln(FLog, '-fs ', '-fs'.GetHashCode);
  Writeln(FLog, '--file-size ', '--file-size'.GetHashCode);
  Writeln(FLog, '-h ', '-h'.GetHashCode);
  Writeln(FLog, '--help ', '--help'.GetHashCode);
  idx := 1;
  while idx <= ParamCount do
  begin
    if (Params[idx] = '-h') or (Params[idx] = '--help') then
    begin
      WriteHelp();
      halt(0);
    end;
    if (Params[idx] = '-i') or (Params[idx] = '--input') then
    begin
      FOptions.srtInput := Params[idx + 1];
      Inc(idx);
    end
    else
    if (Params[idx] = '-o') or (Params[idx] = '--ouput') then
    begin
      FOptions.assaOutput := Params[idx + 1];
      Inc(idx);
    end
    else
    if (Params[idx] = '-m') or (Params[idx] = '--multi-media') then
    begin
      FOptions.videoFile := Params[idx + 1];
      Inc(idx);
    end
    else
    if (Params[idx] = '-p') or (Params[idx] = '--position') then
    begin
      if lowercase(Params[idx + 1]) = 'top' then
        FOptions.position := 0;
      if lowercase(Params[idx + 1]) = 'center' then
        FOptions.position := 1;
      if lowercase(Params[idx + 1]) = 'bottom' then
        FOptions.position := 2;
      if lowercase(Params[idx + 1]) = 'custom' then
      begin
        FOptions.position := 3;
        FOptions.coordinate.y := Params[idx + 2].ToInt64;
        Inc(idx, 1);
      end;
      Inc(idx);
    end
    else
    if (Params[idx] = '-fs') or (Params[idx] = '--font-size') then
    begin
      FOptions.fontSize := Params[idx + 1].ToDouble;
      Inc(idx);
    end;
    Inc(idx);
  end;
end;

constructor TSrtToAssApplication.Create(TheOwner: TComponent);
var
  style: TAssaStyle;
  idx: integer;
begin
  inherited Create(TheOwner);
  AssignFile(FLog, ChangeFileExt(Params[0], '.log'));
  Rewrite(FLog);
  StopOnException := True;
  FTokenCount := 0;
  FFontManager := TFontManager.Create;
  MediaInfoDLL_Load('MediaInfo');
  FMediaInfo := TMediaInfo.Create;

  FOptions.fontSize := -1;

  FDocument := TAssaDocument.Create;
  FDocument.Styles.Add(TAssaStyle.Create('Text'));
  FDocument.Styles.Add(TAssaStyle.Create('UNO'));
  FDocument.Styles.Add(TAssaStyle.Create('DUE'));
  FDocument.Styles.Add(TAssaStyle.Create('TRE'));

  for style in FDocument.Styles do
  begin
    Style.fontName := 'DejaVuSans';
    Style.fontSize := 50;
    Style.fontId := FFontManager.RequestFont(Style.fontName);
    Style.primary := TASSAColor.new(0, 255, 255, 0);
    Style.outline := TASSAColor.new(0, 0, 0, 0);
    Style.shadow := TASSAColor.new(0, 0, 0, 0);
  end;

  FDocument.Styles[0].primary := TASSAColor.new(0, 0, 0, 80);
  FDocument.Styles[0].secondary := TASSAColor.new(255, 0, 80);
  FDocument.Styles[0].outline := TASSAColor.new(0, 0, 0, 80);
  FDocument.Styles[0].shadow := TASSAColor.new(0, 0, 0, 80);
  FDocument.Styles[0].alignment := 7;

  FDocument.Styles[1].primary := TASSAColor.new(255, 255, 255, 0);
  FDocument.Styles[2].primary := TASSAColor.new(0, 255, 255, 0);
  FDocument.Styles[3].primary := TASSAColor.new(0, 255, 0, 0);
  FOptions.position := 2;
  FAlignament := 5;

  for style in FDocument.Styles do
  begin
    style.alignment := FAlignament;
  end;
  SetLength(FParameters, 0);
  FParameters //0
    .append(0, '-h', '-help') //0
    .append(1, '-i', '--input') //0
    .append(2, '-o', '--output') //0
    .append(3, '-m', '--multi-media') //0
    .append(4, '-p', '--position') //0
    .append(5, '-fs', '--font-size');
end;

destructor TSrtToAssApplication.Destroy;
begin
  FreeAndNil(FDocument);
  FreeAndNil(FFontManager);
  FMediaInfo.Free;
  CloseFile(FLog);
  inherited Destroy;
end;

procedure TSrtToAssApplication.WriteHelp;
begin
  Writeln('str to advanced sub station file script');
  Writeln('-i [input file name]');
  Writeln('-o [output file name]');
  Writeln('-m [multimedia file name] {optional}');
  Writeln('-p [top|center|bottom|custom] {optional}');
  Writeln('-fs [font size] {optional}');
  Halt(0);
end;

end.
