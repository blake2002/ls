{ *************************************************************************** }
{                                                                             }
{ sunlight AutoRef libaraly Interface Define                                  }
{                                                                             }
{ Copyright (c) 2000, 2003 Sunlight Data System                               }                                                                             
{ *************************************************************************** }

unit AutoIntf;

interface

uses UnitXmlEngine,Classes,SysUtils,DateUtils;//XmlEngineIntf,;

type
  //变长数据块
  TDynamicData=array of byte;
  TDataPack=array of TDynamicData;
  TQuickPack=array of PChar;
  TBlockIndexList=array of Int64;
  PDynamicData=^TDynamicData;
  //数据存储位置信息
  TDataPosInf= packed record
    PageIndex:int64;
    PagePos:word;
  end;

  PDataPosInf=^TDataPosInf;

  //数据记录存储的位置信息
  TDataInfo=Record
    BlockIndex:int64;
    OffSet:integer;
    Size:integer;
  end;

  //链接关联信息
  TLinkData=Record
    Srcinfo:TDataInfo;
    Desinfo:TDataInfo;
  end;

  //明细数据存储结构
  TDetail=Record
    BlockIndex:int64;
    StartOffSet:Word;
    Count:Word;
  end;

  //系统联接对象，用来链接对象数据和引用对象，可以提高系统处理速度
  TLink=class(TObject)
  private
    fLinkInfo:TLinkData;
  public
    function GetData:TDynamicData;
  end;

 { TIndex=record
    BlockIndex:int64;
    BlockOffset:word;
  end;
  TRelation=TIndex;

  TRelationMem=record
    Ref:TObject;
  end;

  TIndexBind=record
    IndexInfo:TIndex;
    DataPos:Word;
    Size:Word;
  end;   }


  TDataType = (dtString, dtSmallint, dtInteger, dtWord,dtBoolean, dtFloat,
    dtCurrency, dtBCD, dtDateTime,dtBlob,dtGuid,dtInt64,dtStructure,dtDetail,
    dtRelation,dtChar,dtWidestring,dtUnknow);

  THuge=record
    first:int64;
    second:int64
  end;
  PHuge=^THuge;
  TIndexBlockRev=record
    BlockIndex:int64;
    LeftBlock:int64;
    RightBlock:int64;
    ParentBlock:int64;
    IndexSize:integer;
  end;

  TIndexBlock=class(TObject)
  private
    fIndexBlockInfo:TIndexBlockRev;
    //fDataIndexes:array of TIndexBind;
    FMaxIndexCount: word;
    procedure SetMaxIndexCount(const Value: word);
  published
    property MaxIndexCount:word read FMaxIndexCount write SetMaxIndexCount;


  end;
  //字符集容器
  TSuperstr=class(TObject)
  private
    FSize: integer;//字符长度
    FCount: integer;
    FData:string;
    procedure MoveStr(Source, Dest: pchar; count: Integer);
    procedure MoveShort(Source, Dest: pchar; count: Integer);

  public
    constructor Create;
    procedure Append(data:string);overload;
    procedure Append(data:shortstring);overload;
    procedure Append(Data:Char);overload;
    procedure Append(data:TDynamicData;count:integer);overload;
    procedure AddBegin;
    procedure AddEnd;
    procedure AddOver;
    procedure AddSpace;
    procedure Addequal;
    procedure AddDataEnd;
    function Value:string;
    procedure Clear;
    procedure SetCapacity(size:integer);
  end;
  //两进制容器
  TSuperDynArry=class(TObject)
  private
    FSize:integer;
    FCapacity:integer;
  public
    StartPos:integer;
    FData:TDynamicData;
    procedure Grow(Size:integer);
    constructor Create;
    procedure Append(data:TDynamicData);
    procedure Clear;
    function Data:TDynamicData;
    property Capacity:integer read FCapacity;
    property Size:integer read FSize;
  end;


  TPackData=class(TObject)
  private
    fData:TDynamicData;
    FMaxSize: integer;
    Fsize: integer;
    Fcapacity:integer;
    fPos:integer;
    procedure Grow;
    procedure SetMaxSize(const Value: integer);
    procedure Setsize(const Value: integer);
    procedure SetCapacity(Capacity:integer);
  public
    constructor Create;
    procedure Reset;
    property size:integer read Fsize write Setsize;
    property MaxSize:integer read FMaxSize write SetMaxSize;
    function GetData:TDynamicData;
    procedure AddData(Data:SmallInt);overload;
    procedure AddData(Data:Integer);overload;
    procedure AddData(Data:Int64);overload;
    procedure AddData(Data:TDateTime);overload;
    procedure AddData(Data:Double);overload;
    procedure AddData(Data:TGuid);overload;
    procedure AddData(Data:Currency);overload;
    procedure AddData(Data:byte);overload;
    procedure AddData(Data:word);overload;
    procedure AddData(Data:longword);overload;
    procedure AddData(Data:String);overload;
    procedure AddData(Data:WideString);overload;
    procedure AddData(Data:TDynamicData);overload;
    procedure AddData(Data:Single);overload;
    procedure AddData(Data:Boolean);overload;
  end;
  TObjs=array of TObject;
  PObjs=^TObjs;
  TObjCompare = function (Item1, Item2: TObject): Integer;
  TAutoList=class(TList)
  public
    constructor Create;virtual;
  end;

  TAutoListBak=class(TObject)  //容器对象用来放置对象实例的容器
  private

    procedure SetCount(const Value: integer);
  protected
    fObjs:TObjs;
    fCapacity:integer;
    fCount:integer;
    procedure Grow;virtual;
    procedure SetCapacity(NewCapacity:integer);virtual;
    function Get(Index: Integer): TObject;virtual;
    procedure Put(Index: Integer; const Value: TObject);virtual;
  public
    constructor Create;virtual;
    constructor CreateQuick;virtual;
    destructor Destroy;override;
    function Add(Obj:TObject):integer;virtual;
    procedure Delete(Index:integer);virtual;
    function Remove(Obj:TObject):integer;virtual;
    procedure Insert(Index:integer;Obj:TObject);virtual;
    procedure Clear;virtual;
    property Count:integer read FCount Write SetCount;
    property Capacity:integer read FCapacity write SetCapacity;
    property Items[Index: Integer]: TObject read Get write Put; default;
    property List: TObjs read FObjs;
  end;

  TListType=(ltIndex,ltData,ltClassIndex);
  TBlockIndex=class(TAutoList)
  private
    FIsLeaf: Boolean;
    FIsPacked: boolean;
    FBlockIndex: int64;
    FAllCount:int64;
    FListType: TListType;
    FOwner:TBlockIndex;
    function GetIsFull: boolean;
    function GetMaxObj: TObject;
    function GetMinObj: TObject;
    procedure SetBlockIndex(const Value: int64);
    procedure SetIsLeaf(const Value: Boolean);
    procedure SetIsPacked(const Value: boolean);
    procedure SetListType(const Value: TListType);
    function GetIsEmpty: boolean;
    procedure PutAll(Index: Int64; const Value: TObject);
    procedure DeleteFromStatic;
    function GetBlockFromStatic:int64;

  protected
    function FirstObj:TObject;
    function LastObj:TObject;
  public
    constructor Create;override;
    destructor Destroy;override;
    function GetAll(Index: Int64): TObject;
    procedure AddHuge(Obj:TObject);
    procedure AddObj(Obj:TObject;ObjCompare:TObjCompare);
    procedure SplitSelf;
    function SplitHalf(BlockIndex:TBlockIndex):TBlockIndex;
    procedure DeleteHuge(Index:int64);virtual;
    procedure InsertHuge(Index:int64;Obj:TObject);virtual;
    procedure InitFromBlock(BlockIndex:int64);
    property MinObj:TObject read GetMinObj;
    property MaxObj:TObject read GetMaxObj;
    property IsFull:boolean read GetIsFull;
    property IsEmpty:boolean read GetIsEmpty;
    property IsLeaf:Boolean read FIsLeaf write SetIsLeaf;
    property BlockIndex:int64 read FBlockIndex write SetBlockIndex;
    property IsPacked:boolean read FIsPacked write SetIsPacked;
    property ListType:TListType read FListType write SetListType;
    property AllCount:int64 read FAllcount;
    property AllItems[Index: Int64]: TObject read GetAll write PutAll; default;
  end;
  //自动处理对象
  ISuperstr=Interface
    procedure Append(data:string);overload;
    procedure Append(data:shortstring);overload;
    function Value:string;
  end;

  IAutoObj=Interface
  ['{D33BA40B-236A-41B9-BE31-A97E3CA8E1DF}']
    procedure AddSub(Obj:IAutoObj);
    function GetSub(Index:integer):IAutoObj;
    function GetXml:string;
    procedure GetSelfXml(Superstr:TSuperstr);
    procedure SetXml(Xml:string);
    procedure SetStandXml(Xml:string);
    function  GetStandXml:string;
    property Xml:string read GetStandXml write SetStandXml;
    procedure InitByXml(XmlNode:TXmlNode);
  end;

  INamedObj=Interface(IAutoObj)
  ['{DEF78927-2506-4D6A-9FAF-D8FCE53AE68E}']
    procedure SetName(const Value: shortstring);
    function GetName:shortstring;
    property Name:shortstring read GetName write SetName;
  end;

  IAutoStruc=Interface(INamedObj)
  ['{D6E7D0BC-8D59-4A17-9E2A-37E210BA9709}']
    function  GetAllocSize:integer;
    procedure InitStruc;
  end;

  IDataDef=Interface(INamedObj)
  ['{3141FEC5-C019-4B6D-BFF8-48EB1B81257B}']
    procedure SetSize(value:integer);
    function GetSize:integer;
    procedure SetDatatype(const Value: TDataType);
    function GetDatatype: TDataType;
    function GetValue(DataPack:TDynamicData;OffSet:integer):Variant;
    function GetStringValue(DataPack:TDynamicData;OffSet:integer):string;
    procedure SetValue(DataPack:TDynamicData;OffSet:integer;value:Variant);
    property Size:integer read GetSize write SetSize;
    property Datatype:TDatatype read GetDataType write SetDataType;
  end;

procedure  MoveQuick(Source:pchar;Dest:pchar;count:Integer );
procedure  MoveQuick2(Source:pchar;Dest:pchar;count:Integer );

const
  MinListSize=16;
  MaxIndexSize=16;
  MaxDataSize=16;
  BalanceLevel=8;
  //pagesize=16;
  SizeInteger=4;
  SizeInt64=8;
  SizeWord=2;
  dymicIndex=2;
  SizePosInf=sizeof(TDataPosinf);


implementation
{ TSuperstr }

procedure TSuperstr.Append(data: string);
var
datasize:integer;
oldsize:integer;
begin
  datasize:=length(data);
  oldsize:=fsize;
  inc(fsize,datasize);
  if fsize>fcount then
    begin
      fcount:=fsize+fsize;//aufsize+fsize-fcount;
      SetLength(fdata,fcount);
    end;
  movestr(@Data[1],@fdata[oldsize+1],datasize);
  //move(Data[1],fdata[oldsize+1],datasize);
end;

procedure TSuperstr.Append(data: shortstring);
var
datasize:integer;
oldsize:integer;
begin
  datasize:=integer(data[0]);
  oldsize:=fsize;
  inc(fsize,datasize);
  if fsize>fcount then
    begin
      fcount:=fsize+fsize;
      SetLength(fdata,fcount);
    end;
  //move(Data[1],fdata[oldsize+1],datasize);
  moveshort(@Data[1],@fdata[oldsize+1],datasize);
end;

{procedure TSuperstr.Append(data: char);
begin

  if fsize=fcount then
    begin
      fcount:=fsize+strinc;
      SetLength(fdata,fcount);
    end;
  inc(fsize);
  fdata[fsize]:=data;
end;}

procedure TSuperstr.Clear;
begin
  fcount:=0;
  fdata:='';
  fsize:=0;
end;

constructor TSuperstr.Create;
begin
  inherited;
  //fcount:=65536;
  //setlength(fdata,fcount);
  clear;
  //fdata:='';
end;

procedure  TSuperstr.Movestr(Source:pchar;Dest:pchar;count:Integer );
var
i:integer;
cycle:integer;
begin
  if count>16 then
    begin
      cycle:=count shr 4;
      for i:=0 to cycle-1  do
        begin
          PHuge(Dest)^:=PHuge(Source)^ ;
          Source:=Source+16;
          Dest:=Dest+16;
        end;
      count:=count and 15;
    end;
  for i:=0 to count-1 do
    begin
      Dest[i]:=Source[i];
    end;
end;



procedure TSuperstr.MoveShort(Source, Dest: pchar; count: Integer);
var
i:integer;
cycle:integer;
begin
  if count>4 then
    begin
      cycle:=count shr 2;
      for i:=0 to cycle-1  do
        begin
          PInteger(Dest)^:=PInteger(Source)^ ;
          Source:=Source+4;
          Dest:=Dest+4;
        end;
      count:=count and 3;
    end;
  for i:=0 to count-1 do
    begin
      Dest[i]:=Source[i];
    end;
end;

function TSuperstr.Value: string;
begin
  setlength(FData,fsize);
  fcount:=fsize;
  Result:=fData;
end;

procedure TSuperstr.AddBegin;
begin
  inc(fsize);
  if fsize>fcount then
    begin
      fcount:=fsize+fsize;
      SetLength(fdata,fcount);
    end;
  fdata[fsize]:='<';
end;

procedure TSuperstr.AddEnd;
begin
  inc(fsize,2);
  if fsize>fcount then
    begin
      fcount:=fsize+fsize;
      SetLength(fdata,fcount);
    end;
  fdata[fsize-1]:='<';
  fdata[fsize]:='/';
end;

procedure TSuperstr.AddOver;
begin
  inc(fsize);
  if fsize>fcount then
    begin
      fcount:=fsize+fsize;
      SetLength(fdata,fcount);
    end;
  fdata[fsize]:='>';
end;

procedure TSuperstr.AddDataEnd;
begin
  inc(fsize);
  if fsize>fcount then
    begin
      fcount:=fsize+fsize;
      SetLength(fdata,fcount);
    end;
  fdata[fsize]:='"';
end;


procedure TSuperstr.Addequal;
begin
  inc(fsize,2);
  if fsize>fcount then
    begin
      fcount:=fsize+fsize;
      SetLength(fdata,fcount);
    end;
  fdata[fsize-1]:='=';
  fdata[fsize]:='"';
end;


procedure TSuperstr.AddSpace;
begin
  inc(fsize);
  if fsize>fcount then
    begin
      fcount:=fsize+fsize;
      SetLength(fdata,fcount);
    end;
  fdata[fsize]:=' ';
end;


procedure TSuperstr.Append(data: TDynamicData; count: integer);
var
oldsize:integer;
begin
  oldsize:=fsize;
  inc(fsize,count);
  if fsize>fcount then
    begin
      fcount:=fsize+fsize;
      SetLength(fdata,fcount);
    end;
  //move(Data[1],fdata[oldsize+1],datasize);
  move(Data[0],fdata[oldsize+1],count);
end;

procedure TSuperstr.Append(Data: Char);
begin
  inc(fsize);
  if fsize>fcount then
    begin
      fcount:=fsize+fsize;
      SetLength(fdata,fcount);
    end;
  fData[fsize]:=Data;
end;

procedure TSuperstr.SetCapacity(size: integer);
begin
  fCount:=size;
  SetLength(fData,fcount);
end;

{ TAutoList }

function TAutoListBak.Add(Obj: TObject):integer;
begin

  if fCount=fCapacity then Grow;
  fObjs[Count]:=Obj;
  Result:=fCount;
  inc(fCount);
end;

procedure TAutoListBak.Clear;
begin
  SetCapacity(MinlistSize);
  fCount:=0;
end;

constructor TAutoListBak.Create;
begin
  inherited;
  fCapacity:=0;
  fcount:=0;
end;

constructor TAutoListBak.CreateQuick;
begin
  inherited;
  fCapacity:=0;
  fCount:=0;
end;

procedure TAutoListBak.Delete(Index: integer);
var
i:integer;
begin
  if Index>count-1 then raise Exception.Create('Index Should less than List Count');
  i:=index;
  while i<count-1 do
    begin
      fObjs[i]:=fObjs[i+1];
      inc(i);
    end;
  Dec(fCount);
  fObjs[i]:=nil;
end;

destructor TAutoListBak.Destroy;
begin
  //Dispose(fObjs);
  inherited;
end;

function TAutoListBak.Get(Index: Integer): TObject;
begin
  //if Index>=count then
  //Result:=fObjs[count-1] else
  Result:=fObjs[index];
    //raise Exception.create('Index out of range!');

end;

procedure TAutoListBak.Grow;
var
Delta:integer;
begin
  if fCapacity>=64 then Delta:=(fCapacity div 4) else Delta:=16;
  //fCapacity:=fCapacity +Delta;
  SetCapacity(fCapacity+Delta);

end;

procedure TAutoListBak.Insert(Index: integer; Obj: TObject);
var
i:integer;
begin
  if fCount=fCapacity then Grow;
  if Index=fcount then
    begin
      Add(Obj);
      exit;
    end;
  i:=fcount;
  while i> Index do
    begin
      fObjs[i]:=fObjs[i-1];
      Dec(i);
    end;
  fObjs[Index]:=Obj;
  inc(fcount);
end;

procedure TAutoListBak.Put(Index: Integer; const Value: TObject);
begin
  fObjs[index]:=Value;
end;

function TAutoListBak.Remove(Obj: TObject): integer;
var
i:integer;
begin
  Result:=-1;
  for I:=0 to fcount-1 do
    begin
      if fObjs[i]=Obj then
        begin
          Delete(i);
          Result:=i;
          Break;
        end;
    end;
end;

procedure TAutoListBak.SetCapacity(NewCapacity: integer);
begin
  fCapacity:=NewCapacity;
  //if fObjs=nil then fObjs:=@Objs;
  SetLength(fObjs,NewCapacity);
end;

procedure TAutoListBak.SetCount(const Value: integer);
begin
  FCount := Value;
end;

{ TBlocklist }

procedure TBlockIndex.AddHuge(Obj: TObject);
var
tmplist:TBlockIndex;
begin

  if isFull then SplitSelf else
    begin
      if Count=Capacity then Grow;
    end;
  if FListType=ltData then
    begin
      inherited Add(Obj);
      inc(fAllCount);
    end else
      begin
        if not(IsEmpty) then
          begin
            tmplist:=TBlockIndex(inherited Items[count-1]);
            if not(tmplist.IsFull) then
              begin
                tmplist.AddHuge(Obj);
                inc(fAllCount);
              end else
                begin
                  tmplist:=TBlockIndex.Create;
                  tmplist.ListType:=ltData;
                  tmplist.BlockIndex:=GetBlockFromStatic;
                  tmplist.AddHuge(Obj);
                  inherited Add(tmplist);
                  inc(fAllCount);
                end;
           end  else
            begin
              tmplist:=TBlockIndex.Create;
              tmplist.ListType:=ltData;
              tmplist.BlockIndex:=GetBlockFromStatic;
              tmplist.Add(Obj);
              inherited Add(tmplist);
              inc(fAllCount);
            end;
      end;
end;

procedure TBlockIndex.AddObj(Obj: TObject; ObjCompare: TObjCompare);
begin

end;

constructor TBlockIndex.Create;
begin
  inherited Create;
  fAllCount:=0;

end;

procedure TBlockIndex.DeleteFromStatic;
begin

end;

procedure TBlockIndex.DeleteHuge(Index: int64);
var
i:integer;
tmpblock:TBlockIndex;
deleteIndex:integer;
begin
  if Index>(fAllCount-1) then
    Raise Exception.Create('The list only have '+inttostr(fallCount)+' elements, Less than the index Enter' );
  if ListType=ltData then
    begin
      inherited Delete(Index);
      Dec(fAllCount) ;
      exit;
    end else
      begin
        DeleteIndex:=Index;
        for i:=0 to count-1 do
          begin
            tmpblock:=TBlockIndex(inherited items[i]);
            if DeleteIndex>(tmpblock.AllCount-1) then Dec(DeleteIndex,tmpblock.AllCount)
              else
                begin
                  tmpblock.DeleteHuge(DeleteIndex);
                  if tmpblock.AllCount=0 then
                    begin
                      tmpblock.DeleteFromStatic;
                      inherited Delete(i);
                    end;
                  Dec(fAllCount);
                  exit;
                end;
          end;
      end;
end;

destructor TBlockIndex.Destroy;
var
i:integer;
tmpblock:TblockIndex;
begin
  if self.ListType=ltIndex then
    begin
      for i:=0 to count-1 do
        begin
          tmpblock:=TBlockIndex(items[i]);
          tmpblock.Free;
        end;
    end;
  inherited Destroy;
end;

function TBlockIndex.FirstObj: TObject;
begin
  if ListType<>ltData then
    begin
      result:=TBlockIndex(Items[0]).FirstObj;
    end else result:=Items[0];
end;

function TBlockIndex.GetAll(Index: Int64): TObject;
var
listindex:Int64;
i:integer;
tmpblock:TBlockIndex;
begin
  Result:=nil;
  if ListType=ltData then result:=items[index] else
    begin
      if index<=(FAllCount shr 1) then
        begin
          listindex:=index;
          for i:=0 to Count-1 do
            begin
              tmpblock:=TBlockIndex(Items[i])  ;
              if listindex>=(tmpblock.FAllCount) then
                begin
                  dec(listindex,tmpblock.FAllCount);

                end else
                  begin
                    result:=tmpblock.GetAll(listIndex);
                    Exit;
                  end;
            end;
        end else
          begin
            listindex:=FAllcount;
            for i:=count-1 downto 0 do
              begin
                tmpblock:=TBlockIndex(Items[i])  ;
                if (listindex-tmpblock.FAllCount)>Index then
                  begin
                    dec(listindex,tmpblock.FAllCount);

                  end else
                    begin
                      dec(listindex,tmpblock.FAllCount);
                      result:=tmpblock.GetAll(Index-listIndex);
                      Exit;
                    end;
              end;
          end;
    end;

end;

function TBlockIndex.GetBlockFromStatic: int64;
begin

end;

function TBlockIndex.GetIsEmpty: boolean;
begin
  if Count=0 then Result:=true else result:=false;
end;

function TBlockIndex.GetIsFull: boolean;
begin
  if self.ListType=ltIndex then
    begin
      if self.Count=MaxIndexSize then result:=true else Result:=false;
    end else
      begin
        if self.Count=MaxDataSize then result:=true else Result:=false;
      end;

end;

function TBlockIndex.GetMaxObj: TObject;
begin

end;

function TBlockIndex.GetMinObj: TObject;
begin

end;

procedure TBlockIndex.InitFromBlock(BlockIndex: int64);
begin

end;

procedure TBlockIndex.InsertHuge(Index: int64; Obj: TObject);
var
i:integer;
tmpblock:TBlockIndex;
insertIndex:int64;
tmplist:TBlockIndex;
begin
  if IsFull then Splitself;
  if (Index>(fAllCount-1)) and (Index<>0) then
    begin
      AddHuge(Obj);
      exit;
      //Index:=fAllCount-1;
      //exit;
    end;

  if ListType=ltData then
    begin
      inherited insert(Index,Obj);
      inc(fAllcount);
      exit;
    end else
      begin

        if Index<=(FAllcount shr 1) then
          begin
            InsertIndex:=Index;
            for i:=0 to Count-1 do
              begin
                tmpblock:=TBlockIndex(items[i]);
                if InsertIndex>(tmpblock.AllCount-1) then Dec(InsertIndex,tmpblock.AllCount)
                  else
                    begin
                      if not(tmpblock.IsFull) then
                        begin
                          tmpblock.InsertHuge(InsertIndex,Obj);
                          inc(fAllCount);
                          exit;
                        end else
                          begin
                            tmplist:=Splithalf(tmpblock);
                            insert(i+1,tmplist);
                            if InsertIndex>=(tmpblock.AllCount) then
                              tmplist.InsertHuge(InsertIndex-tmpblock.AllCount,Obj)
                              else tmpblock.InsertHuge(Insertindex,obj);
                            inc(fAllCount);
                            exit;
                          end;

                    end;
              end;
            end else
              begin
                InsertIndex:=FAllcount;
                for i:=count-1 downto 0 do
                  begin
                    tmpblock:=TBlockIndex(items[i]);
                    if (InsertIndex-tmpblock.FAllCount)>Index then Dec(InsertIndex,tmpblock.AllCount)
                      else
                        begin
                          Dec(InsertIndex,tmpblock.AllCount);
                          InsertIndex:=Index-InsertIndex;
                          if not(tmpblock.IsFull) then
                            begin
                              tmpblock.InsertHuge(InsertIndex,Obj);
                              inc(fAllCount);
                              exit;
                            end else
                              begin
                                tmplist:=Splithalf(tmpblock);
                                insert(i+1,tmplist);
                                if InsertIndex>=(tmpblock.AllCount) then
                                  tmplist.InsertHuge(InsertIndex-tmpblock.AllCount,Obj)
                                  else tmpblock.InsertHuge(Insertindex,obj);
                                inc(fAllCount);
                                exit;
                              end;
                        end;
                  end;
              end;
      end;
end;

function TBlockIndex.LastObj: TObject;
begin
  if ListType<>ltData then
    begin
      result:=TBlockIndex(items[Count-1]).FirstObj;
    end else result:=items[0];
end;

procedure TBlockIndex.PutAll(Index: Int64; const Value: TObject);
begin

end;

procedure TBlockIndex.SetBlockIndex(const Value: int64);
begin
  FBlockIndex := Value;
end;

procedure TBlockIndex.SetIsLeaf(const Value: Boolean);
begin
  FIsLeaf := Value;
end;

procedure TBlockIndex.SetIsPacked(const Value: boolean);
begin
  FIsPacked := Value;
end;

procedure TBlockIndex.SetListType(const Value: TListType);
begin
  FListType := Value;
end;

function TBlockIndex.SplitHalf(BlockIndex: TBlockIndex): TBlockIndex;
var
tmplist:TBlockIndex;
splitcount:int64;
halfcount,j:integer;
movedata:Tobject;
begin
  splitcount:=0;
  tmplist:=TBlockIndex(Classtype.Create);
  tmplist.ListType:=BlockIndex.ListType;
  tmplist.Capacity:=BlockIndex.Capacity;
  halfcount:=BlockIndex.count div 2;
  for j:=halfcount to BlockIndex.Count-1 do
    begin
      movedata:=BlockIndex.items[j];
      tmplist.items[j-halfcount]:=movedata;
      if BlockIndex.ListType=ltIndex then
        inc(splitcount,TBlockIndex(movedata).AllCount) else
        inc(splitcount);
    end;
  tmplist.Count:=BlockIndex.count-halfcount;
  BlockIndex.Count:=halfcount;
  BlockIndex.FAllCount:=BlockIndex.AllCount-splitCount;
  tmplist.FAllCount:=splitCount;
  tmplist.BlockIndex:=GetBlockFromStatic;
  Result:=tmplist;
end;

procedure TBlockIndex.SplitSelf;
var
tmplist1,tmplist2:TBlockIndex;
halfcount,i:integer;
splitcount:int64;
tmpobj:TObject;
begin
  halfcount:=count shr 1;
  if listtype=ltIndex then Splitcount:=0 else Splitcount:=halfcount;
  tmplist1:=TBlockIndex(Classtype.Create);
  tmplist1.Capacity:=Capacity;
  tmplist1.ListType:=ListType;
  tmplist2:=TBlockIndex(Classtype.Create);
  tmplist2.ListType:=ListType;
  tmplist2.Capacity:=Capacity;
  for i:=0 to count-1 do
    begin
      tmpobj:=items[i];
      if i<halfcount then
        begin
           tmplist1.items[i]:=tmpobj;
           if ListType=ltIndex then  inc(splitcount,TBlockIndex(tmpobj).AllCount);
        end else tmplist2.items[i-halfcount]:=tmpobj;
    end;
  tmplist1.BlockIndex:=tmplist1.GetBlockFromStatic;
  tmplist1.Count:=halfcount;
  tmplist1.FAllCount:=Splitcount;
  tmplist2.BlockIndex:=tmplist1.GetBlockFromStatic;
  tmplist2.Count:=count-halfcount;
  tmplist2.FAllCount:=FAllcount-splitcount;
  clear;
  Add(tmplist1);
  Add(tmpList2);
  ListType:=ltIndex;
end;

{ TAutoList }

constructor TAutoList.Create;
begin
  inherited Create;
end;

{ TIndexBlock }

procedure TIndexBlock.SetMaxIndexCount(const Value: word);
begin
  FMaxIndexCount := Value;
end;

{ TPackData }

procedure TPackData.AddData(Data: TGuid);
begin

end;

procedure TPackData.AddData(Data: Double);
begin

end;

procedure TPackData.AddData(Data: byte);
begin

end;

procedure TPackData.AddData(Data: Currency);
begin

end;

procedure TPackData.AddData(Data: Integer);
begin

end;

procedure TPackData.AddData(Data: SmallInt);
var
fsize:integer;
begin
  fsize:=sizeof(Data);
  move(data,fdata[fPos],fsize);
  inc(fPos,fsize);
  if fPos>=size then Size:=fPos+1;
end;

procedure TPackData.AddData(Data: TDateTime);
var
fsize:integer;
begin
  fsize:=sizeof(Data);
  move(data,fdata[fPos],fsize);
  inc(fPos,fsize);
  if fPos>=size then Size:=fPos+1;
end;

procedure TPackData.AddData(Data: Int64);
var
fsize:integer;
begin
  fsize:=sizeof(Data);
  move(data,fdata[fPos],fsize);
  inc(fPos,fsize);
  if fPos>=size then Size:=fPos+1;
end;

procedure TPackData.AddData(Data: word);
begin

end;

procedure TPackData.AddData(Data: TDynamicData);
begin

end;

procedure TPackData.AddData(Data: Single);
begin

end;

procedure TPackData.AddData(Data: Boolean);
begin

end;

procedure TPackData.AddData(Data: longword);
begin

end;

procedure TPackData.AddData(Data: String);
begin

end;

procedure TPackData.AddData(Data: WideString);
begin

end;



constructor TPackData.Create;
begin
  inherited Create;
  fsize:=0;
end;

function TPackData.GetData: TDynamicData;
begin

end;

procedure TPackData.Grow;
var
Delta:integer;
begin
  if fCapacity<16 then Delta:=8 else  Delta:= fCapacity shr 2;
  inc(fCapacity,Delta);
  SetCapacity(fCapacity);

end;

procedure TPackData.Reset;
begin
  fSize:=0;
  fPos:=0;
end;

procedure TPackData.SetCapacity(Capacity: integer);
begin
  Setlength(fData,Capacity);
end;

procedure TPackData.SetMaxSize(const Value: integer);
begin
  FMaxSize := Value;
end;

procedure TPackData.Setsize(const Value: integer);
begin
  FSize := Value;
end;

{ TLink }

function TLink.GetData: TDynamicData;
begin
  SetLength(Result,sizeof(fLinkInfo));
  Move(fLinkInfo,Result,sizeof(fLinkinfo));
end;

{ TSuperDynArry }

procedure TSuperDynArry.Append(data: TDynamicData);
var
datasize,delta:integer;
oldsize:integer;
begin
  datasize:=length(data);
  oldsize:=fsize;
  inc(fsize,datasize);
  if fsize>fcapacity then
    begin
      delta:=fcapacity shr 2;
      if delta<datasize then delta:=datasize+ (datasize shr 4);
      fcapacity:=fcapacity+delta;
      SetLength(fdata,fcapacity);
    end;
  move(Data[0],fdata[oldsize],datasize);

end;


procedure TSuperDynArry.Clear;
begin
  fCapacity:=256;
  fsize:=0;
  Setlength(fData,fCapacity);
  StartPos:=0;
end;

constructor TSuperDynArry.Create;
begin
  clear;

end;

function TSuperDynArry.Data: TDynamicData;
begin
  fCapacity:=fsize;
  SetLength(fData,fCapacity);
  Result:=fData;
end;

procedure TSuperDynArry.Grow(Size: integer);
begin
  fCapacity:=fCapacity+size;
  setlength(fData,fCapacity);
end;


procedure  MoveQuick(Source:pchar;Dest:pchar;count:Integer );
var
pagesize:integer;
begin
  pagesize:=16;
  while count >=pagesize do
    begin
      PHuge(Dest)^:=PHuge(Source)^ ;
      inc(Source,pagesize);
      inc(Dest,pagesize);
      dec(count,pagesize);
    end;

  while count >=1 do
    begin
      PChar(Dest)^:=PChar(Source)^ ;
      inc(Source);
      inc(Dest);
      dec(count);
    end;
end;

procedure  MoveQuick2(Source:pchar;Dest:pchar;count:Integer );
var
i:integer;
cycle:integer;
begin
  if count>=16 then
    begin
      cycle:=count shr 4;
      for i:=0 to cycle-1  do
        begin
          PHuge(Dest)^:=PHuge(Source)^ ;
          inc(Source,16);
          inc(Dest,16);
        end;
      count:=count and 15;
    end;
  for i:=0 to count-1 do
    begin
      Dest[i]:=Source[i];
    end;
end;

end.



