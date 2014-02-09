// (c) Alex Konshin  mailto:alexk@mtgroup.ru 27 Oct 1997
// 16 Jan 2000 - gbt_unlink, TAVLtree, TIntKeyAVLtree, TStringKeyAVLtree

// VP Vlad Pervushin 03 Apr 2000 - fixes skipping FRoot.Destroy
// VP 04 Apr 2000 - TBalancedTree.Find bugfix
// VP 19 Apr 2000 - TStringKeyAVLtree.Find bugfix

// Delphi 4+ (uses BeforeDestruction methods)

unit AVLtrees;

interface

{$ifdef debug_arrays}
{$define debug}
{$endif}

uses
	SysUtils, Classes,UnitAutoClass;

type

	EAVLtreeException = class(Exception);

	TBalancedTree = class;
	PBalancedTree = ^TBalancedTree;

	TBTTreateNode = function ( ANode : TBalancedTree; AParm : Pointer ) : Boolean; // True -> break treation loop

	// Generic low-level AVL-Tree node class
	// Warninig: use Destroy for root node only.
	TBalancedTree = class(TAutoObj)
	protected
		LLink, RLink : TBalancedTree;
		FBal, FCmp : Byte;
		function Compare( AWith : TBalancedTree ) : Integer; virtual; abstract;
	public
		procedure BeforeDestruction; override; // destroy tree - all node children.
		class function Add( var ARoot {: TBalancedTree}; ANode : TBalancedTree; var bFound : Boolean ) : TBalancedTree; virtual;
		class function AddItem( var ARoot {: TBalancedTree}; ANode : TBalancedTree; const bRaiseError : Boolean ) : TBalancedTree; virtual;
		procedure Beat( AProc : TBTTreateNode; AParm : Pointer ); //
		procedure RecursiveBeat( AProc : TBTTreateNode; AParm : Pointer );
		function Find( ANode : TBalancedTree ) : TBalancedTree;
	end;
	TBTClass = class of TBalancedTree;

	//-------------------------------------------------------------
	THackBTree = class(TBalancedTree)
	public
		property Left : TBalancedTree read LLink;
		property Right : TBalancedTree read RLink;
	end;

	//-------------------------------------------------------------
	// TStringBTree is for backward compatibility
	// Key - string
	// Case insensetive compare (AnsiCompareText) is used!
	TStringBTree = class(TBalancedTree)
	protected
		FKey : String;
		function Compare( AWith : TBalancedTree ) : Integer; override;
	public
		constructor Create( const AKey : String );
		function FindKey( const AKey : String ) : TStringBTree;
		property Key : String read FKey write FKey;
	end;


	//=============================================================
	// User friendly AVL-tree classes
	TAVLtreeNode = class;
	TAVLtreeNodeClass = class of TAVLtreeNode;

	TAVLtree = class(TAutoObj)
	protected
		FRoot : TAVLtreeNode;
		FNodeClass : TAVLtreeNodeClass;
	public
		constructor Create( ANodeClass : TAVLtreeNodeClass );
		destructor Destroy; override; // destroy all tree nodes
		function AddNodeEx( ANode : TAVLtreeNode; var ASuccess : Boolean ) : TAVLtreeNode; virtual; // result = ANode or node with same key from tree
		function AddNode( ANode : TAVLtreeNode ) : Boolean;
		function Unlink( ANode : TAVLtreeNode ) : Boolean;
		property Root : TAVLtreeNode read FRoot;
		property NodeClass : TAVLtreeNodeClass read FNodeClass;
	end;

	// abstract AVL-tree node class
	TAVLtreeNode = class(TBalancedTree)
	protected
		FTree : TAVLtree;
		procedure SetTree( Value : TAVLtree );
	public
		procedure BeforeDestruction; override; // unlink from tree
		property Tree : TAVLtree read FTree write SetTree;
	end;
	PAVLtreeNode = ^TAVLtreeNode;

	//-------------------------------------------------------------
	// Integer key
	TIntKeyAVLtreeNode = class;
	TIntKeyAVLtreeNodeClass = class of TIntKeyAVLtreeNode;
	TIntKeyAVLtree = class(TAVLtree)
	public
		function Add( const AKey : Integer ) : TIntKeyAVLtreeNode; // warning: return Nil if AKey already exists
		function Find( const AKey : Integer ) : TIntKeyAVLtreeNode;
	end;

	TIntKeyAVLtreeNode = class(TAVLTreeNode)
	protected
		FKey : Integer;
		function Compare( AWith : TBalancedTree ) : Integer ; override;
	public
		constructor Create( ATree : TIntKeyAVLtree; const AKey : Integer ); virtual; // ATree can be Nil
		property Key : Integer read FKey;
	end;

	//-------------------------------------------------------------
	// String key
	TStringKeyAVLtreeNode = class;
	TStringKeyAVLtreeNodeClass = class of TStringKeyAVLtreeNode;

	TStringCompareProc = function ( S1, S2 : String ) : Integer of object;

	// case insensetive compare (AnsiCompareText)
	TStringKeyAVLtree = class(TAVLtree)
	protected
		FCompareMethod : TStringCompareProc; // Is there is no other legal way to call virtual method from basm ?
		function CompareKeys( S1, S2 : String ) : Integer; virtual; // case insensetive ANSI compare
	public
		constructor Create( ANodeClass : TStringKeyAVLtreeNodeClass );
		function Add( const AKey : String ) : TStringKeyAVLtreeNode; // warning: return Nil if AKey already exists
		function Find( const AKey : String ) : TStringKeyAVLtreeNode; virtual;
	end;

	TStringKeyAVLtreeNode = class(TAVLTreeNode)
	protected
		FKey : String;
		function Compare( AWith : TBalancedTree ) : Integer ; override;
	public
		constructor Create( ATree : TStringKeyAVLtree; const AKey : String ); virtual;
		property Key : String read FKey;
	end;

	// binary compare
	TBinaryKeyAVLtree = class(TStringKeyAVLtree)
	protected
		function CompareKeys( S1, S2 : String ) : Integer; override;
	end;

	TBinaryKeyAVLtreeNode = TStringKeyAVLtreeNode;

//-------------------------------------------------------------
// Low level functions
function gbt_insert( var ARoot{ : TBalancedTree}; ANode : TBalancedTree ) : TBalancedTree;
function gbt_replace( var ARoot{ : TBalancedTree}; ANode : TBalancedTree ) : TBalancedTree;
function gbt_unlink( var ARoot{ : TBalancedTree}; ANode : TBalancedTree ) : Boolean;

const
	offsetLLink = 4;
	offsetRLink = 8;
	vmtCompare = 12;

//=============================================================
implementation

uses Windows;

{$ifndef VER130}
procedure FreeAndNil(var Obj); // VP Delphi 5+ only
var
  P: TObject;
begin
  P := TObject(Obj);
	if P<>nil then
	begin
  	TObject(Obj) := nil;  // clear the reference before destroying the object
		P.Destroy;
	end;
end;
{$endif}



//=============================================================
function gbt_insert( var ARoot{ : TBalancedTree}; ANode : TBalancedTree ) : TBalancedTree; assembler;
var N : TBalancedTree;
		T : PBalancedTree;
asm
	test	eax,eax
	jz		@@Exit0
	push	esi
	push	edi
//	p = ATree; s = ATree;
	mov		edi,[eax] // P = edi
	test	edi,edi
	jnz		@@A101
	mov		[eax],edx
	jmp		@@Null
@@A101:
	mov		esi,edi		// S = esi
	mov		T,eax
	mov		N,edx
//	goto A2;
	xor		eax,eax
	jmp		@@A2

@@A3:
// if( B(Q) )
	cmp		[edx].TBalancedTree.FBal,0
	jz		@@A301
// { T = W; S = Q }
	mov		T,ecx
	mov		esi,edx
@@A301:
//	P = Q;
	mov		edi,edx
@@A2:
	mov		eax,N
	mov		edx,edi
	mov		ecx,[eax] // VMT
//	mov		ecx,[ecx+4*3] // offset TBalancedTree.Compare
//	call	ecx
	call	dword ptr [ecx].vmtCompare
	test	eax,eax
	jz		@@Found
// Q = *(W = pLink(P,a))    ecx = W
	mov		eax,offset(TBalancedTree.LLink)
	jl		@@A201
	mov		eax,offset(TBalancedTree.RLink)
@@A201:
	lea		ecx,[edi+eax]
	mov		[edi].TBalancedTree.FCmp,al
	mov		edx,[ecx]	// edx = Q
	test	edx,edx
	jnz		@@A3
// *W=Q=N
	mov		edx,N
	mov		[ecx],edx
// A6
// R = P = Link(S,A(S))
	mov		al,[esi].TBalancedTree.FCmp
	mov		edi,[esi+eax]
	mov		ecx,edi	// ecx = R
	cmp		edi,edx
	je		@@A7
// while( P != Q )  P = Link( P, B(P)=A(P) );
@@A601:
	mov   al,[edi].TBalancedTree.FCmp
	mov		[edi].TBalancedTree.FBal,al
	mov		edi,[edi+eax]
	cmp		edi,edx
	jne		@@A601
@@A7:
// if( ( a = A(S) ) != B(S) )
	mov		al,[esi].TBalancedTree.FCmp
	cmp		al,[esi].TBalancedTree.FBal
	je		@@A702
// B(S) = (byte)( B(S) ? 0 : (byte)a ); return NULL;
	cmp		[esi].TBalancedTree.FBal,0
	jz		@@A701
	xor		al,al
@@A701:
	mov		[esi].TBalancedTree.FBal,al
	jmp		@@Null
@@A702:		// edx = W = pLink( R, Neg(a) )
	mov		edx,(offset(TBalancedTree.LLink) xor offset(TBalancedTree.RLink))
	xor		dl,al
	add		edx,ecx
// if( B(R)==a )
	cmp		al,[ecx].TBalancedTree.FBal
	jne		@@A9
@@A8:
// P = R;
	mov		edi,ecx
// B(R) = B(S) = 0
	mov		[ecx].TBalancedTree.FBal,0
	mov		[esi].TBalancedTree.FBal,0
// Link(S,a) = *( W = pLink( R, Neg(a) ) );
	mov		ecx,[edx]
	mov		[esi+eax],ecx
// *W = S
	mov		[edx],esi
	jmp		@@A10
@@Found:
	mov		eax,edi
	jmp		@@Exit
@@A9:
	push	ebx
// P = *(W = pLink( R, Neg(a) ) );
	mov		edi,[edx]
// *W = Link(P,a); Link(P,a) = R
	mov		ebx,[edi+eax]
	mov		[edx],ebx
	mov		[edi+eax],ecx
//  Link( S, a ) = *(W = pLink( P, Neg(a) ));
	mov		ebx,(offset(TBalancedTree.LLink) xor offset(TBalancedTree.RLink))
	xor		ebx,eax	// ebx = Neg(a)
	mov		edx,[edi+ebx]
	mov   [esi+eax],edx
//  *W = S;
	mov		[edi+ebx],esi
//  if( !B(P) )
	cmp		[edi].TBalancedTree.FBal,0
	jnz		@@A901
//{ B(S) = 0;
	mov		[esi].TBalancedTree.FBal,0
	jmp		@@A909
@@A901:
//}else if( B(P) != a )
	cmp		al,[edi].TBalancedTree.FBal
	je		@@A908
//{ B(S) = 0; B(R) = (byte)a; }
	mov		[esi].TBalancedTree.FBal,0
	mov		[ecx].TBalancedTree.FBal,al
	jmp		@@A999
@@A908:
// B(S) = Neg(a);
	mov		[esi].TBalancedTree.FBal,bl
@@A909:
//  B(R) = 0;
	mov		[ecx].TBalancedTree.FBal,0
@@A999:
//  B(P)=0;
	mov		[edi].TBalancedTree.FBal,0
	pop		ebx
@@A10:
	mov		edx,T		// ATree
	mov   [edx],edi
@@Null:
	xor		eax,eax
@@Exit:
	pop		edi
	pop		esi
@@Exit0:
end;
//-------------------------------------------------------------
// если найдем узел с таким же ключом, то подменяем его и выдаем старый как результат, в противном случае
// вставляем новый узел и результат = nil
function gbt_replace( var ARoot{ : TBalancedTree}; ANode : TBalancedTree ) : TBalancedTree; assembler;
var N : TBalancedTree;
		T : PBalancedTree;
		Parent : PBalancedTree;
asm
	test	eax,eax
	jz		@@Exit0
	push	esi
	push	edi
//	p = ATree; s = ATree;
	mov		edi,[eax] // P = edi
	test	edi,edi
	jnz		@@A101
	mov		[eax],edx
	jmp		@@Null
@@A101:
	mov		esi,edi		// S = esi
	mov		T,eax
	mov		Parent,eax
	mov		N,edx
//	goto A2;
	xor		eax,eax
	jmp		@@A2

@@A3:
// if( B(Q) )
	mov   Parent,ecx
	cmp		[edx].TBalancedTree.FBal,0
	jz		@@A301
// { T = W; S = Q }
	mov		T,ecx
	mov		esi,edx
@@A301:
//	P = Q;
	mov		edi,edx
@@A2:
	mov		eax,N
	mov		edx,edi
	mov		ecx,[eax]
//	mov		ecx,[ecx+4*3] // offset TBalancedTree.Compare
//	call	ecx
	call	dword ptr[ecx].vmtCompare
	test	eax,eax
	jz		@@Found
// Q = *(W = pLink(P,a))    ecx = W
	mov		eax,offset(TBalancedTree.LLink)
	jl		@@A201
	mov		eax,offset(TBalancedTree.RLink)
@@A201:
	lea		ecx,[edi+eax]
	mov		[edi].TBalancedTree.FCmp,al
	mov		edx,[ecx]	// edx = Q
	test	edx,edx
	jnz		@@A3
// *W=Q=N
	mov		edx,N
	mov		[ecx],edx
// A6
// R = P = Link(S,A(S))
	mov		al,[esi].TBalancedTree.FCmp
	mov		edi,[esi+eax]
	mov		ecx,edi	// ecx = R
	cmp		edi,edx
	je		@@A7
// while( P != Q )  P = Link( P, B(P)=A(P) );
@@A601:
	mov   al,[edi].TBalancedTree.FCmp
	mov		[edi].TBalancedTree.FBal,al
	mov		edi,[edi+eax]
	cmp		edi,edx
	jne		@@A601
@@A7:
// if( ( a = A(S) ) != B(S) )
	mov		al,[esi].TBalancedTree.FCmp
	cmp		al,[esi].TBalancedTree.FBal
	je		@@A702
// B(S) = (byte)( B(S) ? 0 : (byte)a ); return NULL;
	cmp		[esi].TBalancedTree.FBal,0
	jz		@@A701
	xor		al,al
@@A701:
	mov		[esi].TBalancedTree.FBal,al
	jmp		@@Null
@@A702:		// edx = W = pLink( R, Neg(a) )
	mov		edx,(offset(TBalancedTree.LLink) xor offset(TBalancedTree.RLink))
	xor		dl,al
	add		edx,ecx
// if( B(R)==a )
	cmp		al,[ecx].TBalancedTree.FBal
	jne		@@A9
@@A8:
// P = R;
	mov		edi,ecx
// B(R) = B(S) = 0
	mov		[ecx].TBalancedTree.FBal,0
	mov		[esi].TBalancedTree.FBal,0
// Link(S,a) = *( W = pLink( R, Neg(a) ) );
	mov		ecx,[edx]
	mov		[esi+eax],ecx
// *W = S
	mov		[edx],esi
	jmp		@@A10

// edi = old node
@@Found:
	mov		edx,N
	mov		eax,TBalancedTree[edi].RLink
	mov		TBalancedTree[edx].RLink,eax
	mov		eax,TBalancedTree[edi].LLink
	mov		TBalancedTree[edx].LLink,eax
	mov		al,TBalancedTree[edi].FBal
	mov		TBalancedTree[edx].FBal,al
	mov		eax,Parent
	mov		[eax],edx
	mov		TBalancedTree[edx].RLink,0
	mov		TBalancedTree[edx].LLink,0
	mov		TBalancedTree[edx].FBal,0
	mov		eax,edi
	jmp		@@Exit

@@A9:
	push	ebx
// P = *(W = pLink( R, Neg(a) ) );
	mov		edi,[edx]
// *W = Link(P,a); Link(P,a) = R
	mov		ebx,[edi+eax]
	mov		[edx],ebx
	mov		[edi+eax],ecx
//  Link( S, a ) = *(W = pLink( P, Neg(a) ));
	mov		ebx,(offset(TBalancedTree.LLink) xor offset(TBalancedTree.RLink))
	xor		ebx,eax	// ebx = Neg(a)
	mov		edx,[edi+ebx]
	mov   [esi+eax],edx
//  *W = S;
	mov		[edi+ebx],esi
//  if( !B(P) )
	cmp		[edi].TBalancedTree.FBal,0
	jnz		@@A901
//{ B(S) = 0;
	mov		[esi].TBalancedTree.FBal,0
	jmp		@@A909
@@A901:
//}else if( B(P) != a )
	cmp		al,[edi].TBalancedTree.FBal
	je		@@A908
//{ B(S) = 0; B(R) = (byte)a; }
	mov		[esi].TBalancedTree.FBal,0
	mov		[ecx].TBalancedTree.FBal,al
	jmp		@@A999
@@A908:
// B(S) = Neg(a);
	mov		[esi].TBalancedTree.FBal,bl
@@A909:
//  B(R) = 0;
	mov		[ecx].TBalancedTree.FBal,0
@@A999:
//  B(P)=0;
	mov		[edi].TBalancedTree.FBal,0
	pop		ebx
@@A10:
	mov		edx,T		// ATree
	mov   [edx],edi
@@Null:
	xor		eax,eax
@@Exit:
	pop		edi
	pop		esi
@@Exit0:
end;
//-------------------------------------------------------------
// An Iterative Algorithm for Deletion from AVL-Balanced Trees       Ben Pfaff <blp@gnu.org>  http://www.msu.edu/user/pfaffben/avl
function gbt_unlink( var ARoot{ : TBalancedTree}; ANode : TBalancedTree ) : Boolean; assembler;
var N, Q : PBalancedTree;
		Root : PBalancedTree;
		PK : Array [0..27] of PBalancedTree;
		AK : Array [0..27] of Byte;
asm
	mov		N,edx		// N <- ANode
	test	eax,eax	// @ARoot = nil ?
	jz		@@Exit0
	push	esi
	push	edi
// P == edi
	mov		edi,[eax]	// P <- [ARoot]
	test	edi,edi
	jz		@@Null
	xor		esi,esi	// k := 0
	mov		dword ptr PK,eax
	mov		byte ptr AK,0
	inc		esi

@@D2:
	mov		Q,eax
	mov		eax,N
	cmp		eax,edi
	jz		@@D5
	mov		edx,edi
	mov		ecx,[eax]
//	mov		ecx,[ecx+4*3] // offset TBalancedTree.Compare
//	call	ecx
	call	dword ptr[ecx].vmtCompare
	test	eax,eax
	jz		@@D5
	mov		dword ptr [PK+esi*4],edi // Pk <- P
	mov		eax,offset(TBalancedTree.LLink)
	jl		@@D201
	mov		eax,offset(TBalancedTree.RLink)
@@D201:
	mov		byte ptr [AK+esi],al // ak <- a
	inc		esi	// k := k+1
	lea		eax,[edi+eax]
	mov		edi,[eax]
	test	edi,edi
	jnz		@@D2
@@Null:
	xor		eax,eax
	jmp		@@Exit

@@D5:
	mov		ecx,[edi].TBalancedTree.RLink	// R == ecx <- RLink(P)
	mov		edx,Q	// edx <- Q
// if RLink(P)<>nil then goto D6
	test	ecx,ecx
	jnz		@@D6
// CONTENTS(Q) <- LLink(P)
	mov		eax,[edi].TBalancedTree.LLink
	mov		[edx],eax
// if LLink(P)<>nil then B(LLink(P)) <- 0
	test	eax,eax
  jz		@@D10
	mov		[eax].TBalancedTree.FBal,0
	jmp		@@D10

@@D6:
// if LLink(R)<>nil then goto D7
	mov		eax,[ecx].TBalancedTree.LLink // eax <- LLink(R)
	test	eax,eax
	jnz		@@D7
// LLink(R) <- LLink(P)
	mov		eax,[edi].TBalancedTree.LLink
	mov		[ecx].TBalancedTree.LLink,eax
// CONTENTS(Q) <- R
	mov		[edx],ecx
// B(R) <- B(P)
	mov		al,[edi].TBalancedTree.FBal
	mov		[ecx].TBalancedTree.FBal,al
// ak <- RLink; P(k) <- R; k <- k+1
	mov		dword ptr [PK+esi*4],ecx
	mov		byte ptr [AK+esi],offset(TBalancedTree.RLink)
	inc		esi
	jmp		@@D10

@@D7:
// eax == S == LLink(R)
// l <- k; k <- k+1
	push	esi
	inc   esi
// ak <- LLink; P(k) <- R; k <- k+1
	mov		dword ptr [PK+esi*4],ecx
	mov		byte ptr [AK+esi],offset(TBalancedTree.LLink)
	inc		esi
@@D8:
// if LLink(S)=nil then goto D9
	mov		edx,[eax].TBalancedTree.LLink
	test	edx,edx
	jz		@@D9
// R <- S; S <- LLink(R); ak <- LLink; Pk <- R
	mov		ecx,eax
	mov		eax,edx
	mov		byte ptr [AK+esi],offset(TBalancedTree.LLink)
	mov		dword ptr [PK+esi*4],ecx
	inc		esi
	jmp   @@D8

@@D9:
// al <- RLink, Pl <- S
	pop		edx	// edx <- l
	mov		byte ptr [AK+edx],offset(TBalancedTree.RLink)
	mov		dword ptr [PK+edx*4],eax
// LLink(S) <- LLink(P); LLink(R) <- RLink(S); RLink(S) <- RLink(P)
	mov		edx,[edi].TBalancedTree.LLink
	mov		[eax].TBalancedTree.LLink,edx
	mov		edx,[eax].TBalancedTree.RLink
	mov		[ecx].TBalancedTree.LLink,edx
	mov		edx,[edi].TBalancedTree.RLink
	mov		[eax].TBalancedTree.RLink,edx
// B(S) <- B(P)
	mov		dl,[edi].TBalancedTree.FBal
	mov		[eax].TBalancedTree.FBal,dl
// CONTENTS(Q) := S
	mov		edx,Q
	mov		[edx],eax

// edx == S
// ecx == R
@@D10:
	push	ebx
@@D100:
// k <- k-1; if k=0 then goto Success
	dec		esi
	jz    @@Success
// eax <- ak
	xor		eax,eax
	movzx	eax,byte ptr [AK+esi]
// S <- Pk
	mov		edx,dword ptr [PK+esi*4]
@@D101:
// if B(S)<>0 then goto D102
	cmp		[edx].TBalancedTree.FBal,0
	jnz		@@D102
// (i)   B(S) <- -ak; goto Success
	xor		al,(offset(TBalancedTree.LLink) xor offset(TBalancedTree.RLink)) // eax <- -ak
	mov		[edx].TBalancedTree.FBal,al
	jmp		@@Success

@@D102:
// if B(S) <> ak then goto D103
	cmp		[edx].TBalancedTree.FBal,al
	jnz		@@D103
// (ii) B(S) <- 0; goto D10
	mov		[edx].TBalancedTree.FBal,0
	jmp		@@D100

@@D103:
	mov		ebx,eax
	xor		bl,(offset(TBalancedTree.LLink) xor offset(TBalancedTree.RLink)) // ebx <- -ak
// (iii) B(S) <- -ak; R <- Link(-ak,S);
	mov		[edx].TBalancedTree.FBal,bl
	mov		ecx,[edx+ebx]
// if B(R)=0 then goto D11
	cmp		[ecx].TBalancedTree.FBal,0
	jz		@@D11
	cmp		[ecx].TBalancedTree.FBal,al
	je		@@D13
// D12
// Link(-ak,S) <- Link(ak,R); Link(ak,R) <- S; B(S) <- 0; B(R) <- 0;
	lea		edi,[ecx+eax]	// edi <- PLink(ak,R)
	mov		eax,ebx
	mov		ebx,[edi]	// ebx <- Link(ak,R)
	mov		[edx+eax],ebx // Link(-ak,S) <- ebx
	mov		[edi],edx	// Link(ak,R) <- S
	mov		[ecx].TBalancedTree.FBal,0
	mov		[edx].TBalancedTree.FBal,0
// Link(a[k-1],P{k-1]) <- R
	dec		esi
	movzx	eax,byte ptr[AK+esi]
	mov		edx,dword ptr[PK+esi*4]
	mov		[edx+eax],ecx
	jnz		@@D101
	jmp		@@Success

@@D13:
	push	esi
	mov		edi,[ecx+eax]	// edi == P <- Link(ak,R)
// Link(ak,R) <- Link(-ak,P)
	mov		esi,[edi+ebx]	// esi <- Link(-ak,P)
	mov		[ecx+eax],esi	// Link(ak,R) <- esi
// Link(-ak,P) <- R
	mov		[edi+ebx],ecx
// Link(-ak,S) <- Link(ak,P)
	mov		esi,[edi+eax]
	mov		[edx+ebx],esi
// Link(ak,P) <- S;
	mov		[edi+eax],edx
// if B(P)<>-ak then goto D1301
	cmp		[edi].TBalancedTree.FBal,bl
	jne    @@D1301
	mov		[edx].TBalancedTree.FBal,al // B(S) <- ak
	mov		[ecx].TBalancedTree.FBal,0 // B(R) <- 0
	jmp		@@D1304

@@D1301:
	mov		[edx].TBalancedTree.FBal,0 // B(S) <- 0
// if B(P)=0 then bl <- 0
	cmp		[edi].TBalancedTree.FBal,0
  jne		@@D1302
	xor		ebx,ebx
@@D1302:
	mov		[ecx].TBalancedTree.FBal,bl // B(R) <- bl
@@D1304:
	pop		esi
	mov		[edi].TBalancedTree.FBal,0 // B(P) <- 0
// Link(a[k-1],P{k-1]) <- P
	dec		esi
	movzx	eax,byte ptr[AK+esi]
	mov		edx,dword ptr[PK+esi*4]
	mov		[edx+eax],edi
	jnz		@@D101
	jmp		@@Success

@@D11:
//	Link(-ak,S) <- Link(ak,R); Link(ak,R) <- S; B(R) <- ak
	mov		[ecx].TBalancedTree.FBal,al
	lea		edi,[ecx+eax]
	mov		ebx,[edi]
	xor		al,(offset(TBalancedTree.LLink) xor offset(TBalancedTree.RLink))
	mov		[edx+eax],ebx
	mov		[edi],edx
// Link(a[k-1],P{k-1]) <- R
	dec		esi
	movzx	eax,byte ptr[AK+esi]
	mov		edx,dword ptr[PK+esi*4]
	mov		[edx+eax],ecx
@@Success:
	pop		ebx
	mov		eax,1
@@Exit:
	pop		edi
	pop		esi
@@Exit0:
end;


//=============================================================
// Destroy children
procedure TBalancedTree.BeforeDestruction;
var	pItem : TBalancedTree;
	procedure InternalBeat( ANode : TBalancedTree );
	begin
		pItem := ANode.LLink;
		ANode.LLink := nil;
		if pItem<>nil then InternalBeat(pItem);
		pItem := ANode.RLink;
		ANode.RLink := nil;
		if pItem<>nil then InternalBeat(pItem);
		ANode.Destroy;
	end;
begin
	if Self<>nil then
	begin
		pItem := LLink;
		LLink := nil;
		if pItem<>nil then InternalBeat(pItem);
		pItem := RLink;
		RLink := nil;
		if pItem<>nil then InternalBeat(pItem);
	end;
end;
//-------------------------------------------------------------
class function TBalancedTree.Add( var ARoot {: TBalancedTree}; ANode : TBalancedTree; var bFound : Boolean ) : TBalancedTree;
begin
	result := gbt_insert( ARoot, ANode );
	bFound := result<>nil;
	if bFound then ANode.Destroy else result := ANode;
end;
//-------------------------------------------------------------
class function TBalancedTree.AddItem( var ARoot {: TBalancedTree}; ANode : TBalancedTree; const bRaiseError : Boolean ) : TBalancedTree;
begin
	Result := gbt_insert( ARoot, ANode );
	if Result=nil then Result := ANode
	else
		begin
			ANode.Destroy;
			if bRaiseError then raise EAVLtreeException.Create('Duplicated key');
		end;
end;
//-------------------------------------------------------------
// обход дерева в порядке возрастания ключей
// в процессе обхода используются поля LLink и RLink (но в конце все восстанавливается)
procedure TBalancedTree.Beat( AProc : TBTTreateNode; AParm : Pointer );
label GoLeft, Treate;
var	prev,cur,next : TBalancedTree;
		bSkip : Boolean;
begin
	prev := nil;
	cur := Self;
	if cur=nil then Exit;
	bSkip := False;
GoLeft:
	while cur.LLink<>nil do
	begin
		next := cur.LLink;
		cur.LLink := prev;
		cur.FCmp := offsetLLink;
		prev := cur;
		cur := next;
	end;
Treate:
	if not bSkip then
	begin
		bSkip := AProc(cur,AParm);
		if not bSkip and(cur.RLink<>nil) then
		begin
			next := cur.RLink;
			cur.RLink := prev;
			cur.FCmp := offsetRLink;
			prev := cur;
			cur := next;
			goto GoLeft;
		end;
	end;
	repeat
		next := cur;
		cur := prev;
		if cur=nil then Exit;
		prev := PBalancedTree(PChar(Pointer(cur))+cur.FCmp)^;
		PBalancedTree(PChar(Pointer(cur))+cur.FCmp)^ := next;
	until cur.FCmp<>offsetRLink;
	goto Treate;
end; {TBalancedTree.Beat}
//-------------------------------------------------------------
// обход дерева в порядке возрастания ключей
// в процессе обхода используется стек
procedure TBalancedTree.RecursiveBeat( AProc : TBTTreateNode; AParm : Pointer );
var bSkip : Boolean;
	procedure InternalBeat( ANode : TBalancedTree );
	begin
		if ANode.LLink<>nil then InternalBeat(ANode.LLink);
		if not bSkip then
		begin
			bSkip := AProc(ANode,AParm);
			if bSkip then Exit;
			if ANode.RLink<>nil then InternalBeat(ANode.RLink);
		end;
	end;
begin
	if Self=nil then Exit;
	bSkip := False;
	InternalBeat(Self);
end; {TBalancedTree.RecursiveBeat}
//-------------------------------------------------------------
function TBalancedTree.Find( ANode : TBalancedTree ) : TBalancedTree; assembler;
asm
// eax = Self - Tree
// edx = ANode
// ecx = Result
	test	eax,eax
	jz		@@Exit
	push	esi
	push	edi
	mov		esi,edx	// esi = cur
	mov		edi,eax	// edi = ANode
	xchg	eax,edx
	test	eax,eax
	jnz		@@8
	jmp		@@Nil
@@1:
	lea		eax,[esi].TBalancedTree.RLink
	jl		@@5
	lea		eax,[esi].TBalancedTree.LLink
@@5:
	mov		edx,[eax]
	test	edx,edx
	jz		@@Nil
	mov		esi,edx
	mov		eax,edi
@@8:
	mov		ecx,[edi]
	call	dword ptr [ecx].vmtCompare		// Compare - cur и ANode
	test	eax,eax
	jnz		@@1
	mov		eax,esi
@@Nil:
	pop		edi
	pop		esi
@@Exit:
end; {TBalancedTree.Find}

//=============================================================
constructor TStringBTree.Create( const AKey : String );
begin
	inherited Create;
	FKey := AKey;
end;
//-------------------------------------------------------------
function TStringBTree.Compare( AWith : TBalancedTree ) : Integer;
begin
	Result := Windows.CompareString(LOCALE_USER_DEFAULT, NORM_IGNORECASE, PChar(FKey), Length(FKey), PChar(TStringBTree(AWith).FKey), Length(TStringBTree(AWith).FKey)) - 2;
end;
//-------------------------------------------------------------
function TStringBTree.FindKey( const AKey : String ) : TStringBTree;
asm
// eax = Self - Tree
// edx = AKey
	test	eax,eax
	jz		@@Exit0
	push	esi
	push	edi
	mov		esi,eax	// esi = Self
	mov		edi,edx	// edi = AKey
	test	edx,edx
	jnz		@@8
@@Nil:
	xor		eax,eax
	jmp		@@Exit
@@1:
	lea		eax,[esi].TBalancedTree.LLink
	jl		@@5
	lea		eax,[esi].TBalancedTree.RLink
@@5:
	mov		eax,[eax]
	test	eax,eax
	jz		@@Exit
	mov		esi,eax
	mov		edx,edi
@@8:
	mov   eax,edi
	mov		edx,[esi].TStringBTree.FKey
	call	AnsiCompareText		// сравнивает ключи
	test	eax,eax
	jnz		@@1
	mov		eax,esi
@@Exit:
	pop		edi
	pop		esi
@@Exit0:
end; {TStringBTree.FindKey}


//==TAVLtree===========================================================
constructor TAVLtree.Create( ANodeClass : TAVLtreeNodeClass );
begin
	inherited Create;
	FNodeClass := ANodeClass;
end;
//-------------------------------------------------------------
destructor TAVLtree.Destroy;
label GoLeft, GoRight;
var	prev,cur,next : TAVLTreeNode;
begin
	if FRoot<>nil then
	begin
		prev := nil;
		cur := FRoot;
GoLeft:
		while cur.LLink<>nil do
		begin
			next := TAVLTreeNode(cur.LLink);
			cur.LLink := prev;
			cur.FCmp := offsetLLink;
			prev := cur;
			cur := next;
		end;
GoRight:
		if cur.RLink<>nil then
		begin
			next := TAVLTreeNode(cur.RLink);
			cur.RLink := prev;
			cur.FCmp := offsetRLink;
			prev := cur;
			cur := next;
			goto GoLeft;
		end;
		next := cur;
		cur := prev;
		if cur <> nil then // VP 03/04/00 - fixes skipping FRoot.Destroy
		begin
			prev := PAVLtreeNode(PChar(Pointer(cur))+cur.FCmp)^;
			PAVLtreeNode(PChar(Pointer(cur))+cur.FCmp)^ := nil;
		end;
		next.FTree := nil; // supress call of Unlink
		next.Destroy;
		if next<>FRoot then goto GoRight;
		FRoot := nil;
	end;
	inherited Destroy;
end;
//-------------------------------------------------------------
function TAVLtree.AddNodeEx( ANode : TAVLtreeNode; var ASuccess : Boolean ) : TAVLtreeNode;
begin
	if ANode=nil then Result := nil
	else
		begin
			if ANode.FTree<>nil then
			begin
				gbt_unlink(FRoot,ANode);
				ANode.FTree := nil;
			end;
			Result := TAVLtreeNode( gbt_insert( FRoot, ANode ));
			ASuccess := Result=nil;
			if ASuccess then
			begin
				ANode.FTree := Self;
				Result := ANode;
			end;
		end;
end;
//-------------------------------------------------------------
function TAVLtree.AddNode( ANode : TAVLtreeNode ) : Boolean;
begin
	AddNodeEx(ANode,Result);
end;
//-------------------------------------------------------------
function TAVLtree.Unlink( ANode : TAVLtreeNode ) : Boolean;
begin
	Result := gbt_unlink(FRoot,ANode);
	if Result then ANode.FTree := nil;
end;


//==TAVLtreeNode===========================================================
procedure TAVLtreeNode.BeforeDestruction;
begin
	if FTree<>nil then
	begin
		gbt_unlink(FTree.FRoot,Self);
		FTree := nil;
	end;
end;
//-------------------------------------------------------------
procedure TAVLtreeNode.SetTree( Value : TAVLtree );
begin
	if FTree=Value then Exit;
	if FTree<>nil then
	begin
		gbt_unlink(FTree.FRoot,Self);
		FTree := nil;
	end;
	if ( Value<>nil ) and ( gbt_insert(Value.FRoot,Self)=nil ) then FTree := Value;
end;


//==TIntKeyAVLtreeNode===========================================================
constructor TIntKeyAVLtreeNode.Create( ATree : TIntKeyAVLtree; const AKey : Integer );
begin
	inherited Create;
	FKey := AKey;
	if (ATree<>nil)and not ATree.AddNode(Self) then raise EAVLtreeException.Create('Attempt to insert duplicate key '+IntToStr(AKey)+' into '+ATree.ClassName);
end;
//-------------------------------------------------------------
function TIntKeyAVLtreeNode.Compare( AWith : TBalancedTree ) : Integer ;
begin
	Result := FKey - TIntKeyAVLtreeNode(AWith).FKey;
end;


//==TIntKeyAVLtree===========================================================
// Return NIL if key already exists
function TIntKeyAVLtree.Add( const AKey : Integer ) : TIntKeyAVLtreeNode;
begin
	Result := TIntKeyAVLtreeNodeClass(FNodeClass).Create(nil,AKey);
	if not AddNode(Result) then FreeAndNil(Result);
end;
//-------------------------------------------------------------
function TIntKeyAVLtree.Find( const AKey : Integer ) : TIntKeyAVLtreeNode; assembler;
asm
	test	eax,eax
	jz		@@Exit
	mov		eax,TAVLtree[eax].FRoot
	jmp		@@6
@@1:
	lea		ecx,TAVLtreeNode[eax].LLink
	jl		@@5
	lea		ecx,TAVLtreeNode[eax].RLink
@@5:
	mov		eax,[ecx]
@@6:
	test	eax,eax
	jz		@@Exit
	cmp		edx,TIntKeyAVLtreeNode[eax].FKey
	jne		@@1
@@Exit:
end;


//==TStringKeyAVLtreeNode===========================================================
constructor TStringKeyAVLtreeNode.Create( ATree : TStringKeyAVLtree; const AKey : String );
begin
	inherited Create;
	FKey := AKey;
	if (ATree<>nil)and not ATree.AddNode(Self) then raise EAVLtreeException.Create('Attempt to insert duplicate key '''+AKey+''' into '+ATree.ClassName);
end;
//-------------------------------------------------------------
function TStringKeyAVLtreeNode.Compare( AWith : TBalancedTree ) : Integer ;
begin
	Result := TStringKeyAVLtree(TStringKeyAVLtreeNode(AWith).FTree).CompareKeys(FKey,TStringKeyAVLtreeNode(AWith).FKey);
end;


//==TStringKeyAVLtree===========================================================
constructor TStringKeyAVLtree.Create( ANodeClass : TStringKeyAVLtreeNodeClass );
var	mCompare : TStringCompareProc;
begin
	inherited Create(ANodeClass);
//	FCompareMethod := CompareKeys; compiler bug workaround
	mCompare := CompareKeys;
	FCompareMethod := mCompare;
end;
//-------------------------------------------------------------
// case insensetive ANSI compare
function TStringKeyAVLtree.CompareKeys( S1, S2 : String ) : Integer;
begin
	Result := CompareString(LOCALE_USER_DEFAULT, NORM_IGNORECASE, PChar(S1), Length(S1), PChar(S2), Length(S2)) - 2;
end;
//-------------------------------------------------------------
// Return NIL if key already exists
function TStringKeyAVLtree.Add( const AKey : String ) : TStringKeyAVLtreeNode;
begin
	Result := TStringKeyAVLtreeNodeClass(FNodeClass).Create(nil,AKey);
	if not AddNode(Result) then FreeAndNil(Result);
end;
//-------------------------------------------------------------
function TStringKeyAVLtree.Find( const AKey : String ) : TStringKeyAVLtreeNode;
var oSelf : TStringKeyAVLtree;
asm
	test	eax,eax
	jz		@@Exit0
	mov		oSelf,eax
	mov		eax,[eax].TStringKeyAVLtree.FRoot
	test	eax,eax		// VP 19 Apr 2000 fix
	jz		@@Exit0
	push	esi
	push	edi
	mov		esi,eax
	mov		edi,edx	// edi = AKey
	test	edx,edx
	jnz		@@8
@@Nil:
	xor		eax,eax
	jmp		@@Exit
@@1:
	lea		eax,[esi].TBalancedTree.LLink
	jl		@@5
	lea		eax,[esi].TBalancedTree.RLink
@@5:
	mov		eax,[eax]
	test	eax,eax
	jz		@@Exit
	mov		esi,eax
	mov		edx,edi
@@8:
	mov		eax,oSelf
	mov   edx,edi
	mov		ecx,[esi].TStringKeyAVLtreeNode.FKey
	call	TMethod[eax+Offset(TStringKeyAVLtree.FCompareMethod)]//.Code
	test	eax,eax
	jnz		@@1
	mov		eax,esi
@@Exit:
	pop		edi
	pop		esi
@@Exit0:
end; {TStringKeyAVLtree.FindKey}


//==TBinaryKeyAVLtree===========================================================
function TBinaryKeyAVLtree.CompareKeys( S1, S2 : String ) : Integer;
begin
	Result := CompareStr(S1,S2);
end;

{$undef debug}
end.
