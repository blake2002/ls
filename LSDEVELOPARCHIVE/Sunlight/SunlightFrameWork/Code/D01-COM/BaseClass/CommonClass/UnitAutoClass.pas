unit UnitAutoClass;


interface

uses
  SysUtils, Types,windows, Classes,Typinfo,db,DateUtils,RTLConsts,AutoIntf,
  UnitXmlEngine,fmtBcd,controls,variants,math,Graphics,stdctrls,syncObjs;
type
{$M+}
  //对象操作类型（新插入，更新，删除，未操作）
  TObjType=(otInsert,otUpdate,otDelete,otNone);
  TAutoObj=class;
  TArray2=record
    byte1:byte;
    byte2:byte;
  end;
  PExtended=^Extended;
  TArray3=array [0..2]of byte;
  TArray4=record
    byte1:byte;
    byte2:byte;
    byte3:byte;
    byte4:byte;
  end;
  TArray5=array [0..4]of byte;
  TArray6=array [0..5]of byte;
  TArray7=array [0..6]of byte;
  TArray8=array [0..7]of byte;
  PIndexNode=^TIndexNode;
  TSpliteinfo=record
    BlockIndex:integer;
    BlockCount:integer;
  end;

  TClassType=(ctStorage,ctClient,ctLogic,ctVirtual);

  TAutoBlock=class(TObject)
  private
    FBlockIndex:int64;
    FCacheData:TDynamicData;
    FCount:Word;
    FFreeOffset:Word;
  public
    function GetRemainSize:integer;virtual;
    procedure AppendData(Data:TDynamicData);
    function GetData(index:integer):TDynamicData;
  end;

  TAutoStruc=class;
  TAutoPropInfo=class;

  TSublist=class(TAutoList)
  private
    FBlockIndex:Int64;
    FIsLeaf: Boolean;
    FIsPacked: Boolean;
    FAttatchBlock:TAutoBlock;
    function GetIsFull: boolean;
    function GetMaxObj: TAutoObj;
    function GetMinObj: TAutoObj;
    procedure SetIsLeaf(const Value: Boolean);
    procedure SetBlockIndex(const Value: int64);
    procedure SetIsPacked(const Value: boolean);
  protected
    procedure Grow;override;
  public
    procedure Pack;
    procedure UnPack;
    property MinObj:TAutoObj read GetMinObj;
    property MaxObj:TAutoObj read GetMaxObj;
    property IsFull:boolean read GetIsFull;
    property IsLeaf:Boolean read FIsLeaf write SetIsLeaf;
    property BlockIndex:int64 read FBlockIndex write SetBlockIndex;
    property IsPacked:boolean read FIsPacked write SetIsPacked;
  end;



  TBlockList=class(TObject)
  private
    FSubList:TAutoList; //所有块列表
    FBlockCount:integer;
    FSort:Boolean;
    FIndexProp: shortstring;
    FPos:integer;
    FBlockIndex:integer; //块位置
    FDataIndex:integer; //数据位置
    PProinf:PPropInfo;
    fObjKeyIndex:integer;
    procedure PackBlocks(StartIndex:integer);
    procedure PackBlock(Block1,Block2:TSubList);
    procedure SpliteBlock(BlockIndex,Index:integer);
    procedure InsertAutoObj(Obj: TAutoObj);
    function GetBlockIndexIn(startIndex,endIndex:integer;Obj:TAutoObj):integer;
    function GetBlockIndexofObj(Obj:TAutoObj):integer;
    function GetBlockIndexofKey(startIndex,endIndex:integer;key:Variant):integer;
    function CmpObj(BaseObj,CmpObj:TAutoObj;Propname:string):integer;
    function Cmp(BaseValue,CmpValue:Variant):integer;
    procedure SetIndexProp(const Value: shortstring);
    function GetItems(ItemIndex: integer): TObject;
    procedure SetItems(ItemIndex: integer; const Value: TObject);
  public
    procedure Add(Obj:TAutoObj);
    procedure Next;
    procedure First;
    function GetObj:TAutoObj;
    function GetObjByKey(Key:variant):TAutoObj;
    constructor Create;virtual;
    destructor Destroy;override;
    property IndexProp:shortstring read FIndexProp write SetIndexProp;
    function blockcount:integer;
    procedure Delete;
    property Items[ItemIndex:integer]:TObject read GetItems;
  end;

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
    isDynamic:boolean;
    DynamicIndex:word;
  end;

  PStrucInfo=^TStrucInfo;

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
  TAutoObjClass=class of TAutoObj;
  TAutoContainerClass=class of TAutoContainer;
  TAutoObjs=array of TAutoObj;
  //树节点
  TIndexNode=class(TObject)
  public
    Left:TIndexNode;
    Right:TIndexNode;
    Parent:TIndexNode;
    Balance:integer;
    Data:TAutoObj;
    //constructor  Create;virtual;
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
    function GetRTTIClassProp(PropName:shortstring):TPersistent;
    function GetClassXml(Obj:TObject):string;
    //function GetSubsCount: integer;
    procedure SetPropValue(Instance: TObject; const PropInfo: PPropInfo;
      const Value: Variant);

    procedure InitObjByXml(Obj: TPersistent; XmlNode: TXmlNode);

    procedure SetPropDynmValue(Instance: TObject;
      const PropInfo: PPropInfo; Data: TDynamicData);
    procedure execute;


  protected
    propcount:Integer;
    proplist:PPropList;
    function  GetClassProp(PropName:shortstring):TAutoObj;
    class procedure GetXmlOfObj(Obj:TPersistent;Superstr:TSuperstr);
    class function GetPropValue(Instance: TObject; const PropInfo: PPropInfo;
     PreferStrings: Boolean = True): Variant;
    function GetPropDynmData(Instance: TObject; const PropInfo: PPropInfo;
     PreferStrings: Boolean = True):TDynamicData;
    function GetPropData(Instance: TObject; const PropInfo: PPropInfo;
     PreferStrings: Boolean = True):TDynamicData;
    procedure InitPropsQuick(XmlNode:TXmlNode);virtual;
    procedure InitObjPropsQuick(Obj:TPersistent;XmlNode:TXmlNode);
    function GetStandXmlStr(Data:string):string;
    function CmpValue(Data,CmpData:Variant):integer;
    function ConvertVariantToDynamic(Value:Variant;DataType:TDataType):TDynamicData;
  public

    constructor Create;virtual;
    destructor Destroy;override;
    procedure GetSelfXml(Superstr:TSuperstr);virtual;
    procedure InitByXml(XmlNode:TXmlNode);virtual;//设置string格式的xml 来重构对象
    class function GetInfo:string;
    function GetDataOf(Name: shortstring): Variant;virtual;
    procedure SetDataOf(Name: shortstring; const Value: Variant);virtual;
    function GetXml:string;virtual;//得到xml打包的数据string格式
    function GetStandXml:string;//得到utf-8格式的xml数据
    procedure SetXml(Xml:string);virtual;//设置string 格式的xml 来重构对象
    procedure SetObjXml(Obj:TPersistent;Xml: string);
    procedure SetStandXml(Xml:string);virtual;//设置utf-8 格式的xml 来重构对象
    procedure Assign(Source: TPersistent);override;
    procedure SaveXmltoFile(filename:string);
    procedure SaveBintoFile(filename:string);
    procedure LoadBinfromFile(filename:string);
    procedure LoadXmlfromFile(filename:string);
    class function GetObjXml(Obj:TPersistent):string;
    class function GetMirrorofProp(Propname:shortstring):shortstring;
    class function GetPropofMirror(Mirror:shortstring):shortstring;
    class function GetSearchofProp(Propname:shortstring):shortstring;
    class function GetNewId:string;
    class procedure copyarraydata(ArraySrc:TDynamicData;SrcOffset:integer;
      ArrayDes:TDynamicData;DesOffset,size:integer);
    class function GetHash(Data:TDynamicData):integer;
    function GetIndexOfProp(PropName:shortstring):integer;virtual;
    property Xml:string read GetStandXml write SetStandXml;//
    function GetSize:integer;
    function GetSubSize:integer;
    function GetKeyValue(KeyIndex:integer):variant;virtual;
    function CmpWith(Obj:TAutoObj;PropName:string):integer;
    function GetData:TDynamicData;virtual;
    function GetDataQuick(Data:TSuperDynArry):integer;
    procedure SetData(Data: TDynamicData);virtual;
    procedure SetDataQuick(Data:Pointer);virtual;
    function GetPropDynm(PropIDX:integer):TDynamicData;virtual;
    function GetPropIDXValue(PropIDX:integer):Variant;virtual;
    function CmpDataIDX(Data:TDynamicData;PropIDX:integer):integer;virtual;
    function GetDataTypeOfIDX(DataIndex:integer):TDatatype;virtual;
  published

  end;

  //线程安全对象
  TThreadSafeObj=class(TAutoObj)
  private
    FCriticalSection:TCriticalSection;
  protected
    procedure Lock;virtual;
    procedure unLock;virtual;
  public
    constructor Create;override;
    destructor Destroy;override;

  end;

  TAutoPropinfo=class(TAutoObj)
  private
    FTitle: string;
    FPropName: string;
    FClassName: string;
    FSearchClass: string;
    FDetail: String;
    FShowIndex: integer;
    FCanModify: boolean;
    FCanShow: boolean;
    FSize: integer;
    FDataType: TDataType;
    procedure SetClassName(const Value: string);
    procedure SetPropName(const Value: string);
    procedure SetSearchClass(const Value: string);
    procedure SetTitle(const Value: string);
    procedure SetDetail(const Value: String);
    procedure SetShowIndex(const Value: integer);
    procedure SetCanModify(const Value: boolean);
    procedure SetCanShow(const Value: boolean);
    procedure SetDataType(const Value: TDataType);
    procedure SetSize(const Value: integer);
  public
    Constructor create;override;
    destructor Destroy;override;
  published
    property ClassName:string read FClassName write SetClassName;
    property PropName:string read FPropName write SetPropName;
    property Title:string read FTitle write SetTitle;
    property Detail:String read FDetail write SetDetail;//说明
    property SearchClass:string read FSearchClass write SetSearchClass;
    property ShowIndex:integer read FShowIndex write SetShowIndex;
    property CanModify:boolean read FCanModify write SetCanModify;
    property CanShow:boolean read FCanShow write SetCanShow;
    property DataType:TDataType read FDataType write SetDataType;
    property Size:integer read FSize write SetSize;
  end;



  TUniqueObj=Class(TAutoObj)
  private
    fobjid:TGuid;
    procedure Setobjid(const Value:String);
    function Getobjid: String;
  public
    constructor Create;override;
    //class function GetInfo:string;override;
    function GetPropDynm(PropIDX: integer): TDynamicData;override;
    function GetKeyValue(KeyIndex:integer):Variant;override;
  published
    property objid:String read GetObjid write SetObjid;
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
  protected
    FAutoClass: TAutoObjClass;
    //子对象
    FSubObjects:TAutoList;
    //清除容器中所有对象
    procedure ClearSubObjs;virtual;
    //初始化容器的盛方类型，所有容器子类必须重载
    procedure InitContainerClass;virtual;
    procedure InitSubsQuick(XmlNode: TXmlNode);virtual;
    procedure InitByXml(XmlNode: TXmlNode);override;
  public
    constructor Create;override;
    destructor Destroy;override;
    procedure GetSelfXml(Superstr: TSuperstr);override;
    //清除容器中的对象
    procedure ClearContainer;virtual;
    function Add(Obj:TAutoObj):integer;virtual;
    procedure Insert(Index:integer;Obj:TAutoObj);virtual;
    procedure Delete(Index:integer);overload;virtual;
    function DeleteObj(Obj:TAutoObj):integer;
    function AddSub(Obj:TAutoObj):integer;virtual;
    function  NewSub:TAutoObj;virtual;
    function GetSubObj(Index:integer):TAutoObj;
    function GetSub(Index: integer): TAutoObj;
    function Get(Index:integer):TAutoObj;
    function ContainerCount:integer;
    function GetObj:TAutoObj;
    procedure SaveToStream(Stream:TStream);
    procedure Delete;overload;virtual;
    procedure Update(Index:integer;Obj:TAutoObj);virtual;
    property AutoClass:TAutoObjClass read FAutoClass write SetAutoClass;
    property Pos:integer read FPos write SetPos;
    function GetData:TDynamicData;override;
    procedure SetData(Data:TDynamicData);override;
    procedure SetCapacity(Capacity:integer);virtual;
    procedure SetDataQuick(Data:Pointer);override;
  end;

  TThreadSafeContainer=class(TAutoContainer)
  private
    FCriticalSection:TCriticalSection;
  public

    procedure Lock;virtual;
    procedure unLock;virtual;
    constructor Create;override;
    destructor Destroy;override;

  end;

  //临时对象容器,该容器用与临时存放单体类,不履行释放对象任务禁止使用newSub 方法
  TTmpContainer=class(TAutoContainer)
  protected
    procedure ClearSubObjs;override;//清除容器中所有对象
  public
    procedure ClearSubObjsDirectly;//强制清除容器(在特殊情况下允许使用强制清除容器内对象)
    function  NewSub:TAutoObj;override;
  end;

  //放置特征定义的容器
  TAutoPropInfos=class(TAutoContainer)
  protected
    FClassName:String;
    procedure initcontainerclass;override;
    function AddSub(Obj:TAutoObj):integer;override;
  public
    procedure initclassname(classname:string);
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
    //class function GetInfo:string;override;
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
    FName: string;
    function GetName: string;
    procedure SetName(const Value: string);virtual;
  published
    property name:string read GetName write SetName;
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
    FTitle: string;
    FCheck: TDataCheck;
    FDatatype: TDataType;
    FDataSource: TDataSrcType;
    FStructureName: String;
    FStruc:TAutoStruc;
    FIsRecursive: boolean;
    procedure SetCheck(const Value: TDataCheck);
    procedure SetDatatype(const Value: TDataType);
    procedure SetPrecision(const Value: integer);
    procedure SetTitle(const Value: string);
    procedure SetDataSource(const Value: TDataSrcType);
    function GetDatatype: TDataType;
    procedure SetStructureName(const Value: String);
    procedure SetIsRecursive(const Value: boolean);
  protected
    procedure SetSize(Value: integer);
    function GetSize:integer;
  public
    constructor Create;override;
    destructor Destroy;override;
    function GetValue(DataPack:TDataPack;OffSet:integer):Variant;
    function GetStringValue(DataPack:TDataPack;OffSet:integer):string;
    function GetPackedData(DataPack: TDataPack;OffSet:integer):TDynamicData;
    function SetPackedData(DataPack:TDynamicData;Offset:integer;
              PackedData:TDynamicData;PackStart:integer):integer;
    procedure SetValue(DataPack:TDataPack;OffSet:integer;value:Variant);
    function GetAllocSize:integer;
    function GetStruc:TAutoStruc;
    procedure SetStruc(Struc:TAutoStruc);
    function IsDynamic:Boolean;
  published
    property Datatype:TDataType read GetDatatype write SetDatatype default dtString;
    property Size:integer read FSize write SetSize default 20;
    property Title:string read FTitle write SetTitle;
    property Precision:integer read FPrecision write SetPrecision default 0;
    property DataSource:TDataSrcType read FDataSource write SetDataSource;
    property Check:TDataCheck read FCheck write SetCheck;
    property StructureName:String  read FStructureName write SetStructureName;
    property Struc:TAutoStruc read FStruc;
    property IsRecursive:boolean read FIsRecursive write SetIsRecursive default false;
  end;

  //数据结构定义
  TAutoStruc=Class(TInheritedObj)
  private
    FActive:boolean;
    FDefs: TDataDefContainer;
    fStrucContainer: TStrucContainer;
    FIsVirtual: boolean;
    FAllocSize:integer;
    FKeyProp: string;
    FDynamicCount:integer;
    function GetStringHash(str: shortstring): integer;
    procedure SetIsVirtual(const Value: boolean);
    procedure SetKeyProp(const Value: string);
  public
    StrucInfos:TStrucInfos;
    Constructor Create;override;
    Destructor Destroy;override;
    function GetAllocSize:integer;
    function GetDataDef(Index:integer):TDataDef;
    function GetDataOffset(Index:integer):integer;
    function GetOffSetof(Index:integer):integer;
    function GetSizeof(Index:integer):integer;
    function GetDataTypeof(Index:integer):TDataType;
    function GetIndexOf(Name: string): integer;
    function GetDataValue(DataPack:TDynamicData;Index:integer):variant;
    procedure SetDataValue(DataPack:TDynamicData;Index:integer;Data:Variant);
    procedure InitByXml(XmlNode:TXmlNode);override;
    procedure InitStruc;
    function IsStatic:Boolean;
    function GetDymicCount:integer;
  published
    property Defs:TDataDefContainer read FDefs ; //结构定义
    property IsVirtual:boolean read FIsVirtual write SetIsVirtual;//虚结构标示,说明该结构是否有应用实例还仅作为中间继承对象
    //property SubStrucs:TStrucContainer read fStrucContainer; //子结构定义,结构定义支持嵌套结构声明
    property KeyProp:string read FKeyProp write SetKeyProp;
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
    function GetStrucbyName(name:string):TAutoStruc;
  published
    //property name:string read FName write SetName;
  end;

  TDynamicContainer=class;
  
  TDynmObj=class(TAutoObj)
  private
    fInited:boolean;
    fStructure:TAutoStruc;
    function GetStrOfStruc(Strucinfo:PStrucInfo):string;
  protected

  public
    ObjType:TObjType;
    fDynmData:TDataPack;
    procedure GetSelfXml(Superstr:TSuperstr);override;
    constructor Create;override;
    constructor CreateByStructure(Structure:TAutoStruc);
    destructor Destroy;override;
    procedure InitbyStruc(Structure:TAutoStruc);
    procedure InitbyContainer(Container:TDynamicContainer);
    procedure InitObjData(Data:TDynamicData);
    function GetData(Index:integer):Variant;overload;
    function GetContainer(Index:integer):TDynamicContainer;
    function GetStringData(Index:integer):string;
    function GetDetailData(index:integer):TDynamicContainer;
    function GetStructureData(index: Integer): TDynmObj;
    function GetDataOf(Name: shortstring): Variant;override;
    procedure SetDataOf(Name: shortstring; const Value: Variant); override;
    procedure LoadFromStreamOf(Name: shortstring; const Source: TStream);
    procedure SaveToStreamOf(Name: shortstring; const Source: TStream);
    procedure LoadFromFileOf(Name: shortstring; const FileName: string);
    procedure SaveToFileOf(Name: shortstring; const FileName: string);
    procedure InitPropsQuick(XmlNode:TXmlNode);override;
    procedure SetData(Index:integer;value:variant);overload;
    function GetPackData:TDynamicData;
    function GetStructure:TAutoStruc;
    procedure SetPackData(Data:TDynamicData);
    function GetInsertSQL:String;
    function GetKeyValue(KeyIndex:integer):variant;override;
    function GetIndexOfProp(PropName:shortstring):integer;override;
    property DataOf[Name: shortstring]:Variant read GetDataOf write SetDataOf;
    function GetDataArray(Index:integer):TDynamicData;
    function GetData:TDynamicData;overload;override;
    procedure SetData(Data: TDynamicData);overload;override;
    procedure SetDataQuick(Data:Pointer);override;
    function GetPropDynm(FSortIdx:integer):TDynamicData;override;
    function GetPropIDXValue(PropIDX:integer):Variant;override;
    function GetDataTypeOfIDX(DataIndex:integer):TDatatype;override;
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
    FStructure: TAutoStruc;
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
    procedure GetSelfXml(Superstr:TSuperstr);override;
    constructor Create;override;
    constructor CreatebyXml(Xml:string);
    constructor CreatebyStructure(Structure:TAutoStruc);
    function  Add(Obj:TAutoObj):integer;override;
    procedure Insert(Index:integer;Obj:TAutoObj);override;
    destructor Destroy;override;
    procedure InitbyStruc(Structure:TAutoStruc);
    function  NewData:TDynmObj;virtual;
    function NewStaticData:TDynmobj;
    function GetDynmObj(Index:integer):TDynmObj;
    function GetDataDef(Index:integer):TDataDef;
    function GetDataOffset(Index:integer):integer;
    function GetDefCount:integer;
    class function GetSysStructure(XmlNode: TXmlNode): TAutoStruc;
    procedure VerifyStructure(XmlNode: TXmlNode);
    procedure SetXml(Xml:string);override;
    procedure SaveToFile(FileName:string);
    procedure LoadFromFile(FileName:string);
    procedure SavetoBlockContainer(DataPoolName:string);
    procedure LoadfromBlockContainer(DataPoolName:string);
    property StructureXml:string read GetStructureXml write SetStructureXml;
    property Structure:TAutoStruc read FStructure ;
  published

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

  TClassInfo=class(TNamedTreeObj)
  private
    FInheritedFrom: String;
    FClassInfo: String; 
    FClassType: TClassType;
    procedure SetClassInfo(const Value: String);
    procedure SetInheritedFrom(const Value: String);
    procedure SetName(const Value:string);override;
    procedure SetClassType(const Value: TClassType);
  protected
    FPropInfos: TAutoPropInfos;
  public
    constructor Create;override;
    destructor Destroy;override;
  published
    property ClassInfo:String read FClassInfo write SetClassInfo;
    property InheritedFrom:String read FInheritedFrom write SetInheritedFrom;
    property ClassType:TClassType read FClassType write SetClassType;
    property PropInfos:TAutoPropInfos read FPropInfos;
  end;

  TClassInfos=class(TTreeContainer)
  protected
    procedure initcontainerclass;override;
  end;

{$M-}
TNameMirrors=array[0..16] of TNameMirror;

function GetStringHash(str: shortstring): integer;//得到字符串的hashcode;
function Encode(Data:string ):string;
function Decode(Data:string ):string;

const
  allinc=512;
  strinc=2048;
  BlockMax=2048;
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

var
  SysClassInfos:TClassInfos;
  SysStructures:TStrucContainer;
implementation

uses UnitDynamicBlock;
{ TAutoObj }

{procedure TAutoObj.AddSub(Obj: TAutoObj);
begin
  FSubObjects.Add(Obj)
end; }

procedure TAutoObj.Assign(Source: TPersistent);
var
propname:shortstring;
tmpobj:TPersistent;
begin
  if Source is TAutoObj then
    begin
      Xml:=TAutoObj(Source).Xml;
      //SetData(TAutoObj(Source).GetData);
    end else inherited;
end;



{procedure TAutoObj.ClearSubObjs;
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
end; }

constructor TAutoObj.Create;
var
tmpguid:Tguid;
begin
  inherited Create;
  //FSubsCount:=0;
  //falloccount:=0;
  //FSubObjects:=TList.Create;
  propcount:=GetProplist(self,proplist);
  //fxml:=Tsuperstr.Create;
end;

destructor TAutoObj.Destroy;
begin
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
            begin
		Result := GetVariantProp(Instance, PropInfo);
                if TVarData(Result).VType=varDate then
                  begin
                    Result:=Double(TVarData(Result).VDate);
                  end;
            end;
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
var
i,j:integer;
tmpPropinfos:TAutoPropInfos;
tmpClassinfo:TClassInfo;
tmpPropInfo:TAutoPropInfo;
begin
  //Result:='没有找到特征';
  Result:='';
  for i:=0 to SysClassInfos.ContainerCount-1 do
    begin
      tmpClassinfo:=SysClassInfos.GetSub(i) as TClassInfo;
      if tmpClassInfo.Name=ClassName then
        begin
          Result:=tmpClassInfo.ClassInfo;
          exit;
        end;
    end;
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
             superstr.Append(propname);
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
            superstr.Append(GetStandXmlStr(GetStrProp(self,propinf))) else
            superstr.Append(GetPropValue(self,propinf));
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
  superstr.Append(classname);
  superstr.AddOver;

end;

function TAutoObj.GetStandXml: string;
begin
   result:=Utf8Encode(GetXml);
end;


function TAutoObj.GetXml: string;
var
fxml:TSuperstr;
begin
  fxml:=TSuperstr.Create;
  GetSelfXml(fxml);
  Result:=Fxml.Value;
  fxml.Free;

end;


procedure TAutoObj.InitByXml(XmlNode:TXmlNode);
begin
  InitPropsQuick(XmlNode);
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
  for i:=0 to propcount-1 do
    begin
      tmpPropInfo:=proplist^[i];
      if not(tmppropinfo.PropType^.Kind in [tkClass,tkInterface] ) then
        begin
          if tmppropinfo.SetProc<>nil then
            try
              SetPropValue(self,tmppropinfo,XmlNode.GetAttribValue(tmppropinfo.Name));
            except
              //SetPropValue(self,tmppropinfo,XmlNode.GetAttribValue(tmppropinfo.Name));
            end;
        end else
          begin
            tmpobj:=GetClassProp(tmppropinfo.Name);
            tmpnode:=xmlnode.GetChildByName(tmpPropInfo.name);
            if (tmpobj<>nil) and (tmpnode<>nil) then tmpobj.InitByXml(tmpnode.GetChild(0));
          end;
    end;
end;



{procedure TAutoObj.InitSubsQuick(XmlNode:TXmlNode);
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
      tmpobj:=AutoClass.Create;
      AddSub(tmpobj);
      tmpobj.InitByXml(tmpxmlnode);
    end;
end;}

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
end;

procedure TAutoObj.SetObjXml(Obj:TPersistent;Xml: string);
var
XmlEng:TXmlEngine;
begin
  XmlEng:=TXmlEngine.Create;
  XmlEng.DataXml:=Xml;
  InitObjByXml(Obj,xmlEng.Getroot);
  XmlEng.Free;

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
  if  FileExists(filename) then tmpfile:=TFilestream.Create(filename,fmOpenWrite)
     else tmpfile:=TFilestream.Create(filename,fmCreate);
  try
    data:=Xml;
    tmpfile.Position:=0;
    tmpfile.Write(data[1],length(data));
    tmpfile.Size:=length(data);
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
i,j:integer;
tmpPropinfos:TAutoPropInfos;
tmpClassinfo:TClassInfo;
tmpPropInfo:TAutoPropInfo;
begin
  //Result:='没有找到特征';
  Result:=Propname;
  for i:=0 to SysClassInfos.ContainerCount-1 do
    begin
      tmpClassinfo:=SysClassInfos.GetSub(i) as TClassInfo;
      if tmpClassInfo.Name=ClassName then
        begin
          tmpPropInfos:=tmpClassinfo.PropInfos;
          for j:=0 to tmpPropInfos.ContainerCount-1 do
            begin
              tmpPropInfo:=tmpPropInfos.GetSub(j) as TAutoPropInfo;
              if tmpPropInfo.PropName=PropName then
                begin
                  Result:=tmpPropInfo.FTitle;
                  Break;
                end;
            end;
          Break;
        end;
    end;
end;

class function TAutoObj.GetPropofMirror(Mirror: shortstring): shortstring;
var
i,j:integer;
tmpPropinfos:TAutoPropInfos;
tmpClassinfo:TClassInfo;
tmpPropInfo:TAutoPropInfo;
begin
  //Result:='没有找到特征';
  Result:=Mirror;
  for i:=0 to SysClassInfos.ContainerCount-1 do
    begin
      tmpClassinfo:=SysClassInfos.GetSub(i) as TClassInfo;
      if tmpClassInfo.Name=ClassName then
        begin
          tmpPropInfos:=tmpClassinfo.PropInfos;
          for j:=0 to tmpPropInfos.ContainerCount-1 do
            begin
              tmpPropInfo:=tmpPropInfos.GetSub(j) as TAutoPropInfo;
              if tmpPropInfo.Title=Mirror then
                begin
                  Result:=tmpPropInfo.PropName;
                  Break;
                end;
            end;
          Break;
        end;
    end;
end;




procedure TUniqueObj.Setobjid(const Value: String);
begin
  try
    FObjid:=stringtoGuid(Value);
    //Fobjid:=stringtoguid(Value);
  except
    raise Exception.Create('Objid must a Guid!');
  end;
end;

{class function TUniqueObj.GetInfo: string;
begin
  result:='本对象是所有唯一化对象的根，是用来描述和记录实体对象的，'
          +'用唯一ID(property objid 数据类型Guid)来表示实体唯一性，'
          +' 继承来自TAutoObj';
end;}



class function TAutoObj.GetNewId: string;
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
  for i:=0 to (size div 4) do
    begin
      TArray4((@ArrayDes[DesOffset+offset])^):=TArray4((@ArraySrc[SrcOffset+offset])^) ;
      inc(offset,4);
    end;
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
{  Result:=0;
  for i:=0 to Subscount-1 do
    begin
      Result:=Result+Getsub(i).GetSize;
    end; }
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
  fStruc:=TAutoStruc.Create;
  //DataSource:=dtManual;
  
end;

destructor TDataDef.Destroy;
begin
  fCheck.Free;
  fStruc.Free;
  inherited;
end;

function TDataDef.GetAllocSize: integer;
begin
  case FDataType of
    dtString:
      begin
        result:=dymicIndex;
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
        result:=dymicIndex;
      end;
    dtGuid:
      begin
        result:=size;
      end;
    dtInt64:
      begin
        result:=size;
      end;
    dtStructure:result:=dymicIndex;
    dtDetail:result:=dymicIndex;
    else raise exception.Create('Incorrect type defined!');
  end;
end;

function TDataDef.GetDatatype: TDataType;
begin
  Result:=fDatatype;
end;

function TDataDef.GetPackedData(DataPack: TDataPack;
  OffSet:integer): TDynamicData;
var
  i,count,Pos:integer;
  {tmpid:TGuid;
  tmpword:Word;
  tmpboolean:boolean;
  tmpstr:string;
  tmpsmallint:smallint;
  tmpint64:Int64;
  tmpDouble:Double;
  tmpcurrency:currency;
  tmpdatetime:Tdatetime;
  tmpint:integer;
  strsize:word;}
begin
  count:=length(DataPack);
  //For i:=0 to length(fDynmData) do
  {exit;
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
        copyarrayData(DataPack,offset,result,0,size);
      end;
    dtInteger:
      begin
        setlength(result,sizeof(integer));
        copyarrayData(DataPack,offset,result,0,size);
      end;
    dtWord:
      begin
        setlength(result,sizeof(word));
        copyarrayData(DataPack,offset,result,0,size);
      end;
    dtBoolean:
      begin
        setlength(result,sizeof(boolean));
        copyarrayData(DataPack,offset,result,0,size);
      end;
    dtFloat:
      begin
        setlength(result,sizeof(Double));
        copyarrayData(DataPack,offset,result,0,size);
      end;
    dtCurrency:
      begin
        setlength(result,sizeof(Currency));
        copyarrayData(DataPack,offset,result,0,size);
      end;
    dtDateTime:
      begin
        setlength(result,sizeof(TDatetime));
        copyarrayData(DataPack,offset,result,0,size);
      end;
    dtBlob:
      begin
        Raise Exception.Create('Blob Data Can not Send to Variant,'
        +'must use Stream to attach Blob Data!');
      end;
    dtGuid:
      begin
        setlength(result,sizeof(TGuid));
        copyarrayData(DataPack,offset,result,0,size);
      end;
    dtInt64:
      begin
        setlength(result,sizeof(Int64));
        copyarrayData(DataPack,offset,result,0,size);
      end;
  end;   }
end;

function TDataDef.GetSize: integer;
begin
  Result:=fsize;
end;

function TDataDef.GetStringValue(DataPack:TDataPack;
  OffSet: integer): string;
var
  tmpstr:string;
  tmpid:Tguid;
  tmpword:Word;
  tmpboolean:boolean;
  tmpsmallint:smallint;
  tmpint64:Int64;
  tmpDouble:Double;
  tmpcurrency:currency;
  tmpdatetime:Tdatetime;
  strsize,dynmIndex:word;
  blobsize:integer;
begin
  case FDataType of
    dtString:
      begin
        move(DataPack[0][offset],dynmIndex,2);
        strsize:=length(DataPack[dynmIndex]);
        setlength(Result,strsize);
        move(DataPack[dynmIndex][0],result[1],strsize);
      end;
    dtSmallint:
      begin
        result:=inttostr(PSmallInt(@DataPack[0][offset])^);
      end;
    dtInteger:
      begin
        result:=inttostr(Pinteger(@DataPack[0][offset])^);
      end;
    dtWord:
      begin
        result:=inttostr(PWord(@DataPack[0][offset])^);
      end;
    dtBoolean:
      begin
        result:=booltostr(PBool(@DataPack[0][offset])^);
      end;
    dtFloat:
      begin
        result:=floattostr(PDouble(@DataPack[0][offset])^);
      end;
    dtCurrency:
      begin
        result:=currtostr(PCurrency(@DataPack[0][offset])^);
      end;
    dtDateTime:
      begin
        result:=Datetimetostr(PDatetime(@DataPack[0][offset])^);
      end;
    dtBlob:
      begin
        move(DataPack[0][offset],dynmIndex,2);
        blobsize:=length(DataPack[dynmIndex]);
        setlength(tmpstr,blobsize);
        move(Datapack[dynmIndex][0],tmpstr[1],blobsize);
        result:=encode(tmpstr);
        exit;
        Raise Exception.Create('Blob Data Can not Send to Variant,'
        +'must use Stream to attach Blob Data!');
      end;
    dtStructure:
      begin
        move(DataPack[0][offset],dynmIndex,sizeword);
        blobsize:=length(DataPack[dynmIndex]);
        setlength(tmpstr,blobsize);
        move(Datapack[dynmIndex][0],tmpstr[1],blobsize);
        result:=encode(tmpstr);
      end;
    dtGuid:
      begin
        result:=GuidtoString(PGuid(@DataPack[0][offset])^);
      end;
    dtInt64:
      begin
        result:=Inttostr(PInt64(@DataPack[0][offset])^);
      end;
  end;
end;

function TDataDef.GetStruc: TAutoStruc;
begin
  Result:=FStruc;
end;

function TDataDef.GetValue(DataPack:TDataPack;OffSet:integer): Variant;
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
  strsize,dynmindex:word;
  blobsize:integer;
  p: Pointer;
begin
  case FDataType of
    dtString:
      begin
        move(DataPack[0][offset],dynmindex,sizeword);
        strsize:=length(DataPack[dynmindex]);
        setlength(tmpstr,strsize);
        move(DataPack[dynmindex][0],tmpstr[1],strsize);
        result:=tmpstr;
      end;
    dtSmallint:
      begin
        move(DataPack[0][offset],tmpsmallint,size);
        result:=tmpsmallint;
      end;
    dtInteger:
      begin
        move(DataPack[0][offset],tmpInt,size);
        result:=tmpint;
      end;
    dtWord:
      begin
        move(DataPack[0][offset],tmpWord,size);
        result:=tmpword;
      end;
    dtBoolean:
      begin
        move(DataPack[0][offset],tmpBoolean,size);
        TVarData(result).VType:=varBoolean;
        TVarData(result).VBoolean:=tmpBoolean;
        result:=tmpBoolean;
      end;
    dtFloat:
      begin
        move(DataPack[0][offset],tmpdouble,size);
        result:=tmpdouble;
      end;
    dtCurrency:
      begin
        move(DataPack[0][offset],tmpcurrency,size);
        result:=tmpcurrency;
      end;
    dtDateTime:
      begin
        move(DataPack[0][offset],tmpDatetime,size);
        result:=tmpDatetime;
      end;
    dtBlob:
      begin
        move(DataPack[0][offset],dynmIndex,sizeword);
        blobsize:=length(DataPack[dynmIndex]);
        Result := VarArrayCreate([0, blobsize], varByte);
        blobsize:=length(DataPack[dynmIndex]);
        try
          p := VarArrayLock(Result);
          move(Datapack[dynmIndex][0],p^,blobsize);
        finally
          VarArrayUnLock(Result);
        end;

        //setlength(tmpstr,blobsize);
        //move(Datapack[dynmIndex][0],tmpstr[1],blobsize);
        //result:=encode(tmpstr);
        exit;
        Raise Exception.Create('Blob Data Can not Send to Variant,'
        +'must use Stream to attach Blob Data!');
      end;
    dtDetail:
      begin
        move(DataPack[0][offset],dynmIndex,sizeword);
        blobsize:=length(DataPack[dynmIndex]);
        setlength(tmpstr,blobsize);
        move(Datapack[dynmIndex][0],tmpstr[1],blobsize);
        result:=encode(tmpstr);
      end;
    dtGuid:
      begin
        move(DataPack[0][offset],tmpid,size);
        result:=Guidtostring(tmpid);
      end;
    dtInt64:
      begin
        move(DataPack[0][offset],tmpint64,size);
        result:=tmpint64;
      end;

  end;
end;

function TDataDef.IsDynamic: Boolean;
begin
  if FDatatype in  [dtstring,dtblob,dtStructure,dtDetail]  then
    result:=true else result:=false;
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
    dtBlob:size:=dymicIndex;
    dtGuid:size:=16;
    dtInt64:size:=8;
    dtStructure:size:=dymicIndex;
    dtDetail:size:=dymicIndex;
    dtRelation:size:=dymicIndex;
  end;
  FDatatype := Value;
end;

procedure TDataDef.SetIsRecursive(const Value: boolean);
begin
  FIsRecursive := Value;
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

procedure TDataDef.SetStruc(Struc: TAutoStruc);
begin
  FStruc.SetData(Struc.GetData);
  FStructureName:=Struc.Name;
end;

procedure TDataDef.SetStructureName(const Value: String);
begin
 // if (sysStructures.GetStrucbyName('Value')=nil)  and (Value<>'') then
 //   raise exception.Create('There is no struc of name'+#39+Value+#39);
  FStructureName := Value;
end;

procedure TDataDef.SetTitle(const Value: string);
begin
  FTitle := Value;
end;

procedure TDataDef.SetValue(DataPack:TDataPack; OffSet: integer;
  value: Variant);
var
  tmpid:TGuid;
  tmpsmallint:SmallInt;
  tmpinteger:integer;
  tmpword:Word;
  tmpbool:boolean;
  tmpcurrency:Currency;
  tmpdouble:Double;
  tmpInt64:Int64;
  tmpdatetime:TDateTime;
  tmpstr:string;
  i:integer;
  strsize,dynmIndex:word;
  blobsize:integer;
  //arr: TByteDynArray;
  p: Pointer;
begin
  case FDataType of
    dtString:
      begin
        move(DataPack[0][offset],dynmIndex,sizeword);
        tmpstr:=Value;
        strsize:=length(tmpstr);
        setlength(DataPack[dynmIndex],length(tmpstr));
        move(tmpstr[1],DataPack[dynmIndex][0],strsize);
      end;
    dtSmallint:
      begin
        if(VarType(Value)=varSmallInt) then
          begin
            move(TVardata(Value).VSmallInt,DataPack[0][offset],size);
          end  else
            begin
              tmpsmallint:=value;
              move(tmpsmallint,DataPack[0][offset],size);
            end;
      end;
    dtInteger:
      begin
        if(VarType(Value)=varInteger) then
          begin
            move(TVardata(Value).VInteger,DataPack[0][offset],size);
          end else
            begin
              tmpinteger:=value;
              move(tmpinteger,DataPack[0][offset],size);
            end;
      end;
    dtWord:
      begin
        if(VarType(Value)=varWord) then
          begin
            move(TVardata(Value).VWord,DataPack[0][offset],size);
          end else
            begin
              tmpWord:=value;
              move(tmpWord,DataPack[0][offset],size);
            end;
      end;
    dtBoolean:
      begin
        if(VarType(Value)=varBoolean) then
          begin
            move(TVardata(Value).VBoolean,DataPack[0][offset],size);
          end else
            begin
              tmpbool:=value;
              move(tmpbool,DataPack[0][offset],size);
            end;
      end;
    dtFloat:
      begin
        if(VarType(Value)=varDouble) then
          begin
            move(TVardata(Value).VDouble,DataPack[0][offset],size);
          end else
            begin
              tmpdouble:=value;
              move(tmpdouble,DataPack[0][offset],size);
            end;
      end;
    dtCurrency:
      begin
        if(VarType(Value)=varCurrency) then
          begin
            move(TVardata(Value).VCurrency,DataPack[0][offset],size);
          end else
            begin
              tmpcurrency:=value;
              move(tmpcurrency,DataPack[0][offset],size);
            end;
      end;
    dtDateTime:
      begin
         if(VarType(Value)=varDate) then
          begin
            move(TVardata(Value).VDate,DataPack[0][offset],size);
          end else
            begin
              if TryStrToDateTime(value, tmpdatetime) then
                move(tmpdatetime,DataPack[0][offset],size);
            end;

      end;
    dtBlob:
      begin
        if VarIsStr(Value) then
        begin
          move(DataPack[0][offset],dynmIndex,sizeword);
          tmpstr:=Decode(Value);
          blobsize:=length(tmpstr);
          setlength(DataPack[dynmIndex],blobsize);
          move(tmpstr[1],Datapack[dynmIndex][0],blobsize);
        end else if VarIsArray(Value) then
        begin
          move(DataPack[0][offset],dynmIndex,sizeword);
          blobsize:=VarArrayHighBound(Value, 1);

          setlength(DataPack[dynmIndex],blobsize);
          try
            p := VarArrayLock(Value);
            move(p^, Datapack[dynmIndex][0],blobsize);
          finally
            VarArrayUnLock(Value);
          end;
        end;
        //exit;
        //Raise Exception.Create('Blob Data Can not Send to Variant,'
        //+'must use Stream to attach Blob Data!');
      end;
    dtStructure:
      begin
        move(DataPack[0][offset],dynmIndex,sizeword);
        tmpstr:=Decode(Value);
        blobsize:=length(tmpstr);
        setlength(DataPack[dynmIndex],blobsize);
        move(tmpstr[1],Datapack[dynmIndex][0],blobsize);
        exit;
        Raise Exception.Create('Blob Data Can not Send to Variant,'
        +'must use Stream to attach Blob Data!');
      end;
    dtDetail:
      begin
        move(DataPack[0][offset],dynmIndex,sizeword);
        tmpstr:=Decode(Value);
        blobsize:=length(tmpstr);
        setlength(DataPack[dynmIndex],blobsize);
        move(tmpstr[1],Datapack[dynmIndex][0],blobsize);
        exit;
        Raise Exception.Create('Blob Data Can not Send to Variant,'
        +'must use Stream to attach Blob Data!');
      end;
    dtGuid:
      begin
        tmpid:=StringToguid(value);
        move(tmpid,DataPack[0][offset],size);
      end;
    dtInt64:
      begin
        if(VarType(Value)=varInt64) then
          begin
            move(TVardata(Value).VInt64,DataPack[0][offset],size);
          end else
            begin
              tmpInt64:=value;
              move(tmpInt64,DataPack[0][offset],size);
            end;


      end;
  end;
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

function  TAutoContainer.Add(Obj: TAutoObj):integer;
begin
  if FAutoClass=nil then raise Exception.Create('Have not Set the Container Class!');
  if Obj is FAutoClass then Result:=AddSub(Obj)
   else raise Exception.Create('The AutoObj add to Container is Incorrect Typed!');
end;



function TAutoContainer.GetSub(Index: integer): TAutoObj;
begin
  if Index>=FSubObjects.Count then Raise Exception.Create('Index Out Of Range!');
  Result:= TAutoObj(FsubObjects.Items[index]);
end;

procedure TAutoContainer.InitByXml(XmlNode:TXmlNode);
begin
  inherited InitPropsQuick(XmlNode);
  InitSubsQuick(XmlNode.GetSubs);
end;

procedure TAutoContainer.ClearContainer;
begin
  ClearSubObjs;
  fPos:=-1;
end;

procedure TAutocontainer.InitSubsQuick(XmlNode:TXmlNode);
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
      autoclass:=TAutoObjClass(FindClass(tmpxmlnode.Getname));
      tmpobj:=AutoClass.Create;
      tmpobj.InitByXml(tmpxmlnode);
      AddSub(tmpobj);
    end;
end;

procedure TAutoContainer.GetSelfXml(Superstr: TSuperstr);
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
             superstr.Append(propname);
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

function TAutoContainer.ContainerCount: integer;
begin
  result:=FSubObjects.Count;
end;

constructor TAutoContainer.Create;
begin
  inherited;
  FSubObjects:=TAutoList.Create;
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
      Obj:=TAutoObj(FSubObjects.items[i]);
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
  if FSubobjects.Count>0 then ClearSubObjs;
  FSubObjects.Free;
  inherited;
end;

function  TAutoContainer.AddSub(Obj: TAutoObj):integer;
begin
  Result:=FSubObjects.Add(Obj)
end;

procedure TAutoContainer.SaveToStream(Stream:TStream);
var
tmpstream:Tmemorystream;
data:string;
begin
  tmpstream:=TMemoryStream.Create;
  try
    data:=self.Xml;
    Stream.WriteBuffer(Pointer(data)^,length(data));
  finally
    tmpstream.Free;
  end;
end;

procedure TAutoContainer.Update(Index: integer; Obj: TAutoObj);
var
tmpobj:TAutoObj;
begin
  tmpobj:=Get(Index);
  tmpobj.SetData(Obj.GetData);
end;

procedure TAutoContainer.Insert(Index: integer; Obj: TAutoObj);
begin
if FAutoClass=nil then raise Exception.Create('Have not Set the Container Class!');
  if Obj is FAutoClass then FSubObjects.Insert(Index,Obj)
   else raise Exception.Create('The AutoObj add to Container is Incorrect Typed!');
end;

procedure TAutoContainer.Delete(Index: integer);
var
tmpobj:TAutoObj;
begin
  if fPos>Index then dec(fPos);
  tmpobj:=Getsub(Index);
  tmpobj.Free;
  FSubObjects.Delete(Index);
end;

function TAutoContainer.GetData: TDynamicData;
var
i:integer;
tmpObj:TAutoObj;
size,capacity:integer;
tmpdata:TDynamicData;
count:integer;
datasize:integer;
containersize:integer;
delta:integer;
Reserved:integer;
begin
  capacity:=1024;
  //tmpdata:=inherited GetData;
  count:=ContainerCount;
  Reserved:=sizeof(size)+sizeof(count);
  size:=Reserved;
  //datasize:=length(tmpdata);
  if (datasize+sizeof(count)+sizeof(size)+size)>capacity then
    begin
      capacity:=capacity+datasize+datasize shr 2+16;
    end;
  setlength(Result,capacity);
  //move(tmpdata[0],Result[size],datasize);
  //inc(size,datasize);
  for i:=0 to count-1 do
    begin
      tmpdata:=GetSub(i).GetData;
      datasize:=length(tmpdata);
      if (datasize+size)>capacity then
        begin
          delta:=capacity shr 2;
          if delta<datasize then delta:=datasize+datasize shr 2 +16;
          capacity:=capacity+delta;
          setlength(Result,capacity);
        end;
      MoveQuick(@tmpdata[0],@Result[size],datasize);
      inc(size,datasize);
    end;
  Pinteger(@Result[0])^:=size;
  Pinteger(@Result[sizeinteger])^:=count;
  SetLength(Result,size);
end;

procedure TAutoContainer.SetData(Data: TDynamicData);
var
i:integer;
size,capacity:integer;
tmpdata:TDynamicData;
count:integer;
//Reserved:integer;
fclassname:string;
classsize:integer;
fPos:integer;
tmpobj:TAutoObj;
fClass:TAutoObjClass;
fnotinited:boolean;
begin
  fnotinited:=true;
  ClearSubObjs;
  count:=PInteger(@Data[sizeinteger])^;
  fPos:=sizeInteger+sizeInteger;//保留2个整形数据标志数据包的大小和数据块的数量
  //size:=Pinteger(@Data[fPos])^;
  //setlength(tmpdata,size);
  //Move(Data[fPos],tmpdata[0],size);
  //inherited SetDataQuick(tmpData);
  //inherited SetDataQuick(@Data[fPos]);
  //inc(fPos,size);
  for i:=0 to count-1 do
    begin
      size:=Pinteger(@Data[fPos])^;
      //SetLength(tmpdata,size);
      //Move(Data[fPos],tmpdata[0],size);
      if fnotinited then
        begin
          //classsize:=Pinteger(@tmpdata[sizeinteger])^;
          classsize:=Pinteger(@data[fPos+sizeinteger])^ ;
          setlength(fclassname,classsize);
          //move(tmpdata[sizeof(integer)+sizeof(integer)],fclassname[1],classsize);
          move(Data[fPos+sizeinteger+sizeinteger],fclassname[1],classsize);
          fClass:=TAutoObjClass(FindClass(fclassname));
          fnotinited:=false;
        end;
      tmpobj:=fClass.Create;
      //tmpobj.SetDataQuick(tmpdata);
      try
      tmpobj.SetDataQuick(@Data[fPos]);
      except
        raise;
      end;
      AddSub(tmpobj);
      inc(fPos,size);
    end;
end;

function TAutoContainer.DeleteObj(Obj: TAutoObj):integer;
begin
  result:=FSubObjects.Remove(Obj);
  Obj.Free;
end;

procedure TAutoContainer.SetCapacity(Capacity: integer);
begin
  FSubObjects.Capacity:=Capacity;
end;

procedure TAutoContainer.SetDataQuick(Data: Pointer);
var
i:integer;
classsize:integer;
size:integer;
count:integer;
fclassname:string;
fPos:PChar;
tmpobj:TAutoObj;
fClass:TAutoObjClass;
fnotinited:boolean;
frev:integer;
begin
  fnotinited:=true;
  ClearSubObjs;
  fPos:=PChar(Data)+sizeinteger;
  //读取容器的容量
  count:=PInteger(fPos)^;
  inc(fPos,sizeinteger);
  //size:=Pinteger(fPos+SizeInteger)^;
  //inherited SetDataQuick(fPos);
  //inc(fPos,size);
  for i:=0 to count-1 do
    begin
      size:=Pinteger(fPos)^;
      if fnotinited then
        begin
          classsize:=Pinteger(fPos+sizeinteger)^ ;
          setlength(fclassname,classsize);
          move((fPos+sizeinteger+sizeinteger)^,fclassname[1],classsize);
          fClass:=TAutoObjClass(FindClass(fclassname));
          fnotinited:=false;
        end;
      tmpobj:=fClass.Create;
      tmpobj.SetDataQuick(fPos);
      AddSub(tmpobj);
      inc(fPos,size);
    end;
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



constructor TAutoStruc.Create;
begin
  inherited Create;
  FDefs:=TDataDefContainer.Create;
  FActive:=false;
  FAllocSize:=-1;
end;

destructor TAutoStruc.Destroy;
begin
  FDefs.Free;
  //FStrucContainer.Free;
  inherited;
end;

function TAutoStruc.GetAllocSize: integer;
var
i:integer;
begin
  if FAllocSize=-1 then
    begin
      FAllocSize:=0;
      for i:=0 to Defs.ContainerCount-1 do
        begin
          fAllocSize:=fAllocSize+((Defs.GetSub(i))as TDataDef).GetAllocSize;
        end;
    end ;
    Result:=fAllocSize;
end;

function TAutoStruc.GetDataTypeof(Index: integer): TDataType;
begin
  result:=StrucInfos[Index].DataDef.Datatype;
end;

function TAutoStruc.GetIndexOf(Name: string): integer;
var
i:integer;
hashcode:integer;
begin
  if fActive then
    begin
      hashcode:=GetStringHash(Name);
      for i:=0 to Length(StrucInfos)-1 do
        begin
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
dyindex:word;
tmpdef:TDataDef;
begin
  if fActive then exit;
  dyindex:=1;
  fDynamicCount:=0;
  SetLength(StrucInfos,Defs.ContainerCount);
  for i:=0 to Length(StrucInfos)-1 do
    begin
      tmpdef:=TDataDef(Defs.GetSub(i));
      StrucInfos[i].DataDef:=tmpdef;
      StrucInfos[i].OffSet:=GetOffSetof(i);
      StrucInfos[i].HashCode:=GetStringHash(StrucInfos[i].DataDef.Name);
      StrucInfos[i].isDynamic:=tmpdef.IsDynamic;
      if tmpdef.IsDynamic then
        begin
         StrucInfos[i].DynamicIndex:=dyindex;
         inc(dyIndex);
         inc(fDynamicCount);
        end;
      if tmpdef.Datatype in [dtDetail, dtStructure] then
        begin
          tmpdef.Struc.InitStruc;
        end;
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

procedure TAutoStruc.SetKeyProp(const Value: string);
begin
  FKeyProp := Value;
end;

function TAutoStruc.IsStatic: Boolean;
var
i:integer;
begin
  Result:=true;
  for i:=0 to fDefs.ContainerCount-1 do
    begin
       if StrucInfos[i].DataDef.Datatype in [dtString,dtBlob,dtStructure,dtDetail]
         then
           begin
             result:=false;
             exit;
           end;
    end;
end;

function TAutoStruc.GetDymicCount: integer;
begin
  Result:=FDynamicCount;
end;

{ TDatadefContainer }







procedure TAutoStruc.InitByXml(XmlNode: TXmlNode);
begin
  inherited InitByXml(XmlNode);
  fActive:=false;
  InitStruc;
end;

{ TStrucContainer }

constructor TStrucContainer.Create;
begin
  inherited;
  
end;

function TStrucContainer.GetStrucbyName(name: string): TAutoStruc;
var
i:integer;
Struc:TAutoStruc;
begin
  Result:=nil;
  for i:=0 to ContainerCount-1 do
    begin
      Struc:=GetSub(i) as TAutoStruc;
      if name=Struc.name then
        begin
          if not(Struc.FActive) then Struc.InitStruc;
          result:=Struc;//TAutoStruc(GetSub(i));
          //Result.InitStruc;
          Break;
        end;
    end;
  if Result=nil then  Raise Exception.Create('Can not find Struc '+name);
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
  if fInited then Result:=fStructure.GetDataDef(Index).GetValue(fDynmData,
    fStructure.GetDataOffset(Index)) else raise exception.Create('Must set struc first');
end;

function TDynmObj.GetStringData(Index: integer): string;
var
tmpinfo:PStrucInfo;
begin
  if fInited then
    begin
      tmpinfo:=@(fStructure.StrucInfos[Index]);
      Result:=tmpinfo.DataDef.GetStringValue(fDynmData,
      tmpinfo.OffSet);
    end else raise exception.Create('Must set struc first');
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
classmark:string;
tmpinfo:PStrucInfo;
ptmp:pointer;
begin
  classmark:=fStructure.name+'>';
  superstr.AddBegin;
  superstr.Append(classmark);
  for i:=0 to fStructure.Defs.ContainerCount-1 do
    begin
      tmpinfo:=@(fStructure.StrucInfos[i]);
      propname:=tmpinfo.DataDef.Name;
      if tmpinfo.DataDef.Datatype=dtDetail then
        begin
          move(fDynmData[tmpinfo.dynamicIndex][0],Ptmp,sizeof(pointer));
          superstr.AddBegin;
          superstr.Append(propname);
          superstr.AddOver;
          TDynamiccontainer(Ptmp).GetSelfXml(Superstr);
          superstr.AddEnd;
          superstr.Append(propname);
          superstr.AddOver;
      end else if tmpinfo.DataDef.Datatype=dtStructure then
        begin
          move(fDynmData[tmpinfo.dynamicIndex][0],Ptmp,sizeof(pointer));
          superstr.AddBegin;
          superstr.Append(propname);
          superstr.AddOver;
          TDynmObj(Ptmp).GetSelfXml(Superstr);
          superstr.AddEnd;
          superstr.Append(propname);
          superstr.AddOver;
        end else
          begin
            superstr.AddSpace;
            superstr.Append(propname);
            superstr.Addequal;
            superstr.Append(GetStrOfStruc(tmpinfo));
            superstr.AddDataEnd;
          end;
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
tmpinfo:PStrucInfo;
Ptmp:Pointer;
struc: TAutoStruc;
begin
  SetLength(fDynmData,Structure.GetDymicCount+1);
  SetLength(fDynmData[0],Structure.GetAllocSize);
  for i:=0 to length(Structure.StrucInfos)-1 do
    begin
      tmpinfo:=@(Structure.StrucInfos[i]);
      if tmpinfo.isDynamic then
      PWord(@fDynmData[0][tmpinfo.OffSet])^:=tmpInfo.DynamicIndex;
      if tmpinfo.DataDef.Datatype in [dtDetail, dtStructure] then
        begin
          setlength(fDynmData[tmpinfo.dynamicIndex],sizeof(pointer));
          //高洪亮修改begin   
          if tmpinfo.DataDef.IsRecursive then
          begin
            if Structure.name=tmpinfo.DataDef.StructureName then
              struc:=Structure
            else struc := SysStructures.GetStrucbyName(tmpinfo.DataDef.StructureName)
          end else
            struc := tmpinfo.DataDef.Struc;
          //高洪亮修改end
          //原来的代码
          {
          if tmpinfo.DataDef.IsRecursive then
            struc := SysStructures.GetStrucbyName(tmpinfo.DataDef.StructureName)
          else
            struc := tmpinfo.DataDef.Struc;
          }
          if tmpinfo.DataDef.Datatype = dtDetail then
            Ptmp:=TDynamiccontainer.CreatebyStructure(struc)
          else
            Ptmp:=TDynmObj.CreatebyStructure(struc);
          move(Ptmp,fDynmData[tmpinfo.dynamicIndex][0],sizeof(pointer));  
          {if tmpinfo.DataDef.IsRecursive then
            begin
              Ptmp:=TDynamiccontainer.CreatebyStructure(SysStructures.GetStrucbyName(tmpinfo.DataDef.StructureName));
            end else Ptmp:=TDynamiccontainer.CreatebyStructure(tmpinfo.DataDef.Struc);
          move(Ptmp,fDynmData[tmpinfo.dynamicIndex][0],sizeof(pointer));
        end
      else if tmpinfo.DataDef.Datatype=dtStructure then
      begin
         setlength(fDynmData[tmpinfo.dynamicIndex],sizeof(pointer));
         if tmpinfo.DataDef.IsRecursive then
            begin
              Ptmp:=TDynmObj.CreatebyStructure(SysStructures.GetStrucbyName(tmpinfo.DataDef.StructureName));
            end else Ptmp:=TDynmObj.CreatebyStructure(tmpinfo.DataDef.Struc);
         move(Ptmp,fDynmData[tmpinfo.dynamicIndex][0],sizeof(pointer));   }
      end;
    end;
  fStructure:=Structure;
  fInited:=true;
end;

procedure TDynmObj.SetData(Index: integer; value: variant);
begin
  if fInited then  fStructure.GetDataDef(Index).SetValue(fDynmData,
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
  inherited Destroy;
  if not(fInitedbyStructure) then FStructure.Free;
end;


function TDynamicContainer.GetDataDef(Index: integer): TDataDef;
begin
  if fInitedbyStructure then Result:=fStructure.GetDataDef(Index)
    else Raise Exception.Create('Must Init Struc of DynamicContainer!');
end;

function TDynamicContainer.GetDataOffset(Index: integer): integer;
begin
  if fInitedbyStructure then Result:=fStructure.GetDataOffset(Index)
    else Raise Exception.Create('Must Init Struc of DynamicContainer!');
end;

function TDynamicContainer.GetDefCount: integer;
begin
  //result:=length(strucinfos);
  result:=fStructure.Defs.ContainerCount;
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
  stru: TAutoStruc;
begin
  ClearSubObjs;
  if XmlNode=nil then exit;

  subcount:=XmlNode.GetCount;
  for i:=0 to subcount-1 do
    begin
      tmpxmlnode:=Xmlnode.GetChild(i);
      //--- and by xk 2006.7.19
      VerifyStructure(tmpxmlnode);
      tmpobj:=NewData;
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
end;

function TDynamicContainer.NewData: TDynmObj;
begin
  if fInitedbyStructure then
    begin
      result:=TDynmobj(NewSub);
      result.InitbyContainer(Self);
    end else raise Exception.Create('Must set Struc first');
end;

procedure TDynamicContainer.SetStructure(const Value: TAutoStruc);
begin
  fInitedbyStructure:=true;
  FStructure := Value;
  InitContainer;
end;

procedure TDynamicContainer.SetStructureXml(const Value: string);
begin
  FStructure.Xml:=Value;
  Initcontainer;
end;

procedure TDynamicContainer.SetXml(Xml: string);
var
  XmlEng:TXmlEngine;
  name:String;
  AutoStruc:TAutoStruc;
begin

  //2006.7.17 修改..by 老高
  //inherited;
  XmlEng:=TXmlEngine.Create;
  XmlEng.DataXml:=Xml;
  VerifyStructure(xmlEng.Getroot);
  InitByXml(xmlEng.Getroot);
  XmlEng.Free;
  //-----------------------------------------------------------------

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
  
end;

constructor TDynamicContainer.CreatebyStructure(Structure: TAutoStruc);
begin
  inherited Create;
  if Structure=nil then
    begin
      FStructure:=TAutoStruc.Create;
      fInitedbyStructure:=false;
      fIsAcid:=true;
      exit;
    end;
  SetStructure(Structure);
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
  if not fInitedbyStructure then Raise Exception.Create('must init container before save to disk');
  DataStream:=TFileStream.Create(FileName,fmCreate,fmShareDenyWrite);
  {try
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
  end; }

end;

procedure TDynamicContainer.LoadFromFile(FileName: string);
var
DataStream:TFileStream;
StrucXml:string;
StrucSize:integer;
Datasize,i:integer;
tmpdata:TDynmObj;
begin
  {if not fActive then Raise Exception.Create('must init container before save to disk');
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
  end; }

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
  if fInitedbyStructure then
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
  if fInitedbyStructure then
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

function  TDynamicContainer.Add(Obj: TAutoObj):integer;
begin
  if TDynmObj(obj).fStructure<>FStructure then
    raise exception.Create('Not same structure,Can not append to DynamicContainer');
  Result:=inherited Add(Obj);

end;

procedure TDynamicContainer.Insert(Index: integer; Obj: TAutoObj);
begin
  if TDynmObj(obj).fStructure<>FStructure then
    raise exception.Create('Not same structure,Can not append to DynamicContainer');
  inherited Insert(Index,Obj);
end;

procedure TDynamicContainer.GetSelfXml(Superstr: TSuperstr);
var
i:integer;
Classmark:string;
begin
  //classmark:=fStructure.name+'>';
  superstr.AddBegin;
  superstr.Append(fStructure.name);
  superstr.AddOver;
  //superstr.Append(classmark);
  superstr.Append('<subs>');
  for i:=0 to ContainerCount-1 do
    begin
      GetSub(i).GetSelfXml(Superstr);
    end;
  superstr.Append('</subs>');
  superstr.AddEnd;
  superstr.Append(fStructure.name);
  superstr.AddOver;
end;


class function TDynamicContainer.GetSysStructure(
  XmlNode: TXmlNode): TAutoStruc;
begin
  Result := SysStructures.GetStrucbyName(XmlNode.Getname);
end;

procedure TDynamicContainer.VerifyStructure(XmlNode: TXmlNode);
begin
  if not fInitedbyStructure then
    SetStructure(GetSysStructure(XmlNode));
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
      if tmpdef.Datatype=dtDetail then
        begin
          GetDetailData(i).InitByXml(xmlnode.GetChildByName(tmpdef.Name).GetChild(0));
        end else if tmpdef.Datatype=dtStructure then
        begin
          //GetStructureData(i).InitByXml(xmlnode.GetChildByName(tmpdef.Name));
          GetStructureData(i).InitByXml(xmlnode.GetChildByName(tmpdef.Name).GetChild(0));
        //end else if tmpdef.Datatype=dtBlob then
        //begin
        end else SetData(i,xmlNode.GetAttribValue(tmpdef.Name));
    end;
end;

function TDynmObj.GetContainer(Index: integer): TDynamicContainer;
begin
  result:=self.GetDetailData(index);
end;

{ TDataDefContainer }

procedure TDataDefContainer.InitContainerClass;
begin
  inherited;
  FAutoClass:=TDataDef;
end;

procedure TDynmObj.InitObjData(Data: TDynamicData);
begin
  fDynmData[0]:=Data;
end;

function TDynmObj.GetPackData: TDynamicData;
var
i,count:integer;
datasize:integer;
fpos:integer;
allsize:integer;
posinfo:array of integer;
reserved:integer;
begin
  //数据包的结构是包大小(integer)
  //包含的数据块数量(integer),包括定长部分1个,变长部分由动态结构决定
  //每个包的具体尺寸列表(array of integer)
  fPos:=sizeinteger*2;//留出2个整型数据空间用来表示数据包的大小和数据块数
  count:=length(fDynmData);
  Reserved:=(count+2)*sizeinteger;
  datasize:=Reserved;
  setlength(posinfo,count);
  //posinfo[0]:=count;
  for i:=0 to count-1 do
    begin
      posinfo[i]:=length(fDynmData[i]);
      inc(datasize,posinfo[i]);
    end;
  setlength(Result,datasize);
  Pinteger(@Result[0])^:=datasize;
  Pinteger(@Result[sizeinteger])^:=count;
  Move(Posinfo[0],Result[fPos],Reserved-sizeinteger-sizeinteger);
  fPos:=Reserved;
  for i:=0 to count-1 do
    begin
      if posinfo[i]>0 then
        begin
          Move(fDynmData[i][0],Result[fpos],posinfo[i]);
        end;
      inc(fPos,Posinfo[i]);
    end;

end;

procedure TDynmObj.SetPackData(Data: TDynamicData);
var
i,fpos,fcount:integer;
datasize:integer;
tmpdata:TDynamicData;
allsize:integer;
reserved:integer;
Posinfo:array of Integer;
begin
  fcount:=Pinteger(@Data[SizeInteger])^;
  //SetLength(fDynmData,0);
  Setlength(fDynmData,fcount);
  setlength(posinfo,fcount);
  reserved:=(fcount+2)*sizeinteger;
  Move(data[SizeInteger*2],Posinfo[0],reserved-sizeinteger-sizeinteger);
  //MoveQuick(@data[SizeInteger],@Posinfo[0],reserved-sizeinteger);
  fPos:=reserved;
  for i:=0 to fcount-1 do
    begin
      datasize:=posinfo[i];
      //if datasize>4000 then Raise Exception.Create('Data pack err!');
      setlength(fDynmData[i],datasize);
      if datasize>0 then
        begin
          //Movequick(@Data[fpos],@fDynmData[i][0],datasize);
          Move(Data[fpos],fDynmData[i][0],datasize);
        end;
      inc(fpos,datasize);
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
  if fInitedbyStructure then
    begin
      result:=TDynmobj(NewSub);
      ResetData;
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
  CreateGuid(FObjid);
  //FObjid:=StringtoGuid(GetNewId);
  //FObjid:=GetNewId;
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

function TNamedTreeObj.GetName: string;
begin
  result:=fName;
end;

procedure TNamedTreeObj.SetName(const Value: string);
begin
  fName:=value;
end;

function TUniqueObj.Getobjid:String;
begin
  result:=Guidtostring(fObjid);
  //result:=Variant(fObjid);
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

{constructor TIndexNodebak.Create;
begin
  inherited;
  Balance:=0;
  Left:=nil;
  Right:=nil;
  Parent:=nil;
  Data:=nil;
end; }

{ TSublist }

function TSublist.GetIsFull: boolean;
begin
  if self.Count=BlockMax then result:=true else result:=false;
end;

function TSublist.GetMaxObj: TAutoObj;
begin
  if count=0 then result:=nil else
  Result:=TAutoObj(Items[count-1]);
end;

function TSublist.GetMinObj: TAutoObj;
begin
  if count=0 then result:=nil else
  Result:=TAutoObj(Items[0]);
end;

procedure TSublist.Grow;
var
Delta:integer;
NewSize:integer;
begin
  if Capacity >=64 then Delta := Capacity div 2
  else  Delta := 32 ;
  newsize:=Capacity+Delta;
  if newsize<BlockMax then
  SetCapacity(newsize) else SetCapacity(BlockMax);

end;

procedure TSublist.Pack;
begin
  isPacked:=true;
end;


procedure TSublist.SetBlockIndex(const Value: int64);
begin
  FBlockIndex := Value;
end;

procedure TSublist.SetIsLeaf(const Value: Boolean);
begin
  FIsLeaf := Value;
end;

procedure TSublist.SetIsPacked(const Value: boolean);
begin
  FIsPacked := Value;
end;

procedure TSublist.UnPack;
begin
  isPacked:=false;
end;

{ TBlockList }

procedure TBlockList.Add(Obj: TAutoObj);
var
i:integer;
BlockIndex:integer;
tmpblock:TSubList;
Posofblock:integer;
tmpobj:TAutoObj;
Range:integer;
cmpresult:integer;
PosStart,PosEnd:integer;
key:variant;

begin
  if fObjkeyindex=-99 then
    begin
      fObjkeyIndex:=Obj.GetIndexOfProp(FIndexProp)
    end;
  key:=Obj.GetKeyValue(fObjkeyindex);
  BlockIndex:=GetBlockIndexofkey(0,fsublist.Count-1,key);
  tmpblock:=TSublist(fSublist.items[blockIndex]);
  While  tmpblock.IsFull do
    begin
      self.SpliteBlock(blockIndex,blockMax div 2);
      BlockIndex:=GetBlockIndexofkey(BlockIndex,BlockIndex+1,key);
      tmpblock:=TSublist(fSublist.items[blockIndex]);
    end;
  if tmpblock.Count=0 then
    begin
      tmpblock.Add(obj);
      exit;
    end;
  Range:=(tmpblock.Count+1) div 2;
  PosofBlock:=tmpblock.Count div 2;
  while Range<>0 do
    begin
      tmpobj:=TAutoObj(tmpblock.items[posofblock]);
      cmpresult:= Cmp(tmpobj.GetKeyValue(fobjkeyindex),key);
      if cmpresult=0 then range:=0 else
        begin
          if cmpresult=1 then
            begin
              Range:=Range div 2 ;
              if (Range=0) and (posofblock>0) then
                dec(Posofblock) else
                  begin
                    posofblock:=posofblock-Range-1;
                    if posofblock<0 then posofblock:=0;
                  end;
            end;
          if cmpresult=-1 then
            begin
              Range:= Range div 2;
              if (Range=0) and (posofblock<(tmpblock.Count-1)) then
                inc(posofblock) else
                  begin
                    posofblock:=posofblock+Range+1;
                    if posofblock>(tmpblock.Count-1)
                     then posofblock:=tmpblock.Count-1;
                  end;
            end;
        end;
    end;
  tmpobj:=TAutoObj(tmpblock.items[posofblock]);
  cmpresult:= Cmp(tmpobj.GetKeyValue(fobjkeyindex),key);
  if cmpresult in [0,1] then  tmpblock.Insert(posofblock,obj)
  else
    begin
      if posofblock=tmpblock.Count-1 then tmpblock.Add(obj) else
         tmpblock.Insert(Posofblock+1,obj);
    end;
end;

function TBlockList.blockcount: integer;
begin
  Result:=fsublist.Count;
end;

function TBlockList.Cmp(BaseValue, CmpValue:Variant): integer;
var
PBase,PCmp:Pchar;
begin
  result:=0;
  Case TVarData(BaseValue).VType of
    VarString:
      begin
        PBase:= TVarData(BaseValue).VString;
        PCmp:= TVarData(BaseValue).VString;
        While (byte((PBase)^)<> 0)  and (byte((PBase)^)<> 0) do
          begin
            if (PBase)^>(PCmp)^ then
              begin
                Result:=1;
                Exit;
              end else
                begin
                  if (PBase)^<(PCmp)^  then
                    begin
                      Result:=-1;
                      exit;
                    end;
                end;
            inc(PBase);
            inc(PCmp);
          end;
        if (PBase)^= (PCmp)^  then exit;
        if byte(PBase^)=0 then result:=-1 else result:=1;
      end;
    VarInteger:
      begin
        if TVarData(BaseValue).VInteger>TVarData(CmpValue).VInteger then
          begin
            Result:=1;
            exit;
          end;
        if TVarData(BaseValue).VInteger<TVarData(CmpValue).VInteger then
          begin
            result:=-1;
            exit;
          end;
      end;
    else
      begin
        if BaseValue>CmpValue then
          begin
            Result:=1;
            exit;
          end;
        if CmpValue<BaseValue then
          begin
            result:=-1;
            exit;
          end;
        end;
   end;
end;

function TBlockList.CmpObj(BaseObj,CmpObj:TAutoObj;Propname:string): integer;
var
tmp1,tmp2:variant;
begin
  result:=0;
  tmp1:=BaseObj.GetDataOf(Propname);
  tmp2:=CmpObj.GetDataOf(propname);
  if tmp1>tmp2 then
    begin
      Result:=1;
      exit;
    end;
  if tmp1<tmp2 then
    begin
      result:=-1;
      exit;
    end;
end;

constructor TBlockList.create;
begin
  inherited;
  FSubList:=TAutolist.Create;
  Fsublist.Add(Tsublist.Create);
  fobjkeyindex:=-99;
end;

procedure TBlockList.Delete;
var
tmplist:TSublist;
begin
  tmplist:=TSublist(fsublist.Items[FBlockIndex]);
  tmplist.Delete(fDataIndex);
end;

destructor TBlockList.Destroy;
var
i:integer;
begin
  for i:=0 to fsublist.Count-1 do
    begin
      TSublist(fsublist.Items[i]).free;
    end;
  fsublist.Free;
  inherited;
end;



procedure TBlockList.First;
begin
  fPos:=0;
  FBlockIndex:=0;
  FDataIndex:=0;
end;

function TBlockList.GetBlockIndexIn(startIndex, endIndex: integer;
  Obj: TAutoObj): integer;
var
pos:integer;
tmpblock:Tsublist;
cmpmax,cmpmin:integer;
maxobj,minobj:TAutoObj;
begin
  if StartIndex=endindex then
    begin
      result:=startIndex;
      exit;
    end;
  pos:=(startIndex+endIndex) div 2;
  {if Pos=0 then
    begin
      Result:=0;
      exit;
    end;
  if Pos=fsublist.Count-1 then
    begin
      Result:=endIndex;
      exit;
    end; }
  tmpblock:=TSublist(fsublist.items[pos]);
  maxObj:=tmpblock.GetMaxObj;
  if MaxObj<>nil then  cmpmax:= cmpobj(Maxobj,Obj,FIndexProp)
    else begin
           result:=0;
           exit;
         end;
  if cmpmax in [1,0] then
    begin
      if Pos=0 then
        begin
          result:=Pos;
          exit;
        end;
      cmpmin:=cmpobj(obj,tmpblock.GetMinObj,FindexProp) ;
      if  cmpmin in [1,0] then
        begin
          result:=Pos;
          exit;
        end else
          begin

            tmpblock:=TSublist(fsublist.items[pos-1]);
            maxobj:=tmpblock.GetMaxObj;
            cmpmax:=cmpobj(maxobj,obj,FindexProp);
            if cmpmax in [1,0] then  result:=GetblockIndexIn(startIndex,Pos-1,Obj) else
              begin
                result:=Pos;
                exit;
              end;
          end;
    end  else
      begin
        if Pos=(fsublist.count-1) then
          begin
            result:=Pos;
            exit;
          end else
            begin
              tmpblock:=TSublist(fsublist.items[pos+1]);
              minobj:=tmpblock.GetMinObj;
              cmpmin:=cmpobj(minobj,obj,FindexProp);
              if cmpmin =-1 then result:=GetblockIndexIn(Pos+1,endIndex,Obj) else
                begin
                  result:=pos;
                  exit;
                end;
            end;
      end;
end;

function TBlockList.GetBlockIndexofKey(startIndex, endIndex: integer;
  key: Variant): integer;
var
pos:integer;
tmpblock:Tsublist;
cmpmax,cmpmin:integer;
maxobj,minobj:TAutoObj;
maxkey,minkey:variant;
begin
  if StartIndex=endindex then
    begin
      result:=startIndex;
      exit;
    end;
  pos:=(startIndex+endIndex) div 2;
  tmpblock:=TSublist(fsublist.items[pos]);
  maxObj:=tmpblock.GetMaxObj;
  if MaxObj<>nil then
    begin
     maxkey:=maxobj.GetKeyValue(fobjkeyindex);
     cmpmax:= cmp(MaxKey,key);
    end
      else
        begin
          result:=0;
          exit;
        end;
  if cmpmax in [1,0] then
    begin
      if Pos=0 then
        begin
          result:=Pos;
          exit;
        end;
      minObj:=tmpblock.GetMinObj;
      cmpmin:=cmp(key,minObj.GetKeyValue(fobjkeyindex)) ;
      if  cmpmin in [1,0] then
        begin
          result:=Pos;
          exit;
        end else
          begin
            tmpblock:=TSublist(fsublist.items[pos-1]);
            maxobj:=tmpblock.GetMaxObj;
            cmpmax:=cmp(maxobj.GetKeyValue(fobjkeyindex),key);
            if cmpmax in [1,0] then  result:=GetblockIndexOfKey(startIndex,Pos-1,key) else
              begin
                result:=Pos;
                exit;
              end;
          end;
    end  else
      begin
        if Pos=(fsublist.count-1) then
          begin
            result:=Pos;
            exit;
          end else
            begin
              tmpblock:=TSublist(fsublist.items[pos+1]);
              minobj:=tmpblock.GetMinObj;
              cmpmin:=cmp(minobj.GetKeyValue(fobjkeyindex),key);
              if cmpmin =-1 then result:=GetblockIndexofkey(Pos+1,endIndex,key) else
                begin
                  result:=pos;
                  exit;
                end;
            end;
      end;
end;

function TBlockList.GetBlockIndexofObj(Obj: TAutoObj): integer;
begin
  Result:= GetBlockIndexIn(0,fsublist.count-1,Obj);
  Result:=GetBlockIndexofKey(0,fsublist.Count-1,Obj.GetDataOf(fIndexProp));
end;



function TBlockList.GetItems(ItemIndex: integer): TObject;
var
i,pos:integer;
tmpblock:TSublist;
begin
  Pos:=0;
  i:=0;
  Result:=nil;
  While Pos<ItemIndex do
    begin
      tmpblock:=TSublist(fSublist.items[i]);
      if Pos+tmpblock.Count>ItemIndex then
        begin
          Result:=tmpblock.Items[ItemIndex-Pos];
          exit;
        end;
      inc(Pos,tmpblock.Count);
      inc(i);
    end;

end;

function TBlockList.GetObj: TAutoObj;
var
tmpblock:TSublist;
begin
  tmpblock:=TSublist(Fsublist.items[fBlockIndex]);
  result:=TAutoObj(tmpblock.items[fDataIndex]);
end;

function TBlockList.GetObjByKey(Key: variant): TAutoObj;
var
blockindex:integer;
fObjkey:Variant;
tmpblock:TSublist;
Range:integer;
begin
 //GetBlockIndexofObj(key)
  result:=nil;
  blockindex:=GetBlockIndexofKey(0,fsublist.Count-1,key);
  tmpblock:=TSublist(fSublist.items[blockindex]);
  Range:=tmpblock.count-(tmpblock.count div 2);
  if fObjKeyIndex=-99 then raise exception.Create('Have not enter any data');
  fObjKey:= TAutoObj(tmpblock.Items[Range]).GetKeyValue(fObjKeyIndex);
  While Range>0 do
    begin


    end;


end;

procedure TBlockList.InsertAutoObj(Obj: TAutoObj);
begin

end;

procedure TBlockList.Next;
var
tmpblock:TSublist;
begin
  tmpblock:=TSublist(Fsublist.items[fBlockIndex]);
  if tmpblock.Count-1>fDataIndex then
    begin
      fDataIndex:=fDataIndex+1;
      fPos:=fPos+1 ;
    end else
      begin
        if fblockIndex<fsublist.Count-1 then
          begin
            fDataIndex:=0 ;
            fBlockIndex:=fBlockIndex+1;
            fPos:=fPos+1;
          end;
      end;
end;

procedure TBlockList.PackBlock(Block1, Block2: TSubList);
var
PackCount,i:integer;
begin
  if Block1.Count+Block2.Count>BlockMax then
    begin
      for i:=Block1.Count to BlockMax do
        begin
          Block1.Add(Block2.Items[0]);
          Block2.Delete(0);
        end;
    end else
          for i:=Block1.Count to (Block1.Count+Block2.Count) do
            begin
              Block1.Add(Block2.Items[0]);
              Block2.Delete(0);
            end;
end;

procedure TBlockList.PackBlocks(StartIndex: integer);
var
BlockFirst,BlockSecond:TSubList;
begin
  BlockFirst:=TSubList(Fsublist.items[StartIndex]);
  BlockSecond:=TSubList(Fsublist.items[StartIndex+1]);
  PackBlock(BlockFirst,BlockSecond);
  if BlockSecond.Count=0 then
    begin
      FSublist.Delete(StartIndex+1);
      BlockSecond.Free;
    end;

end;

procedure TBlockList.SetIndexProp(const Value: shortstring);
begin
  FIndexProp := Value;
end;

procedure TBlockList.SetItems(ItemIndex: integer; const Value: TObject);
begin

end;

procedure TBlockList.SpliteBlock(BlockIndex, Index: integer);
var
oldBlock:TSublist;
tmpBlock:TSubList;
i:integer;
begin
  oldBlock:=TSublist(Fsublist.items[BlockIndex]);
  tmpBlock:=TSubList.Create;
  FSubList.Insert(BlockIndex+1,tmpBlock);
  for i:=Index to oldblock.Count-1 do
    begin
      tmpblock.Add(oldblock.Items[i]);
    end;
  for i:= Oldblock.Count-1 downto Index do
    begin
      Oldblock.Delete(i);
    end;
end;

function TAutoObj.GetKeyValue(KeyIndex: integer): variant;
begin
  result:=null;
end;

function TUniqueObj.GetKeyValue(KeyIndex: integer): variant;
begin
  case keyindex of
    0:Result:=Variant(fobjid);//Guidtostring(fobjid);
  end;
end;

function TAutoObj.GetIndexOfProp(PropName: shortstring): integer;
var
PPropinf:PPropinfo;
i:integer;
begin
  PPropinf:=GetPropinfo(self,PropName);
  Result:=PPropinf.NameIndex;
  result:=-1;
  for i:=0 to propcount-1 do
    begin
      if Proplist^[i].Name=PropName then
        begin
          result:=i;
          exit;
        end;
    end;
end;

function TDynmObj.GetIndexOfProp(PropName: shortstring): integer;
begin
  Result:=fStructure.GetIndexOf(PropName);
end;

function TDynmObj.GetKeyValue(KeyIndex: integer): variant;
begin
  Result:=GetData(KeyIndex);
end;

{ TAutoBlock }

procedure TAutoBlock.AppendData(Data: TDynamicData);
begin

end;

function TAutoBlock.GetData(index: integer): TDynamicData;
begin

end;

function TAutoBlock.GetRemainSize: integer;
begin

end;

function TDynmObj.GetDataArray(Index: integer): TDynamicData;
var
PDefInfo:PStrucInfo;
begin
  if fInited then
    begin
      PDefInfo:=@(fStructure.StrucInfos[index]);
      if PDefInfo.isDynamic then Result:=fDynmData[PDefinfo.DynamicIndex] else
        begin
          Setlength(Result,PDefInfo.DataDef.Size);
          move(fDynmData[0][PDefInfo.Offset],Result[0],PDefInfo.DataDef.Size);
        end;
    end
    else raise exception.Create('Must set struc first');
end;

//将自己与输入的对象作比较，根据设定的特征来判断大小
function TAutoObj.CmpWith(Obj: TAutoObj; PropName: string): integer;
begin

end;

function TAutoObj.GetData: TDynamicData;
var
i:integer;
PropInfo: PPropInfo;
size,capacity:integer;
tmpdata:TDynamicData;
appendsize:integer;
delta:integer;
fclassname:shortstring;
begin
  capacity:=512;
  size:=sizeinteger+sizeinteger;
  SetLength(Result,capacity);
  fClassname:=self.ClassName;
  appendsize:=length(fClassname);
  Move(fClassName[1],result[size],appendsize);
  Pinteger(@Result[size-sizeinteger])^:=appendsize;
  inc(size,appendsize);
  for i:=0 to propcount-1 do
    begin
      PropInfo:=proplist^[i];
      tmpdata:=GetPropDynmData(self,PropInfo);
      appendsize:=length(tmpdata);
      if (appendsize+size)>Capacity then
        begin
          delta:=capacity shr 1;
          if delta<(appendsize) then delta:=appendsize+(appendsize shr 2);
          capacity:=capacity+delta;
          setlength(Result,capacity);
        end;
      Move(tmpdata[0],result[size],appendsize);
      inc(size,appendsize);
    end;
  Pinteger(@Result[0])^:=size;
  SetLength(Result,size);
end;

function TAutoObj.GetPropDynmData(Instance: TObject;
  const PropInfo: PPropInfo; PreferStrings: Boolean): TDynamicData;
var
tmpObj:TAutoObj;
tmpData:TDynamicData;
size:integer;
tmpstr:string;
tmpwstr:WideString;
tmpExtended:Extended;
begin
    case PropInfo^.PropType^^.Kind of
      tkInteger:
        begin
          SetLength(Result,sizeof(integer));
          Pinteger(@Result[0])^:=GetOrdProp(Instance, PropInfo);
        end;
      tkChar:
        begin
          SetLength(Result,sizeof(Char));
          PChar(@Result[0])^:=Char(GetOrdProp(Instance, PropInfo));
        end;
      tkWChar:
        begin
          SetLength(Result,sizeof(widechar));
          PWideChar(@Result[0])^:=WideChar(GetOrdProp(Instance, PropInfo));
        end;
      tkClass:
        begin
          tmpObj:=GetObjectProp(Instance, PropInfo, TAutoObj) as TAutoObj;
          try
          result:=tmpObj.GetData;
          except
            raise;
            //result:=tmpobj.getData;
          end;
          //tmpdata:=tmpObj.GetData;
          {size:=length(tmpdata);
          SetLength(Result,sizeof(Integer)+size);
          Pinteger(@Result[0])^:=size;
          Move(tmpdata[0],Result[sizeof(Integer)],size); }
        end;

      tkEnumeration:
        begin
          tmpstr := GetEnumProp(Instance, PropInfo);
          size:=length(tmpstr);
          SetLength(Result,size+sizeof(integer));
          Pinteger(@Result[0])^:=size;
          move(tmpstr[1],Result[sizeof(integer)],size);
        end;
      tkSet:
        begin
          tmpstr := GetSetProp(Instance, PropInfo);
          size:=length(tmpstr);
          SetLength(Result,size+sizeof(integer));
          Pinteger(@Result[0])^:=size;
          move(tmpstr[1],Result[sizeof(integer)],size);
        end;
      tkFloat:
        begin
          tmpextended := GetFloatProp(Instance, PropInfo);
          SetLength(Result,sizeof(Extended));
          PExtended(@Result[0])^:=tmpExtended;
        end;
      tkMethod:
          //	Result := PropInfo^.PropType^.Name;
          SetLength(Result,0);
      tkString, tkLString:
        begin
          tmpstr := GetStrProp(Instance, PropInfo);
          size:=length(tmpstr);
          SetLength(Result,size+sizeof(integer));
          Pinteger(@Result[0])^:=size;
          move(tmpstr[1],Result[sizeof(integer)],size);

        end;
      tkVariant:
        begin
          tmpstr := GetVariantProp(Instance, PropInfo);
          size:=length(tmpstr);
          SetLength(Result,size+sizeof(integer));
          Pinteger(@Result[0])^:=size;
          move(tmpstr[1],Result[sizeof(integer)],size);
        end;
      tkWString:
        begin
          tmpwstr := GetWideStrProp(Instance, PropInfo);
          size:=length(tmpwstr)*2;
          SetLength(Result,size+sizeof(integer));
          Pinteger(@Result[0])^:=size;
          move(tmpwstr[1],Result[sizeof(integer)],size);
        end;
      //tkVariant:
      //    Result := GetVariantProp(Instance, PropInfo);
      tkInt64:
        begin
          SetLength(Result,sizeof(int64));
          Pint64(@Result[0])^:=GetInt64Prop(Instance, PropInfo);
        end;
    else
      raise EPropertyConvertError.CreateResFmt(@SInvalidPropertyType,[PropInfo.PropType^^.Name]);
    end;
end;




procedure TAutoObj.SetData(data:TDynamicData);
var
i,Pos,size:integer;
PropInfo: PPropInfo;
tmpstr:string;
fclassname:shortstring;
tmpwidestr:widestring;
tmpdata:TDynamicData;
appendsize:integer;
tmpobj:TAutoObj;
begin
  Pos:=sizeInteger;
  size:=Pinteger(@data[Pos])^;
  inc(Pos,sizeInteger+size);
  for i:=0 to propcount-1 do
    begin
      PropInfo:=proplist^[i];
      case PropInfo.PropType^^.Kind of
          tkInteger:
            begin
              if propinfo.SetProc<>nil then
              SetOrdProp(self, PropInfo, Pinteger(@Data[Pos])^);
              Inc(Pos,sizeInteger);
            end;
          tkChar:
            begin
              if propinfo.SetProc<>nil then
              SetOrdProp(self, PropInfo, Integer(PChar(@Data[Pos])^));
              Inc(Pos,Sizeof(char));
            end;
          tkWChar:
            begin
              if propinfo.SetProc<>nil then
	      SetOrdProp(self, PropInfo, Integer(PWideChar(@Data[Pos])^));
              inc(Pos,Sizeof(widechar));
            end;
	  tkEnumeration:
            begin
              size:=Pinteger(@Data[Pos])^;
              SetLength(tmpstr,size);
              Move(Data[Pos+sizeof(integer)],tmpstr[1],size);
              if propinfo.SetProc<>nil then
	      SetEnumProp(self, PropInfo, tmpstr);
              inc(Pos,sizeInteger+size);
	    end;
	  tkSet:
	    begin
              size:=Pinteger(@Data[Pos])^;
              SetLength(tmpstr,size);
              Move(Data[Pos+sizeof(integer)],tmpstr[1],size);
              if propinfo.SetProc<>nil then
              SetSetProp(self, PropInfo, tmpstr);
              inc(Pos,sizeInteger+size);
            end;
          tkClass:
            begin
              tmpObj:=GetObjectProp(self, PropInfo, TAutoObj) as TAutoObj;
              size:=Pinteger(@Data[Pos])^;
              tmpObj.SetDataQuick(@Data[Pos]);
              inc(Pos,size);
            end;
	  tkFloat:
	    begin
              if propinfo.SetProc<>nil then
              SetFloatProp(self, PropInfo, PExtended(@Data[Pos])^);
              inc(Pos,sizeof(Extended));
            end;
	  tkString, tkLString:
            begin
              size:=Pinteger(@Data[Pos])^;
              SetLength(tmpstr,size);
              Move(Data[Pos+sizeof(integer)],tmpstr[1],size);
              if propinfo.SetProc<>nil then
              SetStrProp(self, PropInfo, tmpstr);
              inc(Pos,sizeInteger+size);
            end;
	  tkWString:
            begin
              size:=Pinteger(@Data[Pos])^;
              SetLength(tmpwidestr,size shr 1);
              Move(Data[Pos+sizeof(integer)],tmpWidestr[1],size);
              if propinfo.SetProc<>nil then
              SetWideStrProp(self, PropInfo, tmpwidestr);
              inc(Pos,sizeinteger+size);
            end;
	  tkInt64:
            begin
              if propinfo.SetProc<>nil then
              SetInt64Prop(self, PropInfo, PInt64(@Data[Pos])^);
              inc(Pos,sizeInt64);
            end;

          else
	  raise EPropertyConvertError.CreateResFmt(@SInvalidPropertyType,
		[PropInfo.PropType^^.Name]);
      end;
    end
end;

procedure TAutoObj.SetPropDynmValue(Instance: TObject;
  const PropInfo: PPropInfo; Data: TDynamicData);
  function RangedValue(const AMin, AMax: Int64;Value:Real): Int64;
  begin
	Result := Trunc(Value);
	if Result < AMin then
	  Result := AMin;
	if Result > AMax then
	  Result := AMax;
  end;
var

  size:integer;
  tmpstr:string;
  tmpwidestr:widestring;
begin
  // get the prop info
  begin
	//TypeData := GetTypeData(PropInfo^.PropType^);

	// set the right type
	case PropInfo.PropType^^.Kind of
	  tkInteger:
            begin
              SetOrdProp(Instance, PropInfo, Pinteger(@Data[0])^);
            end;
          tkChar:
            begin
              SetOrdProp(Instance, PropInfo, Integer(PChar(@Data[0])^));
            end;
          tkWChar:
            begin
	      SetOrdProp(Instance, PropInfo, Integer(PWideChar(@Data[0])^));
            end;
	  tkEnumeration:
            begin
              size:=Pinteger(@Data[0])^;
              SetLength(tmpstr,size);
              Move(Data[sizeof(integer)],tmpstr[1],size);
	      SetEnumProp(Instance, PropInfo, tmpstr)
	    end;
	  tkSet:
	    begin
              size:=Pinteger(@Data[0])^;
              SetLength(tmpstr,size);
              Move(Data[sizeof(integer)],tmpstr[1],size);
              SetSetProp(Instance, PropInfo, tmpstr);
            end;
	  tkFloat:
	    begin
              SetFloatProp(Instance, PropInfo, PExtended(@Data[0])^);
            end;
	  tkString, tkLString:
            begin
              size:=Pinteger(@Data[0])^;
              SetLength(tmpstr,size);
              Move(Data[sizeof(integer)],tmpstr[1],size);
              SetStrProp(Instance, PropInfo, tmpstr);
            end;
	  tkWString:
            begin
              size:=Pinteger(@Data[0])^;
              SetLength(tmpwidestr,size shr 1);
              Move(Data[sizeof(integer)],tmpwidestr[1],size);
              SetWideStrProp(Instance, PropInfo, tmpwidestr);
            end;
	  tkInt64:
		SetInt64Prop(Instance, PropInfo, PInt64(@Data[0])^);
	else
	  raise EPropertyConvertError.CreateResFmt(@SInvalidPropertyType,
		[PropInfo.PropType^^.Name]);
	end;
  end;
end;

procedure TAutoObj.execute;
begin

end;

procedure TAutoObj.SetDataQuick(Data: Pointer);
var
fPos:PChar;
i,fsize:integer;
PropInfo: PPropInfo;
tmpstr:string;
fclassname:shortstring;
tmpwidestr:widestring;
tmpdata:TDynamicData;
appendsize:integer;
tmpobj:TAutoObj;
begin
  fPos:=PChar(Data)+sizeInteger;
  fsize:=Pinteger(fPos)^;
  //classname check for object;
  {setlength(fclassname,size);
  Move(Data[Pos+sizeof(integer)],fclassname[1],size);
  if fclassname<>classname then
  Raise Exception.Create('NotSameClass!'+classname+' '+fclassname);  }
  inc(fPos,sizeInteger+fsize);
  for i:=0 to propcount-1 do
    begin
      PropInfo:=proplist^[i];
      case PropInfo.PropType^^.Kind of
      tkInteger:
            begin
              if propinfo.SetProc<>nil then
              SetOrdProp(self, PropInfo, Pinteger(fPos)^);
              Inc(fPos,sizeInteger);
            end;
          tkChar:
            begin
              if propinfo.SetProc<>nil then
              SetOrdProp(self, PropInfo, Integer(PChar(fPos)^));
              Inc(fPos,Sizeof(char));
            end;
          tkWChar:
            begin
              if propinfo.SetProc<>nil then
	      SetOrdProp(self, PropInfo, Integer(PWideChar(fPos)^));
              inc(fPos,Sizeof(widechar));
            end;
	  tkEnumeration:
            begin
              fsize:=Pinteger(fPos)^;
              SetLength(tmpstr,fsize);
              Move((fPos+sizeinteger)^,tmpstr[1],fsize);
              if propinfo.SetProc<>nil then
	      SetEnumProp(self, PropInfo, tmpstr);
              inc(fPos,sizeInteger+fsize);
	    end;
	  tkSet:
	    begin
              fsize:=Pinteger(fPos)^;
              SetLength(tmpstr,fsize);
              Move((fPos+sizeinteger)^,tmpstr[1],fsize);
              if propinfo.SetProc<>nil then
              SetSetProp(self, PropInfo, tmpstr);
              inc(fPos,sizeInteger+fsize);
            end;
          tkClass:
            begin
              tmpObj:=GetObjectProp(self, PropInfo, TAutoObj) as TAutoObj;
              fsize:=Pinteger(fPos)^;
              tmpObj.SetDataQuick(fPos);
              inc(fPos,fsize);
            end;
	  tkFloat:
	    begin
              if propinfo.SetProc<>nil then
              SetFloatProp(self, PropInfo, PExtended(fPos)^);
              inc(fPos,sizeof(Extended));
            end;
	  tkString, tkLString:
            begin
              fsize:=Pinteger(fPos)^;
              SetLength(tmpstr,fsize);
              Move((fPos+sizeinteger)^,tmpstr[1],fsize);
              if propinfo.SetProc<>nil then
              SetStrProp(self, PropInfo, tmpstr);
              inc(fPos,sizeInteger+fsize);
            end;
          tkVariant:
            begin
              fsize:=Pinteger(fPos)^;
              SetLength(tmpstr,fsize);
              Move((fPos+sizeinteger)^,tmpstr[1],fsize);
              if propinfo.SetProc<>nil then
              SetVariantProp(self, PropInfo, tmpstr);
              inc(fPos,sizeInteger+fsize);
            end;
	  tkWString:
            begin
              fsize:=Pinteger(fPos)^;
              SetLength(tmpwidestr,fsize shr 1);
              Move((fPos+sizeinteger)^,tmpWidestr[1],fsize);
              if propinfo.SetProc<>nil then
              SetWideStrProp(self, PropInfo, tmpwidestr);
              inc(fPos,sizeinteger+fsize);
            end;
	  tkInt64:
            begin
              if propinfo.SetProc<>nil then
              SetInt64Prop(self, PropInfo, PInt64(fPos)^);
              inc(fPos,sizeInt64);
            end;

          else
	  raise EPropertyConvertError.CreateResFmt(@SInvalidPropertyType,
		[PropInfo.PropType^^.Name]);
      end;
    end
end;

//修定中
function TAutoObj.GetDataQuick(Data: TSuperDynArry): integer;
var
fStarPos:integer;
i,Pos,size:integer;
PropInfo: PPropInfo;
tmpstr:string;
tmpwidestr:widestring;
tmpdata:TDynamicData;
appendsize:integer;
tmpobj:TAutoObj;
begin
 { Pos:=Data.StartPos;
  inc(Pos,sizeof(integer));
  for i:=0 to propcount-1 do
    begin
      PropInfo:=proplist^[i];
      case PropInfo.PropType^^.Kind of
      tkInteger:
            begin
              Pinteger(@Data.fData[Pos])^:=GetOrdProp(self, PropInfo);
              Inc(Pos,sizeof(Integer));
            end;
          tkChar:
            begin
              if propinfo.SetProc<>nil then
              SetOrdProp(self, PropInfo, Integer(PChar(@Data[Pos])^));
              Inc(Pos,Sizeof(char));
            end;
          tkWChar:
            begin
              if propinfo.SetProc<>nil then
	      SetOrdProp(self, PropInfo, Integer(PWideChar(@Data[Pos])^));
              inc(Pos,Sizeof(widechar));
            end;
	  tkEnumeration:
            begin
              size:=Pinteger(@Data[Pos])^;
              SetLength(tmpstr,size);
              Move(Data[Pos+sizeof(integer)],tmpstr[1],size);
              if propinfo.SetProc<>nil then
	      SetEnumProp(self, PropInfo, tmpstr);
              inc(Pos,sizeof(Integer)+size);
	    end;
	  tkSet:
	    begin
              size:=Pinteger(@Data[Pos])^;
              SetLength(tmpstr,size);
              Move(Data[Pos+sizeof(integer)],tmpstr[1],size);
              if propinfo.SetProc<>nil then
              SetSetProp(self, PropInfo, tmpstr);
              inc(Pos,sizeof(Integer)+size);
            end;
          tkClass:
            begin
              tmpObj:=GetObjectProp(self, PropInfo, TAutoObj) as TAutoObj;
              size:=Pinteger(@Data[Pos])^;
              setlength(tmpdata,size);
              move(Data[Pos+sizeof(Integer)],tmpdata[0],size);
              tmpObj.SetData(tmpdata);
              inc(Pos,sizeof(Integer)+size);
            end;
	  tkFloat:
	    begin
              if propinfo.SetProc<>nil then
              SetFloatProp(self, PropInfo, PExtended(@Data[0])^);
              inc(Pos,sizeof(Extended));
            end;
	  tkString, tkLString:
            begin
              size:=Pinteger(@Data[Pos])^;
              SetLength(tmpstr,size);
              Move(Data[Pos+sizeof(integer)],tmpstr[1],size);
              if propinfo.SetProc<>nil then
              SetStrProp(self, PropInfo, tmpstr);
              inc(Pos,sizeof(Integer)+size);
            end;
	  tkWString:
            begin
              size:=Pinteger(@Data[Pos])^;
              SetLength(tmpwidestr,size shr 1);
              Move(Data[Pos+sizeof(integer)],tmpWidestr[1],size);
              if propinfo.SetProc<>nil then
              SetWideStrProp(self, PropInfo, tmpwidestr);
              inc(Pos,sizeof(integer)+size);
            end;
	  tkInt64:
            begin
              if propinfo.SetProc<>nil then
              SetInt64Prop(self, PropInfo, PInt64(@Data[Pos])^);
              inc(Pos,sizeof(Int64));
            end;

          else
	  raise EPropertyConvertError.CreateResFmt(@SInvalidPropertyType,
		[PropInfo.PropType^^.Name]);
      end;
    end  }
end;

function TAutoObj.GetPropDynm(PropIDX: integer): TDynamicData;
begin
  Result:=GetPropData(self,proplist^[PropIDx]);
end;

function TAutoObj.GetPropData(Instance: TObject; const PropInfo: PPropInfo;
  PreferStrings: Boolean): TDynamicData;
var
tmpObj:TAutoObj;
tmpData:TDynamicData;
size:integer;
tmpstr:string;
tmpwstr:WideString;
tmpExtended:Extended;
begin
    case PropInfo^.PropType^^.Kind of
      tkInteger:
        begin
          SetLength(Result,sizeof(integer));
          Pinteger(@Result[0])^:=GetOrdProp(Instance, PropInfo);
        end;
      tkChar:
        begin
          SetLength(Result,sizeof(Char));
          PChar(@Result[0])^:=Char(GetOrdProp(Instance, PropInfo));
        end;
      tkWChar:
        begin
          SetLength(Result,sizeof(widechar));
          PWideChar(@Result[0])^:=WideChar(GetOrdProp(Instance, PropInfo));
        end;
      tkClass:
        begin
          tmpObj:=GetObjectProp(Instance, PropInfo, TAutoObj) as TAutoObj;
          tmpdata:=tmpObj.GetData;
          size:=Length(tmpdata);
          SetLength(Result,sizeof(Integer)+size);
          Pinteger(@Result[0])^:=size;
          MoveQuick(@tmpdata[0],@Result[sizeof(Integer)],size);
        end;
      tkEnumeration:
        begin
          tmpstr := GetEnumProp(Instance, PropInfo);
          size:=length(tmpstr);
          SetLength(Result,size);
          //Pinteger(@Result[0])^:=size;
          moveQuick(@tmpstr[1],@Result[0],size);
        end;
      tkSet:
        begin
          tmpstr := GetSetProp(Instance, PropInfo);
          size:=length(tmpstr);
          SetLength(Result,size);
          moveQuick(@tmpstr[1],@Result[0],size);
        end;
      tkFloat:
        begin
          tmpextended := GetFloatProp(Instance, PropInfo);
          SetLength(Result,sizeof(Extended));
          PExtended(@Result[0])^:=tmpExtended;
        end;
      tkMethod:
          //	Result := PropInfo^.PropType^.Name;
          SetLength(Result,0);
      tkString, tkLString:
        begin
          tmpstr := GetStrProp(Instance, PropInfo);
          size:=length(tmpstr);
          SetLength(Result,size);
          moveQuick(@tmpstr[1],@Result[0],size);

        end;
      tkWString:
        begin
          tmpwstr := GetWideStrProp(Instance, PropInfo);
          size:=length(tmpwstr)*2;
          SetLength(Result,size);
          moveQuick(@tmpwstr[1],@Result[0],size);
        end;
      tkVariant:
            Result := GetVariantProp(Instance, PropInfo);
      tkInt64:
        begin
          SetLength(Result,sizeof(int64));
          Pint64(@Result[0])^:=GetInt64Prop(Instance, PropInfo);
        end;
    else
      raise EPropertyConvertError.CreateResFmt(@SInvalidPropertyType,[PropInfo.PropType^^.Name]);
    end;
end;


function TAutoObj.GetPropIDXValue(PropIDX: integer): Variant;
begin
  Result:=GetPropValue(self,proplist^[PropIdx]);
end;

function TDynmObj.GetData: TDynamicData;
begin
  Result:=GetPackData;
end;

procedure TDynmObj.SetData(Data: TDynamicData);
begin
  try
    if length(Data)=0 then Raise Exception.create('DataErr');
    SetPackData(Data);
  except
    Raise;
  end;
end;

function TDynmObj.GetPropDynm(FSortIdx:integer): TDynamicData;
begin
  result:=GetDataArray(FSortIdx)
end;

function TDynmObj.GetPropIDXValue(PropIDX: integer): Variant;
begin
  Result:=GetData(PropIDX)
end;

{ TPropInfos }

function TAutoPropInfos.AddSub(Obj: TAutoObj): integer;
begin
  Result:=inherited AddSub(Obj);
  TAutoPropInfo(Obj).ClassName:=FClassName;
end;

procedure TAutoPropInfos.initclassname(classname: string);
begin
  FClassName:=Classname;
  if ContainerCount=0 then
    begin
      exit;
    end;
end;

procedure TAutoPropInfos.initcontainerclass;
begin
  FAutoClass:=TAutoPropInfo;


end;

{ TPropinfo }

constructor TAutoPropinfo.create;
begin
  inherited;
  self.FCanModify:=true;
  self.FCanShow:=true;
end;

destructor TAutoPropinfo.Destroy;
begin

  inherited;
end;

procedure TAutoPropinfo.SetCanModify(const Value: boolean);
begin
  FCanModify := Value;
end;

procedure TAutoPropinfo.SetCanShow(const Value: boolean);
begin
  FCanShow := Value;
end;

procedure TAutoPropinfo.SetClassName(const Value: string);
begin
  FClassName := Value;
end;

procedure TAutoPropinfo.SetDataType(const Value: TDataType);
begin
  FDataType := Value;
end;

procedure TAutoPropinfo.SetDetail(const Value: String);
begin
  FDetail := Value;
end;

procedure TAutoPropinfo.SetPropName(const Value: string);
begin
  FPropName := Value;
end;

procedure TAutoPropinfo.SetSearchClass(const Value: string);
begin
  FSearchClass := Value;
end;

procedure TAutoPropinfo.SetShowIndex(const Value: integer);
begin
  FShowIndex := Value;
end;

procedure TAutoPropinfo.SetSize(const Value: integer);
begin
  FSize := Value;
end;

procedure TAutoPropinfo.SetTitle(const Value: string);
begin
  FTitle := Value;
end;

{ TClassInfo }

constructor TClassInfo.Create;
begin
  inherited;
  FPropInfos:=TAutoPropInfos.Create;
end;

destructor TClassInfo.Destroy;
begin
  FPropInfos.Free;
  inherited;
end;

procedure TClassInfo.SetClassInfo(const Value: String);
begin
  FCLassInfo := Value;
end;


procedure TClassInfo.SetClassType(const Value: TClassType);
begin
  FClassType := Value;
end;

procedure TClassInfo.SetInheritedFrom(const Value: String);
begin
  FInheritedFrom := Value;
end;

procedure TClassInfo.SetName(const Value: string);
begin
  inherited;
  FPropInfos.initclassname(Value);
end;

{ TClassInfos }

procedure TClassInfos.initcontainerclass;
begin
  FAutoClass:=TClassInfo;

end;

function TAutoObj.CmpDataIDX(Data: TDynamicData;
  PropIDX: integer): integer;
var
fPropinfo:PPropInfo;
begin
  result:=0;
  fPropInfo:=Proplist^[PropIDX];
  case fPropInfo.PropType^.Kind of
    tkInteger:
      begin

      end;
  end;
end;

{ TThreadSafeObj }

constructor TThreadSafeObj.Create;
begin
  inherited;
  FCriticalSection:=TCriticalSection.Create;
end;

destructor TThreadSafeObj.Destroy;
begin
  FCriticalSection.Free;
  inherited;
end;

procedure TThreadSafeObj.Lock;
begin
  FCriticalSection.Acquire;
end;



procedure TThreadSafeObj.unLock;
begin
  FCriticalSection.Release;
end;

function TAutoObj.GetDataTypeOfIDX(DataIndex: integer): TDatatype;
var
datakind:TTypeKind;
begin
  datakind:=proplist^[DataIndex].PropType^.Kind ;
  case datakind of
    tkInteger:Result:=dtInteger;
    tkChar:Result:=dtChar;
    tkFloat:Result:=dtFloat;
    tkString,tkLString:Result:=dtString;
    tkEnumeration:Result:=dtString;
    tkWString:Result:=dtWidestring;
    tkInt64:result:=dtInt64;
  end;
end;

function TDynmObj.GetDataTypeOfIDX(DataIndex: integer): TDatatype;
begin
  result:=fStructure.GetDataTypeof(DataIndex);
end;

procedure TDynmObj.SetDataQuick(Data: Pointer);
var
i,fpos,fcount:integer;
datasize:integer;
tmpdata:TDynamicData;
allsize:integer;
reserved:integer;
Posinfo:array of Integer;
begin
  fcount:=Pinteger(PChar(Data)+SizeInteger)^;
  if length(fDynmData)<>fcount then Setlength(fDynmData,fcount);
  setlength(posinfo,fcount);
  reserved:=(fcount+2)*sizeinteger;
  Move((PChar(data)+SizeInteger*2)^,Posinfo[0],reserved-sizeInt64);
  fPos:=reserved;
  for i:=0 to fcount-1 do
    begin
      datasize:=posinfo[i];
      if Length(fDynmData[i])<>datasize then setlength(fDynmData[i],datasize);
      if datasize>0 then
        begin
          Move((PChar(Data)+fpos)^,fDynmData[i][0],datasize);
        end;
      inc(fpos,datasize);
    end;

end;

function TAutoObj.GetStandXmlStr(Data: string): string;
var
i:integer;
tmp:string;
superStr:TSuperStr;
begin
  superstr:=TSuperStr.Create;
  try
    for i:=1 to Length(Data) do
      begin
        Case Data[i] of
          '&':superstr.Append(amp);
          '<':superstr.Append(less);
          '>':superstr.Append(great);
          '''':superstr.Append(apos);
          '"':superstr.Append(quot);
        else
          superstr.Append(Data[i]);
        end;
      end;
    result:=superstr.Value;
  finally
    superstr.Free;
  end;
end;


function TAutoObj.CmpValue(Data, CmpData: Variant): integer;
begin
  result:=0;
  if Data>CmpData then
    begin
      Result:=1;
      exit;
    end;
  if Data<CmpData then
    begin
      result:=-1;
      exit;
    end;
end;

procedure TAutoObj.LoadBinfromFile(filename: string);
var
tmpfile:TFilestream;
data:TDynamicData;
begin
  tmpfile:=TFilestream.Create(filename,fmOpenread);
  try
    setlength(data,tmpfile.size);
    tmpfile.read(data[0],tmpfile.Size);
    SetData(Data);
  finally
    tmpfile.Free;
  end;
end;

procedure TAutoObj.SaveBintoFile(filename: string);
var
tmpfile:TFilestream;
data:TDynamicData;
begin
  if  FileExists(filename) then tmpfile:=TFilestream.Create(filename,fmOpenWrite)
    else tmpfile:=TFilestream.Create(filename,fmCreate);
  try
    data:=GetData;
    tmpfile.Position:=0;
    tmpfile.Write(data[0],length(data));
    tmpfile.Size:=length(data);
  finally
    tmpfile.Free;
  end;
end;

function TUniqueObj.GetPropDynm(PropIDX: integer): TDynamicData;
begin
  if PropIDx=0 then
    begin
      setlength(result,sizeof(fobjid));
      move(fObjid,result[0],sizeof(fobjid));
    end else result:=inherited GetPropDynm(PropIDX);
end;

function TAutoObj.ConvertVariantToDynamic(Value: Variant;
  DataType: TDataType): TDynamicData;
var
fsize:integer;
tmpstring:string;
begin
case DataType of
    dtString:
      begin
        tmpstring:=Value;
        fsize:=length(tmpstring);
        setlength(result,fsize);
        move(tmpstring[1],result[0],fsize);
      end;
    dtSmallint:
      begin
        fsize:=sizeof(smallint);
        setlength(result,fsize);
        move(TVardata(Value).VSmallInt,result[0],fsize);

      end;
    dtInteger:
      begin
        fsize:=sizeof( integer);
        setlength(result,fsize);
        move(TVardata(Value).VInteger,result[0],fsize);
      end;
    dtWord:
      begin
        fsize:=sizeof(word);
        setlength(result,fsize);
        move(TVardata(Value).VWord,result[0],fsize);
      end;
    dtBoolean:
      begin
        fsize:=sizeof(boolean);
        setlength(result,fsize);
        move(TVardata(Value).VBoolean,result[0],fsize);
      end;
    dtFloat:
      begin
        fsize:=sizeof(Extended);
        setlength(result,fsize);
        PExtended(@Result[0])^:= TVardata(Value).VDouble;
      end;
    dtCurrency:
      begin
        fsize:=sizeof(Currency);
        setlength(result,fsize);
        move(TVardata(Value).VCurrency,result[0],fsize);
      end;
    dtDateTime:
      begin
        fsize:=sizeof(TDatetime);
        setlength(result,fsize);
        move(TVardata(Value).VDate,result[0],fsize);
      end;
    dtBlob:
      begin
        Raise Exception.Create('Blob Data Can not Send to Variant,'
        +'must use Stream to attach Blob Data!');
      end;
    dtDetail:
      begin
        Raise Exception.Create('Detail Data Can not Send to Variant,'
        +'must use Detail Objects to manage Data!');
      end;
    dtGuid:
      begin
        Raise Exception.Create('Guid Data Can not Send to Variant!');
      end;
    dtInt64:
      begin
        fsize:=sizeof(Int64);
        setlength(result,fsize);
        move(TVardata(Value).VInt64,result[0],fsize);
      end;

  end;
end;

{ TTmpContainer }

procedure TTmpContainer.ClearSubObjs;
begin
  Exit;

end;

procedure TTmpContainer.ClearSubObjsDirectly;
begin
  inherited ClearSubObjs;
end;

function TTmpContainer.NewSub: TAutoObj;
begin
  Raise Exception.Create('Without Obj destrucor mantainece,can not use this function! ');
end;

destructor TDynmObj.Destroy;
var
i:integer;
tmpinfo:PStrucInfo;
Ptmp:Pointer;
begin
  if fInited=true then
    begin
      for i:=0 to length(fStructure.StrucInfos)-1 do
        begin
          tmpinfo:=@(fStructure.StrucInfos[i]);
          if tmpinfo.DataDef.Datatype=dtDetail then
            begin
              move(fDynmData[tmpinfo.dynamicIndex][0],Ptmp,sizeof(pointer));
              TDynamiccontainer(Ptmp).Free;
            end;
        end; 

    end;
  inherited;
end;

function TDynmObj.GetStrOfStruc(Strucinfo: PStrucInfo): string;
begin
  if fInited then
    begin
      Result:=Strucinfo.DataDef.GetStringValue(fDynmData,
      Strucinfo.OffSet);
    end else raise exception.Create('Must set struc first');
end;

function TDynmObj.GetDetailData(index: integer): TDynamicContainer;
var
tmpinfo:PStrucInfo;
Ptmp:pointer;
begin
  tmpinfo:=@(fStructure.strucinfos[index]);
  move(fDynmData[tmpinfo.dynamicIndex][0],Ptmp,sizeof(pointer));
  result:=Ptmp;
end;

{ TThreadSafeContainer }

constructor TThreadSafeContainer.Create;
begin
  inherited;
  FCriticalSection:=TCriticalSection.Create;
end;

destructor TThreadSafeContainer.Destroy;
begin
  FCriticalSection.Free;
  inherited;
end;

procedure TThreadSafeContainer.Lock;
begin
  FCriticalSection.Acquire;
end;

procedure TThreadSafeContainer.unLock;
begin
  FCriticalSection.Release;
end;

constructor TDynmObj.CreateByStructure(Structure: TAutoStruc);
begin
  Create;
  InitbyStruc(Structure);
end;

function TDynmObj.GetStructureData(index: Integer): TDynmObj;
var
tmpinfo:PStrucInfo;
Ptmp:pointer;
begin
  tmpinfo:=@(fStructure.strucinfos[index]);
  move(fDynmData[tmpinfo.dynamicIndex][0],Ptmp,sizeof(pointer));
  result:=Ptmp;
end;

procedure TDynmObj.LoadFromStreamOf(Name: shortstring;
  const Source: TStream);
var
  v: Variant;
  p: Pointer;
  i: Integer;
begin
  i := Source.Size;
  v := VarArrayCreate([0, i], varByte);
  p := VarArrayLock(v);
  try
    Source.Read(p^, i);
  finally
    VarArrayUnLock(v);
  end;
  SetDataOf(Name, v);
end;

procedure TDynmObj.SaveToStreamOf(Name: shortstring;
  const Source: TStream);
var
  v: Variant;
  p: Pointer;
  i: Integer;
begin
  v := GetDataOf(Name);
  i := VarArrayHighBound(v, 1);
  p := VarArrayLock(v);
  try
    Source.Write(p^, i);
  finally
    VarArrayUnLock(v);
  end;
end;

procedure TDynmObj.LoadFromFileOf(Name: shortstring; const FileName: string);
var
  fs: TFileStream;
begin
  fs := TFileStream.Create(FileName, fmOpenRead);
  try
    LoadFromStreamOf('Bmp', fs);
  finally
    fs.Free;
  end;
end;

procedure TDynmObj.SaveToFileOf(Name: shortstring; const FileName: string);
var
  fs: TFileStream;
  fm: Integer;
begin
  if FileExists(FileName) then
    fm := fmOpenWrite
  else
    fm := fmCreate;
  fs := TFileStream.Create(FileName, fm);
  try
    SaveToStreamOf('Bmp', fs);
  finally
    fs.Free;
  end;
end;

initialization
  registerclasses([TAutoObj,TAutoContainer,TAutoStruc,TDataCheck,TDataDef,
                   TDataDefContainer,TNamedObj,TStrucContainer,TDynmObj,TUniqueObj,
                   TDynamicContainer,TAutoPropInfo,TAutoPropInfos,TTreeContainer,TTreeObj,
                   TClassInfo,TClassInfos,TTmpContainer]);
  SysClassInfos:=TClassInfos.Create;
  SysStructures:=TStrucContainer.Create;


finalization
  SysClassInfos.Free;
  SysStructures.Free;
end.
