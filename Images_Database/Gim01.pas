unit Gim01;      // Gestionnaire de banque d'images

{ On stocke aussi bien des Bitmap's que des Jpeg's mélangés ou non.
  Un paquet contient dans l'ordre : le nombre d'images (Nbima), les éléments de
  la table des paramètres images (tbPima[..]) et le stream contenant l'ensemble
  des images.
  En ajout ou insertion les images sont toujours ajoutées en fin de ImaStrm.
  Par contre les paramètres sont sont ajoutés ou inséréz à leur place dans la
  table tbPima.
  Il n'y a qu'en cas de suppression que le le stream ImaStrm est réorganisé
  pour récupérer la mémoire occupée par l'image supprimée.
  La position d'une image dans le stream est donnée par la taille du stream
  avant ajout. La taille de l'image est calculée par différence entre sa
  position et la taille du stream après ajout.
}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtDlgs, Jpeg, StdCtrls, ExtCtrls, Menus, Math, Buttons,
  ComCtrls, Gim02, Gim05;

type
  TFmain = class(TForm)
    OPDlg: TOpenPictureDialog;
    FileBox: TListBox;
    Vimage: TImage;                   
    ODlg: TOpenDialog;
    SPDlg: TSavePictureDialog;
    PBxIma: TPaintBox;
    SBdroite: TSpeedButton;
    SBGauche: TSpeedButton;
    VShape: TShape;
    Pnom0: TPanel;
    Pnom1: TPanel;
    Pnom2: TPanel;
    Pnom3: TPanel;
    Panel3: TPanel;
    Panel1: TPanel;
    Pnom4: TPanel;
    SBGpage: TSpeedButton;
    SBGdeb: TSpeedButton;
    SBDpage: TSpeedButton;
    SBDdeb: TSpeedButton;
    Lbn0: TLabel;
    Lbn1: TLabel;
    Lbn2: TLabel;
    Lbn3: TLabel;
    Lbn4: TLabel;
    SDlg: TSaveDialog;
    Lab_Nbi: TLabeledEdit;
    Lab_Enc: TLabeledEdit;
    Lab_Pak: TLabeledEdit;
    Lab_Nom: TEdit;
    Lab_Typ: TEdit;
    Lab_X: TLabeledEdit;
    Lab_Y: TLabeledEdit;
    Panel2: TPanel;
    Bt_Nouveau: TButton;
    Bt_Ouvrir: TButton;
    Bt_Enregistrer: TButton;
    Panel4: TPanel;
    Bt_Ajouter: TButton;
    Bt_Inserer: TButton;
    Bt_Supprimer: TButton;
    Bt_Extraire: TButton;
    Panel5: TPanel;
    Bt_Aide: TButton;
    Bt_Quitter: TButton;
    Bt_Copier: TButton;
    Bt_Coller: TButton;

    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure QuitterClick(Sender: TObject);

    procedure NouveauPaquetClick(Sender: TObject);
    procedure ChargerUnPaquet(nomf : string);
    procedure OuvrirUnPaquetClick(Sender: TObject);
    function  NomPaquet(nf : string) : string;
    procedure EnregistrerLePaquetClick(Sender: TObject);
    procedure ReorganiserLePaquet;

    procedure Ajouter;
    procedure AjouterDesImagesClick(Sender: TObject);
    function  NomImage(nf : string) : string;
    procedure Inserer;
    procedure Inserer1ImageClick(Sender: TObject);
    procedure Supprimer1ImageClick(Sender: TObject);
    procedure AfficherLesImages(db : integer);
    procedure FormatVignette;
    procedure Extraire1ImageClick(Sender: TObject);
    procedure Couper1ImageClick(Sender: TObject);
    procedure Copier1ImageClick(Sender: TObject);
    procedure Coller1ImageClick(Sender: TObject);

    procedure InitVImage;
    procedure PBxImaPaint(Sender: TObject);
    procedure PBxImaMouseUp(Sender: TObject; Button: TMouseButton;
              Shift: TShiftState; X, Y: Integer);

    function  Lbnum(no : byte) : TLabel;
    function  Pnom(no : byte) : TPanel;

    procedure Aide1Click(Sender: TObject);
    procedure AfficheValeurs;
    procedure SBGaucheClick(Sender: TObject);
    procedure SBdroiteClick(Sender: TObject);

  private
    { Déclarations privées }

  public
    { Déclarations publiques }

  end;

var
  Fmain: TFmain;

implementation     

{$R *.dfm}

var
  debima,
  encours : integer;
  psx,psy,
  vgx,vgy : integer;
  minX : integer = 160;
  minY : integer = 120;
  ftemp : string;

////////////////////////////////////////////////////////////////////////////////

function QuelType(ext : string) : integer;
begin
  Result := -1;
  if LowerCase(ext) = '.bmp' then Result := 0
  else
    if (LowerCase(ext) = '.jpg') or (LowerCase(ext) = '.jpe') then Result := 1;
  if Result = -1 Then ShowMessage('Ce format d''image n''est pas reconnu.');
end;

////////////////////////////////////////////////////////////////////////////////

procedure TFmain.FormCreate(Sender: TObject);
begin
  FMain.DoubleBuffered := true;
  chemin := ExtractFilePath(Application.ExeName);
  Initialise;
  fond.Width := minX;
  fond.Height := minY;
  fond.Canvas.Brush.Color := clWhite;
  fond.Canvas.Brush.Style := bsSolid;
  fond.Canvas.Rectangle(0,0,minX,minY);
  encours := 0;
end;

procedure TFmain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Libere;
end;

procedure TFmain.QuitterClick(Sender: TObject);
begin
  Close;
end;

////////////// Paramètres Paquets /////////////////////////////////////////////

procedure TFmain.NouveauPaquetClick(Sender: TObject);
begin
  nompk := InputBox('Création d''un paquet', 'Donnez un nom', '');
  if nompk = '' then exit;
  Nbima := 0;
  SetLength(tbPima,1);                 // création et initialisation de la
  with tbPima[0] do                    // table des paramètres images
  begin
    posima := 0;
    taille := 0;
    ftype := 0;
    imx := 0;
    imy := 0;
    nom := ' ';
  end;
  inter.Width := minX;
  inter.Canvas.Draw(0,0,fond);
  PBxIma.Repaint;
  ImaStrm.Free;
  ImaStrm := TMemoryStream.Create;
  AfficheValeurs;
end;

procedure TFmain.ChargerUnPaquet(nomf : string);
// pour changer, on ne charge pas le ficher en bloc, mais par FileStream, on
// récupère les éléments un à un, soit directement, soit en passant par un
// memoryStream.
var  lg : integer;
     st : string;
begin
  inter.Width := minX;
  inter.Canvas.Draw(0,0,fond);
  PBxIma.Repaint;
  st := ExtractFilename(nomf);
  nompk := NomPaquet(st);
  try
    FileStrm := TFileStream.Create(nomf,fmOpenRead); // initialise en lecture
    FileStrm.ReadBuffer(Nbima,SizeOf(integer));
    SetLength(tbPima,Nbima+1);
    for lg := 1 to Nbima do                     // table des paramètres images
      FileStrm.ReadBuffer(tbPima[lg],SizeOf(TParima));
    FileStrm.ReadBuffer(lg,SizeOf(integer));    // longueur du stream d'images
    ImaStrm.Clear;
    Imastrm.Position := 0;
    ImaStrm.CopyFrom(FileStrm,lg);              // stream d'images
  finally
    FileStrm.Free;
  end;
  AfficherLesImages(1);
  AfficheValeurs;
end;

procedure TFmain.OuvrirUnPaquetClick(Sender: TObject);
begin
  Odlg.FilterIndex := 1;
  ODlg.InitialDir := chemin;
  if ODlg.Execute then
    ChargerUnPaquet(ODlg.Filename);
end;

procedure TFmain.ReorganiserLePaquet;
// après des modidications(suppression), réorganisation du stream
// d'images à l'aide de la table des paramètres
var  mems : TMemoryStream;
     i : byte;
begin
  mems := TmemoryStream.Create;
  try
    for i := 1 to Nbima do
    begin
      ImaStrm.Position := tbPima[i].posima;
      tbPima[i].posima := mems.Position;
      mems.CopyFrom(ImaStrm,tbPima[i].taille);
    end;
    ImaStrm.Clear;
    mems.Position := 0;
    ImaStrm.CopyFrom(mems,mems.Size);
  finally
    mems.Free;
  end;
end;

function TFmain.NomPaquet(nf : string) : string;
var  st : string;
     p : integer;
begin
  st := ExtractFileName(nf);
  p := Pos('.',st);
  if p > 0 then st:= Copy(st,1,p-1)
  else st := nf;
  Result := st;
end;

procedure TFmain.EnregistrerLePaquetClick(Sender: TObject);
// Enregistrement des images. Les éléments sont rassemblés dans un
// MemoryStream qui est ensuite copié dans un fichier.
var  mms : TMemoryStream;
     i,lg : integer;
     nomf : string;
begin
  nomf := chemin+nompk+'.pak';
  MemStrm.Clear;
  mms := TMemoryStream.Create;
  try
    MemStrm.WriteBuffer(Nbima,SizeOf(integer));
    for i := 1 to Nbima do
      MemStrm.WriteBuffer(tbPima[i],SizeOf(TParima)); // paramètres images
    lg := ImaStrm.Size;
    MemStrm.WriteBuffer(lg,SizeOf(integer));        // taille du stream images
    ImaStrm.Position := 0;
    MemStrm.CopyFrom(ImaStrm,lg);                   // stream images
    MemStrm.SaveToFile(nomf);
  finally
    mms.Free;
  end;
end;

////////////// Menu Images /////////////////////////////////////////////////////

procedure TFmain.Ajouter;
var  ext,nf : string;
     typ : integer;
begin
  nf := NomImage(ImaFile);
  ext := ExtractFileExt(ImaFile);
  typ := QuelType(ext);
  if typ > -1 then
  begin
    inc(Nbima);
    SetLength(tbPima,Nbima+1);   // on agrandit la table des paramètres
    tbPima[Nbima] := tbPima[0];  // initialisation à l'aide de l'élément 0
    tbPima[Nbima].ftype := typ;  // on note le type de fichier image
    tbPima[Nbima].nom := nf;
    ImaStrm.Position := ImaStrm.Size;
    tbPima[Nbima].posima := ImaStrm.Position; // position dans le stream
    VImage.Picture.LoadFromFile(ImaFile);
    Image.Assign(VImage.Picture.Graphic);
    tbPima[Nbima].imx := Image.Width;
    tbPima[Nbima].imy := Image.Height;
    VImage.Picture.Graphic.SaveToStream(ImaStrm); // copie de l'image
    tbPima[Nbima].taille := ImaStrm.Position - tbPima[Nbima].posima;
    // la taille de l'image est calculée par différence entre sa position
    // et la taille du stream après ajout de l'image.
  end;
end;

procedure TFmain.AjouterDesImagesClick(Sender: TObject);
// Ajout d'une ou plusieurs images. Il est possible de modifier la position
// des images en place.
var     i,nbi : integer;
begin
  if OPDlg.Execute then
  begin
    nbi := OPDlg.Files.Count;
    FileBox.Clear;
    FileBox.Items.Assign(OPDlg.Files);
    if Nbima = 0 then debima := Nbima+1;
    for i := 1 to nbi do
    begin
      ImaFile := FileBox.Items[i-1];
      Ajouter;
    end;
    AfficherLesImages(debima);
    AfficheValeurs;
  end;
end;

function TFmain.NomImage(nf : string) : string;
var  st : string;
     p : integer;
begin
  st := ExtractFileName(nf);
  p := Pos('.',st);
  if p > 12 then st:= Copy(st,1,11)
  else st := Copy(st,1,p-1);
  Result := st;
end;

procedure TFmain.Inserer;
var  ext,nf : string;
     i : integer;
begin
  nf := NomImage(ImaFile);
  ext := ExtractFileExt(ImaFile);
  if QuelType(ext) = -1 then exit;
  inc(Nbima);
  SetLength(tbPima,Nbima+1);
  for i := Nbima-1 downto encours do tbPima[i+1] := tbPima[i];
  tbPima[encours].ftype := QuelType(ext);
  tbPima[encours].nom := nf;
  ImaStrm.Position := ImaStrm.Size;
  tbPima[encours].posima := ImaStrm.Position;
  VImage.Picture.LoadFromFile(ImaFile);
  Image.Assign(VImage.Picture.Graphic);
  tbPima[Nbima].imx := Image.Width;
  tbPima[Nbima].imy := Image.Height;
  VImage.Picture.Graphic.SaveToStream(ImaStrm);
  tbPima[encours].taille := ImaStrm.Position - tbPima[encours].posima;
end;

procedure TFmain.Inserer1ImageClick(Sender: TObject);
// l'image est insérée à sa place (devant l'image en cours) dans la table
// et ajoutée en fin de stream.
begin
  if OPDlg.Execute then
  begin
    ImaFile := OPDlg.FileName;
    Inserer;
    AfficherLesImages(debima);
    AfficheValeurs;
  end;
end;

procedure TFmain.Supprimer1ImageClick(Sender: TObject);
// l'image est supprimée de la table, puis le stream est réorganisé pour
// récupérer la place mémoire.
var  i : integer;
begin
  if encours < Nbima then
    for i := encours to Nbima-1 do tbPima[i] := tbPima[i+1];
  dec(Nbima);
  ReorganiserLePaquet;
  encours := debima;
  AfficherLesImages(debima);
  VShape.Left := PBxIma.Left;
  AfficheValeurs;
end;

procedure TFmain.AfficherLesImages(db : integer);
var  i,n,fn : integer;
begin
  i := 0;
  inter.Width := 0;
  inter.Height := minY;
  debima := db;
  fn := db + 4;
  while fn > Nbima do dec(fn);
  for n := db to fn do
  begin
    inter.Width := inter.Width + minX;
    LitUneImage(tbPima[n]);
    FormatVignette;
    inter.Canvas.Draw(minX * (i),0,fond);
    inter.Canvas.Draw(minX * (i) + psx,psy,vignette);
    PBxIma.Repaint;
    if i < 5 then
    begin
      Pnom(i).Caption := tbPima[n].nom;
      Lbnum(i).Caption := IntToStr(n);
    end;
    inc(i);
  end;
  while i < 5 do
  begin
    Pnom(i).Caption := '';
    Lbnum(i).Caption := '';
    inc(i);
  end;
  encours := debima;
end;

procedure TFmain.FormatVignette;
// réduction de la taille des images au format des vignettes affichées.
var   md : boolean;
begin
  md := false;
  vgx := Image.Width;
  vgy := Image.Height;
  if vgx > minX then
  begin
    vgy := vgy * minX div vgx;
    vgx := minX;
    md := true;
  end;
  if vgy > minY then
  begin
    vgx := vgx * minY div vgy;
    vgy := minY;
    md := true;
  end;
  if md then BitmapRedim(Image,vignette,vgx,vgy,true)
  else
    begin
      vignette.Width := vgx;
      vignette.Height := vgy;
      vignette.Canvas.CopyRect(Rect(0,0,vgx,vgy),Image.Canvas,Rect(0,0,vgx,vgy));
    end;
  if vgx < minX then psx := (minX-vgx) div 2 else psx := 0;
  if vgy < minY then psy := (minY-vgy) div 2 else psy := 0;
end;

procedure TFmain.InitVImage;
var  bmp : TBitmap;
begin
  bmp := TBitmap.Create;
  bmp.Width := tbPima[encours].imx;
  bmp.Height := tbPima[encours].imy;
  bmp.Canvas.Rectangle(bmp.Canvas.ClipRect);
  if tbPima[encours].ftype = 0 then VImage.Picture.Bitmap := bmp
  else begin
         jpgim.Assign(bmp);
         VImage.Picture.Graphic := jpgim;
       end;
  bmp.Free;
end;

procedure TFmain.Extraire1ImageClick(Sender: TObject);
// extraction d'une image du stream et sauvegarde dans un fichier.
var  p : integer;
     ex : string;
begin
  if SPDlg.Execute then
  begin
    p := Pos('.',SPDlg.FileName);
    if p > 0 then ex := ''
    else ex := ktype[tbPima[encours].ftype];
    LitUneImage(tbPima[encours]);
    if tbPima[encours].ftype = 0 then Image.SaveToFile(SPDlg.FileName+ex)
    else Jpgim.SaveToFile(SPDlg.FileName+ex);
  end;
end;

procedure TFmain.Couper1ImageClick(Sender: TObject);
// mémorisation puis suppression d'une image du stream images
begin
  Copier1ImageClick(Self);
  Supprimer1ImageClick(Self);
end;

procedure TFmain.Copier1ImageClick(Sender: TObject);
// mémorisation d'une image à partir du stream images
begin
  svPima := tbPima[encours];
  ftemp := chemin +'temp'+ ktype[svPima.ftype];
  LitUneImage(svPima);
  if svPima.ftype = 0 then Image.SaveToFile(ftemp)
  else Jpgim.SaveToFile(ftemp);
  Bt_Coller.Enabled := true;
end;

procedure TFmain.Coller1ImageClick(Sender: TObject);
// insertion d'une image mémorisée.
var  fc : file;
begin
  if not Bt_Coller.Enabled then exit;
  svPima.nom := svPima.nom+'2';
  ImaFile := ftemp;
  if encours > Nbima then Ajouter
  else Inserer;
  tbPima[encours] := svPima;
  AfficherLesImages(encours);
  AfficheValeurs;
  AssignFile(fc,ftemp);
  Erase(fc);
  Bt_Coller.Enabled := false;
end;

procedure TFmain.PBxImaPaint(Sender: TObject);
begin
 PBxIma.Canvas.Draw(0,0,inter);
end;

procedure TFmain.PBxImaMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);  // Sélection d'une image
var  px : integer;
begin
  encours := debima + X div minX;
  px := minX * (encours-debima);
  VShape.Left := PBxIma.Left+px;
  AfficheValeurs;
end;

////////////// Affichage et Mise à jour des paramètres /////////////////////////

function TFmain.Lbnum(no : byte) : TLabel;
// adressage d'un composant TLabel.
begin
  result := FindComponent('Lbn'+ IntToStr(no)) as TLabel;
end;

function TFmain.Pnom(no : byte) : TPanel;
// adressage d'un composant TPanel.
begin
  result := FindComponent('Pnom'+ IntToStr(no)) as TPanel;
end;

procedure TFmain.AfficheValeurs;
begin
  Lab_Pak.Text := nompk;
  Lab_Nbi.Text := IntToStr(Nbima);
  Lab_Nom.Text := tbPima[encours].nom;
  Lab_Enc.Text := IntToStr(encours);
  Lab_Typ.Text := ktype[tbPima[encours].ftype];
  Lab_X.Text := IntToStr(tbPima[encours].imx);
  Lab_Y.Text := IntToStr(tbPima[encours].imy);
end;

procedure TFmain.SBdroiteClick(Sender: TObject);
// décalage de la bande images vers la droite
var  tag : byte;
begin
  if Nbima < 6 then exit;
  tag := (sender as TSpeedButton).Tag;
  case tag of
    0 : if debima+4 <= Nbima then inc(debima);
    1 : if debima+5 <= Nbima then inc(debima,5);
    2 : debima := Nbima-4;
  end;
  encours := debima;
  AfficherLesImages(debima);
  VShape.Left := PBxIma.Left;
  AfficheValeurs;
end;

procedure TFmain.SBGaucheClick(Sender: TObject);
// décalage de la bande images vers la gauche
var  tag : byte;
begin
  if (Nbima < 6) or (debima = 1) then exit;
  tag := (sender as TSpeedButton).Tag;
  case tag of
    0 : dec(debima);
    1 : if debima < 6 then debima := 1
         else dec(debima,5);
    2 : debima := 1;
  end;
  encours := debima;
  AfficherLesImages(debima);
  VShape.Left := PBxIma.Left;
  AfficheValeurs;
end;

procedure TFmain.Aide1Click(Sender: TObject);
// Affichage de l'aide
begin
  Faide.ShowModal;
end;

end.
