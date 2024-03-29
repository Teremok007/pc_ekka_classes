Unit IndicatorU;

Interface

Uses Windows, Dialogs, Messages, Classes, SysUtils, Util, ComU, Forms;

Type

     TIndicator=class(TComPort)
     private

       FArrStr:TStringList;
       FCt:TCommTimeouts;
       FPortNumber:Integer;
       FUseIndicator:Boolean;
       FAsynchron:Boolean;

       procedure SetUseIndicator(const Value:Boolean);
       procedure SetAsynchron(const Value:Boolean);
       procedure AddCommand(S:String);
       procedure Execute(Sender: TObject; var Done: Boolean);

       function Connect:Boolean;
       function SendCommand(S:String):Boolean;

     public

       constructor Create; override;
       destructor Destroy; override;

       procedure ClearBuffer;                               // ������� ������ �������

       { --- ���������� ������� � ������ --- }
       procedure inClearScreen;                      // ������� ����� ������
       procedure inClearString(N:Integer);           // ������� ����� �� ����� ������
       procedure inShowString(N:Integer; S:String);  // ����� ������ � ������� ������
       procedure inSetBrightness(V:Byte);            // ���������� ������� ��������� ������

       function  inSendCommand(S:String):Boolean;    // ���������� ������������ �������

       property PortNumber:Integer read FPortNumber write FPortNumber;
       property UseIndicator:Boolean read FUseIndicator write SetUseIndicator;
       property Asynchron:Boolean read FAsynchron write SetAsynchron;
       property ArrStr:TStringList read FArrStr write FArrStr;

     end;

Function Indicator:TIndicator;

Implementation

Var FIndicator:TIndicator=nil;

Function Indicator:TIndicator;
 begin
  if FIndicator=nil then FIndicator:=TIndicator.Create;
  Result:=FIndicator;
 end;

{ TIndicator }

constructor TIndicator.Create;
 begin
  inherited;
  FPortNumber:=2;
  FUseIndicator:=False;
  FCt.ReadIntervalTimeout:=500;
  FArrStr:=TStringList.Create;
  FAsynchron:=False;
  Asynchron:=True;
 end;

function TIndicator.SendCommand(S:String):Boolean;
var B:Array[1..255] of Byte;
    i:Integer;
 begin
  try
   S:=#1+Chr(Length(S)+3)+S+#$2;
   for i:=1 to Length(S) do B[i]:=Ord(S[i]);
   SendCom(B,Length(S));
   ReceiveCom(B,1);
   Result:=B[1]=6;
  except
   Result:=False;
  end;
 end;

function TIndicator.Connect:Boolean;
var Pn,i:Integer;
    B:Boolean;
 begin
  Result:=True;
  if IsConnect then
   if SendCommand(#112+#33) then Exit;
  try
   CloseCom;
   B:=False;
   for i:=1 to 32 do
    begin
     if i=1 then Pn:=FPortNumber else Pn:=i;
     if Not InitCom(9600,Pn,#1,FCt) then Continue;
     ClearInputCom;
     if SendCommand(#112+#33) then
      begin
       B:=True;
       FPortNumber:=Pn;
       Break;
      end;
    end;
   Result:=B;
  except
   Result:=False;
  end;
 end;

function TIndicator.inSendCommand(S:String):Boolean;
 begin
  Result:=True;
  if Not UseIndicator then Exit;
  Result:=Connect;
  if Not Connect then Exit;
  Result:=SendCommand(S);
 end;

procedure TIndicator.inClearScreen;
 begin
  AddCommand(#$63);
 end;

procedure TIndicator.inClearString(N:Integer);
 begin
  if N<1 then N:=1 else if N>4 then N:=4;
  AddCommand(#$43+Chr($31+N-1));
 end;

procedure TIndicator.inShowString(N:Integer; S:String);
 begin
  if N<1 then N:=1 else if N>4 then N:=4;
  S:=S+'                                        ';
  AddCommand(#$53+Chr($31+N-1)+Copy(S,1,21));
 end;

procedure TIndicator.inSetBrightness(V:Byte);
 begin
  AddCommand(#$4C+Chr(V));
 end;

destructor TIndicator.Destroy;
var T:TDateTime;
 begin
  ArrStr.Clear;
  Application.OnIdle:=nil;
  FArrStr.Free;
  FAsynchron:=False;
  inClearScreen;
  inSetBrightness(0);
  inherited;
 end;

procedure TIndicator.SetUseIndicator(const Value:Boolean);
 begin
  FUseIndicator:=Value;
  if Value=False then Application.OnIdle:=nil
                 else begin
                       Application.OnIdle:=Execute;
                       inClearScreen;
                       inSetBrightness(0);
                      end;
 end;

procedure TIndicator.SetAsynchron(const Value:Boolean);
 begin
  FAsynchron:=Value;
  if Not Value then Application.OnIdle:=nil else
  if UseIndicator then Application.OnIdle:=Execute;
 end;

procedure TIndicator.ClearBuffer;
 begin
  ArrStr.Clear;
  inClearScreen;
  inClearScreen;
 end;

procedure TIndicator.AddCommand(S:String);
 begin
  if FAsynchron then ArrStr.Add(S) else inSendCommand(S);
 end;

procedure TIndicator.Execute(Sender:TObject; var Done:Boolean);
 begin
  if FArrStr.Count>0 then
   begin
    inSendCommand(FArrStr[0]);
    FArrStr.Delete(0);
   end;
  Done:=FAlse;
 end;

Initialization

Finalization
 if FIndicator<>nil then FIndicator.Free;

End.