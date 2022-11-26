{*******************************************************}
{                                                       }
{             	Edmund Cinco                            }
{             	http://www.edmundcinco.com              }
{               Copyright(c) 2014-2015                  }
{                                                       }
{*******************************************************}

// Yo Charge App
// Version 1.4.0
// http://www.yochargeapp.com

program YoCharge;

uses
  System.StartUpCopy,
  FMX.MobilePreview,
  FMX.Forms,
  MainUnit in 'MainUnit.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.FormFactor.Orientations := [TFormOrientation.Portrait];
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
