
(*
copyright (c) 2013, simon cruanes
all rights reserved.

redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.  redistributions in binary
form must reproduce the above copyright notice, this list of conditions and the
following disclaimer in the documentation and/or other materials provided with
the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*)

(** {1 GADT Description of Printers}

This module provides combinators to build printers for user-defined types.
It doesn't try to do {b pretty}-printing (see for instance Pprint for this),
but a simple way to print complicated values without writing a lot of code.
*)

type 'a sequence = ('a -> unit) -> unit

type 'a t = Buffer.t -> 'a -> unit
  (** A printer for the type ['a] *)

(** {2 Combinators} *)

let unit buf () = ()
let int buf i = Buffer.add_string buf (string_of_int i)
let string buf s = Buffer.add_string buf s
let bool buf b = Printf.bprintf buf "%B" b
let float3 buf f = Printf.bprintf buf "%.3f" f
let float buf f = Buffer.add_string buf (string_of_float f)

let list ?(start="[") ?(stop="]") ?(sep=", ") pp buf l =
  let rec pp_list l = match l with
  | x::((y::xs) as l) ->
    pp buf x;
    Buffer.add_string buf sep;
    pp_list l
  | x::[] -> pp buf x
  | [] -> ()
  in
  Buffer.add_string buf start;
  pp_list l;
  Buffer.add_string buf stop
  
let array ?(start="[") ?(stop="]") ?(sep=", ") pp buf a =
  Buffer.add_string buf start;
  for i = 0 to Array.length a - 1 do
    (if i > 0 then Buffer.add_string buf sep);
    pp buf a.(i)
  done;
  Buffer.add_string buf stop
  
let arrayi ?(start="[") ?(stop="]") ?(sep=", ") pp buf a =
  Buffer.add_string buf start;
  for i = 0 to Array.length a - 1 do
    (if i > 0 then Buffer.add_string buf sep);
    pp buf (i, a.(i))
  done;
  Buffer.add_string buf stop

let seq ?(start="[") ?(stop="]") ?(sep=", ") pp buf seq =
  Buffer.add_string buf start;
  let first = ref true in
  seq (fun x ->
    (if !first then first := false else Buffer.add_string buf sep);
    pp buf x);
  Buffer.add_string buf stop

let opt pp buf x = match x with
  | None -> Buffer.add_string buf "none"
  | Some x -> Printf.bprintf buf "some %a" pp x

let pair ppa ppb buf (a, b) =
  Printf.bprintf buf "(%a, %a)" ppa a ppb b

let triple ppa ppb ppc buf (a, b, c) =
  Printf.bprintf buf "(%a, %a, %a)" ppa a ppb b ppc c

let quad ppa ppb ppc ppd buf (a, b, c, d) =
  Printf.bprintf buf "(%a, %a, %a, %a)" ppa a ppb b ppc c ppd d

let map f pp buf x =
  pp buf (f x);
  ()

(** {2 IO} *)

let output oc pp x =
  let buf = Buffer.create 64 in
  pp buf x;
  Buffer.output_buffer oc buf

let to_string pp x =
  let buf = Buffer.create 64 in
  pp buf x;
  Buffer.contents buf

let sprintf format =
  let buffer = Buffer.create 64 in
  Printf.kbprintf
    (fun fmt -> Buffer.contents buffer)
    buffer
    format

let fprintf oc format =
  let buffer = Buffer.create 64 in
  Printf.kbprintf
    (fun fmt -> Buffer.output_buffer oc buffer)
  buffer
  format

let printf format = fprintf stdout format
let eprintf format = fprintf stderr format
