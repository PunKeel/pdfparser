(** * ImpParser: Lexing and Parsing in Coq *)
(* Version of 6/19/2010 *)

(** The development of the [Imp] language in Imp.v completely ignores
    issues of concrete syntax -- how an ascii string that a programmer
    might write gets translated into the abstract syntax trees defined
    by the datatypes [aexp], [bexp], and [com].  In this file we
    illustrate how the rest of the story can be filled in by building
    a simple lexical analyzer and parser using Coq's functional
    programming facilities.

    This development is not really intended to be understood in
    detail: the explanations are fairly terse and there are no
    exercises.  The main point is simply to demonstrate that it can be
    done.  You are invited to look through the code -- most of it is
    not very complicated, though the parser relies on some "monadic"
    programming idioms that may require a little work to make out --
    but most readers will probably want to just skip down to the
    Examples section at the very end to get the punchline. *)

(* ####################################################### *)
(** * Internals *)

Require Import SfLib.

Require Import String.
Require Import Ascii.
Require Import ZArith.
Require Import QArith.

Open Scope list_scope.

(* ####################################################### *)
(** ** Lexical Analysis *)

Open Scope nat_scope.
Open Scope char_scope.

Definition eq_ascii (c d : ascii) : bool :=
  if ascii_dec c d then true else false.

Definition never : ascii -> bool :=
  fun _ => false.

Definition check_aux (to : ascii) (continuation : ascii -> bool) : ascii -> bool :=
  fun c =>
    (orb (eq_ascii c to) (continuation c)).

Eval compute in (check_aux "a" (check_aux "b" (check_aux "c" never))) "c".

(*
Notation "{{ a , .. , b }}" := (check_aux a .. (check_aux b never)  .. ) (at level 0). 
Notation "c 'isin' f" := (f c) (at level 99).

Eval compute in "b" isin {{ "a", "b", "c"}}.

Fixpoint ascii_sequence_aux (a : ascii) (n : nat) : ascii -> bool :=
  match n with
  | O   => (check_aux a never)
  | S n => let next := (ascii_of_nat (S (nat_of_ascii a))) in
             (check_aux a (ascii_sequence_aux next n))
  end.

Definition ascii_sequence (from to : ascii) : ascii -> bool :=
  let diff := (nat_of_ascii to) - (nat_of_ascii from) in
  if leb diff 0
    then never
    else ascii_sequence_aux from diff.

Notation "{[ a '--' b ]}" := (ascii_sequence a b) (at level 42).

Example ascii_sequence_decimal_works :
  {["0"--"9"]} = {{"0","1","2","3","4","5","6","7","8","9"}}.
Proof.
  unfold ascii_sequence; simpl. unfold ascii_of_pos; simpl.
  reflexivity.
Qed.

Definition isWhite (c : ascii) : bool :=
  c isin {{"000", "009", "010", "012", "013", "032"}}.
  (* NUL TAB LF formfeed CR space *)

Notation "x '<=?' y" := (ble_nat x y)
  (at level 70, no associativity) : nat_scope.

Definition isDelimiter (c : ascii) : bool :=
  c isin {{"(", ")", "<", ">", "[", "]", "{", "}", "/", "%"}}.

Definition isAscii (c : ascii) : bool :=
  let n := nat_of_ascii c in
    (n <=? 127).

Definition isRegularCharacter (c : ascii) : bool :=
  (andb (isAscii c) (negb (orb (isWhite c) (isDelimiter c)))).

Definition isDigit (c : ascii) : bool :=
  c isin {["0"--"9"]}.
*)
(* xxxx *)

Module PDF.

Parameter Zpos0 : Set.


Inductive Numeric : Set :=
  | Integer : Z -> Numeric
  | Float : Q -> Numeric.

Inductive PDFObject : Set :=
  | PDFBoolean : bool -> PDFObject
  | PDFNumber : Numeric -> PDFObject
  | PDFString : string -> PDFObject
  | PDFName : string -> PDFObject
  | PDFArray : list PDFObject -> PDFObject
  | PDFDictionary : (string -> PDFObject) -> PDFObject
  | PDFStream : string -> PDFObject
  | PDFNull : PDFObject
  | PDFIndirect : positive -> Zpos0 -> PDFObject -> PDFObject
  | PDFReference : positive -> Zpos0 -> PDFObject.

(* An option with error messages. *)
Inductive optionE (X:Type) : Type :=
  | SomeE : X -> optionE X
  | NoneE : string -> optionE X.

Implicit Arguments SomeE [[X]].
Implicit Arguments NoneE [[X]].

Inductive sublist {A : Set} : list A -> list A -> Prop :=
| sl_eq : forall l, sublist l l
| sl_cons : forall (c : A) (l l' : list A), sublist l l' -> sublist l (c::l').

Inductive truesublist {A : Set} : list A -> list A -> Prop :=
(*| tsl_nil : forall l, truesublist [] l *)
| tsl_cons : forall (c : A) (l l' : list A), sublist l l' -> truesublist l (c::l').

Example sl_ex : (@sublist ascii [] []).
Proof.
constructor.
Qed.

Example sl_ex1 : (sublist [1, 2, 3] [0, 1, 2, 3]).
Proof.
  repeat constructor.
Qed.

Definition parser (T : Type) := 
  forall l: list ascii, optionE (T * {l' : list ascii | truesublist l' l}).

Check parser.

Require Import Recdef.

Check exist.

Check le.
Check @truesublist ascii.
Check transitive _ le.
Check relation.
Check forall A, transitive _ (@truesublist A).

Lemma truesublist_transitive : 
  forall A, transitive _ (@truesublist A).
Proof.
  unfold transitive. intros. induction H0.
  



Function many_helper (T:Set) (p : parser T) (acc : list T) (xs : list ascii) {measure List.length xs } 
  : optionE (list T * {l'' : list ascii | truesublist l'' xs}) :=
match p xs with
| NoneE err        => match acc with
                      | [] => NoneE err
                      | _ =>  SomeE ((rev acc), exist _ xs _)
                        end
| SomeE (t, xsp) => match xsp with 
                      | exist xs' H => let xsp' := many_helper _ p (t::acc) xs' in
                        match xsp' with
                          | NoneE _ => SomeE ((t::acc), exist _ xs' H)
                          | SomeE (acc'', exist xs'' H') 
                            => let H'' := (fun h => _) H' in SomeE (acc'', exist _ xs'' H'')

                        end
                    end
end.
Proof.
  intros.
  clear - H.
  destruct H.
  induction H.
    auto.
    simpl in *. unfold lt in *. apply le_S. assumption.
Qed.

Fixpoint many {T} (p : parser T) (steps : nat) : parser (list T) :=
  many_helper p [] steps.



Fixpoint parse_Integer_aux (tokens : (list ascii)) : optionE(Numeric*(list ascii)) :=
  match tokens with
    | [] => NoneE "end of token stream"
    | c :: tokens' =>
      if isDigit(c) then
        match parse_Integer_aux(tokens') with
          | SomeE (n, tokens'') => SomeE(n, tokens'')
          | NoneE errors => NoneE errors
        end
      else
        SomeE(Integer 0, tokens)
  end.

Definition parse_Integer (tokens : (list ascii)) : optionE(Numeric*(list ascii)) :=
  match tokens with
    | [] => NoneE "end of token stream"
    | c :: tokens' =>
      if isDigit(c) then
        match parse_Integer_aux(tokens') with
          | SomeE (Integer n, tokens'') => SomeE(Integer n, tokens'')
          | NoneE error => NoneE error
        end
      else
        NoneE "Illegal character"
  end.

boolean,
integer,
float,
string,
name,
array,
dictionary,
stream,
null
indirect object

Definition isLowerAlpha (c : ascii) : bool :=
  let n := nat_of_ascii c in
    andb (97 <=? n) (n <=? 122).

Definition isAlpha (c : ascii) : bool :=
  let n := nat_of_ascii c in
    orb (andb (65 <=? n) (n <=? 90))
        (andb (97 <=? n) (n <=? 122)).

Definition isDigit (c : ascii) : bool :=
  let n := nat_of_ascii c in 
     andb (48 <=? n) (n <=? 57).

Inductive chartype := white | alpha | digit | other.

Definition classifyChar (c : ascii) : chartype :=
  if isWhite c then 
    white
  else if isAlpha c then
    alpha
  else if isDigit c then
    digit
  else
    other.

Fixpoint list_of_string (s : string) : list ascii :=
  match s with
  | EmptyString => []
  | String c s => c :: (list_of_string s)
  end.

Fixpoint string_of_list (xs : list ascii) : string :=
  fold_right String EmptyString xs.

Definition token := string.

Fixpoint tokenize_helper (cls : chartype) (acc xs : list ascii) 
                       : list (list ascii) :=
  let tk := match acc with [] => [] | _::_ => [rev acc] end in
  match xs with
  | [] => tk
  | (x::xs') =>
    match cls, classifyChar x, x with
    | _, _, "("      => tk ++ ["("]::(tokenize_helper other [] xs') 
    | _, _, ")"      => tk ++ [")"]::(tokenize_helper other [] xs') 
    | _, white, _    => tk ++ (tokenize_helper white [] xs')
    | alpha,alpha,x  => tokenize_helper alpha (x::acc) xs'
    | digit,digit,x  => tokenize_helper digit (x::acc) xs'
    | other,other,x  => tokenize_helper other (x::acc) xs'
    | _,tp,x         => tk ++ (tokenize_helper tp [x] xs')
    end
  end %char.

Definition tokenize (s : string) : list string :=
  map string_of_list (tokenize_helper white [] (list_of_string s)).

Example tokenize_ex1 : 
    tokenize "abc12==3  223*(3+(a+c))" %string
  = ["abc", "12", "==", "3", "223",
       "*", "(", "3", "+", "(",
       "a", "+", "c", ")", ")"]%string.
Proof. reflexivity. Qed.

(* ####################################################### *)
(** ** Parsing *)

(* ####################################################### *)
(** *** Options with Errors *)


(* Some syntactic sugar to make writing nested match-expressions on
   optionE more convenient. *)

Notation "'DO' ( x , y ) <== e1 ;; e2" 
   := (match e1 with
         | SomeE (x,y) => e2
         | NoneE err => NoneE err
       end)
   (right associativity, at level 60).

Notation "'DO' ( x , y ) <-- e1 ;; e2 'OR' e3" 
   := (match e1 with
         | SomeE (x,y) => e2
         | NoneE err => e3
       end)
   (right associativity, at level 60, e2 at next level). 

(* ####################################################### *)
(** *** Symbol Table *)

(* Build a mapping from [tokens] to [nats].  A real parser would do
   this incrementally as it encountered new symbols, but passing
   around the symbol table inside the parsing functions is a bit
   inconvenient, so instead we do it as a first pass. *)
Fixpoint build_symtable (xs : list token) (n : nat) : (token -> nat) :=
  match xs with
  | [] => (fun s => n)
  | x::xs =>
    if (forallb isLowerAlpha (list_of_string x))
     then (fun s => if string_dec s x then n else (build_symtable xs (S n) s))
     else build_symtable xs n
  end.

(* ####################################################### *)
(** *** Generic Combinators for Building Parsers *)

Open Scope string_scope.

Definition parser (T : Type) := 
  list token -> optionE (T * list token).

Fixpoint many_helper {T} (p : parser T) acc steps xs :=
match steps, p xs with
| 0, _ => NoneE "Too many recursive calls"
| _, NoneE _ => SomeE ((rev acc), xs)
| S steps', SomeE (t, xs') => many_helper p (t::acc) steps' xs'
end.

(* A (step-indexed) parser which expects zero or more [p]s *)
Fixpoint many {T} (p : parser T) (steps : nat) : parser (list T) :=
  many_helper p [] steps.

(* A parser which expects a given token, followed by p *)
Definition firstExpect {T} (t : token) (p : parser T) : parser T :=
  fun xs => match xs with
              | x::xs' => if string_dec x t 
                           then p xs' 
                          else NoneE ("expected '" ++ t ++ "'.")
              | [] =>  NoneE ("expected '" ++ t ++ "'.")
            end. 

(* A parser which expects a particular token *)
Definition expect (t : token) : parser unit :=
  firstExpect t (fun xs => SomeE(tt, xs)).

(* ####################################################### *)
(** *** A Recursive-Descent Parser for Imp *)

(* Identifiers *)
Definition parseIdentifier (symtable :string->nat) (xs : list token) 
                         : optionE (id * list token) :=
match xs with
| [] => NoneE "Expected identifier"
| x::xs' => 
    if forallb isLowerAlpha (list_of_string x) then
      SomeE (Id (symtable x), xs')
    else
      NoneE ("Illegal identifier:'" ++ x ++ "'")
end.

(* Numbers *)
Definition parseNumber (xs : list token) : optionE (nat * list token) :=
match xs with 
| [] => NoneE "Expected number"
| x::xs' => 
    if forallb isDigit (list_of_string x) then
      SomeE (fold_left (fun n d =>
                        10 * n + (nat_of_ascii d - nat_of_ascii "0"%char))
                (list_of_string x)
                0,
              xs')
    else 
      NoneE "Expected number"
end.

(* Parse arithmetic expressions *)
Fixpoint parsePrimaryExp (steps:nat) symtable (xs : list token) 
   : optionE (aexp * list token) :=
  match steps with
  | 0 => NoneE "Too many recursive calls"
  | S steps' =>
      DO (i, rest) <-- parseIdentifier symtable xs ;;
          SomeE (AId i, rest)
      OR DO (n, rest) <-- parseNumber xs ;;
          SomeE (ANum n, rest)
      OR (DO (e, rest)  <== firstExpect "(" (parseSumExp steps' symtable) xs;;
          DO (u, rest') <== expect ")" rest ;;
          SomeE(e,rest'))
  end
with parseProductExp (steps:nat) symtable (xs : list token)  :=
  match steps with
  | 0 => NoneE "Too many recursive calls"
  | S steps' => 
    DO (e, rest) <== 
      parsePrimaryExp steps' symtable xs ;;
    DO (es, rest') <== 
      many (firstExpect "*" (parsePrimaryExp steps' symtable)) steps' rest;;
    SomeE (fold_left AMult es e, rest')
  end
with parseSumExp (steps:nat) symtable (xs : list token)  :=
  match steps with
  | 0 => NoneE "Too many recursive calls"
  | S steps' => 
    DO (e, rest) <== 
      parseProductExp steps' symtable xs ;;
    DO (es, rest') <== 
      many (fun xs =>
             DO (e,rest') <-- 
               firstExpect "+" (parseProductExp steps' symtable) xs;;
                                 SomeE ( (true, e), rest')
             OR DO (e,rest') <== 
               firstExpect "-" (parseProductExp steps' symtable) xs;;
                                 SomeE ( (false, e), rest'))
                            steps' rest;;
      SomeE (fold_left (fun e0 term => 
                          match term with 
                            (true,  e) => APlus e0 e
                          | (false, e) => AMinus e0 e
                          end)
                       es e, 
             rest')         
  end.

Definition parseAExp := parseSumExp.

(* Parsing boolean expressions. *)
Fixpoint parseAtomicExp (steps:nat) (symtable : string->nat) (xs : list token)  :=
match steps with
  | 0 => NoneE "Too many recursive calls"
  | S steps' =>
     DO    (u,rest) <-- expect "true" xs;;
         SomeE (BTrue,rest)
     OR DO (u,rest) <-- expect "false" xs;;
         SomeE (BFalse,rest)
     OR DO (e,rest) <-- firstExpect "not" (parseAtomicExp steps' symtable) xs;;
         SomeE (BNot e, rest)
     OR DO (e,rest) <-- firstExpect "(" (parseConjunctionExp steps' symtable) xs;;
          (DO (u,rest') <== expect ")" rest;; SomeE (e, rest'))
     OR DO (e, rest) <== parseProductExp steps' symtable xs ;;
            (DO (e', rest') <-- 
              firstExpect "==" (parseAExp steps' symtable) rest ;;
              SomeE (BEq e e', rest')
             OR DO (e', rest') <-- 
               firstExpect "<=" (parseAExp steps' symtable) rest ;;
               SomeE (BLe e e', rest')
             OR
               NoneE "Expected '==' or '<=' after arithmetic expression")
end
with parseConjunctionExp (steps:nat) (symtable : string->nat) (xs : list token)   :=
  match steps with
  | 0 => NoneE "Too many recursive calls"
  | S steps' =>
    DO (e, rest) <== 
      parseAtomicExp steps' symtable xs ;;
    DO (es, rest') <== 
      many (firstExpect "&&" (parseAtomicExp steps' symtable)) steps' rest;;
    SomeE (fold_left BAnd es e, rest')
  end.

Definition parseBExp := parseConjunctionExp.

(* 
Eval compute in 
  (parseProductExp 100 (tokenize "x*y*(x*x)*x")).

Eval compute in 
  (parseDisjunctionExp 100 (tokenize "not((x==x||x*x<=(x*x)*x)&&x==x)")). 
*)

(* Parsing commands *)
Fixpoint parseSimpleCommand (steps:nat) (symtable:string->nat) (xs : list token) :=
  match steps with
  | 0 => NoneE "Too many recursive calls"
  | S steps' => 
    DO (u, rest) <-- expect "SKIP" xs;;
      SomeE (SKIP, rest)
    OR DO (e,rest) <-- 
         firstExpect "IF" (parseBExp steps' symtable) xs;;
       DO (c,rest')  <== 
         firstExpect "THEN" (parseSequencedCommand steps' symtable) rest;;
       DO (c',rest'') <== 
         firstExpect "ELSE" (parseSequencedCommand steps' symtable) rest';;
       DO (u,rest''') <== 
         expect "END" rest'';;
       SomeE(IFB e THEN c ELSE c' FI, rest''')
    OR DO (e,rest) <-- 
         firstExpect "WHILE" (parseBExp steps' symtable) xs;;
       DO (c,rest') <== 
         firstExpect "DO" (parseSequencedCommand steps' symtable) rest;;
       DO (u,rest'') <== 
         expect "END" rest';;
       SomeE(WHILE e DO c END, rest'')
    OR DO (i, rest) <== 
         parseIdentifier symtable xs;;
       DO (e, rest') <== 
         firstExpect ":=" (parseAExp steps' symtable) rest;;
       SomeE(i ::= e, rest')
  end

with parseSequencedCommand (steps:nat) (symtable:string->nat) (xs : list token) :=
  match steps with
  | 0 => NoneE "Too many recursive calls"
  | S steps' => 
      DO (c, rest) <== 
        parseSimpleCommand steps' symtable xs;;
      DO (c', rest') <-- 
        firstExpect ";" (parseSequencedCommand steps' symtable) rest;;
        SomeE(c ; c', rest')
      OR
        SomeE(c, rest)
  end.

Definition parse (str : string) : optionE (com * list token) :=
  let tokens := tokenize str in
  parseSequencedCommand 1000 (build_symtable tokens 0) tokens.

(* ####################################################### *)
(** * Examples *)

(*
Eval compute in parse "
    IF x == y + 1 + 2 - y * 6 + 3 THEN
      x := x * 1;
      y := 0
    ELSE
      SKIP
    END  ".
====>
    SomeE
       (IFB BEq (AId (Id 0))
                (APlus
                   (AMinus (APlus (APlus (AId (Id 1)) (ANum 1)) (ANum 2))
                      (AMult (AId (Id 1)) (ANum 6))) 
                   (ANum 3))
        THEN Id 0 ::= AMult (AId (Id 0)) (ANum 1); Id 1 ::= ANum 0
        ELSE SKIP FI, [])
*)

(*
Eval compute in parse "
    SKIP;
    z:=x*y*(x*x);
    WHILE x==x DO
      IF z <= z*z && not x == 2 THEN
        x := z;
        y := z
      ELSE
        SKIP
      END;
      SKIP
    END;
    x:=z  ".
====> 
     SomeE
        (SKIP;
         Id 0 ::= AMult (AMult (AId (Id 1)) (AId (Id 2)))
                        (AMult (AId (Id 1)) (AId (Id 1)));
         WHILE BEq (AId (Id 1)) (AId (Id 1)) DO 
           IFB BAnd (BLe (AId (Id 0)) (AMult (AId (Id 0)) (AId (Id 0))))
                     (BNot (BEq (AId (Id 1)) (ANum 2)))
              THEN Id 1 ::= AId (Id 0); Id 2 ::= AId (Id 0) 
              ELSE SKIP FI; 
           SKIP 
         END; 
         Id 1 ::= AId (Id 0), 
        []) 
*)

(*
Eval compute in parse "
   SKIP;
   z:=x*y*(x*x);
   WHILE x==x DO
     IF z <= z*z && not x == 2 THEN
       x := z;
       y := z
     ELSE
       SKIP
     END;
     SKIP
   END;
   x:=z  ".
=====> 
      SomeE
         (SKIP;
          Id 0 ::= AMult (AMult (AId (Id 1)) (AId (Id 2)))
                (AMult (AId (Id 1)) (AId (Id 1)));
          WHILE BEq (AId (Id 1)) (AId (Id 1)) DO 
            IFB BAnd (BLe (AId (Id 0)) (AMult (AId (Id 0)) (AId (Id 0))))
                     (BNot (BEq (AId (Id 1)) (ANum 2)))
              THEN Id 1 ::= AId (Id 0); 
                   Id 2 ::= AId (Id 0) 
              ELSE SKIP 
            FI; 
            SKIP 
          END; 
          Id 1 ::= AId (Id 0), 
         []).
*)
