unit MainUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics,
  FMX.Dialogs, FMX.TabControl, FMX.Objects, FMX.Layouts, FMX.Edit, FMX.StdCtrls,
  System.Actions, FMX.ActnList, System.IniFiles, System.IOUtils,
  System.Diagnostics, FMX.Controls.Presentation;

type
  TForm1 = class(TForm)
    StyleBook1: TStyleBook;
    ActionList1: TActionList;
    Timer1: TTimer;
    Timer2: TTimer;
    Timer3: TTimer;
    Layout1: TLayout;
    Background: TRectangle;
    TabControl1: TTabControl;
    TabItem1: TTabItem;
    TabItem2: TTabItem;
    ChangeTabAction1: TChangeTabAction;
    ChangeTabAction2: TChangeTabAction;
    USERNAME_Background: TRectangle;
    USERNAME: TEdit;
    CONTINUE_Background: TRectangle;
    CONTINUE: TLabel;
    Link: TLabel;
    Layout2: TLayout;
    AppName_Background: TRectangle;
    AppName: TLabel;
    Battery_Level0: TImage;
    Battery_Level1: TImage;
    Battery_Level2: TImage;
    Battery_Level3: TImage;
    Battery_Level4: TImage;
    Layout3: TLayout;
    Battery_Level_Background: TRectangle;
    Battery_Level: TLabel;
    Status: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure CONTINUEClick(Sender: TObject);
    procedure LinkClick(Sender: TObject);
    procedure AppNameClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure Timer3Timer(Sender: TObject);
    procedure USERNAMEChangeTracking(Sender: TObject);
    procedure Battery_Level1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

uses
  AndroidAPI.JNI.GraphicsContentViewText, AndroidAPI.JNI.JavaTypes,
  AndroidAPI.JNI.OS, AndroidAPI.Helpers, FMX.Helpers.Android,
  FMX.FontGlyphs.Android, AndroidAPI.JNI.Net, IdURI, IdHTTP, Math;

const
  // ---------------------------------------------------------------------------
  Host = 'the_backend_script_is_missing_sad_face';
  // ---------------------------------------------------------------------------

var
  NotifyComplete: boolean;
  ConfigPath, strChargerType: string;

  // Unused
procedure Wait(t: DWORD);
var
  lTicks: DWORD;
begin
  lTicks := TStopwatch.GetTimeStamp + t;
  repeat
    Application.ProcessMessages;
  until (lTicks <= TStopwatch.GetTimeStamp) or Application.Terminated;
end;

// ---------------------------------------------------------------------------
function BatteryCharger(const aContext: JContext): integer;
var
  filter: JIntentFilter;
  battery: JIntent;
  ChargePlug: integer;
begin
  filter := TJIntentFilter.Create;
  filter.addAction(TJIntent.JavaClass.ACTION_BATTERY_CHANGED);

  battery := aContext.registerReceiver(NIL, filter);
  ChargePlug := battery.getIntExtra(StringToJString('plugged'), -1);

  // BatteryManager.BATTERY_PLUGGED_AC;
  // return 1

  // BatteryManager.BATTERY_PLUGGED_USB;
  // return 2

  result := ChargePlug;
end;

function BatteryStatus(const aContext: JContext): integer;
var
  filter: JIntentFilter;
  battery: JIntent;
  Status: integer;
begin
  filter := TJIntentFilter.Create;
  filter.addAction(TJIntent.JavaClass.ACTION_BATTERY_CHANGED);

  battery := aContext.registerReceiver(NIL, filter);
  Status := battery.getIntExtra(StringToJString('status'), -1);

  // BatteryManager.BATTERY_STATUS_FULL;
  // return 5

  // BatteryManager.BATTERY_STATUS_CHARGING;
  // return 2

  result := Status;
end;

function BatteryPercent(const aContext: JContext): integer;
var
  filter: JIntentFilter;
  battery: JIntent;
  Level, Scale: integer;
begin
  filter := TJIntentFilter.Create;
  filter.addAction(TJIntent.JavaClass.ACTION_BATTERY_CHANGED);

  battery := aContext.registerReceiver(NIL, filter);
  Level := battery.getIntExtra(StringToJString('level'), -1);
  Scale := battery.getIntExtra(StringToJString('scale'), -1);

  result := (100 * Level) div Scale;
end;
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
function YoAPI(aURL, aUsername: string): string;
var
  lHTTP: TIdHTTP;
  lParamList: TStringList;
begin
  lParamList := TStringList.Create;
  lParamList.Add('username=' + aUsername);

  lHTTP := TIdHTTP.Create(nil);
  try
    try
      result := lHTTP.Post(aURL, lParamList);
    except
      on E: Exception do
        result := IntToStr(lHTTP.ResponseCode);
    end;
  finally
    lHTTP.Free;
    lParamList.Free;
  end;
end;

function Notify(aURL, aUsername, aBattery_Level: string): string;
var
  lHTTP: TIdHTTP;
  lParamList: TStringList;
begin
  lParamList := TStringList.Create;
  lParamList.Add('username=' + aUsername);
  lParamList.Add('battery_level=' + aBattery_Level);

  lHTTP := TIdHTTP.Create(nil);
  try
    try
      result := lHTTP.Post(aURL, lParamList);
      NotifyComplete := True;
    except
      on E: Exception do
        result := IntToStr(lHTTP.ResponseCode);
    end;
  finally
    lHTTP.Free;
    lParamList.Free;
  end;
end;
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
function LaunchActivity(const Intent: JIntent): boolean; overload;
var
  ResolveInfo: JResolveInfo;
begin
  ResolveInfo := SharedActivity.getPackageManager.resolveActivity(Intent, 0);
  result := ResolveInfo <> nil;
  if result then
    SharedActivity.startActivity(Intent);
end;

function LaunchActivity(const Action: JString): boolean; overload;
var
  Intent: JIntent;
begin
  Intent := TJIntent.JavaClass.init(Action);
  result := LaunchActivity(Intent);
end;

function LaunchActivity(const Action: JString; const URI: Jnet_Uri)
  : boolean; overload;
var
  Intent: JIntent;
begin
  Intent := TJIntent.JavaClass.init(Action, URI);
  result := LaunchActivity(Intent);
end;

procedure LaunchURL(const URL: string);
begin
  LaunchActivity(TJIntent.JavaClass.ACTION_VIEW,
    TJnet_Uri.JavaClass.parse(StringToJString(TIdURI.URLEncode(URL))))
end;
// ---------------------------------------------------------------------------

procedure TForm1.FormCreate(Sender: TObject);
var
  ConfigInfo: TIniFile;
  TabIndex: string;
begin
  // Get Home Path
  ConfigPath := TPath.Combine(TPath.GetHomePath, 'Yo.dat');
  // Path of Yo.dat
  ConfigInfo := TIniFile.Create(ConfigPath);

  if FileExists(ConfigPath) then
  begin
    // Read info from Yo.dat
    USERNAME.Text := ConfigInfo.ReadString('Yo', 'USERNAME', '');
    TabIndex := ConfigInfo.ReadString('Yo', 'TabIndex', '');

    // Login
    if TabIndex = '0' then
    begin
      TabControl1.TabIndex := 0;
    end
    // Logged
    else if TabIndex = '1' then
    begin
      TabControl1.TabIndex := 1;

      // Automatically set to True
      Timer1.Enabled := True;
      Timer2.Enabled := True;
    end;
  end;

  NotifyComplete := False;
end;

procedure TForm1.CONTINUEClick(Sender: TObject);
var
  ConfigInfo: TIniFile;
begin
  // Path of Yo.dat
  ConfigInfo := TIniFile.Create(ConfigPath);

  if Length(USERNAME.Text) = 0 then
  begin
    ShowMessage('Enter Yo USERNAME to continue.');
    Exit;
  end;

  // Update TabIndex from Yo.dat
  ConfigInfo.WriteString('Yo', 'TabIndex', '1');

  // Free Memory
  FreeAndNil(ConfigInfo);

  // Manually set to True
  Timer1.Enabled := True;
  Timer2.Enabled := True;

  // Go to Logged
  ChangeTabAction1.ExecuteTarget(Self);
end;

procedure TForm1.LinkClick(Sender: TObject);
begin
  // Open Yo Charge App website
  LaunchURL('http://www.yochargeapp.com');
end;

procedure TForm1.AppNameClick(Sender: TObject);
var
  ConfigInfo: TIniFile;
begin
  // Path of Yo.dat
  ConfigInfo := TIniFile.Create(ConfigPath);

  // Update TabIndex from Yo.dat
  ConfigInfo.WriteString('Yo', 'TabIndex', '0');

  // Free Memory
  FreeAndNil(ConfigInfo);

  // Manually set to False
  Timer1.Enabled := False;
  Timer2.Enabled := False;

  // Go back to Login
  ChangeTabAction2.ExecuteTarget(Self);
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  intBatteryCharger: integer;
begin
  intBatteryCharger := BatteryCharger(SharedActivityContext);

  // CONNECT AC OR USB
  if intBatteryCharger = 0 then
  begin
    // Update Status
    Status.Text := 'CONNECT AC OR USB';

    Timer3.Enabled := False;
    NotifyComplete := False;
  end
  // BatteryManager.BATTERY_PLUGGED_AC;
  else if intBatteryCharger = 1 then
  begin
    strChargerType := 'AC';
    Timer3.Enabled := True;
  end
  // BatteryManager.BATTERY_PLUGGED_USB;
  else if intBatteryCharger = 2 then
  begin
    strChargerType := 'USB';
    Timer3.Enabled := True;
  end;
end;

procedure TForm1.Timer2Timer(Sender: TObject);
var
  intBatteryPercent: integer;
  ResponseCode: string;
begin
  intBatteryPercent := BatteryPercent(SharedActivityContext);

  // Update Battery Level
  Battery_Level.Text := IntToStr(intBatteryPercent) + '%';

  // Between 76% to 100%
  if InRange(intBatteryPercent, 76, 100) then // intBatteryPercent > 75 then
  begin
    Battery_Level1.Visible := True;
    Battery_Level2.Visible := True;
    Battery_Level3.Visible := True;
    Battery_Level4.Visible := True;
  end
  // Between 51% to 75%
  else if InRange(intBatteryPercent, 51, 75) then
  begin
    Battery_Level1.Visible := True;
    Battery_Level2.Visible := True;
    Battery_Level3.Visible := True;
    Battery_Level4.Visible := False;
  end
  // Between 26% to 50%;
  else if InRange(intBatteryPercent, 26, 50) then
  begin
    Battery_Level1.Visible := True;
    Battery_Level2.Visible := True;
    Battery_Level3.Visible := False;
    Battery_Level4.Visible := False;
  end
  // Between 10% to 25%
  else if InRange(intBatteryPercent, 10, 25) then
  begin
    Battery_Level1.Visible := True;
    Battery_Level2.Visible := False;
    Battery_Level3.Visible := False;
    Battery_Level4.Visible := False;
  end
  // Below or equal to 9%
  else if InRange(intBatteryPercent, -9, 9) then
  begin
    Battery_Level1.Visible := False;
    Battery_Level2.Visible := False;
    Battery_Level3.Visible := False;
    Battery_Level4.Visible := False;
  end
  // Yo From BATTERYLOW
  // Equal to 5%
  else if intBatteryPercent = 5 then
  begin
    // Notify
    ResponseCode := Notify(Host + 'notify.php', USERNAME.Text,
      IntToStr(intBatteryPercent) + '%');

    // No Internet!
    if ResponseCode = '-1' then
    begin
      ShowMessage('Yo Charge needs internet!');
    end;
  end;
end;

procedure TForm1.Timer3Timer(Sender: TObject);
var
  intBatteryStatus, intBatteryPercent: integer;
  ResponseCode: string;
begin
  intBatteryStatus := BatteryStatus(SharedActivityContext);
  intBatteryPercent := BatteryPercent(SharedActivityContext);

  // BatteryManager.BATTERY_STATUS_FULL;
  if intBatteryStatus = 5 then
  begin
    // Update Status
    Status.Text := 'FULLY CHARGED — DISCONNECT ' + strChargerType;

    // Yo From FULLYCHARGED
    if intBatteryPercent = 100 then
    begin
      if NotifyComplete = False then
      begin
        // Notify
        ResponseCode := Notify(Host + 'notify.php', USERNAME.Text,
          IntToStr(intBatteryPercent) + '%');

        // No Internet!
        if ResponseCode = '-1' then
        begin
          ShowMessage('Yo Charge needs internet!');
        end;
      end;
    end;
  end
  // BatteryManager.BATTERY_STATUS_CHARGING;
  else if intBatteryStatus = 2 then
  begin
    // Update Status
    Status.Text := 'CHARGING VIA ' + strChargerType;

    // Yo From HALFCHARGED
    if intBatteryPercent = 50 then
    begin
      if NotifyComplete = False then
      begin
        // Notify
        ResponseCode := Notify(Host + 'notify.php', USERNAME.Text,
          IntToStr(intBatteryPercent) + '%');

        // No Internet!
        if ResponseCode = '-1' then
        begin
          ShowMessage('Yo Charge needs internet!');
        end;
      end;
    end;
  end;
  // * Reset NotifyComplete
  // Between 51% to 99%
  if InRange(intBatteryPercent, 51, 99) then
  begin
    NotifyComplete := False;
  end;
end;

procedure TForm1.USERNAMEChangeTracking(Sender: TObject);
var
  ConfigInfo: TIniFile;
begin
  // Path of Yo.dat
  ConfigInfo := TIniFile.Create(ConfigPath);

  // Update USERNAME from Yo.dat
  ConfigInfo.WriteString('Yo', 'USERNAME', AnsiUpperCase(USERNAME.Text));

  // Free Memory
  FreeAndNil(ConfigInfo);
end;

procedure TForm1.Battery_Level1Click(Sender: TObject);
var
  intBatteryPercent: integer;
  ResponseCode: string;
begin
  intBatteryPercent := BatteryPercent(SharedActivityContext);

  // Yo From YOCHARGEAPP
  // Below or equal to 25%
  if InRange(intBatteryPercent, -25, 25) then
  begin
    // Send a Yo
    ResponseCode := YoAPI(Host + 'yo.php', USERNAME.Text);

    // No Internet
    if ResponseCode = '-1' then
    begin
      ShowMessage('Yo Charge needs internet!');
    end;
  end;
end;

end.
