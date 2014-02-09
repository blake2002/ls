unit UnitAutoClass;


interface

uses
  SysUtils, Types,windows, Classes,Typinfo,db,DateUtils,RTLConsts,AutoIntf,
  UnitXmlEngine,fmtBcd,controls,variants,Activex,math,Graphics,stdctrls;
type
{$M+}
  //对象操作类型（新插入，更新，删除，未操作）
  TObjType=(otInsert,otUpdate,otDelete,otNone);
  PIndexNode=^TIndexNode;


  TCardinalBytes = record
    case integer of
      0: (
        Byte1: Byte;
        Byte2: Byte;
        Byte3: Byte;
        Byte4: Byte; );
      1: (Whole: Cardinal);
  end;

  TNameMirror=record
    ClassName:string;
    PropName:shortstring;
    Title:shortstring;
    SearchClass:shortstring;
  end;
  TDataDef=class;
  //数据结构信息
  TStrucInfo=Record
    HashCode:integer;
    DataDef:TDataDef;
    OffSet:integer;
  end;

  TStrucInfos=array of TStrucInfo;

  TStrucContainer=class;
  TBlobData=Class(TObject)
  private
    fsize:integer;
    fData:array of byte;
    procedure Setsize(const Value: integer);
  public
    constructor Create;
    procedure LoadFromStream(Stream:TStream);
    procedure SaveTStream(Stream:TStream);
    property size:integer read Fsize write Setsize;
  end;
  TDataSrcType=(dtManual,dtEnum,dtSearch);
  TCheckType=(ctEqual,ctMorethan,ctLessthan,ctBetween,ctOutof);

  //PPropInfo=^TPropInfo;
  TAutoObj=class;
  TAutoObjClass=class of TAutoObj;
  TAutoObjs=array of TAutoObj;
  //树节点
  TIndexNode=class(TObject)
  public
    Left:TIndexNode;
    Right:TIndexNode;
    Parent:TIndexNode;
    Balance:integer;
    Data:TAutoObj;
    constructor  Create;virtual;
  end;
  //对象索引器
  TObjIndex=class(TObject)
    private
      FSortProperty: string;
      FRoot:TIndexNode;
      leftcount:integer;
      rightcount:integer;
      procedure SetSortProperty(const Value: string);
      procedure UpdateBalance(Node:TIndexNode);
    public
      constructor Create;virtual;
      destructor Destroy;override;
      procedure AddData(Obj:TAutoObj);
      procedure InsertData(Node:TIndexNode;Obj:TAutoObj);
    published
      property SortProperty:string read FSortProperty write SetSortProperty;
  end;
  //自动结构声名对象（拥有容器可在容器中添加自动结构对象，所有published 声明的
  //特征均可自动结构成Xml）
  TAutoObj=Class(TPersistent)
  private
    proplist:PPropList;
    propcount:Integer;
    function  GetClassProp(PropName:shortstring):TAutoObj;
    function  GetRTTIClassProp(PropName:shortstring):TPersistent;
    function GetClassXml(Obj:TObject):string;
    function GetSubsCount: integer;
    class function GetPropValue(Instance: TObject; const PropInfo: PPropInfo;
     PreferStrings: Boolean = True): Variant;
    procedure SetPropValue(Instance: TObject; const PropInfo: PPropInfo;
      const Value: Variant);
    procedure InitObjByXml(Obj: TPersistent; XmlNode: TXmlNode);


  protected
    FSubObjects:TList;//子对象
    procedure GetSelfXml(Superstr:TSuperstr);virtual;
    class procedure GetXmlOfObj(Obj:TPersistent;Superstr:TSuperstr);
    procedure ClearSubObjs;
    procedure InitSubsQuick(XmlNode:TXmlNode);virtual;
    procedure InitPropsQuick(XmlNode:TXmlNode);virtual;
    procedure InitObjPropsQuick(Obj:TPersistent;XmlNode:TXmlNode);
  public
    constructor Create;virtual;
    destructor Destroy;override;
    class function GetInfo:string;virtual;
    function GetDataOf(Name: shortstring): Variant;virtual;
    procedure SetDataOf(Name: shortstring; const Value: Variant);virtual;
    procedure AddSub(Obj:TAutoObj);virtual;//添加子对象
    function GetSub(Index:integer):TAutoObj;//得到子对象
    function GetXml:string;virtual;//得到xml打包的数据string格式
    function GetStandXml:string;//得到utf-8格式的xml数据
    procedure SetXml(Xml:string);virtual;//设置string 格式的xml 来重构对象
    procedure SetObjXml(Obj:TPersistent;Xml: string);
    procedure SetStandXml(Xml:string);virtual;//设置utf-8 格式的xml 来重构对象
    procedure InitByXml(XmlNode:TXmlNode);virtual;//设置string格式的xml 来重构对象
    procedure Assign(Source: TPersistent);override;
    procedure SaveXmltoFile(filename:string);
    procedure LoadXmlfromFile(filename:string);
    class function GetObjXml(Obj:TPersistent):string;
    class function GetMirrorofProp(Propname:shortstring):shortstring;
    class function GetPropofMirror(Mirror:shortstring):shortstring;
    class function GetSearchofProp(Propname:shortstring):shortstring;
    class function GetNewId:shortstring;
    class procedure copyarraydata(ArraySrc:TDynamicData;SrcOffset:integer;
      ArrayDes:TDynamicData;DesOffset,size:integer);
    class function GetHash(Data:TDynamicData):integer;
    property Xml:string read GetStandXml write SetStandXml;//
    property SubsCount:integer read GetSubsCount;
    function GetSize:integer;
    function GetSubSize:integer;
  published

  end;

  TUniqueObj=Class(TAutoObj)
  private
    fobjid:TGuid;
    procedure Setobjid(const Value: shortstring);
    function Getobjid: shortstring;
  public
    constructor Create;override;
    class function GetInfo:string;override;
  published
    property objid:shortstring read Getobjid write Setobjid;
  end;

  TStreamObj=Class(TAutoObj)
  private
    FStream: TStream;
    procedure SetStream(const Value: TStream);
  public
    function GetXml:string;override;
    property Stream:TStream read FStream write SetStream;
  end;

  //自动化容器
  TAutoContainer=class(TAutoObj)
  private
    FPos: integer;
    procedure SetAutoClass(const Value: TAutoObjClass);
    procedure SetPos(const Value: integer);
    procedure ClearSubObjs;

  protected
    FAutoClass: TAutoObjClass;
    //初始化容器的盛方类型，所有容器子类必须重载
    FSubObjects:TList;//子对象

    procedure InitContainerClass;virtual;
    //清除容器中的对象
    procedure ClearContainer;

  public
    constructor Create;override;
    destructor Destroy;override;
    procedure Add(Obj:TAutoObj);virtual;
    //procedure AddSub(Obj:TAutoObj);override;
    function  NewSub:TAutoObj;virtual;
    function GetSubObj(Index:integer):TAutoObj;
    function GetSub(Index: integer): TAutoObj;
    function Get(Index:integer):TAutoObj;
    function ContainerCount:integer;
    function GetObj:TAutoObj;
    procedure Delete;
    property AutoClass:TAutoObjClass read FAutoClass write SetAutoClass;
    property Pos:integer read FPos write SetPos;
  end;

  //所有树型容器的根
  TTreeContainer=class(TAutoContainer)
  public
    procedure InitContainerClass;override;
  end;
  //数据结构定义的容器
  TDataDefContainer=class(TAutoContainer)
  protected

  public
    procedure InitContainerClass;override;

  end;

  //命名的自动结构声名对象
  TNamedObj=class(TUniqueObj)
  private
    FName: shortstring;
    FHash:integer;
  protected
    procedure SetName(const Value: shortstring);virtual;
  public
    function GetName:shortstring;
    class function GetInfo:string;override;
    property Hash:integer read fHash;
  published
    property Name:shortstring read GetName write SetName;
  end;

  TTreeObj=class(TUniqueObj)
  private
    FParentID: TGuid;
    procedure SetParent(const Value: shortstring);
    function GetParent: shortstring;
  published
    property ParentID:shortstring read GetParent write SetParent;
  end;

  TNamedTreeObj=class(TTreeObj)
  private
    FName: shortstring;
    function GetName: shortstring;
    procedure SetName(const Value: shortstring);virtual;
  published
    property name:shortstring read GetName write SetName;
  end;


  TInheritedObj=class(TNamedTreeObj)
  public

  end;
  
  TDataCheck=class(TAutoObj)
  private
    FRange: string;
    FCheckType: TCheckType;
    procedure SetCheckType(const Value: TCheckType);
    procedure SetRange(const Value: string);
  public
    procedure DoCheck;
  published
    property Range:string read FRange write SetRange;
    property CheckType:TCheckType read FCheckType write SetCheckType;
  end;

  TDataDef=class(TNamedObj)
  private
    FSize: integer;
    FPrecision: integer;
    FTitle: shortstring;
    FCheck: TDataCheck;
    FDatatype: TDataType;
    FDataSource: TDataSrcType;
    procedure SetCheck(const Value: TDataCheck);
    procedure SetDatatype(const Value: TDataType);
    procedure SetPrecision(const Value: integer);
    procedure SetTitle(const Value: shortstring);
    procedure SetDataSource(const Value: TDataSrcType);
    function GetDatatype: TDataType;

  protected
    procedure SetSize(Value: integer);
    function GetSize:integer;
  public
    constructor Create;override;
    destructor Destroy;override;
    function GetValue(DataPack:TDynamicData;OffSet:integer):Variant;
    function GetStringValue(DataPack:TDynamicData;OffSet:integer):string;
    function GetPackedData(DataPack:TDynamicData;OffSet:integer):TDynamicData;
    function  SetPackedData(DataPack:TDynamicData;Offset:integer;
              PackedData:TDynamicData;PackStart:integer):integer;
    procedure SetValue(DataPack:TDynamicData;OffSet:integer;value:Variant);
    function GetAllocSize:integer;
  published
    property Datatype:TDataType read GetDatatype write SetDatatype default dtString;
    property Size:integer read FSize write SetSize default 20;
    property Title:shortstring read FTitle write SetTitle;
    property Precision:integer read FPrecision write SetPrecision default 0;
    property DataSource:TDataSrcType read FDataSource write SetDataSource;
    property Check:TDataCheck read FCheck write SetCheck;
  end;

  //数据结构定义
  TAutoStruc=Class(TInheritedObj)
  private
    FActive:boolean;
    StrucInfos:TStrucInfos;
    FDefs: TDataDefContainer;
    fStrucContainer: TStrucContainer;
    FIsVirtual: boolean;
    function GetStringHash(str: shortstring): integer;
    procedure SetIsVirtual(const Value: boolean);
  public
    Constructor Create;override;
    Destructor Destroy;override;
    function GetAllocSize:integer;
    function GetDataDef(Index:integer):TDataDef;
    function GetDataOffset(Index:integer):integer;
    function GetOffSetof(Index:integer):integer;
    function GetSizeof(Index:integer):integer;
    function GetDataTypeof(Index:integer):TDataType;
    function GetIndexOf(Name: shortstring): integer;
    function GetDataValue(DataPack:TDynamicData;Index:integer):variant;
    procedure SetDataValue(DataPack:TDynamicData;Index:integer;Data:Variant);
    procedure InitByXml(XmlNode:TXmlNode);override;
    procedure InitStruc;
  published
    property Defs:TDataDefContainer read FDefs ;
    property SubStrucs:TStrucContainer read fStrucContainer;
    property IsVirtual:boolean read FIsVirtual write SetIsVirtual;
  end;



  //数据结构定义的容器
  TStrucContainer=class(TTreeContainer)
  private
    FName: string;
    procedure SetName(const Value: string);
  protected

  public
    constructor Create;override;
    procedure InitContainerClass;override;
    function GetStrucbyName(name:shortstring):TAutoStruc;
  published
    property name:string read FName write SetName;
  end;

  TDynamicContainer=class;
  TDynmObj=class(TAutoObj)
  private
    fInited:boolean;
    fStructure:TAutoStruc;
    //fContainer:TDynamicContainer;//所隶属的容器
  protected
    procedure GetSelfXml(Superstr:TSuperstr);override;
  public
    ObjType:TObjType;
    fData:TDynamicData;
    constructor Create;override;
    procedure InitbyStruc(Structure:TAutoStruc);
    procedure InitbyContainer(Container:TDynamicContainer);
    procedure InitObjData(Data:TDynamicData);
    function GetData(Index:integer):Variant;
    function GetContainer(Index:integer):TDynamicContainer;
    function GetStringData(Index:integer):string;
    function GetDataOf(Name: shortstring): Variant;override;
    procedure SetDataOf(Name: shortstring; const Value: Variant);override;
    procedure InitPropsQuick(XmlNode:TXmlNode);override;
    procedure SetData(Index:integer;value:variant);
    function GetPackData:TDynamicData;
    function GetStructure:TAutoStruc;
    procedure SetPackData(Data:TDynamicData);
    function GetInsertSQL:String;
    property  DataOf[Name: shortstring]:Variant read GetDataOf write SetDataOf;
  published

  end;

  TContainerIndex=class(TAutoObj)
  private
    fContainer:TAutoContainer;
    DataList:Array of Integer;
  public

  published

  end;

  TDynamicContainer=class(TAutoContainer)
  private
    fInitedbyStructure:boolean;
    StrucInfos:TStrucInfos;
    fData:array of TDynamicData;
    FStructure: TAutoStruc;
    FActive:boolean;
    FAllocSize:integer;

    procedure SetStructure(const Value: TAutoStruc);
    procedure SetStructureXml(const Value: string);
    function GetStructureXml: string;
    procedure InitContainer;
    function GetStringHash(str:shortstring):integer;
    procedure ResetData;
    function Cmp(DynmObj:TDynmObj;DynamicData:TDynamicData;DataIndex:integer):integer;
  protected
    procedure InitContainerClass;override;
    procedure InitPropsQuick(XmlNode:TXmlNode);override;
    procedure InitSubsQuick(XmlNode: TXmlNode);override;
    function GetDynmObjfromBlocks(Index:integer):TDynmObj;
  public
    FISAcid:boolean;
    constructor Create;override;
    constructor CreatebyXml(Xml:string);
    constructor CreatebyStructure(Structure:TAutoStruc);
    procedure Add(Obj:TAutoObj);override;
    destructor Destroy;override;
    procedure InitbyStruc(Structure:TAutoStruc);
    function  NewData:TDynmObj;virtual;
    function NewStaticData:TDynmobj;
    function  GetDynmObj(Index:integer):TDynmObj;
    function GetDataDef(Index:integer):TDataDef;
    function GetDataOffset(Index:integer):integer;
    function GetAllocSize:integer;
    function GetDefCount:integer;
    procedure SetXml(Xml:string);override;
    procedure SaveToFile(FileName:string);
    procedure LoadFromFile(FileName:string);
    procedure SavetoBlockContainer(DataPoolName:string);
    procedure LoadfromBlockContainer(DataPoolName:string);
    property StructureXml:string read GetStructureXml write SetStructureXml;
  published
    property Structure:TAutoStruc read FStructure ;
  end;

  TDynamicContainerImg=class(TDynamicContainer)
  private
    FImgName: string;
    FBlockContainer:TAutoContainer;
    procedure SetImgName(const Value: string);
  public
    destructor Destroy; override;
    function New:TDynmObj;
    function  NewData:TDynmObj;override;
  published
    property ImgName:string read FImgName write SetImgName;
  end;

{$M-}
TNameMirrors=array[0..16] of TNameMirror;

function GetStringHash(str: shortstring): integer;//得到字符串的hashcode;
function Encode(Data:string ):string;
function Decode(Data:string ):string;

const
  allinc=512;
  strinc=2048;
  primenumber:array[0..30] of byte=(2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,
    53,59,61,67,71,73,79,83,87,89,91,97,101,103,107,109);//,113,119,127,129,131,133,
    //137,141,143,149,151,153,157,161,167,173);
  CodeTable: string =
    '+-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  propmirrors:TNameMirrors
     =((PropName:'objid';Title:'唯一化ID';SearchClass:''), //Trootbill
       (PropName:'billtype';Title:'单据类型';SearchClass:''), //Trootbill
       (PropName:'status';Title:'单据状态';SearchClass:''),   //Tcustombill
       (PropName:'classlevel';Title:'分类等级';SearchClass:''), //Tclassification
       (PropName:'classtype';Title:'分类类型';SearchClass:''), //Tclassification
       (PropName:'code';Title:'编号';SearchClass:''),//TDataBill
       (PropName:'detail';Title:'说明';SearchClass:''), //TDataBill
       (PropName:'name';Title:'名称';SearchClass:''), //TDataBill
       (PropName:'parentid';Title:'父分类编号';SearchClass:''),//Tclassification
       (PropName:'quickcode';Title:'速查码';SearchClass:''),//Tclassification
       (PropName:'showindex';Title:'显示顺续';SearchClass:''), //Tclassification
       (PropName:'StrucContainer';Title:'结构容器';SearchClass:''),
       (PropName:'Defs';Title:'结构定义';SearchClass:''),
       (PropName:'Release';Title:'版本号';SearchClass:''),
       (PropName:'01';Title:'结构定义';SearchClass:''),
       (PropName:'02';Title:'结构定义';SearchClass:''),
       (PropName:'03';Title:'结构定义';SearchClass:'')
       );

implementation

uses UnitDynamicBlock;
{ TAutoObj }

procedure TAutoObj.AddSub(Obj: TAutoObj);
begin
  FSubObjects.Add(Obj)
end;

procedure TAutoObj.Assign(Source: TPersistent);
var
propname:shortstring;
tmpobj:TPersistent;
begin
  if Source is TAutoObj then
    begin
      Xml:=TAutoObj(Source).Xml;

    end else inherited;
end;



procedure TAutoObj.ClearSubObjs;
var
i:integer;
Obj:TAutoObj;
begin
  for i:=0 to FSubObjects.Count-1 do
    begin
      Obj:=FSubObjects.items[i];
      if Obj<>nil then Obj.Free;
    end;
  FSubObjects.Clear;
end;

constructor TAutoObj.Create;
var
tmpguid:Tguid;
begin
  inherited Create;
  //FSubsCount:=0;
  //falloccount:=0;
  FSubObjects:=TList.Create;
  propcount:=GetProplist(self,proplist);
  //fxml:=Tsuperstr.Create;
end;

destructor TAutoObj.Destroy;
begin
  ClearSubObjs;
  FSubObjects.Free;
  //ClearPropList;
  if propcount<>0 then dispose(proplist);
  inherited;
end;



function TAutoObj.GetClassProp(PropName: shortstring): TAutoObj;
begin
  result:=TAutoObj(GetObjectProp(self,PropName,TAutoObj));
end;

{function TAutoObj.GetClassPropValue(instance: TAutoObj;
  propname: shortstring): String;
begin
  Result:=GetPropValue(instance,propname );
end;}

function TAutoObj.GetClassXml(Obj: TObject): string;
begin
  if Obj is TStream then
    begin

    end;
end;

function TAutoObj.GetRTTIClassProp(PropName: shortstring): TPersistent;
begin
  result:=TPersistent(GetObjectProp(self,PropName,TPersistent));
end;

procedure TAutoObj.SetPropValue(Instance: TObject; const PropInfo: PPropInfo;
  const Value: Variant);
  function RangedValue(const AMin, AMax: Int64): Int64;
  begin
	Result := Trunc(Value);
	if Result < AMin then
	  Result := AMin;
	if Result > AMax then
	  Result := AMax;
  end;
var
  TypeData: PTypeData;
  DynArray: Pointer;
begin
  // get the prop info
  begin
	TypeData := GetTypeData(PropInfo^.PropType^);

	// set the right type
	case PropInfo.PropType^^.Kind of
	  tkInteger, tkChar, tkWChar:
		if TypeData^.MinValue < TypeData^.MaxValue then
		  SetOrdProp(Instance, PropInfo, RangedValue(TypeData^.MinValue,
			TypeData^.MaxValue))
		else
		  // Unsigned type
		  SetOrdProp(Instance, PropInfo,
			RangedValue(LongWord(TypeData^.MinValue),
			LongWord(TypeData^.MaxValue)));
	  tkEnumeration:
		if VarType(Value) = varString then
		  SetEnumProp(Instance, PropInfo, VarToStr(Value))
		else if VarType(Value) = varBoolean then
		  // Need to map variant boolean values -1,0 to 1,0
		  SetOrdProp(Instance, PropInfo, Abs(Trunc(Value)))
		else
		  SetOrdProp(Instance, PropInfo, RangedValue(TypeData^.MinValue,
			TypeData^.MaxValue));
	  tkSet:
		if VarType(Value) = varInteger then
		  SetOrdProp(Instance, PropInfo, Value)
		else
		  SetSetProp(Instance, PropInfo, VarToStr(Value));
	  tkFloat:
		SetFloatProp(Instance, PropInfo, Value);
	  tkString, tkLString:
		SetStrProp(Instance, PropInfo, VarToStr(Value));
	  tkWString:
		SetWideStrProp(Instance, PropInfo, VarToWideStr(Value));
	  tkVariant:
		SetVariantProp(Instance, PropInfo, Value);
	  tkInt64:
		SetInt64Prop(Instance, PropInfo, RangedValue(TypeData^.MinInt64Value,
		  TypeData^.MaxInt64Value));
	  tkDynArray:
		begin
		  DynArrayFromVariant(DynArray, Value, PropInfo^.PropType^);
		  SetOrdProp(Instance, PropInfo, Integer(DynArray));
		end;
	else
	  raise EPropertyConvertError.CreateResFmt(@SInvalidPropertyType,
		[PropInfo.PropType^^.Name]);
	end;
  end;
end;

class function TAutoObj.GetPropValue(Instance: TObject; const PropInfo: PPropInfo;
  PreferStrings: Boolean): Variant;
begin
  // assume failure
  Result := Null;
  // get the prop info
  begin
	// return the right type
	case PropInfo^.PropType^^.Kind of
	  tkInteger, tkChar, tkWChar, tkClass:
		Result := GetOrdProp(Instance, PropInfo);
	  tkEnumeration:
		if PreferStrings then
		  Result := GetEnumProp(Instance, PropInfo)
		else if GetTypeData(PropInfo^.PropType^)^.BaseType^ = TypeInfo(Boolean) then
		  Result := Boolean(GetOrdProp(Instance, PropInfo))
		else
		  Result := GetOrdProp(Instance, PropInfo);
	  tkSet:
		if PreferStrings then
		  Result := GetSetProp(Instance, PropInfo)
		else
		  Result := GetOrdProp(Instance, PropInfo);
	  tkFloat:
		Result := GetFloatProp(Instance, PropInfo);
	  tkMethod:
		Result := PropInfo^.PropType^.Name;
	  tkString, tkLString:
		Result := GetStrProp(Instance, PropInfo);
	  tkWString:
		Result := GetWideStrProp(Instance, PropInfo);
	  tkVariant:
		Result := GetVariantProp(Instance, PropInfo);
	  tkInt64:
		Result := GetInt64Prop(Instance, PropInfo);
	  tkDynArray:
		DynArrayToVariant(Result, Pointer(GetOrdProp(Instance, PropInfo)), PropInfo^.PropType^);
	else
	  raise EPropertyConvertError.CreateResFmt(@SInvalidPropertyType,[PropInfo.PropType^^.Name]);
	end;
  end;
end;

class function TAutoObj.GetInfo: string;
begin
  result:='本对象是所有自动化对象的根，是用来描述和记录实体对象的，'
          +'拥有自动处理Xml输出和输入的功能！'
end;

procedure TAutoObj.GetSelfXml(Superstr: TSuperstr);
var
i:integer;
propname:shortstring;
PropInf:PPropInfo;
tmpAutoObj:TAutoObj;
classmark:shortstring;
begin

  //setlength(fProps,count);
  classmark:=classname+'>';
  superstr.AddBegin;
  superstr.Append(classname);
  superstr.AddOver;
  for i:=0 to propcount-1 do
    begin
      propinf:=proplist^[i];
      propname:=propinf.Name;
      //propmark:=propname+'>';
      //生成对象特征的Xml
      if Propinf.PropType^.Kind= tkClass then
        begin
          tmpAutoObj:=GetClassProp(propname);
          if tmpAutoObj<>nil then
            begin
             superstr.AddBegin;
             superstr.Append(propname);
             superstr.AddOver;
             tmpAutoObj.GetSelfXml(superstr);
             superstr.AddEnd;
             superstr.append(propname);
             superstr.AddOver;
            end
            else superstr.Append('<'+propname+'>'+'</'+propname+'>');
        end
        else
          begin
            superstr.AddSpace;
            superstr.Append(propname);
            superstr.Addequal;
            if propinf.PropType^.Kind in [tkString, tkLString] then
            superstr.Append(GetStrProp(self,propinf)) else
            superstr.Append(GetPropValue(self,propinf));
            superstr.AddDataEnd;
          end;
    end;
  if FSubObjects.count>0 then
    begin
      superstr.append('<subs>');
      for i:=0 to FSubObjects.count-1 do
        begin
          tmpAutoObj:=GetSub(i);
          if tmpAutoObj<>nil then tmpautoobj.GetSelfXml(superstr);
        end;
      superstr.Append('</subs>');
    end;
  superstr.AddEnd;
  superstr.Append(classname);
  superstr.AddOver;

end;

function TAutoObj.GetStandXml: string;
begin
   result:=Utf8Encode(GetXml);
end;

function TAutoObj.GetSub(Index: integer): TAutoObj;
begin
  //if Index>=FSubObjects.Count then Raise Exception.Create('Index Out Of Range!');
  Result:=FsubObjects.Items[index];
end;

function TAutoObj.GetSubsCount: integer;
begin
  Result:=FSubObjects.count;
end;

function TAutoObj.GetXml: string;
var
fxml:TSuperstr;
begin
  //setlength(fProps,count);
  fxml:=TSuperstr.Create;
  GetSelfXml(fxml);
  Result:=Fxml.Value;
  fxml.Free;

end;


procedure TAutoObj.InitByXml(XmlNode:TXmlNode);
begin
  InitPropsQuick(XmlNode);
  InitSubsQuick(XmlNode.GetSubs);
end;

procedure TAutoObj.InitObjByXml(Obj:TPersistent;XmlNode:TXmlNode);
begin
  InitObjPropsQuick(Obj,XmlNode);

end;




procedure TAutoObj.InitPropsQuick(XmlNode:TXmlNode);
var
i:integer;
tmpPropInfo:PPropInfo;
tmpobj:TAutoObj;
tmpnode:Txmlnode;
begin
  try
    for i:=0 to propcount-1 do
      begin
        tmpPropInfo:=proplist^[i];
        if not(tmppropinfo.PropType^.Kind in [tkClass,tkInterface] ) then
          begin
            if tmppropinfo.SetProc<>nil then
              try
                SetPropValue(self,tmppropinfo,XmlNode.GetAttribValue(tmppropinfo.Name));
              except

              end;
          end;
        if tmppropinfo.PropType^.Kind=tkClass then
          begin
            tmpobj:=GetClassProp(tmppropinfo.Name);
            tmpnode:=xmlnode.GetChildByName(tmpPropInfo.name);
            if (tmpobj<>nil) and (tmpnode<>nil) then tmpobj.InitByXml(tmpnode.GetChild(0));
          end;
      end;
  finally

  end;
end;



procedure TAutoObj.InitSubsQuick(XmlNode:TXmlNode);
var
subcount,i:integer;
tmpobj:TAutoObj;
autoclass:Tautoobjclass;
tmpxmlnode:TXmlNode;
begin
  ClearSubObjs;
  if XmlNode=nil then exit;
  subcount:=XmlNode.GetCount;
  for i:=0 to subcount-1 do
    begin
      tmpxmlnode:=Xmlnode.GetChild(i);
      autoclass:=TautoobjClass(FindClass(tmpxmlnode.Getname));
      tmpobj:=autoclass.Create;
      AddSub(tmpobj);
      tmpobj.InitByXml(tmpxmlnode);
    end;
end;

{procedure TAutoObj.SetClassPropValue(instance: TAutoObj;
  propname: shortstring; value: variant);
begin
  SetPropValue(instance,propname,value );
end; }

procedure TAutoObj.SetStandXml(Xml: string);
begin
  SetXml(Utf8Decode(Xml));
end;

procedure TAutoObj.SetXml(Xml: string);
var
XmlEng:TXmlEngine;
begin
  XmlEng:=TXmlEngine.Create;
  XmlEng.DataXml:=Xml;
  InitByXml(xmlEng.Getroot);
  XmlEng.Free;
  //InitProps(XmlEng);
  //InitSubs(XmlEng);
end;

procedure TAutoObj.SetObjXml(Obj:TPersistent;Xml: string);
var
XmlEng:TXmlEngine;
begin
  XmlEng:=TXmlEngine.Create;
  XmlEng.DataXml:=Xml;
  InitObjByXml(Obj,xmlEng.Getroot);
  XmlEng.Free;
  //InitProps(XmlEng);
  //InitSubs(XmlEng);
end;


function TAutoObj.GetDataOf(Name: shortstring): Variant;
begin
  result:=GetPropValue(self,GetPropInfo(self,Name));
end;

procedure TAutoObj.SetDataOf(Name: shortstring; const Value: Variant);
begin
  SetPropValue(self,GetPropInfo(self,Name),Value);
end;

procedure TAutoObj.SaveXmltoFile(filename: string);
var
tmpfile:TFilestream;
data:string;
begin
  tmpfile:=TFilestream.Create(filename,fmCreate);
  try
    data:=Xml;
    tmpfile.Write(data[1],length(data));
  finally
    tmpfile.Free;
  end;
end;

procedure TAutoObj.LoadXmlfromFile(filename: string);
var
tmpfile:TFilestream;
data:string;
begin
  tmpfile:=TFilestream.Create(filename,fmOpenread);
  try
    setlength(data,tmpfile.size);
    tmpfile.read(data[1],tmpfile.Size);
    xml:=data;
  finally
    tmpfile.Free;
  end;
end;

class function TAutoObj.GetMirrorofProp(Propname: shortstring): shortstring;
var
i:integer;
begin
  //Result:='没有找到特征';
  Result:=Propname;
  for i:=0 to high(PropMirrors) do
    begin
      if PropMirrors[i].PropName=Propname then
        begin
          Result:=PropMirrors[i].Title;
          exit;
        end;
    end;
end;

class function TAutoObj.GetPropofMirror(Mirror: shortstring): shortstring;
var
i:integer;
begin
  result:=Mirror;
  for i:=0 to high(PropMirrors) do
    begin
      if PropMirrors[i].Title=Mirror then
        begin
          Result:=PropMirrors[i].PropName;
          exit;
        end;
    end;
  //Exception.Create('没有找到特征名为'+Mirror+'的特征！');
end;




procedure TUniqueObj.Setobjid(const Value: shortstring);
begin
  try

    Fobjid:=stringtoguid(Value);
  except
    raise Exception.Create('Objid must a Guid!');
  end;
end;

class function TUniqueObj.GetInfo: string;
begin
  result:='本对象是所有唯一化对象的根，是用来描述和记录实体对象的，'
          +'用唯一ID(property objid 数据类型Guid)来表示实体唯一性，'
          +' 继承来自TAutoObj';
end;



class function TAutoObj.GetNewId: shortstring;
var
tmpguid:Tguid;
begin
  inherited;
  CreateGuid(Tmpguid);
  Result:=Guidtostring(tmpguid);
end;


class function TAutoObj.GetSearchofProp(
  Propname: shortstring): shortstring;
var
i:integer;
begin
  result:=Propname;
  for i:=0 to high(PropMirrors) do
    begin
      if PropMirrors[i].PropName=Propname then
        begin
          Result:=PropMirrors[i].SearchClass;
          exit;
        end;
    end;
END;

class procedure TAutoObj.CopyArraydata(ArraySrc: TDynamicData;
  SrcOffset: integer; ArrayDes: TDynamicData; DesOffset, size: integer);
var
i:integer;
offset:integer;
begin
  offset:=0;
 { for i:=0 to (size div 4) do
    begin
      ArrayDes[DesOffset+offset]:=ArraySrc[SrcOffset+offset] ;
      inc(offset,4);
    end;  }
  for i:=0 to size-1 do
    begin
      ArrayDes[Desoffset+offset]:=ArraySrc[SrcOffset+offset];
      inc(offset);
    end;

end;

class function TAutoObj.GetHash(Data: TDynamicData): integer;
var
i:integer;
size:integer;
tmpdata:integer;
begin
  result:=0;
  size:=length(Data);
  for i:=0 to (size div 4)  do
    begin
      if (size-i*4) >=4 then
        move(Data[i*4],tmpdata,4)
      else move(Data[i*4],tmpdata,size-i*4);
      result:=result+ABS(tmpdata div ((i+11)*(i+29)*(i+71)*(i+109)+1))+1;
    end;

end;

class function TAutoObj.GetObjXml(Obj: TPersistent): string;
var
fxml:TSuperstr;
begin
  fxml:=TSuperstr.Create;
  GetXmlOfobj(Obj,fxml);
  Result:=Fxml.Value;
  fxml.Free;
end;



class procedure TAutoObj.GetXmlOfObj(Obj: TPersistent; Superstr: TSuperstr);
var
i:integer;
propname:shortstring;
PropInf:PPropInfo;
tmpAutoObj:TPersistent;
classmark:shortstring;
propcount:integer;
proplist:PProplist;
begin

  //setlength(fProps,count);
  propcount:=GetProplist(Obj,proplist);
  classmark:=obj.classname+'>';
  superstr.AddBegin;
  superstr.Append(obj.classname);
  superstr.AddOver;
  for i:=0 to propcount-1 do
    begin
      propinf:=proplist^[i];
      propname:=propinf.Name;
      //propmark:=propname+'>';
      //生成对象特征的Xml
      if Propinf.PropType^.Kind= tkClass then
        begin
          tmpAutoObj:=TPersistent(GetObjectProp(Obj,PropName,TPersistent));
          if tmpAutoObj<>nil then
            begin
             superstr.AddBegin;
             superstr.Append(propname);
             superstr.AddOver;
             GetXmlofObj(tmpAutoObj,superstr);
             superstr.AddEnd;
             superstr.append(propname);
             superstr.AddOver;
            end
            else superstr.Append('<'+propname+'>'+'</'+propname+'>');
        end
        else
          if Propinf.PropType^.Kind<>tkMethod  then
            begin
              superstr.AddSpace;
              superstr.Append(propname);
              superstr.Addequal;
              if propinf.PropType^.Kind in [tkString, tkLString] then
              superstr.Append(GetStrProp(Obj,propinf)) else
              superstr.Append(GetPropValue(obj,propinf));
              superstr.AddDataEnd;
            end;
    end;
  {if FSubObjects.count>0 then
    begin
      superstr.append('<subs>');
      for i:=0 to FSubObjects.count-1 do
        begin
          tmpAutoObj:=GetSub(i);
          if tmpAutoObj<>nil then tmpautoobj.GetSelfXml(superstr);
        end;
      superstr.Append('</subs>');
    end; }
  superstr.AddEnd;
  superstr.Append(obj.classname);
  superstr.AddOver;

end;

procedure TAutoObj.InitObjPropsQuick(Obj: TPersistent; XmlNode: TXmlNode);
var
i:integer;
tmpPropInfo:PPropInfo;
tmpobj:TPersistent;
tmpfont:TFont;
tmpnode:Txmlnode;
propcount:integer;
proplist:PProplist;
begin
  propcount:=GetProplist(Obj,proplist);
  try
    for i:=0 to propcount-1 do
      begin
        tmpPropInfo:=proplist^[i];
        if not(tmppropinfo.PropType^.Kind in [tkClass,tkInterface,tkMethod] ) then
          begin
            if tmppropinfo.SetProc<>nil then
              try
                SetPropValue(obj,tmppropinfo,XmlNode.GetAttribValue(tmppropinfo.Name));
              except
                //raise;
              end;
          end;
        if tmppropinfo.PropType^.Kind=tkClass then
          begin
            tmpobj:=TPersistent(GetObjectProp(obj,tmppropinfo.name,TPersistent));
            tmpnode:=xmlnode.GetChildByName(tmpPropInfo.name);
            if (tmpobj<>nil) and (tmpnode<>nil) then
              begin
                if (obj is TControl) and (tmpobj is TFont) then
                  begin
                    try
                      tmpfont:=TFont.Create;
                      InitobjByXml(tmpfont,tmpnode.GetChild(0));
                      TFont(tmpobj).Assign(tmpfont);
                    finally
                      tmpfont.Free;
                    end;
                  end else
                    begin
                      InitobjByXml(tmpobj,tmpnode.GetChild(0));
                    end;
              end;
          end;
      end;
  finally
    if propcount<>0 then  dispose(proplist);
  end;
end;

function TAutoObj.GetSize: integer;
var
i:integer;
propinfo:PPropinfo;
begin
  Result:=0;
  for i:=0 to propcount-1 do
    begin
      propinfo:=Proplist^[i];
      case propinfo^.PropType^.Kind of
        tkInteger:Result:=Result+sizeof(integer);
        tkChar:Result:=Result+sizeof(Char);
        tkFloat:Result:=Result+sizeof(Double);
        tkString:Result:=Result+sizeof(integer);
        tkClass:Result:=Result+GetClassProp(propinfo.Name).GetSize;
        tkWChar:Result:=Result+sizeof(widechar);
        tkLString:Result:=Result+length(string(self.GetDataOf(propinfo.Name)));
        tkWString:Result:=Result+2*length(widestring(self.GetDataOf(propinfo.Name)));
        tkInt64:Result:=Result+8;
      end;
    end;

  Result:=Result+GetSubSize;
end;

function TAutoObj.GetSubSize: integer;
var
i:integer;
begin
  Result:=0;
  for i:=0 to Subscount-1 do
    begin
      Result:=Result+Getsub(i).GetSize;
    end;
end;

{ TDataCheck }

procedure TDataCheck.DoCheck;
begin

end;

procedure TDataCheck.SetCheckType(const Value: TCheckType);
begin
  FCheckType := Value;
end;


procedure TDataCheck.SetRange(const Value: string);
begin
  FRange := Value;
end;

{ TDataDef }

constructor TDataDef.Create;
begin
  inherited Create;
  Datatype:=dtString;
  Size:=20;
  Check:=TDataCheck.Create;
  //Check.Range:='0-1000';
  Check.CheckType:=ctBetween;
  //DataSource:=dtManual;
  
end;

destructor TDataDef.Destroy;
begin
  fCheck.Free;
  inherited;
end;

function TDataDef.GetAllocSize: integer;
begin
  case FDataType of
    dtString:
      begin
        result:=size+2;
      end;
    dtSmallint:
      begin
        result:=size;
      end;
    dtInteger:
      begin
        result:=size;
      end;
    dtWord:
      begin
        result:=size;
      end;
    dtBoolean:
      begin
        result:=size;
      end;
    dtFloat:
      begin
        result:=size;
      end;
    dtCurrency:
      begin
        result:=size;
      end;
    dtDateTime:
      begin
        result:=size;
      end;
    dtBlob:
      begin
        result:=size;
      end;
    dtGuid:
      begin
        result:=size;
      end;
    dtInt64:
      begin
        result:=size;
      end;
    else raise exception.Create('Incorrect type defined!');
  end;
end;

function TDataDef.GetDatatype: TDataType;
begin
  Result:=fDatatype;
end;

function TDataDef.GetPackedData(DataPack: TDynamicData;
  OffSet:integer): TDynamicData;
var
  tmpid:TGuid;
  tmpword:Word;
  tmpboolean:boolean;
  tmpstr:string;
  tmpsmallint:smallint;
  tmpint64:Int64;
  tmpDouble:Double;
  tmpcurrency:currency;
  tmpdatetime:Tdatetime;
  tmpint:integer;
  strsize:word;
begin
  case FDataType of
    dtString:
      begin
        move(DataPack[offset],strsize,2);
        setlength(result,strsize+2);
        //move(DataPack[offset],result[0],strsize+2);
        copyArrayData(DataPack,offset,result,0,strsize+2);
      end;
    dtSmallint:
      begin
        setlength(result,sizeof(smallint));
        move(DataPack[offset],Result[0],size);
      end;
    dtInteger:
      begin
        setlength(result,sizeof(integer));
        move(DataPack[offset],Result[0],size);
      end;
    dtWord:
      begin
        setlength(result,sizeof(word));
        move(DataPack[offset],Result[0],size);
      end;
    dtBoolean:
      begin
        setlength(result,sizeof(boolean));
        move(DataPack[offset],Result[0],size);
      end;
    dtFloat:
      begin
        setlength(result,sizeof(Double));
        move(DataPack[offset],Result[0],size);
      end;
    dtCurrency:
      begin
        setlength(result,sizeof(Currency));
        move(DataPack[offset],Result[0],size);
      end;
    dtDateTime:
      begin
        setlength(result,sizeof(TDatetime));
        move(DataPack[offset],Result[0],size);
      end;
    dtBlob:
      begin
        Raise Exception.Create('Blob Data Can not Send to Variant,'
        +'must use Stream to attach Blob Data!');
      end;
    dtGuid:
      begin
        setlength(result,sizeof(TGuid));
        move(DataPack[offset],Result[0],size);
      end;
    dtInt64:
      begin
        setlength(result,sizeof(Int64));
        move(DataPack[offset],Result[0],size);
      end;
  end;
end;

function TDataDef.GetSize: integer;
begin
  Result:=fsize;
end;

function TDataDef.GetStringValue(DataPack: TDynamicData;
  OffSet: integer): string;
var
  tmpid:TGuid;
  tmpword:Word;
  tmpboolean:boolean;
  tmpstr:string;
  tmpsmallint:smallint;
  tmpint64:Int64;
  tmpDouble:Double;
  tmpcurrency:currency;
  tmpdatetime:Tdatetime;
  tmpint:integer;
  strsize:word;
begin
  case FDataType of
    dtString:
      begin
        move(DataPack[offset],strsize,2);
        setlength(tmpstr,strsize);
        move(DataPack[offset+2],tmpstr[1],strsize);
        result:=tmpstr;
      end;
    dtSmallint:
      begin
        move(DataPack[offset],tmpsmallint,size);
        result:=inttostr(tmpsmallint);
      end;
    dtInteger:
      begin
        move(DataPack[offset],tmpInt,size);
        result:=inttostr(tmpint);
      end;
    dtWord:
      begin
        move(DataPack[offset],tmpWord,size);
        result:=inttostr(tmpword);
      end;
    dtBoolean:
      begin
        move(DataPack[offset],tmpBoolean,size);
        result:=booltostr(tmpBoolean);
      end;
    dtFloat:
      begin
        move(DataPack[offset],tmpdouble,size);
        result:=floattostr(tmpdouble);
      end;
    dtCurrency:
      begin
        move(DataPack[offset],tmpcurrency,size);
        result:=currtostr(tmpcurrency);
      end;
    dtDateTime:
      begin
        move(DataPack[offset],tmpDatetime,size);
        result:=Datetimetostr(tmpDatetime);
      end;
    dtBlob:
      begin
        Raise Exception.Create('Blob Data Can not Send to Variant,'
        +'must use Stream to attach Blob Data!');
      end;
    dtGuid:
      begin
        move(DataPack[offset],tmpid,size);
        result:=Guidtostring(tmpid);
      end;
    dtInt64:
      begin
        move(DataPack[offset],tmpint64,size);
        result:=inttostr(tmpint64);
      end;

  end;
end;

function TDataDef.GetValue(DataPack:TDynamicData;OffSet:integer): Variant;
var
  tmpid:TGuid;
  tmpword:Word;
  tmpboolean:boolean;
  tmpstr:string;
  tmpsmallint:smallint;
  tmpint64:Int64;
  tmpDouble:Double;
  tmpcurrency:currency;
  tmpdatetime:Tdatetime;
  tmpint:integer;
  strsize:word;
begin
  case FDataType of
    dtString:
      begin
        move(DataPack[offset],strsize,2);
        setlength(tmpstr,strsize);
        move(DataPack[offset+2],tmpstr[1],strsize);
        result:=tmpstr;
      end;
    dtSmallint:
      begin
        move(DataPack[offset],tmpsmallint,size);
        result:=tmpsmallint;
      end;
    dtInteger:
      begin
        move(DataPack[offset],tmpInt,size);
        result:=tmpint;
      end;
    dtWord:
      begin
        move(DataPack[offset],tmpWord,size);
        result:=tmpword;
      end;
    dtBoolean:
      begin
        move(DataPack[offset],tmpBoolean,size);
        result:=tmpBoolean;
      end;
    dtFloat:
      begin
        move(DataPack[offset],tmpdouble,size);
        result:=tmpdouble;
      end;
    dtCurrency:
      begin
        move(DataPack[offset],tmpcurrency,size);
        result:=tmpcurrency;
      end;
    dtDateTime:
      begin
        move(DataPack[offset],tmpDatetime,size);
        result:=tmpDatetime;
      end;
    dtBlob:
      begin
        Raise Exception.Create('Blob Data Can not Send to Variant,'
        +'must use Stream to attach Blob Data!');
      end;
    dtGuid:
      begin
        move(DataPack[offset],tmpid,size);
        result:=Guidtostring(tmpid);
      end;
    dtInt64:
      begin
        move(DataPack[offset],tmpint64,size);
        result:=tmpint64;
      end;

  end;
end;

procedure TDataDef.SetCheck(const Value: TDataCheck);
begin
  if FCheck<>Value then
    begin
      FCheck.Free;
      FCheck := Value;
    end;
end;

procedure TDataDef.SetDataSource(const Value: TDataSrcType);
begin
  FDataSource := Value;
end;

procedure TDataDef.SetDatatype(const Value: TDataType);
begin
  case Value of
    dtString:if FDatatype<>Value then size:=20;
    dtSmallint:size:=2;
    dtInteger:size:=4;
    dtWord:size:=2;
    dtBoolean:size:=sizeof(Boolean);
    dtFloat:size:=sizeof(Double);
    dtCurrency:size:=sizeof(currency);
    dtBCD:size:=sizeof(Tbcd);
    dtDateTime:size:=sizeof(TDateTime);
    dtBlob:size:=sizeof(TObject);
    dtGuid:size:=8;
    dtInt64:size:=8;
  end;
  FDatatype := Value;
end;

function  TDataDef.SetPackedData(DataPack: TDynamicData; Offset: integer;
          PackedData:TDynamicData;PackStart:integer):integer;
var
  strsize:word;
begin
  case FDataType of
    dtString:
      begin
        move(PackedData[PackStart],strsize,sizeof(word));
        if strsize>size then raise Exception.Create('The Data is to large');
        move(strsize,Datapack[offset],sizeof(word));
        move(packedData[PackStart+sizeof(word)],DataPack[offset+sizeof(word)],strsize);
        result:=strsize+sizeof(word);
      end;
    dtSmallint:
      begin
        move(packedData[PackStart],DataPack[offset],size);
        result:=size;
      end;
    dtInteger:
      begin
        move(packedData[PackStart],DataPack[offset],size);
        result:=size;
      end;
    dtWord:
      begin
        move(packedData[PackStart],DataPack[offset],size);
        result:=size;
      end;
    dtBoolean:
      begin
        move(packedData[PackStart],DataPack[offset],size);
        result:=size;
      end;
    dtFloat:
      begin
        move(packedData[PackStart],DataPack[offset],size);
        result:=size;
      end;
    dtCurrency:
      begin
        move(packedData[PackStart],DataPack[offset],size);
        result:=size;
      end;
    dtDateTime:
      begin
        move(packedData[PackStart],DataPack[offset],size);
        result:=size;
      end;
    dtBlob:
      begin
        Raise Exception.Create('Blob Data Can not Send to Variant,'
        +'must use Stream to attach Blob Data!');
      end;
    dtGuid:
      begin
        move(packedData[PackStart],DataPack[offset],size);
        result:=size;
      end;
    dtInt64:
      begin
        move(packedData[PackStart],DataPack[offset],size);
        result:=size;
      end;
  end;
end;


procedure TDataDef.SetPrecision(const Value: integer);
begin
  FPrecision := Value;
end;

procedure TDataDef.SetSize(Value: integer);
begin
  FSize := Value;
end;

procedure TDataDef.SetTitle(const Value: shortstring);
begin
  FTitle := Value;
end;

procedure TDataDef.SetValue(DataPack: TDynamicData; OffSet: integer;
  value: Variant);
var
  tmpid:TGuid;
  tmpword:Word;
  tmpboolean:boolean;
  tmpstr:string;
  tmpsmallint:smallint;
  tmpint64:Int64;
  tmpDouble:Double;
  tmpcurrency:currency;
  tmpdatetime:Tdatetime;
  tmpint:integer;
  i:integer;
  strsize:integer;
begin
  case FDataType of
    dtString:
      begin
        tmpstr:=Value;
        strsize:=length(tmpstr);
        move(word(strsize),DataPack[offset],2);
        move(tmpstr[1],DataPack[offset+2],strsize);
      end;
    dtSmallint:
      begin
        tmpsmallint:=value;
        move(tmpsmallint,DataPack[offset],size);
      end;
    dtInteger:
      begin
        tmpint:=value;
        move(tmpint,DataPack[offset],size);
      end;
    dtWord:
      begin
        tmpword:=value;
        move(tmpword,DataPack[offset],size);
      end;
    dtBoolean:
      begin
        tmpboolean:=value;
        move(tmpboolean,DataPack[offset],size);
      end;
    dtFloat:
      begin
        tmpdouble:=value;
        move(tmpdouble,DataPack[offset],size);
      end;
    dtCurrency:
      begin
        tmpcurrency:=value;
        move(tmpcurrency,DataPack[offset],size);
      end;
    dtDateTime:
      begin
        tmpDatetime:=value;
        move(tmpDatetime,DataPack[offset],size);
      end;
    dtBlob:
      begin
        Raise Exception.Create('Blob Data Can not Send to Variant,'
        +'must use Stream to attach Blob Data!');
      end;
    dtGuid:
      begin
        tmpid:=StringToguid(value);
        move(tmpid,DataPack[offset],size);
      end;
    dtInt64:
      begin
        tmpint64:=Value;
        move(tmpint64,DataPack[offset],size);
      end;
  end;
end;

{ TNamedObj }

class function TNamedObj.GetInfo: string;
begin
  result:='本对象是所有唯一化命名对象的根，是用来描述和记录带名称的实体对象，'
          +'用名称(property Name 数据类型shortstring)来表示实体名称，'
          +'继承来自TUniqueObj';
end;

function TNamedObj.GetName: shortstring;
begin
  result:=fName;
end;

procedure TNamedObj.SetName(const Value: shortstring);
begin
  FName := Value;
  FHash:=GetStringHash(Name)
end;

{ TAutoContainer }

procedure TAutoContainer.Add(Obj: TAutoObj);
begin
  if FAutoClass=nil then raise Exception.Create('Have not Set the Container Class!');
  if Obj is FAutoClass then
  inherited AddSub(Obj)
   else raise Exception.Create('The AutoObj add to Container is Incorrect Typed!');
end;  

{procedure TAutoContainer.AddSub(Obj: TAutoObj);
begin
  if FAutoClass=nil then raise Exception.Create('Have not Set the Container Class!');
  if Obj is FAutoClass then
  inherited AddSub(Obj)
  //   else raise Exception.Create('The AutoObj add to Container is Incorrect Typed!');
end; }

function TAutoContainer.GetSub(Index: integer): TAutoObj;
begin
  //if Index>=FSubObjects.Count then Raise Exception.Create('Index Out Of Range!');
  Result:=FsubObjects.Items[index];
end;

procedure TAutoContainer.ClearContainer;
begin
  ClearSubObjs;
  fPos:=-1;
end;

function TAutoContainer.ContainerCount: integer;
begin
  result:=SubsCount;
end;

constructor TAutoContainer.Create;
begin
  inherited;
  FSubObjects:=TList.Create;
  fPos:=-1;
  InitContainerClass;
end;

procedure TAutoContainer.Delete;
var
tmpobj:TAutoObj;
begin
  if fPos=-1 then raise Exception.Create('The Container is empty');
  tmpobj:=Getsub(Pos);
  tmpobj.Free;
  FSubObjects.Delete(Pos);
  if Pos=ContainerCount then Pos:=Pos-1;
end;

function TAutoContainer.Get(Index: integer): TAutoObj;
begin
  Result:=GetSub(Index);
end;

function TAutoContainer.GetObj: TAutoObj;
begin
  result:=GetSub(Pos);
end;

function TAutoContainer.GetSubObj(Index: integer): TAutoObj;
begin
  Result:=GetSub(Index);
end;

procedure TAutoContainer.InitContainerClass;
begin
  FAutoClass:=TAutoObj;
end;

procedure TAutoContainer.ClearSubObjs;
var
i:integer;
Obj:TAutoObj;
begin
  for i:=0 to FSubObjects.Count-1 do
    begin
      Obj:=FSubObjects.items[i];
      if Obj<>nil then Obj.Free;
    end;
  FSubObjects.Clear;
end;


function TAutoContainer.NewSub:TAutoObj;
begin
  Result:=FAutoClass.Create;
  AddSub(Result);
  fPos:=containercount-1;
end;

procedure TAutoContainer.SetAutoClass(const Value: TAutoObjClass);
begin
  FAutoClass := Value;
end;

procedure TAutoContainer.SetPos(const Value: integer);
begin
  if (Value=-1) and (containercount>0) then raise exception.Create('there are data in container,can not move to -1');
  if Value<self.ContainerCount then FPos := Value;
end;

destructor TAutoContainer.Destroy;
begin
  ClearSubObjs;
  FSubObjects.Free;
  inherited;
end;

{ TStreamObj }

function TStreamObj.GetXml: string;
begin
  if FStream<>nil then
    begin
      if FStream.Size>0 then
        begin

        end;
    end;
end;

procedure TStreamObj.SetStream(const Value: TStream);
begin
  FStream := Value;
end;

{ TAutoStruc }



{ TAutoStruc }



constructor TAutoStruc.Create;
begin
  inherited Create;
  FDefs:=TDataDefContainer.Create;
  FStrucContainer:=TStrucContainer.Create;
  FActive:=false;
end;

destructor TAutoStruc.Destroy;
begin
  FDefs.Free;
  FStrucContainer.Free;
  inherited;
end;

function TAutoStruc.GetAllocSize: integer;
var
i:integer;
begin
  Result:=0;
  for i:=0 to Defs.ContainerCount-1 do
    begin
      Result:=Result+((Defs.GetSub(i))as TDataDef).GetAllocSize;
    end;
 
end;

function TAutoStruc.GetDataTypeof(Index: integer): TDataType;
begin
  result:=(FDefs.GetSub(index) as TDataDef).Datatype;
end;

function TAutoStruc.GetIndexOf(Name: shortstring): integer;
var
i:integer;
hashcode:integer;
begin
  if fActive then
    begin
      hashcode:=GetStringHash(Name);
      for i:=0 to Length(StrucInfos)-1 do
        begin
          {if StrucInfos[i].DataDef.Name=Name then
            begin
               result:=i;
               exit;
            end; }
         if StrucInfos[i].HashCode=hashcode then
            begin
               result:=i;
               exit;
            end;
        end;
        raise Exception.Create('Can not find DataDef of '+Name+'!');
    end else raise Exception.Create('Must Init Struc of DynamicContainer!');
end;

function TAutoStruc.GetDataValue(DataPack: TDynamicData; Index: integer):variant;
begin

end;

function TAutoStruc.GetOffSetof(Index: integer): integer;
var
i:integer;
begin
  Result:=0;
  if Index>(Defs.ContainerCount-1) then raise exception.Create('Index out of  Defs count');
  for i:=0 to Index-1 do
    begin
      result:=result+(FDefs.GetSub(i) as TDataDef).GetAllocSize;
    end;

end;

function TAutoStruc.GetSizeof(Index: integer): integer;
begin
  Result:=0;
  if Index>(FDefs.ContainerCount-1) then raise exception.Create('Index out of  Defs count');
  result:=(FDefs.GetSub(index) as TDataDef).Size;

end;

procedure TAutoStruc.InitStruc;
var
i:integer;
begin
  SetLength(StrucInfos,Defs.ContainerCount);
  for i:=0 to Length(StrucInfos)-1 do
    begin
      StrucInfos[i].DataDef:=TDataDef(Defs.GetSub(i));
      StrucInfos[i].OffSet:=GetOffSetof(i);
      StrucInfos[i].HashCode:=GetStringHash(StrucInfos[i].DataDef.Name);
    end;
  for i:=0 to fStrucContainer.ContainerCount-1 do
    begin
      (fStrucContainer.GetSub(i) as TAutoStruc).initstruc;
    end;
  fActive:=true;
end;

procedure TAutoStruc.SetDataValue(DataPack: TDynamicData; Index: integer;
  Data: Variant);
begin

end;

function TAutoStruc.GetStringHash(str: shortstring): integer;
var
i:integer;
ascode:byte;
begin
  result:=0;
  for i:=1 to byte(str[0]) do
    begin
      ascode:=byte(str[i]);
      Result:=Result+((ascode*primenumber[i-1]*I) div 2+1);
    end;
end;

function TAutoStruc.GetDataDef(Index: integer): TDataDef;
begin
  result:=nil;
  if FActive then Result:=Strucinfos[Index].DataDef;
end;

function TAutoStruc.GetDataOffset(Index: integer): integer;
begin
  if fActive then Result:=Strucinfos[Index].OffSet
    else Raise Exception.Create('Must Init Struc of DynamicContainer!');
end;

procedure TAutoStruc.SetIsVirtual(const Value: boolean);
begin
  FIsVirtual := Value;
end;

{ TDatadefContainer }







procedure TAutoStruc.InitByXml(XmlNode: TXmlNode);
begin
  inherited;
  InitStruc;
end;

{ TStrucContainer }

constructor TStrucContainer.Create;
begin
  inherited;
  
end;

function TStrucContainer.GetStrucbyName(name: shortstring): TAutoStruc;
var
i:integer;
Struc:TAutoStruc;
begin
  for i:=0 to ContainerCount do
    begin
      Struc:=TAutoStruc(GetSubObj(i));
      if Struc.name=name then
        begin
          result:=Struc;
          exit;
        end;
    end;
  Raise Exception.Create('Can not find Struc '+name);
end;

procedure TStrucContainer.InitContainerClass;
begin
  FAutoClass:=TAutoStruc;
end;

procedure TStrucContainer.SetName(const Value: string);
begin
  FName := Value;
end;




{ TDynamicObj }

constructor TDynmObj.Create;
begin
  inherited Create;
  fInited:=false;
  Objtype:=otInsert;
end;

function TDynmObj.GetData(Index: integer): Variant;
begin
  if fInited then Result:=fStructure.GetDataDef(Index).GetValue(fData,
    fStructure.GetDataOffset(Index)) else raise exception.Create('Must set struc first');
end;

function TDynmObj.GetStringData(Index: integer): string;
begin
  if fInited then Result:=fStructure.GetDataDef(Index).GetStringValue(fData,
    fStructure.GetDataOffset(Index)) else raise exception.Create('Must set struc first');
end;

function TDynmObj.GetDataOf(Name: shortstring): Variant;
begin
  Result:=GetData(Fstructure.GetIndexOf(Name));
end;



procedure TDynmObj.GetSelfXml(Superstr: TSuperstr);
var
i:integer;
propname:shortstring;
tmpAutoObj:TAutoObj;
classmark:shortstring;
tmpdef:TDataDef;
begin
  //setlength(fProps,count);
  classmark:=classname+'>';
  superstr.AddBegin;
  superstr.Append(classmark);
  for i:=0 to fStructure.Defs.ContainerCount-1 do
    begin
      tmpdef:=fStructure.GetDataDef(i);
      propname:=tmpdef.Name;
      superstr.AddSpace;
      superstr.Append(propname);
      superstr.Addequal;
      superstr.Append(GetStringData(i));
      superstr.AddDataEnd;
    end;
  if SubsCount>0 then
    begin
      superstr.append('<subs>');
      for i:=0 to Subscount-1 do
        begin
          tmpAutoObj:=GetSub(i);
          if tmpAutoObj<>nil then tmpautoobj.GetSelfXml(superstr);
        end;
      superstr.Append('</subs>');
    end;
  superstr.AddEnd;
  superstr.Append(classmark);
end;

procedure TDynmObj.InitbyContainer(Container: TDynamicContainer);
begin
  //fContainer:=Container;
  initbyStruc(Container.Structure);
end;

procedure TDynmObj.InitbyStruc(Structure: TAutoStruc);
var
tmpcontainer:TDynamiccontainer;
i:integer;
begin
  if length(fdata)=0 then SetLength(fData,Structure.GetAllocSize);
  for i:=0 to Structure.SubStrucs.ContainerCount-1 do
    begin
      tmpcontainer:=TDynamiccontainer.CreatebyStructure(TAutoStruc(Structure.substrucs.getsub(i)));
      AddSub(tmpcontainer);
    end;
  fStructure:=Structure;
  fInited:=true;
end;

procedure TDynmObj.SetData(Index: integer; value: variant);
begin
  if fInited then  fStructure.GetDataDef(Index).SetValue(fData,
    fStructure.GetDataOffset(Index),value) else raise exception.Create('Must set struc first');
end;

procedure TDynmObj.SetDataOf(Name: shortstring; const Value: Variant);
begin
  SetData(fstructure.GetIndexOf(Name),value);
end;

{ TDynamicContainer }

constructor TDynamicContainer.Create;
begin
  inherited;
  FStructure:=TAutoStruc.Create;
  fInitedbyStructure:=false;
  fActive:=false;
  fIsAcid:=true;
end;

constructor TDynamicContainer.CreatebyXml(Xml: string);
begin
  Create;
  fStructure.Xml:=Xml;
  initContainer;
end;

destructor TDynamicContainer.Destroy;
begin
  if not(fInitedbyStructure) then FStructure.Free;
  inherited;
end;

function TDynamicContainer.GetAllocSize: integer;
begin
  Result:=FAllocSize;
end;

function TDynamicContainer.GetDataDef(Index: integer): TDataDef;
begin
  if fActive then Result:=Strucinfos[Index].DataDef
    else Raise Exception.Create('Must Init Struc of DynamicContainer!');
end;

function TDynamicContainer.GetDataOffset(Index: integer): integer;
begin
  if fActive then Result:=Strucinfos[Index].OffSet
    else Raise Exception.Create('Must Init Struc of DynamicContainer!');
end;

function TDynamicContainer.GetDefCount: integer;
begin
  result:=length(strucinfos)
end;



function TDynamicContainer.GetStringHash(str: shortstring): integer;
var
i:integer;
ascode:byte;
begin
  result:=0;
  for i:=1 to byte(str[0]) do
    begin
      ascode:=byte(str[i]);
      Result:=Result+((ascode*primenumber[i-1]*I) div 2+1);
    end;
end;

procedure TDynamicContainer.InitSubsQuick(XmlNode:TXmlNode);
var
subcount,i:integer;
tmpobj:TDynmObj;
tmpxmlnode:TXmlNode;
begin
  ClearSubObjs;
  if XmlNode=nil then exit;
  subcount:=XmlNode.GetCount;
  for i:=0 to subcount-1 do
    begin
      tmpxmlnode:=Xmlnode.GetChild(i);
      //autoclass:=TautoobjClass(FindClass(tmpxmlnode.Getname));
      tmpobj:=NewData;
      //tmpobj.InitbyContainer(self);
      tmpobj.InitByXml(tmpxmlnode);

    end;
end;

function TDynamicContainer.GetStructureXml: string;
begin
  Result:=FStructure.Xml;
end;

procedure TDynamicContainer.InitContainer;
begin
  ClearContainer;
  fStructure.InitStruc;
  FAllocSize:=fStructure.GetAllocSize;
  FActive:=true;
  SetLength(fData,0);
end;

function TDynamicContainer.NewData: TDynmObj;
begin
  if FActive then
    begin
      result:=TDynmobj(NewSub);
      ResetData;
      result.InitObjData(fData[Pos]);
      result.InitbyContainer(Self);
    end else raise Exception.Create('Must set Struc first');
end;

procedure TDynamicContainer.SetStructure(const Value: TAutoStruc);
begin
  FStructure := Value;
  InitContainer;
end;

procedure TDynamicContainer.SetStructureXml(const Value: string);
begin
  FStructure.Xml:=Value;
  Initcontainer;
end;

procedure TDynamicContainer.SetXml(Xml: string);
begin
  inherited;
 
end;

procedure TDynamicContainer.InitPropsQuick(XmlNode: TXmlNode);
begin
  inherited;
  InitContainer;
end;

procedure TDynamicContainer.InitContainerClass;
begin
  FAutoClass:=TDynmObj;
end;

procedure TDynamicContainer.ResetData;
begin
  if length(fData)<containercount+1 then SetLength(fData,containercount+containercount div 4+1,FAllocsize);
end;

constructor TDynamicContainer.CreatebyStructure(Structure: TAutoStruc);
begin
  inherited Create;
  if Structure=nil then
    begin
      create;
      exit;
    end;
  FStructure:=Structure;
  fInitedbyStructure:=true;
  InitContainer;
  fIsAcid:=true;
end;

procedure TDynamicContainer.SaveToFile(FileName: string);
var
DataStream:TFileStream;
StrucXml:string;
StrucSize:integer;
DataSize:integer;
i:integer;
tmpData:TDynamicData;
tmpobj:TDynmObj;
begin
  if not fActive then Raise Exception.Create('must init container before save to disk');
  DataStream:=TFileStream.Create(FileName,fmCreate,fmShareDenyWrite);
  try
    DataStream.Seek(0,soFromBeginning);
    DataStream.Size:=0;
    StrucXml:=Structure.GetXml;
    StrucSize:=Length(StrucXml);
    DataStream.Write(StrucSize,sizeof(integer));
    Datasize:=Containercount;
    DataStream.Write(DataSize,sizeof(integer));
    DataStream.Write(StrucXml[1],strucSize);
    For i:=0 to Containercount-1 do
      begin
        //tmpData:=fData[i];
        tmpObj:=GetDynmObj(i);
        if tmpObj.Objtype=otDelete then
          begin
            Dec(DataSize);
          end else DataStream.Write(fData[i,0],FAllocsize);
      end;
    DataStream.Seek(sizeof(integer),soFromBeginning);
    DataStream.Write(DataSize,sizeof(integer));
  finally
    DataStream.Free;
  end;

end;

procedure TDynamicContainer.LoadFromFile(FileName: string);
var
DataStream:TFileStream;
StrucXml:string;
StrucSize:integer;
Datasize,i:integer;
tmpdata:TDynmObj;
begin
  if not fActive then Raise Exception.Create('must init container before save to disk');
  DataStream:=TFileStream.Create(FileName,fmOpenRead,fmShareDenyWrite);
  try
    DataStream.Seek(0,soFromBeginning);
    //DataStream.Size:=0;
    DataStream.Read(StrucSize,sizeof(integer));
    SetLength(StrucXml,StrucSize);
    DataStream.Read(DataSize,sizeof(integer));
    DataStream.Read(StrucXml[1],strucSize);
    fStructure.SetXml(StrucXml);
    initContainer;
    for i:=0 to Datasize-1 do
      begin
        tmpdata:=NewData;
        DataStream.Read(fdata[Pos,0],fAllocsize);
        tmpdata.Objtype:=otNone;
      end;
  finally
    DataStream.Free;
  end;

end;

function TDynamicContainer.GetDynmObj(Index: integer):TDynmObj;
begin
  result:=TDynmObj(GetSub(Index));
end;

procedure TDynamicContainer.SavetoBlockContainer(DataPoolName: string);
var
BlockContainer:TBlockContainer;
i:integer;
tmpobj:TDynmObj;
begin
  BlockContainer:=TBlockcontainer.CreateDataPool(DataPoolName);
  try
  if FActive then
    begin
      //Blockcontainer.RootBlock.AppendData(Structure.xml);
      for i:=0 to containercount-1 do
        begin
          tmpobj:=GetDynmObj(i);
          Blockcontainer.AppendData(tmpobj.GetPackData);
        end;
    end;
  finally
    Blockcontainer.Free;
  end;
end;

procedure TDynamicContainer.LoadfromBlockContainer(DataPoolName: string);
//var
//BlockContainer:TBlockContainer;
//i:integer;
//tmpobj:TDynmObj;
//data:TDynamicData;
begin
  {BlockContainer:=TBlockcontainer.CreateDataPool(DataPoolName);
  ClearContainer;
  try
  if FActive then
    begin
      Blockcontainer.First;
      while not Blockcontainer.Eof do
        begin
          Data:=BlockContainer.GetData;
          NewData.SetPackData(Data);
          Blockcontainer.Next;
        end;
    end;
  finally
    BlockContainer.Free;
  end;  }
end;

function TDynamicContainer.GetDynmObjfromBlocks(Index: integer): TDynmObj;
begin

end;

//比较DynmObj和输入的数据之间的大小
function TDynamicContainer.Cmp(DynmObj: TDynmObj;
  DynamicData: TDynamicData; DataIndex: integer): integer;
begin

end;

function TDynamicContainer.NewStaticData: TDynmobj;
begin
  if FActive then
    begin
      result:=TDynmobj.Create;
      result.InitbyContainer(Self);
    end else raise Exception.Create('Must set Struc first');
end;

procedure TDynamicContainer.InitbyStruc(Structure: TAutoStruc);
begin
  if  fInitedbyStructure then
    begin
      FStructure:=Structure;
    end else
      begin
        FStructure.Free;
        FStructure:=Structure;
        fInitedbyStructure:=true;
      end;
  InitContainer;
end;

procedure TDynamicContainer.Add(Obj: TAutoObj);
begin
  if TDynmObj(obj).fStructure<>FStructure then
    raise exception.Create('Not same structure,Can not append to DynamicContainer');
  inherited Add(Obj);

end;

{ TBlobData }

constructor TBlobData.Create;
begin
  inherited;
  size:=0;
end;

procedure TBlobData.LoadFromStream(Stream: TStream);
begin
  size:=Stream.Size;
  Stream.Position:=0;
  Stream.Write(fData,size);
end;

procedure TBlobData.SaveTStream(Stream: TStream);
begin
  Stream.Position:=0;
  Stream.Read(fData,size);
end;

procedure TBlobData.Setsize(const Value: integer);
begin
  Fsize := Value;
  SetLength(fData,FSize);
end;



procedure TDynmObj.InitPropsQuick(XmlNode: TXmlNode);
var
i:integer;
tmpDef:TDataDef;
begin
  inherited;
  for i:=0 to fStructure.Defs.ContainerCount-1 do
    begin
      TmpDef:=fStructure.GetDataDef(i);
      SetData(i,xmlNode.GetAttribValue(tmpdef.Name));
    end;
end;

function TDynmObj.GetContainer(Index: integer): TDynamicContainer;
begin

end;

{ TDataDefContainer }

procedure TDataDefContainer.InitContainerClass;
begin
  inherited;
  FAutoClass:=TDataDef;
end;

procedure TDynmObj.InitObjData(Data: TDynamicData);
begin
  fData:=Data;
end;

function TDynmObj.GetPackData: TDynamicData;
var
i:integer;
datasize:integer;
tmpdata:TDynamicData;
allsize:integer;
begin
  allsize:=0;
  setlength(result,length(fData));
  for i:=0 to fstructure.Defs.ContainerCount-1 do
    begin
      tmpdata:=fStructure.GetDataDef(i).GetPackedData(fdata,fstructure.GetDataOffset(i));
      datasize:=length(tmpdata);
      move(tmpdata[0],result[allsize],datasize);
      inc(allsize,datasize);
    end;
  setlength(result,allsize);
end;

procedure TDynmObj.SetPackData(Data: TDynamicData);
var
i:integer;
datasize:integer;
tmpdata:TDynamicData;
allsize:integer;
begin
  allsize:=0;
  for i:=0 to fstructure.Defs.ContainerCount-1 do
    begin
      datasize:=fStructure.GetDataDef(i).SetPackedData(fdata,
      fstructure.GetDataOffset(i),Data,allsize);
      inc(allsize,datasize);
    end;
end;

{ TDynamicContainerImg }

destructor TDynamicContainerImg.Destroy;
begin
  if FBlockContainer<>nil then FBlockContainer.Free;
  inherited;
end;

function TDynamicContainerImg.New: TDynmObj;
begin
  Result:=NewStaticData;
end;

function TDynamicContainerImg.NewData: TDynmObj;
begin
  if FActive then
    begin
      result:=TDynmobj(NewSub);
      ResetData;
      result.InitObjData(fData[Pos]);
      result.InitbyContainer(Self);
    end else raise Exception.Create('Must set Struc first');
end;

procedure TDynamicContainerImg.SetImgName(const Value: string);
begin
 { FImgName := Value;
  FBlockContainer:=TBlockContainer.CreateDataPool(Value); }
end;

{ TTreeObj }

function TTreeObj.GetParent: shortstring;
begin
  result:=GuidtoString(FParentid);
end;

procedure TTreeObj.SetParent(const Value: shortstring);
begin
  try

    FParentID := stringtoguid(Value);

  except
    Raise Exception.Create('Property Parentid must a Guid Type Data!');
  end;
end;

{ TTreeContainer }

procedure TTreeContainer.InitContainerClass;
begin
  FAutoClass:=TTreeObj;
end;

{ TNamedTreeObj }



constructor TUniqueObj.Create;
var
tmpguid:Tguid;
begin
  inherited;
  FObjid:=StringtoGuid(GetNewId);
end;

//function
function GetStringHash(str: shortstring): integer;
var
i:integer;
ascode:byte;
begin
  result:=0;
  for i:=1 to byte(str[0]) do
    begin
      ascode:=byte(str[i]);
      Result:=Result+((ascode*primenumber[i-1]*I) div 2+1);
    end;
end;

function Encode(Data:string ):string;

  procedure Code3To4( In1,In2,In3:byte ;out Out1,Out2,Out3,Out4:char);
    begin
      Out1 := CodeTable[((In1 shr 2) and 63) + 1];
      Out2 := CodeTable[(((In1 shl 4) or (In2 shr 4)) and 63) + 1];
      Out3 := CodeTable[(((In2 shl 2) or(In3 shr 6)) and 63) + 1];
      Out4 := CodeTable[(Ord(In3) and 63) + 1];
    end;
var
i,j,add:integer;
size:integer;
buffer:string;
buffersize:integer;
char1,char2,char3,char4:char;
begin
  size:=length(data);
  add:=size mod 3;
  if add<>0 then
    begin
      add:=3-add;
      setlength(data,size+add);
      for i:=1 to add do
        begin
          data[size+i]:=' ';
        end;
      inc(size,add);
    end;

  buffersize:=(size div 3) *4 ;
  setlength(result,buffersize);
  i:=1;
  j:=1;
  while i<=size do
    begin
      code3to4(byte(data[i]),byte(data[i+1]),byte(data[I+2]),char1,char2,char3,char4);
      result[j]:=char1;
      result[j+1]:=char2;
      result[j+2]:=char3;
      result[j+3]:=char4;
      inc(i,3);
      inc(j,4);
    end;

end;

function Decode(Data:string ):string;

  procedure Code4To3(const AIn1, AIn2, AIn3, AIn4: Byte; var AOut1,
  AOut2, AOut3: Byte);
  var
  LCardinal: TCardinalBytes;
    begin
      LCardinal.Whole := ((AnsiPos(Chr(AIn1),codetable)-1) shl 18) or
        ((AnsiPos(Chr(AIn2),codetable)-1) shl 12)
        or ((AnsiPos(Chr(AIn3),codetable)-1) shl 6) or (AnsiPos(Chr(AIn4),codetable)-1);
      AOut1 := LCardinal.Byte3;
      AOut2 := LCardinal.Byte2;
      AOut3 := LCardinal.Byte1;
    end;
var
i,j,add:integer;
size:integer;
buffer:string;
buffersize:integer;
char1,char2,char3:byte;
begin
  size:=length(data);
  buffersize:=(size div 4) *3 ;
  setlength(result,buffersize);
  i:=1;
  j:=1;
  while i<=size do
    begin
      code4to3(byte(data[i]),byte(data[i+1]),byte(data[I+2]),byte(data[i+3]),char1,char2,char3);
      result[j]:=char(char1);
      result[j+1]:=char(char2);
      result[j+2]:=char(char3);
      inc(i,4);
      inc(j,3);
    end;

end;

{ TNamedTreeObj }

function TNamedTreeObj.GetName: shortstring;
begin
  result:=fName;
end;

procedure TNamedTreeObj.SetName(const Value: shortstring);
begin
  fName:=value;
end;

function TUniqueObj.Getobjid: shortstring;
begin
  result:=guidtostring(fobjid);
end;

function TDynmObj.GetStructure: TAutoStruc;
begin
  result:=fStructure;
end;

function TDynmObj.GetInsertSQL: String;
var
i:integer;
tmpstr:Tsuperstr;
begin
  tmpstr:=Tsuperstr.Create;
  tmpstr.append('Insert into ');
  tmpstr.append(fstructure.name);
  tmpstr.append('(');
  try
    for i:=0 to Fstructure.FDefs.ContainerCount-1 do
      begin
        tmpstr.append(TDataDef(fStructure.FDefs.Get(i)).Name);
        if i<FStructure.FDefs.ContainerCount-1 then
          begin
            tmpstr.append(',');
          end;
      end;
      tmpstr.append(')');
      tmpstr.append(' values (');
      for i:=0 to Fstructure.FDefs.ContainerCount-1 do
        begin
          tmpstr.append(#39+GetStringData(i)+#39);
          if i<FStructure.FDefs.ContainerCount-1 then
            begin
              tmpstr.append(',');
            end;
        end;
     tmpstr.append(')');
     result:=tmpstr.Value;
  finally
    tmpstr.Free;
  end;
end;

{ TObjIndex }

procedure TObjIndex.AddData(Obj:TAutoObj);
begin
  if FRoot.Data=nil then FRoot.Data:=Obj else
    begin
      InsertData(FRoot,Obj);
    end;
end;

constructor TObjIndex.Create;
begin
  inherited;
  leftcount:=0;
  rightcount:=0;
  FRoot:=TIndexNode.Create;
end;

destructor TObjIndex.Destroy;
begin

  inherited;
end;

procedure TObjIndex.InsertData(Node: TIndexNode;Obj:TAutoObj);
var
tmpobj:TAutoObj;
tmpnode:TIndexNode;
left:integer;
right:integer;
begin
  tmpObj:=Node.Data;
  if tmpobj.GetDataOf(FSortProperty)<=Obj.GetDataOf(FSortProperty) then
    begin
      if node.Left<>nil then InsertData(node.Left,Obj) else
        begin
          tmpnode:=TIndexNode.Create;
          tmpnode.Parent:=Node;
          tmpnode.Data:=Obj;
          node.Balance:=node.Balance-1;
        end;
    end else
      begin
        if node.right<>nil then InsertData(node.right,Obj) else
        begin
          tmpnode:=TIndexNode.Create;
          tmpnode.Parent:=Node;
          tmpnode.Data:=Obj;
          node.Balance:=node.Balance+1;
        end;
      end;
    if (Node.Balance <-1) or (Node.Balance>1) then updatebalance(Node);
end;

procedure TObjIndex.SetSortProperty(const Value: string);
begin

end;

procedure TObjIndex.UpdateBalance(Node: TIndexNode);
var
Parent:TIndexNode;
Left,right:TIndexNode;
begin
  if node.Balance<-1 then
    begin
      Parent:=Node.Parent;
      node.Left.Parent:=Parent;


    end;
end;

{ TIndexNode }

constructor TIndexNode.Create;
begin
  inherited;
  Balance:=0;
  Left:=nil;
  Right:=nil;
  Parent:=nil;
  Data:=nil;
end;

initialization
  registerclasses([TAutoObj,TAutoContainer,TAutoStruc,TDataCheck,TDataDef,
                   TDataDefContainer,TNamedObj,TStrucContainer,TDynmObj,
                   TDynamicContainer]);
end.
