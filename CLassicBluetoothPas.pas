unit CLassicBluetoothPas;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.StdCtrls, FMX.ListBox, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo, System.Bluetooth,
  System.Bluetooth.Components, FMX.Edit;
type

    TcreateServerBT = Class(TThread)
    Private
      FserverSocket : TBluetoothServerSocket;
      FSocketS : TBluetoothSocket;
    Protected
      Procedure Execute ; Override;
    Public
      Constructor Create(ASuspended : Boolean);
      Destructor Destroy ; Override;
    End;

    TcreateClientBT = Class(TThread)
    Private
      FserverSocket : TBluetoothServerSocket;
      FSocketC : TBluetoothSocket;
    Protected
      Procedure Execute ; Override;
    Public
      Constructor Create(ASuspended : Boolean);
      Destructor Destroy ; Override;
    End;

    TForm1 = class(TForm)
    Memo1: TMemo;
    BtnDecouverte: TButton;
    ComboBox1: TComboBox;
    AniIndicator1: TAniIndicator;
    BtnAppareilsAssocies: TButton;
    BtnAppairage: TButton;
    BtnDissocier: TButton;
    BtnCreationServeur: TButton;
    EditMessage: TEdit;
    BtnEnvoieMessage: TButton;
    procedure FormShow(Sender: TObject);
    procedure BtnDecouverteClick(Sender: TObject);
    procedure BtnAppareilsAssociesClick(Sender: TObject);
    procedure BtnAppairageClick(Sender: TObject);
    procedure BtnDissocierClick(Sender: TObject);
    procedure BtnCreationServeurClick(Sender: TObject);
    procedure BtnEnvoieMessageClick(Sender: TObject);
  private
    { Déclarations privées }
    FBluetoothManager : TBluetoothManager;
    FBluetoothDevicesList : TBluetoothDeviceList;
    FAppareilsAssocies : TBluetoothDeviceList;
    FAdapter : TBluetoothAdapter;
    CreationServerBT : TcreateServerBT;
    CreationClientBT : TcreateClientBT;
    Procedure FinDecouverteAppareils (Const Sender : TObject; Const Adevices : TBluetoothDeviceList);
  public
    { Déclarations publiques }
  end;

  Const ServiceGUI = '{B62C4E8D-62CC-404B-BBBF-BF3E3BBB1378}';

var
  Form1: TForm1;
  FSocket : TBluetoothSocket;
implementation

{$R *.fmx}
Constructor TcreateServerBT.Create(ASuspended :boolean);
Begin
  Inherited;
End;
Constructor TcreateClientBT.Create(ASuspended :boolean);
Begin
  Inherited;
End;
Destructor TcreateServerBT.Destroy;
begin
  FServerSocket.Free;
  FSocket.Free;
  Inherited;
end;
Destructor TcreateClientBT.Destroy;
begin
  FServerSocket.Free;
  FSocket.Free;
  Inherited;
end;

Procedure TCreateServerBT.Execute;
Var
LData : TBytes;
begin
  while not Terminated and (FSocketS=nil) do
  begin
    FSocketS := FserverSocket.Accept(100);
  end;
  if FSocketS<>nil then
  begin
    while not Terminated do
    begin
      LData:=FSocketS.ReceiveData;
      if length(LData)>0 then
       Synchronize(procedure
        begin
         Form1.Memo1.Lines.Add('Texte reçu : ');
         Form1.Memo1.Lines.Add(TEncoding.ASCII.GetString(LData));

         FSocketS.SendData(Ldata);
        end);
    end;
  end;
end;

procedure TForm1.BtnCreationServeurClick(Sender: TObject);
begin
  Memo1.Text:='';
  if (CreationServerBT=nil) and (FBluetoothManager.ConnectionState=TBluetoothConnectionState.Connected) then
  begin
    CreationServerBT:=TcreateServerBT.Create(True);
    CreationServerBT.FServerSocket:=FAdapter.CreateServerSocket('Mon Serveur', StringToGuid(ServiceGUI),False);
    CreationServerBT.Start;
    Memo1.Lines.Add('Le serveur Bluetooth est en route');
  end else
  begin
    Memo1.Lines.Add('Votre Bluetooth n''est pas activé');
  end;
end;

Procedure TcreateClientBT.Execute;
Var
LData : TBytes;
begin
  if FsocketC<>nil then
  begin
    while not Terminated do
    begin
      LData:=FSocketC.ReceiveData;
      if Length(LData)>0 then
      begin
        Synchronize(procedure
        begin
         Form1.Memo1.Lines.Add('J''ai bien reçu votre message : ');
         Form1.Memo1.Lines.Add(TEncoding.ASCII.GetString(LData));
         Form1.Memo1.GoToTextEnd;
         LData:=nil;
        end);
      end;
    end;
  end;
end;

procedure TForm1.BtnEnvoieMessageClick(Sender: TObject);
Var
ToSend : TBytes;
LDevice: TBluetoothDevice;
begin
  if ComboBox1.ItemIndex>=0 then
  begin
    if FSocket=nil then
    begin
      LDevice:=FAppareilsAssocies[ComboBox1.ItemIndex] as TBluetoothDevice;
      FSocket:=LDevice.CreateClientSocket(StringToGUID(ServiceGUI), False);
      FSocket.Connect;
    end;
    ToSend:=TEncoding.ASCII.GetBytes(EditMessage.Text);
    FSocket.SendData(ToSend);
  end;

  if CreationClientBT=nil then
  begin
    CreationClientBT:=TcreateClientBT.Create(True);
    CreationClientBT.FSocketC:=FSocket;
    CreationClientBT.Start;
  end;
end;



Procedure TForm1.BtnAppairageClick(Sender: TObject);
begin
  try
  if FBluetoothManager.ConnectionState=TBluetoothConnectionState.Connected then
  begin
    if ComboBox1.ItemIndex>=0 then
    begin
      FAdapter.Pair(FBluetoothDevicesList[ComboBox1.ItemIndex]);
      Memo1.Lines.Add('Votre appareil est appairé');
    end else
    begin
      Memo1.Lines.Add('Vous n''avez selectionné aucun appareil');
    end;
  end else
  begin
     Memo1.Lines.Add('Votre Bluetooth n''est pas activé');
  end;
  Except
   On E : Exception  do
   begin
     Memo1.Lines.Add('L''apparairage a échoué');
   end;
  end;
end;

procedure TForm1.BtnAppareilsAssociesClick(Sender: TObject);
Var I: Integer;
begin
  ComboBox1.Clear;
  AniIndicator1.Visible:=True;
  AniIndicator1.Enabled:=True;
  if FBluetoothManager.ConnectionState=TBluetoothConnectionState.Connected then
  begin
    FAppareilsAssocies:=FBluetoothManager.GetPairedDevices;
    if FAppareilsAssocies.Count<=0 then
    begin
      Memo1.Lines.Add('Il n''y a pas d''appareils associés à votre périphérique');
    end else
    begin
      for I := 0 to FAppareilsAssocies.Count-1 do
      begin
        ComboBox1.Items.Add(FAppareilsAssocies[I].DeviceName)
      end;
    end;
  end else
  begin
    Memo1.Lines.Add('Votre Bluetooth n''est pas activé');
  end;
  ComboBox1.ItemIndex:=0;
  AniIndicator1.Visible:=False;
  AniIndicator1.Enabled:=False;
end;



procedure TForm1.BtnDecouverteClick(Sender: TObject);
begin
  ComboBox1.Clear;
  AniIndicator1.Visible:=True;
  AniIndicator1.Enabled:=True;

  if FBluetoothManager.ConnectionState=TBluetoothConnectionState.Connected then
  begin
    FBluetoothManager.StartDiscovery(10000);
  end else
  begin
    Memo1.Lines.Add('Votre Bluetooth n''est pas activé');
  end;
end;

procedure TForm1.BtnDissocierClick(Sender: TObject);
begin
  try
  if FBluetoothManager.ConnectionState=TBluetoothConnectionState.Connected then
  begin
    if ComboBox1.ItemIndex>=0 then
    begin
      FAdapter.Unpair(FAppareilsAssocies[ComboBox1.ItemIndex]);
      Memo1.Lines.Add('Votre appareil est dissocié');
    end else
    begin
      Memo1.Lines.Add('Vous n''avez selectionné aucun appareil');
    end;
  end else
  begin
     Memo1.Lines.Add('Votre Bluetooth n''est pas activé');
  end;
  Except
   On E : Exception  do
   begin
     Memo1.Lines.Add('La dissociation a échoué');
   end;
  end;
end;



Procedure Tform1.FinDecouverteAppareils (Const Sender : TObject; Const Adevices : TBluetoothDeviceList);
begin
TThread.Synchronize(nil, procedure
  Var I : Integer ;
  begin
    AniIndicator1.Visible:=False;
    AniIndicator1.Enabled:=False;
    FBluetoothDevicesList:=ADevices;

    if FBluetoothDevicesList.Count>0 then
    begin
      Memo1.Lines.Add('Nbre d''appareils trouvés : ' + IntToStr(FBluetoothDevicesList.Count));
      for I := 0 to FBluetoothDevicesList.Count-1 do
      begin
        ComboBox1.Items.Add(FBluetoothDevicesList.Items[I].DeviceName);
      end;
      ComboBox1.ItemIndex:=0;
    end else
    begin
      Memo1.Lines.Add('Nbre d''appareils trouvés : 0');
    end;
  end);
end;

procedure TForm1.FormShow(Sender: TObject);
begin
   FBluetoothManager:=TBluetoothManager.Current;
   FBluetoothManager.OnDiscoveryEnd:=FinDecouverteAppareils;
   FAdapter:=FBluetoothManager.CurrentAdapter;
end;

end.
