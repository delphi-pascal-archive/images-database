unit Gim02;   //  Gestion des fichiers images   version 1.0

interface

uses
  Windows, SysUtils, Classes, Graphics, Controls, StdCtrls, ExtCtrls,
  Dialogs, Jpeg;

const
  ktype : array[0..1] of string[4] = ('.bmp','.jpg');

type
  TParima = record               // Paramètres image
              posima : integer;      // position de l'image dans le stream
              taille : integer;      // taille de l'image
              ftype  : integer;      // 0 = bitmap - 1 = jpeg
              imx    : integer;      // largeur
              imy    : integer;      // hauteur
              nom    : string[11];   // 11 pour atteindre un multiple de 4
            end;
  var
    Prima, vignette,
    Image : TBitmap;
    Jpgim : TJPEGImage;
    ImaStrm,
    MemStrm : TMemoryStream;
    ImaFile : TFileName;
    FileStrm : TFileStream;
    Nbima : integer;
    nompk : string;
    tbPima : array of TParima;
    svPima : TParima;
    fond,
    inter : TBitmap;
    lgFilm : integer;
    Ftitre,
    chemin : string;
    ipl,ipx,ipy,
    bcnb,bclg : integer;
    ipxy : array of TPoint;

    procedure Trace(n : integer);
    procedure Initialise;
    procedure Libere;
    procedure LitUneImage(pima : TParima);
    procedure BitmapRedim(ImgSrc,ImgDest : TBitmap; dx,dy : integer;
                          RefreshBmp: Boolean);

implementation

procedure Trace(n : integer);
begin
  ShowMessage(IntToStr(n));
end;

procedure Initialise;
begin
  Image := TBitmap.Create;
  Jpgim := TJPEGImage.Create;
  inter := TBitmap.Create;
  fond := TBitmap.Create;
  vignette := TBitmap.Create;
  ImaStrm := TMemoryStream.Create;
  MemStrm := TMemoryStream.Create;
end;

procedure Libere;
begin
  Image.Free;
  Jpgim.Free;
  inter.Free;
  fond.Free;
  vignette.Free;
  ImaStrm.Free;
  MemStrm.Free;
end;

procedure LitUneImage(pima : TParima);  // Lecture à partir du stream
var  MemS : TMemoryStream;
begin
  ImaStrm.Position := pima.posima;
  MemS := TMemoryStream.Create;
  try
    MemS.SetSize(pima.taille);            
    MemS.CopyFrom(ImaStrm,pima.taille);
    MemS.Position := 0;
    case pima.ftype of
      0 : Image.LoadFromStream(Mems);
      1 : begin
            jpgim.LoadFromStream(Mems);
            Image.Assign(jpgim);
          end;
    end;
  finally
    MemS.Free;
  end;
end;

procedure BitmapRedim(ImgSrc,ImgDest : TBitmap; dx,dy : integer;
                      RefreshBmp: Boolean);
type
  TRGBArray = ARRAY[0..0] OF TRGBTriple; // élément de bitmap (API windows)
  pRGBArray = ^TRGBArray; // type pointeur vers tableau 3 octets 24 bits
var
  nbpix, R, G, B: Int64;
  x, y: Integer;
  posY1, posY2, posX1, posX2: Integer;
  Tmp, IntervalX, IntervalY: Double;
  SauvPixelFormatSrc : TPixelFormat;
  Row                : PRGBArray;  // pointeur scanline
//-----------------------------------------------------------------------------
      procedure Calcul;
      var _Row : PRGBArray;  // pointeur scanline ...
          _x,_y: Integer;
      begin
        R := 0;
        G := 0;
        B := 0;
        nbpix := 0;
        for _y := posY1 to posY2 do
        begin
          _Row := ImgSrc.scanline[_y];      // scanline
          for _x := posX1 to posX2 do
          begin
            R := R + _Row[_x].rgbtRed;
            G := G + _Row[_x].rgbtGreen;
            B := B + _Row[_x].rgbtBlue;
            nbpix := nbpix + 1;
          end;
        end;
        R := R Div nbpix;
        G := G Div nbpix;
        B := B Div nbpix;
      end;
//-----------------------------------------------------------------------------
begin
  SauvPixelFormatSrc := ImgSrc.PixelFormat;
  if ImgSrc.PixelFormat <> pf24Bit then ImgSrc.PixelFormat := pf24Bit;
  if ImgDest.PixelFormat <> pf24Bit then ImgDest.PixelFormat := pf24Bit;
  x := dx;
  y := dy;
  if x < 1 then x := 1;
  if y < 1 then y := 1;
  ImgDest.Width  := x;
  ImgDest.Height := y;
  IntervalX := ImgSrc.Width / ImgDest.Width;
  IntervalY := ImgSrc.Height / ImgDest.Height;
  for y := 0 to ImgDest.height-1 do
  begin
    row := ImgDest.scanline[y];
    Tmp := y * IntervalY;                    // pos 1er pixel ...
    posY1 := Round(Tmp);
    if posY1 > ImgSrc.Height - 1
    then posY1 := ImgSrc.Height - 1;
    Tmp := Tmp + IntervalY;                  // pos dernier pixel ...
    posY2 := Round(Tmp);
    if posY2 > ImgSrc.Height - 1
    then posY2 := ImgSrc.Height - 1;
    for x := 0 to ImgDest.width-1 do
    begin
      Tmp := x * IntervalX;                  // pos 1er pixel ...
      posX1 := Round(tmp);
      if posX1 > ImgSrc.Width - 1
      then posX1 := ImgSrc.Width - 1;
      Tmp := Tmp + IntervalX;                // pos dernier pixel ...
      posX2 := Round(Tmp);
      if posX2 > ImgSrc.Width - 1
      then posX2 := ImgSrc.Width - 1;
      Calcul; // Calcul des pixels entre posX1, posY1, posX2 et posY2
      if R < 0 then R := 0; if R > 255 then R := 255;
      if G < 0 then G := 0; if G > 255 then G := 255;
      if B < 0 then B := 0; if B > 255 then B := 255;
      row[x].rgbtred   := R;
      row[x].rgbtgreen := G;
      row[x].rgbtblue  := B;
    end;
  end;
  if SauvPixelFormatSrc <> pf24Bit
  then ImgSrc.PixelFormat := SauvPixelFormatSrc;
  if RefreshBmp then ImgDest.Modified := True;
end;

end.
