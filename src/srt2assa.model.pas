unit srt2assa.model;

{$mode ObjFPC}{$H+}
{$modeSwitch advancedRecords}
{$modeSwitch typehelpers}

interface

uses
  Classes, SysUtils, FPColorSpace, fgl, freetype, lib.assa;

type
  TMilliseconds = uint64;

  { TMillisecondsTypeHelper }

  TMillisecondsTypeHelper = type helper for TMilliseconds
    function toString: string;
    procedure parse(aValue: string);
  end;

  TSRT = class
    id: integer;
    start: TMilliseconds;
    stop: TMilliseconds;
    message: utf8string;
  end;

  TSRTArray = array of TSRT;
  TSRTList = specialize TFPGObjectList<TSRT>;

  { TASSAColor }

  TASSAColor = packed record
    red, green, blue, alpha: byte;
    class function New(const ARed, AGreen, ABlue, AAlpha: byte): TASSAColor; overload; static;
    class function New(const ARed, AGreen, ABlue: byte): TASSAColor; overload; static;
    function toString: string;
    class function parse(aValue: string): TASSAColor; static;
  end;

  { TAssaStyle }

  TAssaStyle = class(TObject)
    Name: string;//= 'Default'; ///< Name of the style; must be case-insensitively unique within a file despite being case-sensitive
    fontName: string;//= 'Arial';   ///< Font face name
    fontSize: double;//= 48.0;        ///< Font size
    primary: TASSAColor;//{ 255, 255, 255 }; ///< Default text color
    secondary: TASSAColor;//{ 255, 0, 0 };   ///< Text color for not-yet-reached karaoke syllables
    outline: TASSAColor;//{ 0, 0, 0 };       ///< Outline color
    shadow: TASSAColor;//{ 0, 0, 0 };        ///< Shadow color

    bold: boolean;// = false;
    italic: boolean;//= false;
    underline: boolean;// = false;
    strikeout: boolean;// = false;

    scalex: double;//= 100.;      ///< Font x scale with 100 = 100%
    scaley: double;//= 100.;      ///< Font y scale with 100 = 100%
    spacing: double;// = 0.0;       ///< Additional spacing between characters in pixels
    angle: double;// = 0.0;         ///< Counterclockwise z rotation in degrees
    borderstyle: integer;// = 1;       ///< 1: Normal; 3: Opaque box; others are unused in Aegisub
    outline_w: double;// = 2.;     ///< Outline width in pixels
    shadow_w: double;// = 2.;      ///< Shadow distance in pixels
    alignment: integer;// = 2;         ///< \an-style line alignment
    MarginLeft: integer; ///< Left / Right / Vertical
    MarginRight: integer; ///< Left / Right / Vertical
    MarginVertical: integer; ///< Left / Right / Vertical
    Encoding: boolean; // = false;          ///< ASS font encoding needed for some non-unicode fonts

    Blur: double; // sets a default \blur for the event; same values as \blur
    Justify: integer; // sets text justification independent of event alignment; use ASS_JUSTIFY_*

    fontId: integer;
    constructor Create(aName: string);
  end;


  { TAssaDialogue }

  TAssaDialogue = class
  public
    marked: boolean;
    layer: integer;
    start: TMilliseconds;
    stop: TMilliseconds;
    style: TAssaStyle;
    Name: utf8string;
    marginL: integer;
    marginR: integer;
    marginV: integer;
    alphaLevel: byte;
    effect: utf8string;
    Text: utf8string;

    constructor Create;
  end;

  { TAssaEvent }

  TAssaEvent = class
    evenType: byte;
    dialog: TAssaDialogue;

    constructor Create;
    destructor Destroy; override;
    function toString: utf8string; reintroduce; virtual;
  end;


  TAssaEvents = specialize TFPGObjectList<TAssaEvent>;
  TAssaStyles = specialize TFPGObjectList<TAssaStyle>;

  { TAssaDocument }

  TAssaDocument = class
  private
    FEvents: TAssaEvents;
    FStyles: TAssaStyles;
    function GetEvents: TAssaEvents;
    function GetStyles: TAssaStyles;
  public
    property Styles: TAssaStyles read GetStyles;
    property Events: TAssaEvents read GetEvents;
  end;

operator := (srt: TSRT): TAssaEvent;
operator +(a: TSRTArray; srt: TSRT): TSRTArray;

implementation

var
  fontManager: TFontManager;

operator := (srt: TSRT): TAssaEvent;
begin
  Result := TAssaEvent.Create;
  Result.dialog := TAssaDialogue.Create;
  with Result.dialog do
  begin
    start := srt.start;
    stop := srt.stop;
    Text := srt.message;
  end;
end;

operator +(a: TSRTArray; srt: TSRT): TSRTArray;
begin
  Result := a;
  SetLength(Result, Length(Result) + 1);
  Result[high(Result)] := srt;
end;

{ TMillisecondsTypeHelper }

function TMillisecondsTypeHelper.toString: string;
var
  h: uint64;
  milliseconds: word;
  seconds: word;
  minutes: word;
  hours: word;
begin
  h := self;
  milliseconds := (h mod 1000);
  h := h div 1000;
  seconds := h mod 60;
  h := h div 60;
  minutes := h mod 60;
  h := h div 60;
  hours := h;
  Result := Format('%d:%.2d:%.2d.%.2d', [hours, minutes, seconds, milliseconds div 10]);
end;

procedure TMillisecondsTypeHelper.parse(aValue: string);
var
  Value: TDateTime;
  milliseconds: word;
  seconds: word;
  minutes: word;
  hours: word;
begin
  Value := StrToDateTime(aValue);
  DecodeTime(Value, hours, minutes, seconds, milliseconds);
  self := hours;
  self := self * 60 + minutes;
  self := self * 60 + seconds;
  self := self * 1000 + milliseconds;
end;

{ TAssaStyle }

constructor TAssaStyle.Create(aName: string);
begin
  Name := aname;
  fontName := 'Arial';
  fontsize := 20;
  primary := TASSAColor.New(255, 255, 255, 70);
  secondary := TASSAColor.New(0, 0, 0);
  outline := TASSAColor.New(0, 0, 0);
  shadow := TASSAColor.New(0, 0, 0);
  bold := False;
  italic := False;
  strikeout := False;
  scalex := 100.0;
  scaley := 100.0;
  spacing := 1;
  angle := 0.0;
  borderstyle := 1;
  alignment := 2;
  MarginLeft := 0;
  MarginRight := 0;
  MarginVertical := 0;
  outline_w := 2.0;
  shadow_w := 2.0;
  Encoding := False;
end;

{ TAssaDialogue }

constructor TAssaDialogue.Create;
begin
  marked := True;
  layer := 0;
  start := 0;
  stop := 0;
  style := nil;
  Name := '';
  marginL := 0;
  marginR := 0;
  marginV := 0;
  effect := '';
  alphaLevel := 255;
  Text := '';
end;

{ TAssaEvent }

constructor TAssaEvent.Create;
begin
  evenType := 0;
  dialog := nil;
end;

destructor TAssaEvent.Destroy;
begin
  if dialog <> nil then FreeAndNil(dialog);
  inherited Destroy;
end;

function TAssaEvent.toString: utf8string;
begin
  Result := '';
  case evenType of
    0: Result := dialog.ToString;
  end;

end;

{ TAssaDocument }

function TAssaDocument.GetEvents: TAssaEvents;
begin
  if FEvents = nil then
    FEvents := TAssaEvents.Create(True);
  Result := FEvents;
end;

function TAssaDocument.GetStyles: TAssaStyles;
begin
  if FStyles = nil then
    FStyles := TAssaStyles.Create(True);
  Result := FStyles;
end;

{ TASSAColor }

class function TASSAColor.New(const ARed, AGreen, ABlue, AAlpha: byte): TASSAColor;
begin
  Result.red := ARed;
  Result.green := AGreen;
  Result.blue := ABlue;
  Result.alpha := AAlpha;
end;

class function TASSAColor.New(const ARed, AGreen, ABlue: byte): TASSAColor;
begin
  Result.red := ARed;
  Result.green := AGreen;
  Result.blue := ABlue;
  Result.alpha := 0;
end;

function TASSAColor.toString: string;
begin
  Result := Format('&H%.2x%.2x%.2x%.2x', [alpha, blue, green, red]);
end;

class function TASSAColor.parse(aValue: string): TASSAColor;
var
  c: PChar;
  Value: uint32 = 0;
begin
  c := PChar(aValue);
  while c^ <> #0 do
  begin
    if (c^ = '&') and (((c + 1)^ = 'H') or ((c + 1)^ = 'h')) then
      case c^ of
        '0'..'9': Value += Ord(c^) - Ord('0');
        'A'..'F': Value += Ord(c^) - Ord('A');
        'a'..'f': Value += Ord(c^) - Ord('a');
      end;
  end;
  Result.alpha := (Value shr 24) and $FF;
  Result.blue := (Value shr 16) and $FF;
  Result.green := (Value shr 8) and $FF;
  Result.red := (Value shr 8) and $FF;
end;

initialization

  fontManager := TFontManager.Create;

finalization

  FreeAndNil(fontManager);

end.
