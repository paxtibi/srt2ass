unit lib.assa;

{$mode ObjFPC}{$H+}

interface

uses
  ctypes, Classes, SysUtils, freetypeh;

const
  ASS_VALIGN_SUB = 0;
  ASS_VALIGN_CENTER = 8;
  ASS_VALIGN_TOP = 4;
  ASS_HALIGN_LEFT = 1;
  ASS_HALIGN_CENTER = 2;
  ASS_HALIGN_RIGHT = 3;

  ASS_JUSTIFY_AUTO = 0;
  ASS_JUSTIFY_LEFT = 1;
  ASS_JUSTIFY_CENTER = 2;
  ASS_JUSTIFY_RIGHT = 3;

  FONT_WEIGHT_LIGHT = 300;
  FONT_WEIGHT_MEDIUM = 400;
  FONT_WEIGHT_BOLD = 700;
  FONT_SLANT_NONE = 0;
  FONT_SLANT_ITALIC = 100;
  FONT_SLANT_OBLIQUE = 110;
  FONT_WIDTH_CONDENSED = 75;
  FONT_WIDTH_NORMAL = 100;
  FONT_WIDTH_EXPANDED = 125;

  ASS_FONT_MAX_FACES = 10;



type
  TASSA_YCbCrMatrix = (
    YCBCR_DEFAULT = 0,  // Header missing
    YCBCR_UNKNOWN,      // Header could not be parsed correctly
    YCBCR_NONE,         // "None" special value
    YCBCR_BT601_TV,
    YCBCR_BT601_PC,
    YCBCR_BT709_TV,
    YCBCR_BT709_PC,
    YCBCR_SMPTE240M_TV,
    YCBCR_SMPTE240M_PC,
    YCBCR_FCC_TV,
    YCBCR_FCC_PC
    );

  TASSFontDesc = packed record
    family: string;
    bold: cunsigned;
    italic: cunsigned;
  end;
  PASSFontDesc = ^TASSFontDesc;


  TASSFont = packed record
    desc: TASSFontDesc;
    faces: array[0..ASS_FONT_MAX_FACES] of TFT_Face;
    n_faces: cint;
    scale_x, scale_y: double; // current transform
    v: FT_Vector; // current shift
    size: double;
  end;
  PASSFont = ^TASSFont;

      {
  procedure ass_charmap_magic(face: PFT_Face);
  function ass_font_new(render_priv:PASSRenderer; desc:PASSFontDesc):PASSFont;
  procedure ass_face_set_size(face: TFT_Face; size:double );
  function ass_face_get_weight(face: TFT_Face):cint ;
  procedure ass_font_get_asc_desc(font:PASSFont; face_index:int ;                             var asc; desc: pcint);
  function ass_font_get_index(ASS_FontSelector *fontsel; font:PASSFont;                         symbol:uint32; var face_index, glyph_indexcint):cint ;
  function ass_font_index_magic(face: TFT_Face; uint32_t symbol):uint32;
  function ass_font_get_glyph(font:PASSFont; int face_index; int index;                          hinting:ASS_Hinting ):bool ;
  procedure ass_font_clear(font:PASSFont);
  function ass_get_glyph_outline(ASS_Outline *outline; int32_t *advance;                             face: TFT_Face; unsigned flags): boolean;
  function ass_face_open(FT_Library ftlib; const char *path;                        const postscript_name: String; int index):TFT_Face ;
}


implementation

end.
