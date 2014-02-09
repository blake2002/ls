unit DocStorageUnit;

interface

uses
  Windows, SysUtils, Classes,ActiveX, AxCtrls,ComObj;

type
  TStorage=Class;
  
  //存储或存储流的基础类
  TStgOrStmBase=Class
  private
    FName:String;
    ParentStg:TStorage;
    FModeWrite: integer;
    FModeRead: integer;
  protected
    Procedure StgOrStmNameCheck;
  public
    property Name:String read FName;
  end;

  //存储流类
  TStgStream=Class(TStgOrStmBase)
  private
    FIStream: IStream;
    FXml: String;
    Function  GetXml:String;
    procedure SetXml(const Value: String);
    procedure SaveXmlToStgStream;
    Procedure LoadXmlFromStgStream;
  protected
    constructor Create(VStorage:IStorage;StreamName: string);
  public
    property Xml:String read GetXml write SetXml;
    Destructor  Destroy;Override;
    procedure SaveFileToStgStream(filename: string);
    Procedure SaveStgStreamToFile(filename: string);
  end;

  //存储类
  TStorage=Class(TStgOrStmBase)
  private
    FIStorage: IStorage;
    Function GetEnumStatStg:IEnumStatStg;
  protected
    StgStreams:TStringList;//用来装载StgStream对象
    SubStorages:TStringList;//用来装载SubStorage对象
    constructor InsideCreateStorage(VParentStorage:IStorage;SubStorageName: string;
                               NeedTransacted:boolean=False);
  public
    property EnumStatStg :IEnumStatStg read GetEnumStatStg;
    constructor Create(StorageFileName: string;NeedTransacted:boolean=False);
    Destructor  Destroy;Override;
    Procedure DeleteStgOrStm(StgOrstmName:String);
    Function CreateStgStream(StreamName:String):TStgStream;
    Function CreateSubStorage(SubStorageName: string;NeedTransacted:boolean=False):TStorage;
    procedure Compress;
    procedure Commit;
    procedure Revert;

  end;

implementation

{ TStgStream }

constructor TStgStream.Create(VStorage:IStorage;StreamName: string);
begin
  inherited Create;
  FModeRead:=STGM_READWRITE+STGM_SHARE_EXCLUSIVE ;//读写+独占方式
  FModeWrite:=STGM_CREATE+STGM_READWRITE+STGM_SHARE_EXCLUSIVE; ////创建+读写+独占方式
  if VStorage<>nil then
  begin
    FName:=StreamName;
    StgOrStmNameCheck;
    if not Succeeded(VStorage.OpenStream(StringToOleStr(StreamName), nil,FModeRead, 0,FIStream)) then
      if not Succeeded(VStorage.createstream(StringToOleStr(StreamName),FModeWrite, 0,0,FIStream))then
        raise exception.Create('创建或打开流 '+StreamName+' 时出错！'); 
  end;
end;

destructor TStgStream.Destroy;
var
  IndexValue:Integer;
begin
  inherited;
  if ParentStg<>nil then
  begin
    IndexValue:=ParentStg.StgStreams.IndexOf(FName);
    ParentStg.StgStreams.Objects[IndexValue]:=nil;
    ParentStg.StgStreams.Delete(IndexValue);
    ParentStg:=nil;
  end;

end;

function TStgStream.GetXml: String;
begin
  LoadXmlFromStgStream;
  Result:=FXml;
end;

procedure TStgStream.SaveStgStreamToFile(filename: string);
var
  tmpfile:TFilestream;
  OleStream :TOLESTream;
begin
  if FileExists(filename) then
    DeleteFile(filename);
  OleStream:=TOLEStream.create(FIStream);  
  tmpfile:=TFilestream.Create(filename,fmCreate);
  try
    tmpfile.Size:=0;
    OleStream.Position:=0;
    tmpfile.CopyFrom(OleStream,OleStream.Size)
  finally
    tmpfile.Free;
    OleStream.Free;
  end;
end;

procedure TStgStream.LoadXmlFromStgStream;
var
  OleStream :TOLESTream;
  Data :string;
begin
  OleStream:=nil;
  try
    OleStream:=TOLEStream.create(FIStream);
    setlength(data,OleStream.size);
    OleStream.Position:=0;
    OleStream.read(Data[1],OleStream.size); //读取数据
    FXml:=Data;
  finally
    OleStream.Free;
  end;
end;

procedure TStgStream.SaveFileToStgStream(filename: string);
var
  tmpfile:TFilestream;
  OleStream :TOLESTream;
begin
  tmpfile:=TFilestream.Create(filename,fmOpenread);
  OleStream:=TOLESTream.Create(FIStream);
  try
    tmpfile.Position:=0;
    OleStream.Size:=0;
    OleStream.CopyFrom(tmpfile,tmpfile.Size)
  finally
    tmpfile.Free;
    OleStream.Free;
  end;
end;

procedure TStgStream.SaveXmlToStgStream;
var
  OleStream :TOLESTream;
  Data :String;
begin
  OleStream:=TOLEStream.create(FIStream);
  try
    Data:=FXml;
    OleStream.Position:=0;
    OleStream.write(Data[1],length(Data)); //写入数据
    OleCheck(FIStream.SetSize(length(Data)));
  finally
    OleStream.Free;
  end;
end;

procedure TStgStream.SetXml(const Value: String);
begin
  FXml := Value;
  SaveXmlToStgStream;
end;

{ TStorage }

procedure TStorage.Revert;
begin
  try
    FIStorage.Revert;
  except
    raise;
  end;
end;

procedure TStorage.Commit;
begin
  try
    FIStorage.Commit(0);
  except
    raise;
  end;
end;

constructor TStorage.Create(StorageFileName: string; NeedTransacted:boolean=False);
begin
  StgStreams:=TStringList.Create;
  SubStorages:=TStringList.Create;
  if not NeedTransacted then
  begin
    //读写+独占方式
    FModeRead:=STGM_READWRITE+STGM_SHARE_EXCLUSIVE;
    //创建+读写+独占方式
    FModeWrite:=STGM_CREATE+STGM_READWRITE+STGM_TRANSACTED+STGM_SHARE_EXCLUSIVE;
  end else
  begin
    //读写+独占方式+事务支持
    FModeRead:=STGM_READWRITE+STGM_TRANSACTED+STGM_SHARE_EXCLUSIVE ;
    //创建+读写+独占方式+事务支持
    FModeWrite:=STGM_CREATE+STGM_READWRITE+STGM_TRANSACTED+STGM_SHARE_EXCLUSIVE;
  end;
  if not succeeded(StgOpenStorage(StringToOleStr(StorageFileName), nil, FModeRead, nil, 0, FIStorage))then
    if not succeeded(StgCreateDocfile(StringToOleStr(StorageFileName), FModeWrite, 0, FIStorage))then
      raise exception.Create('创建或打开结构化存储文件'+StorageFileName+'时出错！');
  FName:=StorageFileName;
end;

constructor TStorage.InsideCreateStorage(VParentStorage: IStorage;
  SubStorageName: string; NeedTransacted:boolean=False);
begin
  if VParentStorage<>nil then
  begin
    StgStreams:=TStringList.Create;
    SubStorages:=TStringList.Create;
    if not NeedTransacted then
    begin
      //读写+独占方式
      FModeRead:=STGM_READWRITE+STGM_SHARE_EXCLUSIVE;
      //创建+读写+独占方式
      FModeWrite:=STGM_CREATE+STGM_READWRITE+STGM_TRANSACTED+STGM_SHARE_EXCLUSIVE;
    end else
    begin
      //读写+独占方式+事务保护
      FModeRead:=STGM_READWRITE+STGM_TRANSACTED+STGM_SHARE_EXCLUSIVE ;
      //创建+读写+独占方式+事务保护
      FModeWrite:=STGM_CREATE+STGM_READWRITE+STGM_TRANSACTED+STGM_SHARE_EXCLUSIVE;
    end;
    FName:=SubStorageName;
    StgOrStmNameCheck;
    if not Succeeded(VParentStorage.OpenStorage(StringToOleStr(SubStorageName), nil,FModeRead, nil, 0, FIStorage))then
      if not Succeeded(VParentStorage.CreateStorage(StringToOleStr(SubStorageName),FModeWrite,0,0,FIStorage))then
        raise exception.Create('打开或创建子存储'+SubStorageName+'时出错！');
  end;
end;

function TStorage.CreateStgStream(StreamName: String): TStgStream;
begin
  try
    Result:=TStgStream.Create(FIStorage,StreamName);
    Result.ParentStg:=self;
    StgStreams.AddObject(StreamName,Result);
  except
    raise;
  end;
end;

function TStorage.CreateSubStorage(SubStorageName: string;
  NeedTransacted: boolean=False): TStorage;
begin
  try
    Result:=TStorage.InsideCreateStorage(FIStorage,SubStorageName,NeedTransacted);
    Result.ParentStg:=self;
    SubStorages.AddObject(SubStorageName,Result);
  except
    raise;
  end;
end;

Procedure TStorage.DeleteStgOrStm(StgOrstmName: String);
begin
  if not succeeded(FIStorage.DestroyElement(StringToOleStr(StgOrStmName)))then
    raise exception.Create('删除存储或流 '+StgOrStmName+' 时出错！');
end;

destructor TStorage.Destroy;
var
  IndexValue:Integer;
begin
  if ParentStg<>nil then
  begin
    IndexValue:=ParentStg.SubStorages.IndexOf(FName);
    ParentStg.SubStorages.Objects[IndexValue]:=nil;
    ParentStg.SubStorages.Delete(IndexValue);
    ParentStg:=nil;
  end;
  if Assigned(StgStreams) then
  begin
    while StgStreams.Count>0 do
      TStgStream(StgStreams.Objects[0]).Free;
    StgStreams.Clear;
    StgStreams.Free;
  end;
  if Assigned(SubStorages) then
  begin
    while SubStorages.Count>0 do
      TStorage(SubStorages.Objects[0]).Free;
    SubStorages.Clear;
    SubStorages.Free;
  end;
  inherited;
end;

procedure TStorage.Compress;
var
  stgTemp: IStorage;
  TempFileName: WideString;
  CLSID : TCLSID;
  StatStg : TStatStg;
begin
  //在打开要压缩的文件
  FIStorage.Stat(StatStg,0);
  //获得文件的CLSID
  CLSID := StatStg.clsid;
  // 创建一个临时文件
  TempFileName := ChangeFileExt(FName, '.$$$');
  if not succeeded(StgCreateDocFile(StringToOleStr(TempFileName),
    STGM_WRITE or STGM_SHARE_EXCLUSIVE, 0, stgTemp)) then
    raise exception.Create('压缩文件时出错！');    
  // 用IStorage.CopyTo复制源文档到临时文件中
  FIStorage.CopyTo(0, nil, nil, stgTemp);
  //设置文件的CLSID
  stgTemp.SetClass(CLSID);
  //关闭临时存储
  stgTemp := nil;
  //关闭存储
  FIStorage:=nil;
  //删除源文件
  DeleteFile(FName);
  //重命名临时文件为源文件
  RenameFile(TempFileName, FName);
end;


function TStorage.GetEnumStatStg: IEnumStatStg;
var
  VEnumStatStg:IEnumStatStg;
begin
  if Succeeded(FIStorage.EnumElements(0, nil, 0, VEnumStatStg))then
    Result:=VEnumStatStg
  else
    Result:=nil;
end;

{ TStgBase }

procedure TStgOrStmBase.StgOrStmNameCheck;
var
  i:integer;
begin
  if length(FName)>=32 then
    Raise exception.Create('存储或流的名称的长度不能超过31个字符！');
  for i:=1 to length(FName) do
  begin
    if i=1 then
    begin
      if ord(FName[i])<=32 then
        Raise exception.Create('存储或流的名称的首字符不正确！');
    end;
    case FName[i] of
     '!': Raise exception.Create('存储或流的名称不能包含字符''！''');
     ':': Raise exception.Create('存储或流的名称不能包含字符'':''');
     '/': Raise exception.Create('存储或流的名称不能包含字符''/''');
     '\': Raise exception.Create('存储或流的名称不能包含字符''\''');
    end;
  end;
end;

end.














