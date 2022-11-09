unit UForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls;

const
  cBlockSize=96;
  cHeight=8;
  cWidth=8;

type

  { TColor }
  TColor = (Red, Yellow, Blue);

  { TDirection }
  TDirection = (DirUp, DirDown, DirLeft, DirRight);

  { TTeam }
  TTeam = class(TObject)
  public
    procedure Init();
    procedure Push(X:Longint);
    function Pop():Longint;
    function Count():Longint;
  private
    Head,Tail: Longint;
    Team: array[0..127] of Longint;
  end;

  { TGroup }
  TGroup = class(TObject)
    Color:TColor;
    Enabled:Boolean;
    L,R,T,B:Longint;
  end;

  { TfrmMain }

  TfrmMain = class(TForm)
    imgShow: TImage;
    imgBaseR: TImage;
    imgBaseShell: TImage;
    imgBaseY: TImage;
    imgBaseB: TImage;
    procedure FormCreate(Sender: TObject);
    procedure imgColorMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure imgColorMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure imgShowClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmMain: TfrmMain;
  imgBlock: array[1..8,1..8] of TImage;
  imgShell: array[0..63] of TImage;
  imgClicker: TImage;
  lblScore: TLabel;

  vScore: Longint;

  vTeam: TTeam;
  vGroup: array[0..63] of TGroup;
  vFather: array[1..8,1..8] of Longint;

  vLastFather: Longint;
  vLastX,vLastY:Longint;

implementation

{$R *.lfm}

{ TTeam }
procedure TTeam.Init();
begin
  Head:=0;
  Tail:=0;
end;
procedure TTeam.Push(X:Longint);
begin
  Team[Tail]:=X;
  Tail:=(Tail+1) mod 128;
end;
function TTeam.Pop():Longint;
var
  Ans:Longint;
begin
  if Tail=Head then exit(-1);
  Ans:=Team[Head];
  Head:=(Head+1) mod 128;
  exit(Ans);
end;
function TTeam.Count():Longint;
begin
  if Tail>=Head then exit(Tail-Head);
  if Tail<Head then exit(128-Head+Tail);
end;

{ Processes }
function Val2Str(X:Longint):String;
var
  Ans:String;
begin
  str(X,Ans);
  exit(Trim(Ans));
end;
function GetBlockPos(X:Longint):Longint;
begin
  exit((X-1)*cBlockSize);
end;
function GetBlockID(X:Longint):Longint;
begin
  exit((X div cBlockSize)+1);
end;
function UnitGroup(A,B:Longint):Boolean;
var
  C:Longint;
  i,j:Longint;
begin
  if (A<>B) and vGroup[A].Enabled and vGroup[B].Enabled and (vGroup[A].Color=vGroup[B].Color) then begin
    if (vGroup[A].L=vGroup[B].L)and(vGroup[A].R=vGroup[B].R) then begin
      if (vGroup[A].T=vGroup[B].B) then begin
        vTeam.Push(A);
        vTeam.Push(B);
        C:=vTeam.Pop;
        for i:=vGroup[B].T to vGroup[A].B-1 do for j:=vGroup[A].L to vGroup[B].R-1 do vFather[i,j]:=C;
        vGroup[A].Enabled:=False;
        vGroup[B].Enabled:=False;
        vGroup[C].Enabled:=True;
        vGroup[C].Color:=vGroup[A].Color;
        vGroup[C].R:=vGroup[B].R;
        vGroup[C].L:=vGroup[A].L;
        vGroup[C].T:=vGroup[B].T;
        vGroup[C].B:=vGroup[A].B;
        vScore:=vScore+(vGroup[C].R-vGroup[C].L)*(vGroup[C].B-vGroup[C].T);
        {imgShell[A].Hide();
        imgShell[B].Hide();
        imgShell[C].Show();
        imgShell[C].Left:=GetBlockPos(vGroup[C].L);
        imgShell[C].Width:=GetBlockPos(vGroup[C].R)-GetBlockPos(vGroup[C].L);
        imgShell[C].Top:=GetBlockPos(vGroup[C].T);
        imgShell[C].Height:=GetBlockPos(vGroup[C].B)-GetBlockPos(vGroup[C].T);}
        exit(True);
      end else if (vGroup[A].B=vGroup[B].T) then begin
        vTeam.Push(A);
        vTeam.Push(B);
        C:=vTeam.Pop;
        for i:=vGroup[A].T to vGroup[B].B-1 do for j:=vGroup[A].L to vGroup[B].R-1 do vFather[i,j]:=C;
        vGroup[A].Enabled:=False;
        vGroup[B].Enabled:=False;
        vGroup[C].Enabled:=True;
        vGroup[C].Color:=vGroup[A].Color;
        vGroup[C].L:=vGroup[A].L;
        vGroup[C].R:=vGroup[B].R;
        vGroup[C].T:=vGroup[A].T;
        vGroup[C].B:=vGroup[B].B;
        vScore:=vScore+(vGroup[C].R-vGroup[C].L)*(vGroup[C].B-vGroup[C].T);
        {imgShell[A].Hide();
        imgShell[B].Hide();
        imgShell[C].Show();
        imgShell[C].Left:=GetBlockPos(vGroup[C].L);
        imgShell[C].Width:=GetBlockPos(vGroup[C].R)-GetBlockPos(vGroup[C].L);
        imgShell[C].Top:=GetBlockPos(vGroup[C].T);
        imgShell[C].Height:=GetBlockPos(vGroup[C].B)-GetBlockPos(vGroup[C].T);}
        exit(True);
      end;
    end else if (vGroup[A].T=vGroup[B].T)and(vGroup[A].B=vGroup[B].B) then begin
      if (vGroup[A].L=vGroup[B].R) then begin
        vTeam.Push(A);
        vTeam.Push(B);
        C:=vTeam.Pop;
        for i:=vGroup[B].T to vGroup[A].B-1 do for j:=vGroup[B].L to vGroup[A].R-1 do vFather[i,j]:=C;
        vGroup[A].Enabled:=False;
        vGroup[B].Enabled:=False;
        vGroup[C].Enabled:=True;
        vGroup[C].Color:=vGroup[A].Color;
        vGroup[C].L:=vGroup[B].L;
        vGroup[C].R:=vGroup[A].R;
        vGroup[C].T:=vGroup[B].T;
        vGroup[C].B:=vGroup[A].B;
        vScore:=vScore+(vGroup[C].R-vGroup[C].L)*(vGroup[C].B-vGroup[C].T);
        {imgShell[A].Hide();
        imgShell[B].Hide();
        imgShell[C].Show();
        imgShell[C].Left:=GetBlockPos(vGroup[C].L);
        imgShell[C].Width:=GetBlockPos(vGroup[C].R)-GetBlockPos(vGroup[C].L);
        imgShell[C].Top:=GetBlockPos(vGroup[C].T);
        imgShell[C].Height:=GetBlockPos(vGroup[C].B)-GetBlockPos(vGroup[C].T);}
        exit(True);
      end else if (vGroup[A].R=vGroup[B].L) then begin
        vTeam.Push(A);
        vTeam.Push(B);
        C:=vTeam.Pop;
        for i:=vGroup[B].T to vGroup[A].B-1 do for j:=vGroup[A].L to vGroup[B].R-1 do vFather[i,j]:=C;
        vGroup[A].Enabled:=False;
        vGroup[B].Enabled:=False;
        vGroup[C].Enabled:=True;
        vGroup[C].Color:=vGroup[A].Color;
        vGroup[C].R:=vGroup[B].R;
        vGroup[C].L:=vGroup[A].L;
        vGroup[C].T:=vGroup[B].T;
        vGroup[C].B:=vGroup[A].B;
        vScore:=vScore+(vGroup[C].R-vGroup[C].L)*(vGroup[C].B-vGroup[C].T);
        {imgShell[A].Hide();
        imgShell[B].Hide();
        imgShell[C].Show();
        imgShell[C].Left:=GetBlockPos(vGroup[C].L);
        imgShell[C].Width:=GetBlockPos(vGroup[C].R)-GetBlockPos(vGroup[C].L);
        imgShell[C].Top:=GetBlockPos(vGroup[C].T);
        imgShell[C].Height:=GetBlockPos(vGroup[C].B)-GetBlockPos(vGroup[C].T);}
        exit(True);
      end;
    end;
  end;
  exit(False);
end;
function MoveU(G:Longint):Boolean;
var
  pT,pL,pR:Longint;
  i,j,d:Longint;
  //f:Int64;
  flag:Boolean;
begin
  pT:=vGroup[G].T;
  pL:=vGroup[G].L;
  pR:=vGroup[G].R;
  while (pT>1)and(vFather[pT-1,pL-1]<>vFather[pT-1,pL])and(vFather[pT-1,pR-1]<>vFather[pT-1,pR]) do dec(pT);
  if pT<>1 then begin
    flag:=True;
    for i:=pL to pR-1 do flag:=flag and (vFather[pT,i]<>vFather[pT-1,i]);
    while not flag do begin
      inc(pT);
      flag:=True;
      for i:=pL to pR-1 do flag:=flag and (vFather[pT,i]<>vFather[pT-1,i]);
    end;
  end;
  if pT=vGroup[G].T then exit(False) else begin
    //f:=0;
    d:=vGroup[G].B-vGroup[G].T;
    for i:=vGroup[G].T-1 downto pT do for j:=pL to pR-1 do begin
      vFather[i+d,j]:=vFather[i,j];
      if vGroup[vFather[i,j]].Color=Red then imgBlock[i+d,j].Picture:=frmMain.imgBaseR.Picture;
      if vGroup[vFather[i,j]].Color=Blue then imgBlock[i+d,j].Picture:=frmMain.imgBaseB.Picture;
      if vGroup[vFather[i,j]].Color=Yellow then imgBlock[i+d,j].Picture:=frmMain.imgBaseY.Picture;
      {if (f and (1 shl vFather[i,j]))=0 then begin
        vGroup[vFather[i,j]].T:=vGroup[vFather[i,j]].T+d;
        vGroup[vFather[i,j]].B:=vGroup[vFather[i,j]].B+d;
        //imgShell[vFather[i,j]].Top:=GetBlockPos(vGroup[vFather[i,j]].T);
        f:=f or (1 shl vFather[i,j]);
      end;}
    end;
    for i:=pT to pT+d-1 do for j:=pL to pR-1 do begin
      vFather[i,j]:=G;
      if vGroup[G].Color=Red then imgBlock[i,j].Picture:=frmMain.imgBaseR.Picture;
      if vGroup[G].Color=Blue then imgBlock[i,j].Picture:=frmMain.imgBaseB.Picture;
      if vGroup[G].Color=Yellow then imgBlock[i,j].Picture:=frmMain.imgBaseY.Picture;
    end;
    {vGroup[G].T:=pT;
    vGroup[G].B:=pT+d;
    imgShell[G].Top:=GetBlockPos(vGroup[G].T);}
    exit(True);
  end;
end;
function MoveD(G:Longint):Boolean;
var
  pB,pL,pR:Longint;
  i,j,d:Longint;
  //f:Int64;
  flag:Boolean;
begin
  pB:=vGroup[G].B;
  pL:=vGroup[G].L;
  pR:=vGroup[G].R;
  while (pB<9)and(vFather[pB,pL-1]<>vFather[pB,pL])and(vFather[pB,pR-1]<>vFather[pB,pR]) do inc(pB);
  if pB<>9 then begin
    flag:=True;
    for i:=pL to pR-1 do flag:=flag and (vFather[pB,i]<>vFather[pB-1,i]);
    while not flag do begin
      dec(pB);
      flag:=True;
      for i:=pL to pR-1 do flag:=flag and (vFather[pB,i]<>vFather[pB-1,i]);
    end;
  end;
  if pB=vGroup[G].B then exit(False) else begin
    //f:=0;
    d:=vGroup[G].B-vGroup[G].T;
    for i:=vGroup[G].B to pB-1 do for j:=pL to pR-1 do begin
      vFather[i-d,j]:=vFather[i,j];
      if vGroup[vFather[i,j]].Color=Red then imgBlock[i-d,j].Picture:=frmMain.imgBaseR.Picture;
      if vGroup[vFather[i,j]].Color=Blue then imgBlock[i-d,j].Picture:=frmMain.imgBaseB.Picture;
      if vGroup[vFather[i,j]].Color=Yellow then imgBlock[i-d,j].Picture:=frmMain.imgBaseY.Picture;
      {if (f and (1 shl vFather[i,j]))=0 then begin
        vGroup[vFather[i,j]].T:=vGroup[vFather[i,j]].T+d;
        vGroup[vFather[i,j]].B:=vGroup[vFather[i,j]].B+d;
        //imgShell[vFather[i,j]].Top:=GetBlockPos(vGroup[vFather[i,j]].T);
        f:=f or (1 shl vFather[i,j]);
      end;}
    end;
    for i:=pB-d to pB-1 do for j:=pL to pR-1 do begin
      vFather[i,j]:=G;
      if vGroup[G].Color=Red then imgBlock[i,j].Picture:=frmMain.imgBaseR.Picture;
      if vGroup[G].Color=Blue then imgBlock[i,j].Picture:=frmMain.imgBaseB.Picture;
      if vGroup[G].Color=Yellow then imgBlock[i,j].Picture:=frmMain.imgBaseY.Picture;
    end;
    {vGroup[G].T:=pT;
    vGroup[G].B:=pT+d;
    imgShell[G].Top:=GetBlockPos(vGroup[G].T);}
    exit(True);
  end;
end;
function MoveL(G:Longint):Boolean;
var
  pT,pL,pB:Longint;
  i,j,d:Longint;
  flag:Boolean;
begin
  pT:=vGroup[G].T;
  pL:=vGroup[G].L;
  pB:=vGroup[G].B;
  while (pL>1)and(vFather[pT-1,pL-1]<>vFather[pT,pL-1])and(vFather[pB-1,pL-1]<>vFather[pB,pL-1]) do dec(pL);
  if pL<>1 then begin
    flag:=True;
    for i:=pT to pB-1 do flag:=flag and (vFather[i,pL]<>vFather[i,pL-1]);
    while not flag do begin
      inc(pL);
      flag:=True;
      for i:=pT to pB-1 do flag:=flag and (vFather[i,pL]<>vFather[i,pL-1]);
    end;
  end;
  if pL=vGroup[G].L then exit(False) else begin
    d:=vGroup[G].R-vGroup[G].L;
    for i:=vGroup[G].L-1 downto pL do for j:=pT to pB-1 do begin
      vFather[j,i+d]:=vFather[j,i];
      if vGroup[vFather[j,i]].Color=Red then imgBlock[j,i+d].Picture:=frmMain.imgBaseR.Picture;
      if vGroup[vFather[j,i]].Color=Blue then imgBlock[j,i+d].Picture:=frmMain.imgBaseB.Picture;
      if vGroup[vFather[j,i]].Color=Yellow then imgBlock[j,i+d].Picture:=frmMain.imgBaseY.Picture;
    end;
    for i:=pL to pL+d-1 do for j:=pT to pB-1 do begin
      vFather[j,i]:=G;
      if vGroup[G].Color=Red then imgBlock[j,i].Picture:=frmMain.imgBaseR.Picture;
      if vGroup[G].Color=Blue then imgBlock[j,i].Picture:=frmMain.imgBaseB.Picture;
      if vGroup[G].Color=Yellow then imgBlock[j,i].Picture:=frmMain.imgBaseY.Picture;
    end;
    exit(True);
  end;
end;
function MoveR(G:Longint):Boolean;
var
  pT,pR,pB:Longint;
  i,j,d:Longint;
  flag:Boolean;
begin
  pT:=vGroup[G].T;
  pR:=vGroup[G].R;
  pB:=vGroup[G].B;
  while (pR<9)and(vFather[pT,pR]<>vFather[pT-1,pR])and(vFather[pB,pR]<>vFather[pB-1,pR]) do inc(pR);
  if pR<>9 then begin
    flag:=True;
    for i:=pT to pB-1 do flag:=flag and (vFather[i,pR]<>vFather[i,pR-1]);
    while not flag do begin
      dec(pR);
      flag:=True;
      for i:=pT to pB-1 do flag:=flag and (vFather[i,pR]<>vFather[i,pR-1]);
    end;
  end;
  if pR=vGroup[G].R then exit(False) else begin
    d:=vGroup[G].R-vGroup[G].L;
    for i:=vGroup[G].R to pR-1 do for j:=pT to pB-1 do begin
      vFather[j,i-d]:=vFather[j,i];
      if vGroup[vFather[j,i]].Color=Red then imgBlock[j,i-d].Picture:=frmMain.imgBaseR.Picture;
      if vGroup[vFather[j,i]].Color=Blue then imgBlock[j,i-d].Picture:=frmMain.imgBaseB.Picture;
      if vGroup[vFather[j,i]].Color=Yellow then imgBlock[j,i-d].Picture:=frmMain.imgBaseY.Picture;
    end;
    for i:=pR-d to pR-1 do for j:=pT to pB-1 do begin
      vFather[j,i]:=G;
      if vGroup[G].Color=Red then imgBlock[j,i].Picture:=frmMain.imgBaseR.Picture;
      if vGroup[G].Color=Blue then imgBlock[j,i].Picture:=frmMain.imgBaseB.Picture;
      if vGroup[G].Color=Yellow then imgBlock[j,i].Picture:=frmMain.imgBaseY.Picture;
    end;
    exit(True);
  end;
end;
procedure ChangeGroup(G:Longint;Direction:TDirection);
begin
  //messagedlg(Val2Str(G)+' '+Val2Str(Longint(Direction)),mtInformation,[mbYes,mbNo],0);
  case Direction of
  DirUp:if MoveU(G) then vScore:=vScore-(vGroup[G].R-vGroup[G].L)*(vGroup[G].B-vGroup[G].T);
  DirDown:if MoveD(G) then vScore:=vScore-(vGroup[G].R-vGroup[G].L)*(vGroup[G].B-vGroup[G].T);
  DirLeft:if MoveL(G) then vScore:=vScore-(vGroup[G].R-vGroup[G].L)*(vGroup[G].B-vGroup[G].T);
  DirRight:if MoveR(G) then vScore:=vScore-(vGroup[G].R-vGroup[G].L)*(vGroup[G].B-vGroup[G].T);
  end;
end;
procedure RefreshGroup();
var
  flag:Boolean;
  Visited:array[0..63] of Boolean;
  i,j:Longint;
begin
  fillchar(Visited,sizeof(Visited),False);
  for i:=1 to 8 do for j:=1 to 8 do begin
    if not Visited[vFather[i,j]] then begin
      Visited[vFather[i,j]]:=True;
      vGroup[vFather[i,j]].T:=i;
      vGroup[vFather[i,j]].L:=j;
    end;
    vGroup[vFather[i,j]].B:=i+1;
    vGroup[vFather[i,j]].R:=j+1;
  end;
  flag:=True;
  while flag do begin
    flag:=False;
    for i:=0 to 63 do for j:=0 to 63 do if UnitGroup(i,j) then flag:=True;
  end;
  //for i:=1 to 63 do if vGroup[i].Enabled then begin
  for i:=0 to 63 do if vGroup[i].Enabled then begin
    imgShell[i].Top:=GetBlockPos(vGroup[i].T);
    imgShell[i].Left:=GetBlockPos(vGroup[i].L);
    imgShell[i].Height:=GetBlockPos(vGroup[i].B-vGroup[i].T+1);
    imgShell[i].Width:=GetBlockPos(vGroup[i].R-vGroup[i].L+1);
    imgShell[i].Show();
  end else imgShell[i].Hide();
  lblScore.Caption:=Val2Str(vScore);
end;
procedure Init();
var
  i,j:Longint;
  ran:Longint;
  p:Longint;
begin
  vScore:=0;
  frmMain.imgShow.Hide;
  Randomize();
  vTeam:=TTeam.Create();
  vTeam.Init();
  for i:=0 to 63 do vTeam.Push(i);
  for i:=1 to 8 do for j:=1 to 8 do begin
    imgBlock[i,j]:=TImage.Create(frmMain);
    imgBlock[i,j].Name:='imgBlock_'+Val2Str(i)+'_'+Val2Str(j);
    imgBlock[i,j].Parent:=frmMain;
    imgBlock[i,j].OnMouseDown:=@frmMain.imgColorMouseDown;
    imgBlock[i,j].OnMouseUp:=@frmMain.imgColorMouseUp;
    imgBlock[i,j].Stretch:=True;
    imgBlock[i,j].Top:=GetBlockPos(i);
    imgBlock[i,j].Left:=GetBlockPos(j);
    imgBlock[i,j].Width:=cBlocksize;
    imgBlock[i,j].Height:=cBlockSize;
  end;
  for i:=1 to 8 do for j:=1 to 8 do begin
    ran:=trunc(Random()*3000);
    p:=vTeam.Pop();
    vGroup[p]:=TGroup.Create();
    vGroup[p].Enabled:=True;
    vGroup[p].L:=j;
    vGroup[p].R:=j+1;
    vGroup[p].T:=i;
    vGroup[p].B:=i+1;
    if ran<=1000 then begin
      imgBlock[i,j].Picture:=frmMain.imgBaseR.Picture;
      vGroup[p].Color:=Red;
    end else if ran<=2000 then begin
      imgBlock[i,j].Picture:=frmMain.imgBaseY.Picture;
      vGroup[p].Color:=Yellow;
    end else begin
      imgBlock[i,j].Picture:=frmMain.imgBaseB.Picture;
      vGroup[p].Color:=Blue;
    end;
    imgBlock[i,j].Show();
    vFather[i,j]:=p;
    imgShell[p]:=TImage.Create(frmMain);
    imgShell[p].Name:='imgShell_'+Val2Str(p);
    imgShell[p].OnMouseUp:=@frmMain.imgColorMouseUp;
    imgShell[p].OnMouseDown:=@frmMain.imgColorMouseDown;
    imgShell[p].Parent:=frmMain;
    imgShell[p].Top:=imgBlock[i,j].Top;
    imgShell[p].Left:=imgBlock[i,j].Left;
    imgShell[p].Height:=cBlockSize;
    imgShell[p].Width:=cBlockSize;
    imgShell[p].Picture:=frmMain.imgBaseShell.Picture;
    imgShell[p].Stretch:=True;
    imgShell[p].Show();
  end;
  imgClicker:=TImage.Create(frmMain);
  imgClicker.Name:='imgClicker';
  imgClicker.Parent:=frmMain;
  imgClicker.OnMouseDown:=@frmMain.imgColorMouseDown;
  imgClicker.OnMouseUp:=@frmMain.imgColorMouseUp;
  imgClicker.Stretch:=True;
  imgClicker.Top:=0;
  imgClicker.Left:=0;
  imgClicker.Height:=768;
  imgClicker.Width:=768;
  imgClicker.Picture:=frmMain.imgBaseShell.Picture;
  imgClicker.Show();
  lblScore:=TLabel.Create(frmMain);
  lblScore.Name:='lblScore';
  lblScore.Parent:=frmMain;
  lblScore.Top:=768;
  lblScore.Left:=0;
  lblScore.Height:=24;
  lblScore.AutoSize:=True;
  lblScore.Font.Color:=clRed;
  lblScore.Font.Size:=18;
  lblScore.Font.Bold:=True;
  lblScore.Font.Italic:=True;
  lblScore.Caption:='0';
  lblScore.Show();
  RefreshGroup();
end;

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  imgShow.Show();
end;

procedure TfrmMain.imgColorMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  //messagedlg('Mouse Down',mtInformation,[mbYes,mbNo],0);
  vLastFather:=vFather[GetBlockID(Y),GetBlockID(X)];
  vLastX:=X;
  vLastY:=Y;
end;

procedure TfrmMain.imgColorMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  //messagedlg('Mouse Up',mtInformation,[mbYes,mbNo],0);
  X:=X-vLastX;
  Y:=Y-vLastY;
  if Y=0 then Y:=1;
  if X=0 then X:=1;
  if (abs(X)>cBlockSize/2)or(abs(Y)>cBlockSize/2) then begin
    if (X div abs(Y) >=1) then ChangeGroup(vLastFather,DirRight)
    else if (X div abs(Y) <=-1) then ChangeGroup(vLastFather,DirLeft)
    else if (Y div abs(X) <=-1) then ChangeGroup(vLastFather,DirUp)
    else if (Y div abs(X) >=1) then ChangeGroup(vLastFather,DirDown);
    RefreshGroup();
  end;
end;

procedure TfrmMain.imgShowClick(Sender: TObject);
begin
  Init();
end;

end.

