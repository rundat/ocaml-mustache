%{
  open Mustache_types
  let parse_section start_s end_s contents =
    if start_s = end_s
    then { contents; name=start_s }
    else
      let msg =
        Printf.sprintf "Mismatched section %s with %s" start_s end_s in
      raise (Invalid_template msg)
%}

%token EOF
%token END
%token <string> ESCAPE_START
%token ESCAPE_END
%token <string> UNESCAPE_START_AMPERSAND
%token <string> SECTION_INVERT_START
%token <string> SECTION_START
%token <string> SECTION_END
%token <string> PARTIAL_START
%token <string> UNESCAPE_START
%token UNESCAPE_END

%token <string> RAW
%token DOT

%start mustache
%type <Mustache_types.t> mustache

%%

section:
  | SECTION_INVERT_START END mustache SECTION_END END { Inverted_section (parse_section $1 $4 $3) }
  | SECTION_START END mustache SECTION_END END { Section (parse_section $1 $4 $3) }

mustache_element:
  | UNESCAPE_START UNESCAPE_END { Unescaped $1 }
  | UNESCAPE_START_AMPERSAND ESCAPE_END { Unescaped $1 }
  | ESCAPE_START END { if $1 = "." then Iter_var else Escaped $1 }
  | PARTIAL_START END { Partial $1 }
  | section { $1 }

string:
  | RAW { String $1 }

mustache_l:
  | mustache_element mustache_l { ($1 :: $2) }
  | string mustache_l { ($1 :: $2) }
  | mustache_element { [$1] }
  | string { [$1] }

mustache:
  | mustache_l {
    match $1 with
    | [x] -> x
    | x -> Concat x
  }
  | EOF { String "" }

%%
