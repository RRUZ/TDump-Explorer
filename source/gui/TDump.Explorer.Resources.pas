unit TDump.Explorer.Resources;

interface

uses
  System.SysUtils, System.Classes, Vcl.BaseImageCollection, Vcl.ImageCollection;

type
  TDataModule1 = class(TDataModule)
    ImageCollection1: TImageCollection;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DataModule1: TDataModule1;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

end.
