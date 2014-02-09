unit DocStorageUnit;

interface

uses
  Windows, SysUtils, Classes,ActiveX, AxCtrls,ComObj;

type
  TStorage=Class;
  
  //�洢��洢���Ļ�����
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

  //�洢����
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

  //�洢��
  TStorage=Class(TStgOrStmBase)
  private
    FIStorage: IStorage;
    Function GetEnumStatStg:IEnumStatStg;
  protected
    StgStreams:TStringList;//����װ��StgStream����
    SubStorages:TStringList;//����װ��SubStorage����
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
  FModeRead:=STGM_READWRITE+STGM_SHARE_EXCLUSIVE ;//��д+��ռ��ʽ
  FModeWrite:=STGM_CREATE+STGM_READWRITE+STGM_SHARE_EXCLUSIVE; ////����+��д+��ռ��ʽ
  if VStorage<>nil then
  begin
    FName:=StreamName;
    StgOrStmNameCheck;
    if not Succeeded(VStorage.OpenStream(StringToOleStr(StreamName), nil,FModeRead, 0,FIStream)) then
      if not Succeeded(VStorage.createstream(StringToOleStr(StreamName),FModeWrite, 0,0,FIStream))then
        raise exception.Create('��������� '+StreamName+' ʱ����'); 
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
    OleStream.read(Data[1],OleStream.size); //��ȡ����
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
    OleStream.write(Data[1],length(Data)); //д������
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
    //��д+��ռ��ʽ
    FModeRead:=STGM_READWRITE+STGM_SHARE_EXCLUSIVE;
    //����+��д+��ռ��ʽ
    FModeWrite:=STGM_CREATE+STGM_READWRITE+STGM_TRANSACTED+STGM_SHARE_EXCLUSIVE;
  end else
  begin
    //��д+��ռ��ʽ+����֧��
    FModeRead:=STGM_READWRITE+STGM_TRANSACTED+STGM_SHARE_EXCLUSIVE ;
    //����+��д+��ռ��ʽ+����֧��
    FModeWrite:=STGM_CREATE+STGM_READWRITE+STGM_TRANSACTED+STGM_SHARE_EXCLUSIVE;
  end;
  if not succeeded(StgOpenStorage(StringToOleStr(StorageFileName), nil, FModeRead, nil, 0, FIStorage))then
    if not succeeded(StgCreateDocfile(StringToOleStr(StorageFileName), FModeWrite, 0, FIStorage))then
      raise exception.Create('������򿪽ṹ���洢�ļ�'+StorageFileName+'ʱ����');
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
      //��д+��ռ��ʽ
      FModeRead:=STGM_READWRITE+STGM_SHARE_EXCLUSIVE;
      //����+��д+��ռ��ʽ
      FModeWrite:=STGM_CREATE+STGM_READWRITE+STGM_TRANSACTED+STGM_SHARE_EXCLUSIVE;
    end else
    begin
      //��д+��ռ��ʽ+���񱣻�
      FModeRead:=STGM_READWRITE+STGM_TRANSACTED+STGM_SHARE_EXCLUSIVE ;
      //����+��д+��ռ��ʽ+���񱣻�
      FModeWrite:=STGM_CREATE+STGM_READWRITE+STGM_TRANSACTED+STGM_SHARE_EXCLUSIVE;
    end;
    FName:=SubStorageName;
    StgOrStmNameCheck;
    if not Succeeded(VParentStorage.OpenStorage(StringToOleStr(SubStorageName), nil,FModeRead, nil, 0, FIStorage))then
      if not Succeeded(VParentStorage.CreateStorage(StringToOleStr(SubStorageName),FModeWrite,0,0,FIStorage))then
        raise exception.Create('�򿪻򴴽��Ӵ洢'+SubStorageName+'ʱ����');
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
    raise exception.Create('ɾ���洢���� '+StgOrStmName+' ʱ����');
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
  //�ڴ�Ҫѹ�����ļ�
  FIStorage.Stat(StatStg,0);
  //����ļ���CLSID
  CLSID := StatStg.clsid;
  // ����һ����ʱ�ļ�
  TempFileName := ChangeFileExt(FName, '.$$$');
  if not succeeded(StgCreateDocFile(StringToOleStr(TempFileName),
    STGM_WRITE or STGM_SHARE_EXCLUSIVE, 0, stgTemp)) then
    raise exception.Create('ѹ���ļ�ʱ����');    
  // ��IStorage.CopyTo����Դ�ĵ�����ʱ�ļ���
  FIStorage.CopyTo(0, nil, nil, stgTemp);
  //�����ļ���CLSID
  stgTemp.SetClass(CLSID);
  //�ر���ʱ�洢
  stgTemp := nil;
  //�رմ洢
  FIStorage:=nil;
  //ɾ��Դ�ļ�
  DeleteFile(FName);
  //��������ʱ�ļ�ΪԴ�ļ�
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
    Raise exception.Create('�洢���������Ƶĳ��Ȳ��ܳ���31���ַ���');
  for i:=1 to length(FName) do
  begin
    if i=1 then
    begin
      if ord(FName[i])<=32 then
        Raise exception.Create('�洢���������Ƶ����ַ�����ȷ��');
    end;
    case FName[i] of
     '!': Raise exception.Create('�洢���������Ʋ��ܰ����ַ�''��''');
     ':': Raise exception.Create('�洢���������Ʋ��ܰ����ַ�'':''');
     '/': Raise exception.Create('�洢���������Ʋ��ܰ����ַ�''/''');
     '\': Raise exception.Create('�洢���������Ʋ��ܰ����ַ�''\''');
    end;
  end;
end;

end.














