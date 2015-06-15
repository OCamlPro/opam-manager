(**************************************************************************)
(*                                                                        *)
(*    Copyright 2014-2015, Gregoire Henry, OCamlPro                       *)
(*                                                                        *)
(*  All rights reserved.This file is distributed under the terms of the   *)
(*  GNU Lesser General Public License version 3.0 with linking            *)
(*  exception.                                                            *)
(*                                                                        *)
(*  OPAM is distributed in the hope that it will be useful, but WITHOUT   *)
(*  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY    *)
(*  or FITNESS FOR A PARTICULAR PURPOSE.See the GNU General Public        *)
(*  License for more details.                                             *)
(*                                                                        *)
(**************************************************************************)

let make (f : (_,_,_,_) format4 -> string -> _) fmt =
    let buffer = Buffer.create 127 in
  let ppf = Format.formatter_of_buffer buffer in
  Format.kfprintf
    (fun ppf ->
       Format.pp_print_flush ppf ();
       f "opam-manager: %s" (Buffer.contents buffer))
    ppf
    fmt

let info fmt = make OpamConsole.note fmt
let warn fmt = make OpamConsole.warning fmt
let fail ?(rc = 1) fmt =
  make (fun fmt -> OpamConsole.error_and_exit ~num:rc fmt) fmt

let rec pretty_list = function
  | []    -> ""
  | [a]   -> a
  | [a;b] -> Format.sprintf "%s and %s" a b
  | h::t  -> Format.sprintf "%s, %s" h (pretty_list t)
