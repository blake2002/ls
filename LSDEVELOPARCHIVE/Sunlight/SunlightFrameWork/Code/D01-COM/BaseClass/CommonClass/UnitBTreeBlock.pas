unit UnitBTreeBlock;

interface
uses UnitXmlEngine,Classes,SysUtils,AutoIntf;

type
  TRollType=(rtLeft,rtRight);
  TBTreeBlockIndex=class(TAutoList)
  private
    FAllCount: Int64;
    FLeftBlock: TBTreeBlockIndex;
    FRightblock: TBTreeBlockIndex;
    procedure SetAllCount(const Value: Int64);
    procedure SetLeftBlock(const Value: TBTreeBlockIndex);
    procedure SetRightblock(const Value: TBTreeBlockIndex);
    function GetIsFull: boolean;
    function GetLeftCount: Int64;
    function GetRightCount: Int64;
    procedure MoveDataTo(block:TBTreeBlockIndex;Index,Count:integer);
    function GetMax: TBTreeBlockIndex;
    function GetMin: TBTreeBlockIndex;
    function GetIsEmpty: boolean;
    procedure DeleteLeft;
    procedure DeleteRight;
  protected
    Parentblock:TBTreeBlockIndex;  //父节点;
    function GetBlockFromStatic:int64;
    function Get(Index: Integer): TObject;
    function GetEx(Index:int64):TObject;
    procedure GetLeft(List:TAutoList);
    procedure GetRight(List:TAutoList);
  public
    function AddEx(Obj:TObject):int64;
    procedure Delete(Index:integer);
    procedure DeleteEx(Index:Int64);
    procedure Insert(Index:integer;Obj:TObject);
    procedure InsertEx(Index:int64;Obj:TObject);
    constructor Create;override;
    destructor Destroy;override;
    procedure Clear;override;
    procedure SplitSelf;
    procedure RollRight(RollType:TRollType);
    procedure RollLeft(RollType:TRollType);
    procedure Rebalance;
    function CmpData(Obj1,Obj2:TObject):integer;virtual;
    function CmpKeyValue(Obj:TObject;Key:Variant):integer;virtual;
    function AddData(Obj:TObject):int64;//添加数据树根据数据的大小自动添加的合适的位置
    function GetData(Key:Variant):TObject;//跟据键值得到数据
    function DeleteData(Key:Variant):TObject;
    procedure GetAll(List:TAutoList);
  published
    property AllCount:Int64 read FAllCount write SetAllCount;
    property LeftBlock:TBTreeBlockIndex read FLeftBlock write SetLeftBlock;
    property Rightblock:TBTreeBlockIndex read FRightblock write SetRightblock;
    property IsFull:boolean read GetIsFull;
    property IsEmpty:boolean read GetIsEmpty;
    property LeftCount:Int64 read GetLeftCount;
    property RightCount:Int64 read GetRightCount ;
    property MinBlock:TBTreeBlockIndex read GetMin;
    property MaxBlock:TBTreeBlockIndex read GetMax;
  end;



  TBList=class(TObject)
  private
    froot:TBTreeBlockIndex;
    FAllCount: Int64;
    FLeftBlock: TBTreeBlockIndex;
    FRightblock: TBTreeBlockIndex;
    function GetIsEmpty: boolean;
    function GetIsFull: boolean;
    function GetLeftCount: Int64;
    function GetMax: TBTreeBlockIndex;
    function GetMin: TBTreeBlockIndex;
    function GetRightCount: Int64;
  public
    procedure Rebalance;
    constructor Create;
    destructor Destroy;override;
    procedure AddEx(Obj:TObject);
    procedure Delete(Index:integer);
    procedure DeleteEx(Index:Int64);
    procedure Insert(Index:integer;Obj:TObject);
    procedure InsertEx(Index:int64;Obj:TObject);
  published
    property AllCount:Int64 read FAllCount ;
    property LeftBlock:TBTreeBlockIndex read FLeftBlock ;
    property Rightblock:TBTreeBlockIndex read FRightblock ;
    property IsFull:boolean read GetIsFull;
    property IsEmpty:boolean read GetIsEmpty;
    property LeftCount:Int64 read GetLeftCount;
    property RightCount:Int64 read GetRightCount ;
    property MinBlock:TBTreeBlockIndex read GetMin;
    property MaxBlock:TBTreeBlockIndex read GetMax;
  end;

implementation

{ TBTreeBlockIndex }

function TBTreeBlockIndex.AddEx(Obj: TObject):int64;
var
tmpblock:TBTreeBlockIndex;
newblock:TBTreeBlockIndex;
begin
  tmpblock:=MaxBlock;
  Result:=AllCount;
  if not(tmpblock.IsFull) then
    begin
      tmpblock.Add(Obj);
      while tmpblock<>nil do
        begin
          tmpblock.AllCount:=tmpblock.AllCount+1;
          tmpblock:=tmpblock.Parentblock;
         end;
      exit;
    end else
      begin
        newblock:=Classtype.Create as TBTreeBlockIndex;
        tmpblock.Rightblock:=newblock;
        newBlock.parentblock:=tmpblock;
        newblock.Add(obj);
        newblock.AllCount:=1;
        while tmpblock<>nil do
          begin
            tmpblock.AllCount:=tmpblock.AllCount+1;
            tmpblock:=tmpblock.Parentblock;
          end;
        Rebalance;
      end;

end;

constructor TBTreeBlockIndex.Create;
begin
  inherited;
  FAllCount:=0;
end;

procedure TBTreeBlockIndex.Delete(Index: integer);
begin
  inherited Delete(Index);
end;

procedure TBTreeBlockIndex.DeleteEx(Index:Int64);
var
pos:int64;
tmpblock:TBTreeBlockIndex;
begin
  if FAllCount=0 then exit;
  if Index>FAllCount-1 then
    begin
      Raise Exception.Create('The Position is Large than the size of List');
    end;
  if Index<leftcount then
    begin
      fLeftBlock.DeleteEx(Index);
      if fLeftBlock.isEmpty then
        begin
          DeleteLeft;
        end;
    end else
      begin
        Pos:=Index-leftcount;
        if (Pos<Count)  then
          begin
            inherited Delete(Pos);
            tmpblock:=self;
            while tmpblock<>nil do
              begin
                tmpblock.AllCount:=tmpblock.AllCount-1;
                tmpblock:=tmpblock.Parentblock;
              end;
          end else
            begin
              Dec(Pos,Count);
              FRightBlock.DeleteEx(Pos);
              if fRightBlock.isEmpty then
                begin
                  DeleteRight;
                end;
            end;
      end;
end;

function TBTreeBlockIndex.GetBlockFromStatic: int64;
begin
  result:=1;
end;

function TBTreeBlockIndex.GetIsFull: boolean;
begin
  if Count=maxdatasize then result:=true else result:=false;
end;

function TBTreeBlockIndex.GetLeftCount: Int64;
begin
  try
  if FLeftBlock=nil then result:=0 else Result:=FleftBlock.AllCount;
  except
    exit;
  end;
end;

function TBTreeBlockIndex.GetMax: TBTreeBlockIndex;
begin
  if fRightBlock<>nil then result:=fRightBlock.GetMax else Result:=self;
end;

function TBTreeBlockIndex.GetMin: TBTreeBlockIndex;
begin
  if fLeftBlock<>nil then result:=fLeftBlock.GetMin else Result:=self;
end;

function TBTreeBlockIndex.GetRightCount: Int64;
begin
  try
  if FRightBlock=nil then result:=0 else Result:=FRightBlock.AllCount;
  except
    exit;
  end;
end;

procedure TBTreeBlockIndex.Insert(Index: integer; Obj: TObject);
begin
  InsertEx(Index,Obj);
end;

procedure TBTreeBlockIndex.InsertEx(Index: int64; Obj: TObject);
var
pos:int64;
begin

  if FAllCount=0 then
    begin
      AddEx(Obj);
      exit;
    end;
  if Index>FAllCount-1 then
    begin
      AddEx(Obj);
      exit;
    end;
  if Index<leftcount then
    begin
      fLeftBlock.InsertEx(Index,Obj);
      inc(FAllCount);
    end else
      begin
        Pos:=Index-leftcount;
        if Pos<=Count then
          begin
            if not IsFull then
              begin
                inherited insert(Pos,Obj);
                inc(FAllCount);
                exit;
              end else
              begin
                SplitSelf;
                insertEx(Pos,Obj);
                exit;
              end;
          end else
            begin
              Dec(Pos,Count);
              FRightBlock.InsertEx(Pos,Obj);
              inc(FAllCount);
            end;
      end;

end;

procedure TBTreeBlockIndex.MoveDataTo(block: TBTreeBlockIndex;
 Index, count: integer);
var
i:integer;
begin
  for I:=Index to (Index+count)-1 do
    begin
      block.Add(Items[i]);
    end;
    block.AllCount:=block.AllCount+count;
end;

procedure TBTreeBlockIndex.Rebalance;
var
balancequant:int64;
tmpblock:TBTreeBlockIndex;
begin
  //左树平衡
  if LeftBlock<>nil then
    begin
      LeftBlock.rebalance;
      balancequant:=LeftBlock.leftcount-LeftBlock.RightCount;
      if Abs(balancequant)>balancelevel then
        begin
          if balancequant>0 then
            begin
              RollLeft(rtLeft);
            end else
              begin
                RollLeft(rtRight);
              end;
        end;
    end;
  //右树平衡
  if rightBlock<>nil then
    begin
      RightBlock.Rebalance;
      balancequant:=RightBlock.leftcount-RightBlock.RightCount;
      if Abs(balancequant)>balancelevel then
        begin
          if balancequant>0 then
            begin
              RollRight(rtLeft);
            end else
              begin
                RollRight(rtRight);
              end;
        end;
    end;
end;

procedure TBTreeBlockIndex.RollRight(RollType:TRollType);
var
tmpblock:TBTreeBlockIndex;
begin
  if rightBlock=nil then exit;
  case Rolltype of
    rtLeft:
      begin
        tmpblock:=RightBlock;
        if tmpblock.LeftBlock=nil then exit;
        RightBlock:=tmpblock.LeftBlock;
        RightBlock.Parentblock:=self;
        tmpblock.LeftBlock:=RightBlock.Rightblock;
        if tmpblock.leftblock<>nil then tmpBlock.LeftBlock.Parentblock:=tmpblock;
        RightBlock.RightBlock:=tmpblock;
        tmpblock.Parentblock:=Rightblock;
        tmpblock.AllCount:=tmpblock.LeftCount+tmpblock.RightCount+tmpblock.count;
        RightBlock.AllCount:=RightBlock.LeftCount+RightBlock.RightCount+RightBlock.count;
      end;
    rtRight:
      begin
        tmpblock:=RightBlock;
        if tmpblock.RightBlock=nil then exit;
        RightBlock:=tmpblock.Rightblock;
        RightBlock.Parentblock:=self;
        tmpblock.Rightblock:=RightBlock.LeftBlock;
        if tmpblock.rightblock<>nil then tmpblock.Rightblock.Parentblock:=tmpblock;
        RightBlock.LeftBlock:=tmpblock;
        tmpBlock.Parentblock:=RightBlock;
        tmpblock.AllCount:=tmpblock.LeftCount+tmpblock.RightCount+tmpblock.count;
        RightBlock.AllCount:=RightBlock.LeftCount+RightBlock.RightCount+RightBlock.count;
      end;
  end;
end;

procedure TBTreeBlockIndex.RollLeft(RollType:TRollType);
var
tmpblock:TBTreeBlockIndex;
begin
  if leftBlock=nil then exit;
  case Rolltype of
    rtLeft:
      begin
        tmpblock:=LeftBlock;
        if tmpblock.LeftBlock=nil then exit;
        LeftBlock:=tmpblock.LeftBlock;
        LeftBlock.Parentblock:=self;
        tmpblock.LeftBlock:=LeftBlock.Rightblock;
        if tmpblock.leftblock<>nil then tmpBlock.LeftBlock.Parentblock:=tmpblock;
        LeftBlock.RightBlock:=tmpblock;
        tmpblock.Parentblock:=LeftBlock;
        tmpblock.AllCount:=tmpblock.LeftCount+tmpblock.RightCount+tmpblock.count;
        LeftBlock.AllCount:=LeftBlock.LeftCount+LeftBlock.RightCount+LeftBlock.count;
      end;
    rtRight:
      begin
        tmpblock:=leftblock;
        if tmpblock.Rightblock=nil then exit;
        Leftblock:=tmpblock.Rightblock;
        LeftBlock.Parentblock:=self;
        tmpblock.Rightblock:=leftblock.LeftBlock;
        if tmpblock.rightblock<>nil then tmpblock.Rightblock.Parentblock:=tmpblock;
        leftblock.LeftBlock:=tmpblock;
        tmpblock.Parentblock:=LeftBlock;
        tmpblock.AllCount:=tmpblock.LeftCount+tmpblock.RightCount+tmpblock.count;
        LeftBlock.AllCount:=leftblock.LeftCount+leftblock.RightCount+LeftBlock.count;
      end;
  end;
end;

procedure TBTreeBlockIndex.SetAllCount(const Value: Int64);
begin
  FAllCount := Value;
end;

procedure TBTreeBlockIndex.SetLeftBlock(const Value: TBTreeBlockIndex);
begin
  FLeftBlock := Value;
end;



procedure TBTreeBlockIndex.SetRightblock(const Value: TBTreeBlockIndex);
begin
  FRightblock := Value;
end;

procedure TBTreeBlockIndex.SplitSelf;
var
tmpblock:TBTreeBlockIndex;
halfcount:integer;
i:integer;
quatecount:integer;
begin
 { if self.fLeftBlock=nil then
    begin
      halfcount:=count shr 1  ;
      if fRightBlock=nil then
        begin
          quatecount:=count shr 2;
          if quatecount=0 then quatecount:=1;
          fRightBlock:=TBTreeBlockIndex.Create;
          fRightBlock.Parentblock:=self;
          movedatato(fRightblock,count-quatecount,quatecount);
          fcount:=fcount-quatecount;
          fLeftBlock:=TBTreeBlockIndex.Create;
          fLeftBlock.Parentblock:=self;
          movedatato(fLeftblock,0,quatecount);
          for i:=quatecount to count-quatecount do
              begin
                fobjs[i-quatecount]:=fobjs[i];
              end;
          fcount:=fcount-quatecount;
        end else
          begin
            fLeftBlock:=TBTreeBlockIndex.Create;
            fleftBlock.Parentblock:=self;
            movedatato(fleftblock,0,count-halfcount);
            for i:=halfcount to count-1 do
              begin
                fobjs[i-halfcount]:=fobjs[i];
              end;
            fcount:=fcount-halfcount;
          end;
    end else  }
      begin
        {if fRightBlock=nil then
          begin
            halfcount:=count shr 1;
            fRightBlock:=TBTreeBlockIndex.Create;
            fRightBlock.Parentblock:=self;
            movedatato(fRightblock,count-halfcount,halfcount);
            fcount:=fcount-halfcount;
          end else  }
            begin
              Quatecount:=count shr 2;
              if Quatecount=0 then Quatecount:=1;
              tmpblock:=Classtype.Create as TBTreeBlockIndex;
              tmpblock.Parentblock:=self;
              movedatato(tmpblock,0,Quatecount);
              tmpblock.LeftBlock:=fLeftblock;
              if tmpblock.LeftBlock<>nil then tmpblock.LeftBlock.Parentblock:=tmpblock;
              fleftBlock:=tmpblock;
              tmpblock.FAllCount:=tmpblock.Leftcount+tmpblock.RightCount+tmpblock.Count;
              tmpblock:=Classtype.Create as TBTreeBlockIndex;
              tmpblock.Parentblock:=self;
              movedatato(tmpblock,count-quatecount,quatecount);
              tmpblock.Rightblock:=fRightBlock;
              if tmpblock.Rightblock<>nil then tmpblock.Rightblock.Parentblock:=tmpblock;
              fRightBlock:=tmpblock;
              tmpblock.FAllCount:=tmpblock.Leftcount+tmpblock.RightCount+tmpblock.Count;
              for i:=0 to count-1 do
                begin
                  if i<=(count-quatecount-quatecount-1) then items[i]:=items[i+quatecount] else
                    items[i]:=nil;
                end;
              count:=count-quatecount-quatecount;
              //RollLeft(rtLeft);
              //RollRight(rtRight);
              Rebalance;
            end;
      end;
//  if Self.Parentblock<>nil then
//    if Self.Parentblock.Parentblock<>nil  then
//      if Self.Parentblock.Parentblock.Parentblock<>nil then self.Parentblock.Parentblock.Rebalance;

end;

destructor TBTreeBlockIndex.Destroy;
begin
  {for i:=0 to count-1 do
    begin
      inherited Get(i).Free;
    end;}
  Clear;
  inherited;
end;

function TBTreeBlockIndex.GetIsEmpty: boolean;
begin
  if count=0 then result:=true else result:=false;
end;

procedure TBTreeBlockIndex.DeleteLeft;
var
addblock:TBTreeBlockIndex;
tmpblock:TBTreeBlockIndex;
begin
  if LeftBlock.LeftBlock<>nil then
    begin
      addblock:=leftBlock.LeftBlock.GetMax;
      addblock.Rightblock:=leftBlock.Rightblock;
      if addblock.Rightblock<>nil then addblock.Rightblock.Parentblock:=addblock;
      tmpblock:=leftblock;
      LeftBlock:=leftblock.LeftBlock;
      LeftBlock.Parentblock:=self;
      tmpblock.LeftBlock:=nil;
      tmpblock.Rightblock:=nil;
      tmpblock.Parentblock:=nil;
      tmpblock.Free;
      tmpblock:=addblock;
      while tmpblock<>nil do
        begin
          tmpblock.FAllCount:=tmpblock.LeftCount+tmpblock.RightCount+tmpblock.count;
          tmpblock:=tmpblock.Parentblock;
        end;
    end else
      begin
        tmpblock:=leftblock;
        LeftBlock:=leftblock.Rightblock;
        if LeftBlock<>nil then  LeftBlock.Parentblock:=self;
        tmpblock.Parentblock:=nil;
        tmpblock.LeftBlock:=nil;
        tmpblock.Rightblock:=nil;
        tmpblock.Free;

      end;

end;

procedure TBTreeBlockIndex.DeleteRight;
var
addblock:TBTreeBlockIndex;
tmpblock:TBTreeBlockIndex;
begin
  if RightBlock.LeftBlock<>nil then
    begin
      addblock:=RightBlock.LeftBlock.GetMax;
      addblock.Rightblock:=RightBlock.Rightblock;
      if addblock.Rightblock<>nil then addblock.Rightblock.Parentblock:=addblock;
      tmpblock:=Rightblock;
      RightBlock:=Rightblock.LeftBlock;
      RightBlock.Parentblock:=self;
      tmpblock.LeftBlock:=nil;
      tmpblock.Rightblock:=nil;
      tmpblock.Parentblock:=nil;
      tmpblock.Free;
      tmpblock:=addblock;
      while tmpblock<>nil do
        begin
          tmpblock.FAllCount:=tmpblock.LeftCount+tmpblock.RightCount+tmpblock.count;
          tmpblock:=tmpblock.Parentblock;
        end;
    end else
      begin
        tmpblock:=Rightblock;
        RightBlock:=Rightblock.Rightblock;
        if RightBlock<>nil then  RightBlock.Parentblock:=self;
        tmpblock.LeftBlock:=nil;
        tmpblock.Rightblock:=nil;
        tmpblock.Parentblock:=nil;
        tmpblock.Free;
      end;
end;

function TBTreeBlockIndex.Get(Index: Integer): TObject;
begin
  result:=inherited Get(Index);
end;

function TBTreeBlockIndex.GetEx(Index: int64): TObject;
var
pos:int64;
tmpblock:TBTreeBlockIndex;
begin
  if FAllCount=0 then
    begin
      Result:=nil;
      exit;
    end;
  if Index>FAllCount-1 then
    begin
      Result:=nil;
      exit;
      Raise Exception.Create('The Position is Large than the size of List');
    end;
  if Index<LeftCount then
    begin
      Result:=fLeftBlock.GetEx(Index);
    end else
      begin
        Pos:=Index-leftcount;
        if (Pos<Count)  then
          begin
            Result:=inherited Get(Pos);
            exit;
          end else
            begin
              Dec(Pos,Count);
              Result:=FRightBlock.GetEx(Pos);
            end;
      end;
end;

function TBTreeBlockIndex.AddData(Obj: TObject):int64;
var
tmpobj:TObject;
i:integer;
tmpblock:TBTreeblockIndex;
begin
  if FAllCount=0  then
    begin
      inherited Add(Obj);
      inc(FAllCount);
      exit;
    end;
  if isfull then SplitSelf;
  if Count>0 then
    begin
      tmpobj:=items[0];
      if Cmpdata(tmpobj,obj)>=0 then
        begin
          if FLeftblock<>nil then
            begin
              Result:=FLeftBlock.AddData(Obj);
              Inc(FAllCount);
            end else
              begin
                inherited insert(0,obj);
                Result:=0;
                Inc(FALLCount);
                exit;
              end
        end else
          begin
            tmpobj:=items[count-1];
            if Cmpdata(tmpobj,obj)<=0 then
              begin
                if fRightblock<>nil then
                  begin
                    result:=fRightBlock.AddData(Obj)+leftCount+count;
                    inc(FAllCount);
                    exit;
                  end  else
                    begin
                      inherited Add(obj);
                      Result:=count-1;
                      Inc(FALLCount);
                      exit;
                    end;
              end else
                begin
                  i:=1;
                  tmpobj:=items[i];
                  While cmpdata(obj,tmpobj)>0 Do
                    begin
                      inc(i);
                      tmpobj:=items[i];
                    end;
                  inherited insert(i,Obj);
                  Result:=leftCount+i;
                  inc(FAllcount);
                  exit;
                end;

          end;
    end else
      begin
        try
        if (leftblock=nil) and (rightblock=nil) then
          begin
            Result:=inherited Add(Obj);
          end else
          begin
            if leftblock<>nil then
              begin
                tmpblock:=leftblock.GetMax;
                tmpobj:=tmpblock.Get(tmpblock.Count-1);
                if cmpdata(tmpobj,obj)>0 then Result:=leftblock.AddData(Obj) else
                  begin
                    if rightblock<>nil then result:=rightblock.AddData(Obj)+leftcount+count
                      else Result:=inherited Add(Obj);
                  end;
              end else
                begin
                  tmpblock:=Rightblock.GetMin;
                  tmpobj:=tmpblock.Get(0);
                  if cmpdata(tmpobj,obj)>0 then Result:=inherited Add(Obj) else result:=rightblock.AddData(obj)+leftcount+count;
                end;
          end;
        inc(FAllCount);
        except
          Raise;
        end;
      end;
end;

//比较对象1,和2,如果1>2 则result=1, 1=2 result=0, 1<2 result=-1
function TBTreeBlockIndex.CmpData(Obj1, Obj2: TObject): integer;
begin
  result:=0;
end;

function TBTreeBlockIndex.CmpKeyValue(Obj:TObject;Key:Variant): integer;
begin
  Result:=0;
end;


function TBTreeBlockIndex.GetData(Key: Variant): TObject;
var
tmpobj:TObject;
i:integer;
cmpresult:integer;
begin
  result:=nil;
  if Count>0 then
    begin
      tmpobj:=items[0];
      if CmpKeyValue(tmpobj,Key)>0 then
        begin
          if FLeftblock<>nil then
            begin
              Result:=FLeftBlock.GetData(Key);
              exit;
            end else
              begin
                Result:=nil;
                exit;
              end
        end else
          begin
            tmpobj:=items[count-1];
            if CmpKeyValue(tmpobj,Key)<0 then
              begin
                if fRightblock<>nil then
                  begin
                    Result:=fRightBlock.GetData(key);
                    exit;
                  end else
                    begin
                      Result:=nil;
                      exit;
                    end;
             end else
               begin
                 i:=0;
                 tmpobj:=items[i];
                 cmpresult:=cmpkeyvalue(tmpobj,key);
                 While (cmpresult<0) and (i<(count-1)) Do
                   begin
                     inc(i);
                     tmpobj:=items[i];
                     cmpresult:=cmpkeyvalue(tmpobj,key)
                   end;
                 if cmpresult=0 then result:=tmpobj else result:=nil;

               end;
          end;
    end else
      begin
        result:=nil;
        if leftblock<>nil then Result:=leftblock.GetData(Key);
        if Result=nil then
          begin
            if rightblock<>nil then Result:=rightblock.GetData(key);
          end;
      end;
end;

function TBTreeBlockIndex.DeleteData(Key: Variant): TObject;
var
tmpobj:TObject;
i:integer;
cmpresult:integer;
tmpblock:TBTreeBlockIndex;
begin
  result:=nil;
  if Count>0 then
    begin
      tmpobj:=items[0];
      if CmpKeyValue(tmpobj,Key)>0 then
        begin
          if FLeftblock<>nil then
            begin
              Result:=FLeftBlock.DeleteData(Key);
              if fLeftBlock.isEmpty then
                begin
                  DeleteLeft;
                end;
              exit;
            end else
              begin
                Result:=nil;
                exit;
              end
        end else
          begin
            tmpobj:=items[count-1];
            if CmpKeyValue(tmpobj,Key)<0 then
              begin
                if fRightblock<>nil then
                  begin
                    Result:=fRightBlock.DeleteData(key);
                    if fRightBlock.isEmpty then
                      begin
                        DeleteRight;
                      end;  
                    exit;
                  end else
                    begin
                      Result:=nil;
                      exit;
                    end;
             end else
               begin
                 i:=0;
                 tmpobj:=items[i];
                 cmpresult:=cmpkeyvalue(tmpobj,key);
                 While (cmpresult<0) and (i<(count-1)) Do
                   begin
                     inc(i);
                     tmpobj:=items[i];
                     cmpresult:=cmpkeyvalue(tmpobj,key)
                   end;
                 if cmpresult=0 then
                   begin
                     result:=tmpobj;
                     inherited Delete(i);
                     tmpblock:=self;
                     try
                     while tmpblock<>nil do
                       begin
                         tmpblock.AllCount:=tmpblock.LeftCount+tmpblock.RightCount+tmpblock.count;
                         tmpblock:=tmpblock.Parentblock;
                       end;
                     except

                     end;
                   end else result:=nil;

               end;
          end;
    end else
      begin
        if leftblock<>nil then
          begin
            Result:=leftblock.DeleteData(Key);
            if fLeftBlock.isEmpty then DeleteLeft;
          end;
        if Result=nil then
          begin
            if rightblock<>nil then
              begin
                Result:=rightblock.DeleteData(key);
                if Result<>nil then
                  begin
                    if Rightblock.IsEmpty then DeleteRight;
                  end;
              end;
          end ;

      end;
end;



procedure TBTreeBlockIndex.GetAll(List: TAutoList);
var
i:integer;
begin
  GetLeft(List);
  for i:=0 to count-1 do
    begin
      List.Add(self.Items[i]);
    end;
  GetRight(List);
end;

procedure TBTreeBlockIndex.GetLeft(List: TAutoList);
begin
  if LeftBlock<>nil then LeftBlock.GetAll(List);
end;

procedure TBTreeBlockIndex.GetRight(List: TAutoList);
begin
  if RightBlock<>nil then RightBlock.GetAll(List);
end;

procedure TBTreeBlockIndex.Clear;
begin
  inherited Clear;
  if fLeftBlock<>nil then freeandnil(fLeftBlock);
  if fRightBlock<>nil then freeandnil(fRightBlock);
end;

{ TBList }

procedure TBList.AddEx(Obj: TObject);
begin
  fRoot.AddEx(Obj);
end;

constructor TBList.Create;
begin
  inherited;
  fRoot:=TBTreeBlockIndex.Create;
end;

procedure TBList.Delete(Index: integer);
begin
  FRoot.Delete(Index);
end;

procedure TBList.DeleteEx(Index: Int64);
begin
  FRoot.DeleteEx(Index);
end;

destructor TBList.Destroy;
begin
  fRoot.Free;
  inherited;
end;

function TBList.GetIsEmpty: boolean;
begin
  Result:=fRoot.GetIsEmpty;
end;

function TBList.GetIsFull: boolean;
begin
  Result:=fRoot.GetIsFull;
end;

function TBList.GetLeftCount: Int64;
begin
  Result:=fRoot.GetLeftCount;
end;

function TBList.GetMax: TBTreeBlockIndex;
begin
  Result:=fRoot.GetMax;
end;

function TBList.GetMin: TBTreeBlockIndex;
begin
  Result:=fRoot.GetMin;
end;

function TBList.GetRightCount: Int64;
begin
  Result:=fRoot.GetRightCount;
end;

procedure TBList.Insert(Index: integer; Obj: TObject);
begin
  fRoot.Insert(Index,Obj);
end;

procedure TBList.InsertEx(Index: int64; Obj: TObject);
begin
  fRoot.InsertEx(Index,Obj);
end;

procedure TBList.Rebalance;
var
balancequant:int64;
tmpblock:TBTreeBlockIndex;
begin
  fRoot.Rebalance;
  balancequant:=froot.leftcount-froot.RightCount;
  if Abs(balancequant)>balancelevel then
    begin
      if balancequant>0 then
        begin
          tmpblock:=froot;
          if tmpblock.LeftBlock=nil then exit;
          fRoot:=tmpblock.LeftBlock;
          tmpblock.LeftBlock:=fRoot.Rightblock;
          fRoot.RightBlock:=tmpblock;
          fRoot.Parentblock:=nil;
          tmpblock.Parentblock:=fRoot;
          tmpblock.AllCount:=tmpblock.LeftCount+tmpblock.RightCount+tmpblock.count;
          fRoot.AllCount:=fRoot.LeftCount+fRoot.RightCount+fRoot.count;
        end else
          begin
            tmpblock:=froot;
            if tmpblock.LeftBlock=nil then exit;
            fRoot:=tmpblock.RightBlock;
            tmpblock.Rightblock:=fRoot.Leftblock;
            fRoot.LeftBlock:=tmpblock;
            fRoot.Parentblock:=nil;
            tmpblock.Parentblock:=fRoot;
            tmpblock.AllCount:=tmpblock.LeftCount+tmpblock.RightCount+tmpblock.count;
            fRoot.AllCount:=fRoot.LeftCount+fRoot.RightCount+fRoot.count;
          end;
      end;
end;





end.
