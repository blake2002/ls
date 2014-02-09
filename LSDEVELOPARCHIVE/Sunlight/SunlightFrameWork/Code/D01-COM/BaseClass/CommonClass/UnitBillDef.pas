unit UnitBillDef;

interface

uses UnitAutoClass;

type
  TBillDef=class(TNamedObj)
  private
    FStrucTure: TAutoStruc;
    FIsSystem: boolean;
    FParentBill: shortstring;
    FObjid: shortstring;
    FBillType: shortstring;
    FBillDataBaseImg: shortstring;
    FDetail: string;
    procedure SetStrucTure(const Value: TAutoStruc);
    procedure SetBillDataBaseImg(const Value: shortstring);
    procedure SetBillType(const Value: shortstring);
    procedure SetIsSystem(const Value: boolean);
    procedure SetObjid(const Value: shortstring);
    procedure SetParentBill(const Value: shortstring);
    procedure SetDetail(const Value: string);
  protected
    procedure SetName(const Value: shortstring);override;
  public
    constructor Create;override;
    destructor Destroy;override;
  published
    property Objid:shortstring read FObjid write SetObjid;
    property Name;
    property Detail:string read FDetail write SetDetail;
    property BillType:shortstring read FBillType write SetBillType;
    property ParentBill:shortstring read FParentBill write SetParentBill;
    property IsSystem:boolean read FIsSystem write SetIsSystem;
    property BillDataBaseImg:shortstring read FBillDataBaseImg write SetBillDataBaseImg;
    property StrucTure:TAutoStruc read FStrucTure write SetStrucTure;
  end;

  TBillDefContainer=class(TAutoContainer)
  public
    constructor Create;override;
    function New:TBillDef;
  end;

implementation

{ TBillDef }

constructor TBillDef.Create;
begin
  inherited create;
  FStructure:=TAutoStruc.Create;
end;

destructor TBillDef.Destroy;
begin
  FStructure.Destroy;
  inherited;
end;

procedure TBillDef.SetBillDataBaseImg(const Value: shortstring);
begin
  FBillDataBaseImg := Value;
end;

procedure TBillDef.SetBillType(const Value: shortstring);
begin
  FBillType := Value;
end;

procedure TBillDef.SetDetail(const Value: string);
begin
  FDetail := Value;
end;

procedure TBillDef.SetIsSystem(const Value: boolean);
begin
  FIsSystem := Value;
end;

procedure TBillDef.SetName(const Value: shortstring);
begin
  inherited;
  FStrucTure.Name:=value;
end;

procedure TBillDef.SetObjid(const Value: shortstring);
begin
  FObjid := Value;
end;

procedure TBillDef.SetParentBill(const Value: shortstring);
begin
  FParentBill := Value;
end;

procedure TBillDef.SetStrucTure(const Value: TAutoStruc);
begin
  FStrucTure.Assign(Value);
end;

{ TBillContainer }

constructor TBillDefContainer.Create;
begin
  inherited;
  AutoClass:=TBillDef;
end;

function TBillDefContainer.New: TBillDef;
begin
  Result:=TBillDef(AutoClass.Create);
  inherited AddSub(Result);
end;

end.
