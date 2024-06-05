unit srt2assa.mediainfo;

{$mode delphi}{$H+}
{$ModeSwitch typehelpers}

interface

uses
  Classes, SysUtils, srt2assa.model;

type
  TMIStreamKind =
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
  TMIInfo =
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

var
  LibHandle: THandle = 0;

  // Unicode methods
  MediaInfo_New: function(): THandle; stdcall;
  MediaInfo_Delete: procedure(Handle: THandle); stdcall;
  MediaInfo_Open: function(Handle: THandle; File__: pwidechar): cardinal; stdcall;
  MediaInfo_Close: procedure(Handle: THandle); stdcall;
  MediaInfo_Inform: function(Handle: THandle; Reserved: integer): pwidechar; stdcall;
  MediaInfo_GetI: function(Handle: THandle; StreamKind: TMIStreamKind; StreamNumber: integer; Parameter: integer; KindOfInfo: TMIInfo): pwidechar; stdcall;     //Default: KindOfInfo=Info_Text,
  MediaInfo_Get: function(Handle: THandle; StreamKind: TMIStreamKind; StreamNumber: integer; Parameter: pwidechar; KindOfInfo: TMIInfo; KindOfSearch: TMIInfo): pwidechar; stdcall;     //Default: KindOfInfo=Info_Text, KindOfSearch=Info_Name
  MediaInfo_Option: function(Handle: THandle; Option: pwidechar; Value: pwidechar): pwidechar; stdcall;
  MediaInfo_State_Get: function(Handle: THandle): integer; stdcall;
  MediaInfo_Count_Get: function(Handle: THandle; StreamKind: TMIStreamKind; StreamNumber: integer): integer; stdcall;

  // Ansi methods
  MediaInfoA_New: function(): THandle; stdcall;
  MediaInfoA_Delete: procedure(Handle: THandle); stdcall;
  MediaInfoA_Open: function(Handle: THandle; File__: pansichar): cardinal; stdcall;
  MediaInfoA_Close: procedure(Handle: THandle); stdcall;
  MediaInfoA_Inform: function(Handle: THandle; Reserved: integer): pansichar; stdcall;
  MediaInfoA_GetI: function(Handle: THandle; StreamKind: TMIStreamKind; StreamNumber: integer; Parameter: integer; KindOfInfo: TMIInfo): pansichar; stdcall;     //Default: KindOfInfo=Info_Text
  MediaInfoA_Get: function(Handle: THandle; StreamKind: TMIStreamKind; StreamNumber: integer; Parameter: pansichar; KindOfInfo: TMIInfo; KindOfSearch: TMIInfo): pansichar; stdcall;     //Default: KindOfInfo=Info_Text, KindOfSearch=Info_Name
  MediaInfoA_Option: function(Handle: THandle; Option: pansichar; Value: pansichar): pansichar; stdcall;
  MediaInfoA_State_Get: function(Handle: THandle): integer; stdcall;
  MediaInfoA_Count_Get: function(Handle: THandle; StreamKind: TMIStreamKind; StreamNumber: integer): integer; stdcall;

function MediaInfoDLL_Load(LibPath: string): boolean;


type
  { TMediaInfo }

  TMediaInfo = class
  protected
    FHandle: THandle;
  public
    constructor Create;
    destructor Destroy; override;
    function Open(aFileName: TFileName): boolean;
    function Width(streamIndex: word): word;
    function AspectRatio(streamIndex: word): double;
    function Height(streamIndex: word): word;
    function LengthTime(streamIndex: word): TMilliseconds;
  end;




implementation

uses
  dynlibs;

type
  VideoFieldInfo = (
    Video_Count,
    Video_Status,
    Video_StreamCount,
    Video_StreamKind,
    Video_StreamKind_String,
    Video_StreamKindID,
    Video_StreamKindPos,
    Video_StreamOrder,
    Video_FirstPacketOrder,
    Video_Inform,
    Video_ID,
    Video_ID_String,
    Video_OriginalSourceMedium_ID,
    Video_OriginalSourceMedium_ID_String,
    Video_UniqueID,
    Video_UniqueID_String,
    Video_MenuID,
    Video_MenuID_String,
    Video_Format,
    Video_Format_String,
    Video_Format_Info,
    Video_Format_Url,
    Video_Format_Commercial,
    Video_Format_Commercial_IfAny,
    Video_Format_Version,
    Video_Format_Profile,
    Video_Format_Level,
    Video_Format_Tier,
    Video_Format_Compression,
    Video_Format_AdditionalFeatures,
    Video_MultiView_BaseProfile,
    Video_MultiView_Count,
    Video_MultiView_Layout,
    Video_HDR_Format,
    Video_HDR_Format_String,
    Video_HDR_Format_Commercial,
    Video_HDR_Format_Version,
    Video_HDR_Format_Profile,
    Video_HDR_Format_Level,
    Video_HDR_Format_Settings,
    Video_HDR_Format_Compression,
    Video_HDR_Format_Compatibility,
    Video_Format_Settings,
    Video_Format_Settings_BVOP,
    Video_Format_Settings_BVOP_String,
    Video_Format_Settings_QPel,
    Video_Format_Settings_QPel_String,
    Video_Format_Settings_GMC,
    Video_Format_Settings_GMC_String,
    Video_Format_Settings_Matrix,
    Video_Format_Settings_Matrix_String,
    Video_Format_Settings_Matrix_Data,
    Video_Format_Settings_CABAC,
    Video_Format_Settings_CABAC_String,
    Video_Format_Settings_RefFrames,
    Video_Format_Settings_RefFrames_String,
    Video_Format_Settings_Pulldown,
    Video_Format_Settings_Endianness,
    Video_Format_Settings_Packing,
    Video_Format_Settings_FrameMode,
    Video_Format_Settings_GOP,
    Video_Format_Settings_PictureStructure,
    Video_Format_Settings_Wrapping,
    Video_Format_Settings_SliceCount,
    Video_Format_Settings_SliceCount_String,
    Video_InternetMediaType,
    Video_MuxingMode,
    Video_CodecID,
    Video_CodecID_String,
    Video_CodecID_Info,
    Video_CodecID_Hint,
    Video_CodecID_Url,
    Video_CodecID_Description,
    Video_Codec,
    Video_Codec_String,
    Video_Codec_Family,
    Video_Codec_Info,
    Video_Codec_Url,
    Video_Codec_CC,
    Video_Codec_Profile,
    Video_Codec_Description,
    Video_Codec_Settings,
    Video_Codec_Settings_PacketBitStream,
    Video_Codec_Settings_BVOP,
    Video_Codec_Settings_QPel,
    Video_Codec_Settings_GMC,
    Video_Codec_Settings_GMC_String,
    Video_Codec_Settings_Matrix,
    Video_Codec_Settings_Matrix_Data,
    Video_Codec_Settings_CABAC,
    Video_Codec_Settings_RefFrames,
    Video_Duration,
    Video_Duration_String,
    Video_Duration_String1,
    Video_Duration_String2,
    Video_Duration_String3,
    Video_Duration_String4,
    Video_Duration_String5,
    Video_Duration_FirstFrame,
    Video_Duration_FirstFrame_String,
    Video_Duration_FirstFrame_String1,
    Video_Duration_FirstFrame_String2,
    Video_Duration_FirstFrame_String3,
    Video_Duration_FirstFrame_String4,
    Video_Duration_FirstFrame_String5,
    Video_Duration_LastFrame,
    Video_Duration_LastFrame_String,
    Video_Duration_LastFrame_String1,
    Video_Duration_LastFrame_String2,
    Video_Duration_LastFrame_String3,
    Video_Duration_LastFrame_String4,
    Video_Duration_LastFrame_String5,
    Video_Source_Duration,
    Video_Source_Duration_String,
    Video_Source_Duration_String1,
    Video_Source_Duration_String2,
    Video_Source_Duration_String3,
    Video_Source_Duration_String4,
    Video_Source_Duration_String5,
    Video_Source_Duration_FirstFrame,
    Video_Source_Duration_FirstFrame_String,
    Video_Source_Duration_FirstFrame_String1,
    Video_Source_Duration_FirstFrame_String2,
    Video_Source_Duration_FirstFrame_String3,
    Video_Source_Duration_FirstFrame_String4,
    Video_Source_Duration_FirstFrame_String5,
    Video_Source_Duration_LastFrame,
    Video_Source_Duration_LastFrame_String,
    Video_Source_Duration_LastFrame_String1,
    Video_Source_Duration_LastFrame_String2,
    Video_Source_Duration_LastFrame_String3,
    Video_Source_Duration_LastFrame_String4,
    Video_Source_Duration_LastFrame_String5,
    Video_BitRate_Mode,
    Video_BitRate_Mode_String,
    Video_BitRate,
    Video_BitRate_String,
    Video_BitRate_Minimum,
    Video_BitRate_Minimum_String,
    Video_BitRate_Nominal,
    Video_BitRate_Nominal_String,
    Video_BitRate_Maximum,
    Video_BitRate_Maximum_String,
    Video_BitRate_Encoded,
    Video_BitRate_Encoded_String,
    Video_Width,
    Video_Width_String,
    Video_Width_Offset,
    Video_Width_Offset_String,
    Video_Width_Original,
    Video_Width_Original_String,
    Video_Width_CleanAperture,
    Video_Width_CleanAperture_String,
    Video_Height,
    Video_Height_String,
    Video_Height_Offset,
    Video_Height_Offset_String,
    Video_Height_Original,
    Video_Height_Original_String,
    Video_Height_CleanAperture,
    Video_Height_CleanAperture_String,
    Video_Stored_Width,
    Video_Stored_Height,
    Video_Sampled_Width,
    Video_Sampled_Height,
    Video_PixelAspectRatio,
    Video_PixelAspectRatio_String,
    Video_PixelAspectRatio_Original,
    Video_PixelAspectRatio_Original_String,
    Video_PixelAspectRatio_CleanAperture,
    Video_PixelAspectRatio_CleanAperture_String,
    Video_DisplayAspectRatio,
    Video_DisplayAspectRatio_String,
    Video_DisplayAspectRatio_Original,
    Video_DisplayAspectRatio_Original_String,
    Video_DisplayAspectRatio_CleanAperture,
    Video_DisplayAspectRatio_CleanAperture_String,
    Video_ActiveFormatDescription,
    Video_ActiveFormatDescription_String,
    Video_ActiveFormatDescription_MuxingMode,
    Video_Active_Width,
    Video_Active_Width_String,
    Video_Active_Height,
    Video_Active_Height_String,
    Video_Active_DisplayAspectRatio,
    Video_Active_DisplayAspectRatio_String,
    Video_Rotation,
    Video_Rotation_String,
    Video_FrameRate_Mode,
    Video_FrameRate_Mode_String,
    Video_FrameRate_Mode_Original,
    Video_FrameRate_Mode_Original_String,
    Video_FrameRate,
    Video_FrameRate_String,
    Video_FrameRate_Num,
    Video_FrameRate_Den,
    Video_FrameRate_Minimum,
    Video_FrameRate_Minimum_String,
    Video_FrameRate_Nominal,
    Video_FrameRate_Nominal_String,
    Video_FrameRate_Maximum,
    Video_FrameRate_Maximum_String,
    Video_FrameRate_Original,
    Video_FrameRate_Original_String,
    Video_FrameRate_Original_Num,
    Video_FrameRate_Original_Den,
    Video_FrameRate_Real,
    Video_FrameRate_Real_String,
    Video_FrameCount,
    Video_Source_FrameCount,
    Video_Standard,
    Video_Resolution,
    Video_Resolution_String,
    Video_Colorimetry,
    Video_ColorSpace,
    Video_ChromaSubsampling,
    Video_ChromaSubsampling_String,
    Video_ChromaSubsampling_Position,
    Video_BitDepth,
    Video_BitDepth_String,
    Video_ScanType,
    Video_ScanType_String,
    Video_ScanType_Original,
    Video_ScanType_Original_String,
    Video_ScanType_StoreMethod,
    Video_ScanType_StoreMethod_FieldsPerBlock,
    Video_ScanType_StoreMethod_String,
    Video_ScanOrder,
    Video_ScanOrder_String,
    Video_ScanOrder_Stored,
    Video_ScanOrder_Stored_String,
    Video_ScanOrder_StoredDisplayedInverted,
    Video_ScanOrder_Original,
    Video_ScanOrder_Original_String,
    Video_Interlacement,
    Video_Interlacement_String,
    Video_Compression_Mode,
    Video_Compression_Mode_String,
    Video_Compression_Ratio,
    Video_Bits__Pixel_Frame_,
    Video_Delay,
    Video_Delay_String,
    Video_Delay_String1,
    Video_Delay_String2,
    Video_Delay_String3,
    Video_Delay_String4,
    Video_Delay_String5,
    Video_Delay_Settings,
    Video_Delay_DropFrame,
    Video_Delay_Source,
    Video_Delay_Source_String,
    Video_Delay_Original,
    Video_Delay_Original_String,
    Video_Delay_Original_String1,
    Video_Delay_Original_String2,
    Video_Delay_Original_String3,
    Video_Delay_Original_String4,
    Video_Delay_Original_String5,
    Video_Delay_Original_Settings,
    Video_Delay_Original_DropFrame,
    Video_Delay_Original_Source,
    Video_TimeStamp_FirstFrame,
    Video_TimeStamp_FirstFrame_String,
    Video_TimeStamp_FirstFrame_String1,
    Video_TimeStamp_FirstFrame_String2,
    Video_TimeStamp_FirstFrame_String3,
    Video_TimeStamp_FirstFrame_String4,
    Video_TimeStamp_FirstFrame_String5,
    Video_TimeCode_FirstFrame,
    Video_TimeCode_LastFrame,
    Video_TimeCode_DropFrame,
    Video_TimeCode_Settings,
    Video_TimeCode_Source,
    Video_Gop_OpenClosed,
    Video_Gop_OpenClosed_String,
    Video_Gop_OpenClosed_FirstFrame,
    Video_Gop_OpenClosed_FirstFrame_String,
    Video_StreamSize,
    Video_StreamSize_String,
    Video_StreamSize_String1,
    Video_StreamSize_String2,
    Video_StreamSize_String3,
    Video_StreamSize_String4,
    Video_StreamSize_String5,
    Video_StreamSize_Proportion,
    Video_StreamSize_Demuxed,
    Video_StreamSize_Demuxed_String,
    Video_StreamSize_Demuxed_String1,
    Video_StreamSize_Demuxed_String2,
    Video_StreamSize_Demuxed_String3,
    Video_StreamSize_Demuxed_String4,
    Video_StreamSize_Demuxed_String5,
    Video_Source_StreamSize,
    Video_Source_StreamSize_String,
    Video_Source_StreamSize_String1,
    Video_Source_StreamSize_String2,
    Video_Source_StreamSize_String3,
    Video_Source_StreamSize_String4,
    Video_Source_StreamSize_String5,
    Video_Source_StreamSize_Proportion,
    Video_StreamSize_Encoded,
    Video_StreamSize_Encoded_String,
    Video_StreamSize_Encoded_String1,
    Video_StreamSize_Encoded_String2,
    Video_StreamSize_Encoded_String3,
    Video_StreamSize_Encoded_String4,
    Video_StreamSize_Encoded_String5,
    Video_StreamSize_Encoded_Proportion,
    Video_Source_StreamSize_Encoded,
    Video_Source_StreamSize_Encoded_String,
    Video_Source_StreamSize_Encoded_String1,
    Video_Source_StreamSize_Encoded_String2,
    Video_Source_StreamSize_Encoded_String3,
    Video_Source_StreamSize_Encoded_String4,
    Video_Source_StreamSize_Encoded_String5,
    Video_Source_StreamSize_Encoded_Proportion,
    Video_Alignment,
    Video_Alignment_String,
    Video_Title,
    Video_Encoded_Application,
    Video_Encoded_Application_String,
    Video_Encoded_Application_CompanyName,
    Video_Encoded_Application_Name,
    Video_Encoded_Application_Version,
    Video_Encoded_Application_Url,
    Video_Encoded_Library,
    Video_Encoded_Library_String,
    Video_Encoded_Library_CompanyName,
    Video_Encoded_Library_Name,
    Video_Encoded_Library_Version,
    Video_Encoded_Library_Date,
    Video_Encoded_Library_Settings,
    Video_Encoded_OperatingSystem,
    Video_Language,
    Video_Language_String,
    Video_Language_String1,
    Video_Language_String2,
    Video_Language_String3,
    Video_Language_String4,
    Video_Language_More,
    Video_ServiceKind,
    Video_ServiceKind_String,
    Video_Disabled,
    Video_Disabled_String,
    Video_Default,
    Video_Default_String,
    Video_Forced,
    Video_Forced_String,
    Video_AlternateGroup,
    Video_AlternateGroup_String,
    Video_Encoded_Date,
    Video_Tagged_Date,
    Video_Encryption,
    Video_BufferSize,
    Video_colour_description_present,
    Video_colour_description_present_Source,
    Video_colour_description_present_Original,
    Video_colour_description_present_Original_Source,
    Video_colour_range,
    Video_colour_range_Source,
    Video_colour_range_Original,
    Video_colour_range_Original_Source,
    Video_colour_primaries,
    Video_colour_primaries_Source,
    Video_colour_primaries_Original,
    Video_colour_primaries_Original_Source,
    Video_transfer_characteristics,
    Video_transfer_characteristics_Source,
    Video_transfer_characteristics_Original,
    Video_transfer_characteristics_Original_Source,
    Video_matrix_coefficients,
    Video_matrix_coefficients_Source,
    Video_matrix_coefficients_Original,
    Video_matrix_coefficients_Original_Source,
    Video_MasteringDisplay_ColorPrimaries,
    Video_MasteringDisplay_ColorPrimaries_Source,
    Video_MasteringDisplay_ColorPrimaries_Original,
    Video_MasteringDisplay_ColorPrimaries_Original_Source,
    Video_MasteringDisplay_Luminance,
    Video_MasteringDisplay_Luminance_Source,
    Video_MasteringDisplay_Luminance_Original,
    Video_MasteringDisplay_Luminance_Original_Source,
    Video_MaxCLL,
    Video_MaxCLL_Source,
    Video_MaxCLL_Original,
    Video_MaxCLL_Original_Source,
    Video_MaxFALL,
    Video_MaxFALL_Source,
    Video_MaxFALL_Original,
    Video_MaxFALL_Original_Source);


function MediaInfoDLL_Load(LibPath: string): boolean;
begin
  Result := False;

  if LibHandle = 0 then
    LibHandle := LoadLibrary(PChar(LibPath));

  if LibHandle <> 0 then
  begin
    Pointer(@MediaInfo_New) := GetProcAddress(LibHandle, 'MediaInfo_New');
    Pointer(@MediaInfo_Delete) := GetProcAddress(LibHandle, 'MediaInfo_Delete');
    Pointer(@MediaInfo_Open) := GetProcAddress(LibHandle, 'MediaInfo_Open');
    Pointer(@MediaInfo_Close) := GetProcAddress(LibHandle, 'MediaInfo_Close');
    Pointer(@MediaInfo_Inform) := GetProcAddress(LibHandle, 'MediaInfo_Inform');
    Pointer(@MediaInfo_GetI) := GetProcAddress(LibHandle, 'MediaInfo_GetI');
    Pointer(@MediaInfo_Get) := GetProcAddress(LibHandle, 'MediaInfo_Get');
    Pointer(@MediaInfo_Option) := GetProcAddress(LibHandle, 'MediaInfo_Option');
    Pointer(@MediaInfo_State_Get) := GetProcAddress(LibHandle, 'MediaInfo_State_Get');
    Pointer(@MediaInfo_Count_Get) := GetProcAddress(LibHandle, 'MediaInfo_Count_Get');
    Pointer(@MediaInfoA_New) := GetProcAddress(LibHandle, 'MediaInfoA_New');
    Pointer(@MediaInfoA_Delete) := GetProcAddress(LibHandle, 'MediaInfoA_Delete');
    Pointer(@MediaInfoA_Open) := GetProcAddress(LibHandle, 'MediaInfoA_Open');
    Pointer(@MediaInfoA_Close) := GetProcAddress(LibHandle, 'MediaInfoA_Close');
    Pointer(@MediaInfoA_Inform) := GetProcAddress(LibHandle, 'MediaInfoA_Inform');
    Pointer(@MediaInfoA_GetI) := GetProcAddress(LibHandle, 'MediaInfoA_GetI');
    Pointer(@MediaInfoA_Get) := GetProcAddress(LibHandle, 'MediaInfoA_Get');
    Pointer(@MediaInfoA_Option) := GetProcAddress(LibHandle, 'MediaInfoA_Option');
    Pointer(@MediaInfoA_State_Get) := GetProcAddress(LibHandle, 'MediaInfoA_State_Get');
    Pointer(@MediaInfoA_Count_Get) := GetProcAddress(LibHandle, 'MediaInfoA_Count_Get');
    Result := True;
  end;
end;


{ TMediaInfo }

constructor TMediaInfo.Create;
begin
  FHandle := MediaInfoA_New();
end;

destructor TMediaInfo.Destroy;
begin
  MediaInfoA_Delete(FHandle);
  inherited Destroy;
end;

function TMediaInfo.Open(aFileName: TFileName): boolean;
begin
  Result := MediaInfoA_Open(FHandle, pansichar(aFileName)) = 0;
end;

function TMediaInfo.Width(streamIndex: word): word;
begin
  Result := string(MediaInfoA_Get(FHandle, Stream_Video, 0, 'Width', Info_Text, TMIInfo(0))).ToInteger;
end;

function TMediaInfo.AspectRatio(streamIndex: word): double;
var
  Value: string;
  DefaultFormatSettings: TFormatSettings;
begin
  DefaultFormatSettings.DecimalSeparator := '.';
  Value := string(MediaInfoA_Get(FHandle, Stream_Video, 0, 'DisplayAspectRatio', Info_Text, TMIInfo(0)));
  Value := StringReplace(Value, ',', '.', [rfReplaceAll]);
  if (Value = '') then
    Result := 1.0
  else
    Result := StrToFloat(Value, DefaultFormatSettings);
end;

function TMediaInfo.Height(streamIndex: word): word;
begin
  Result := string(MediaInfoA_Get(FHandle, Stream_Video, 0, 'Height', Info_Text, TMIInfo(0))).ToInteger;
end;

function TMediaInfo.LengthTime(streamIndex: word): TMilliseconds;
var
  Value: string;
begin
  Value := string(MediaInfoA_Get(FHandle, Stream_Video, 0, 'Duration', Info_Text, TMIInfo(0)));
  Result := TMilliseconds(Value.ToInt64);
end;

end.
