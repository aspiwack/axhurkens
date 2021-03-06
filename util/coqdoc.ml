 (*** pretty printing function for Coq code ***)

open Latex
open Prelude

let normal_font =  Latex.Verbatim.verbatim
let ident_font = avantgarde
let tactic_font x = avantgarde (itshape x)

let keywords = [
  "Prop" ;
  "Type" ;
  "forall" ;
  "exists" ;
  "Definition" ;
  "Lemma" ;
  "Theorem" ;
  "Remark" ;
  "Fixpoint" ;
  "Inductive" ;
  "Ltac" ;
  "fun" ;
  "Record" ;
  "Program" ;
  "match" ;
  "with" ;
  "end";

  "let";
  "in";

  "Module";
  "Section";
  "Variable";
  "Variables";
  "Hypothesis";
  "Let";
  "End";

  "Next";
  "Obligation";

  "Proof";
  "Qed";

  "Time";
  "Eval";

  "Implicit"; "Arguments";
  "Notation";
]

let tactic_keywords = [
  "refine";
  "exact";
  "unfold";
  "intro"; "intros";
  "assert";
  "as"; "at";
  "generalize";
  "clear";
  "lazy";
  "repeat";
  "rewrite";
  "destruct";
  "reflexivity";
  "contradiction";
  "apply";
  "contradiction";
  "eauto";
]

let keyword_symbols = [
  "existstac", tactic_font (text"exists");
  "star" , star
]

let symbols = [
  (*"\n" , newline ;*)
  "-->" , longrightarrow ;
  "<->" , leftrightarrow ;
  "->" , rightarrow ;
  "==>" , longrightarrow_ ;
  "=>" , rightarrow_ ;
  "|^" , uparrow ;
  "==" , equiv ;
  "{" , text"\\{" ;
  "}" , text"\\}" ;
  "!" , cdot ;
  "|" , hspace (`Em 0.1)^^rule_ ~lift:(`Ex (-0.6)) (`Sp 1.) (`Baselineskip 1.) ;
  "~0", mode M(sim^^text"0") ;
  "~1", mode M(sim^^text"1") ;
  "~" , lnot ;
  "/\\" , land_ ;
  "\\/" , lor_ ;
  "<>" , neq ;
  "<" , mode M (text"<") ;
  ">" , mode M (text">") ;
  "*" , mode M(text"*") ;
  "_", mode M(text"\\_") ;
  "++", mode M (text"+\\!\\!\\!+") ;
  ":=" , mode M (command"coloneqq" ~packages:["mathtools",""] [] M) ;
  "&" , textsf(text"\\&") ;
  (* utf8 symbols *)
  "η" , upeta ;
  "ι" , upiota ;
  "λ" , lambda ;
  "Λ" , lambda_ ;
  "μ" , upmu ;
  "π" , uppi ;
  "≡" , equiv ;
  "·" , cdot ;
  "⊕" , oplus ;
  "⊗" , otimes ;
  "₀" , mode M(text"_0") ;
  "₁" , mode M(text"_1") ;
  "₂" , mode M(text"_2") ;
  "¹" , mode M(text"^1") ;
  "⟨" , langle;
  "⟩" , rangle;
  "×" , times ;
  "∀" , forall ;
  "⟶" , longrightarrow ;

  "--" , mode T (text"--") ;
]

let id_apply i = ident_font i
let kw_apply k = avantgarde_bold k
let tkw_apply k = tactic_font k
let else_apply s = normal_font s

let idents = (
  Str.regexp "_?[a-zA-Z][a-zA-Z0-9]*\\(_[a-zA-Z0-9]+\\)*" ,
  fun s ->
    try List.assoc s keyword_symbols
    with Not_found ->
      let usplit = Str.split_delim (Str.regexp_string "_") s in
      let escaped = text(String.concat "\\_" usplit) in
      if List.mem s keywords then
        kw_apply escaped
      else if List.mem s tactic_keywords then
        tkw_apply escaped
      else
	id_apply escaped
  )

let symbols =
  List.map begin fun (s,t) ->
    Str.regexp_string s, fun _ -> t
  end symbols

let calletters = (
  Str.regexp "\\\\c[A-Z]" ,
  fun s ->
    mathcal (text (String.sub s 2 1))
)

let comment_whitespaces =
  Str.regexp "[ \n]",
  Latex.Verbatim.verbatim

let indent =
  Str.regexp"^[ ]+",
  Latex.Verbatim.verbatim
let whitespaces =
  Str.regexp "[ ]+",
  fun _ -> text"~"

let blanklines =
  Str.regexp"[\n]\\([ ]*[\n]\\)+",
  (fun _ -> Latex.newline_size (`Baselineskip 0.5))

let rec print n x =
  assert (!n>=0);
  if !n = 0 then
    Latex.Verbatim.regexps (blanklines::indent::whitespaces::(open_comments n)::calletters::idents::symbols) else_apply x
  else
    Latex.Verbatim.regexps [open_comments n ; close_comments n; comment_whitespaces ] (fun s -> itshape(text s)) x

and open_comments n =
  Str.regexp"(\\*\\(.\\|[\n]\\)*",
  fun s -> incr n; itshape (text"(*") ^^ print n (String.sub s 2 (String.length s - 2))
and close_comments n =
  Str.regexp"\\*)\\(.\\|[\n]\\)*",
  fun s -> decr n; itshape (text"*)") ^^ print n (String.sub s 2 (String.length s - 2))

(*let print = print 0*)

open Meltpp_plugin



let verbatim_simpleM name : verbatim_function = fun f l ->
  Format.fprintf f "begin let __n__ = ref 0 in";
  let name = name ^ " __n__" in
  list_iter_concat f begin fun f -> function
    | `V s -> Format.fprintf f "(%s \"%s\")" name (escape_except_newline s)
    | `C a | `M a | `T a -> Format.fprintf f "(%a)" a ()
  end l;
  Format.fprintf f "end"


let () =
  declare_verbatim_function "coqdoc"
    (verbatim_simpleM "Coqdoc.print")
