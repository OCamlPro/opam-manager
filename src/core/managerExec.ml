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

open ManagerTypes
open ManagerMisc

let find_in_switch switch name =
  let open OpamStd.Option.Op in
  let (//) = OpamFilename.create in
  if ManagerSwitch.is_system_switch switch then
    ManagerPath.find_in_path
      (OpamFilename.Base.of_string "ocamlc") >>= fun dirname ->
    let filename = dirname // name in
    if OpamFilename.exists filename then Some filename else None
  else
    let filename = ManagerSwitch.bin_dir switch // name in
    if OpamFilename.exists filename then Some filename else None

let find_in_all_switch name =
  List.filter
    (fun switch -> find_in_switch switch name <> None)
    (Lazy.force ManagerSwitch.all)

(** *)

let do_exec switch argv =
  ManagerSwitch.setup_env switch ;
  try Unix.execv argv.(0) argv
  with e ->
    fail ~rc:2
      "exception while executing %s: %S"
      argv.(0) (Printexc.to_string e)

let do_exec_opam switch argv =
  let do_run cmd =
    match ManagerDefault.find (OpamFilename.Base.of_string cmd) with
    | None ->
        fail ~rc:127 "\"%s\" not in \"%s\""
          cmd (OpamFilename.Dir.to_string ManagerPath.defaults_dir)
    | Some real_cmd ->
        let real_cmd = OpamFilename.to_string real_cmd in
        ManagerSwitch.setup_env switch ;
        try
          let args = List.tl (Array.to_list argv) in
          OpamProcess.run @@
          OpamProcess.command ~allow_stdin:true real_cmd args
        with e ->
          fail ~rc:2
            "Exception while trying to execute %S:\n%s"
            real_cmd (Printexc.to_string e) in
    let rc = do_run "opam" in
    if rc.OpamProcess.r_code = 0 then
      ManagerWrapper.update_switch switch ;
    exit rc.OpamProcess.r_code

let exec ?(switch = Lazy.force ManagerSwitch.current) argv =
  let basename = OpamFilename.basename (OpamFilename.of_string argv.(0)) in
  let is_opam = basename = OpamFilename.Base.of_string "opam" in
  if is_opam then
    do_exec_opam switch argv
  else
    match find_in_switch switch basename with
    | Some filename ->
        argv.(0) <- OpamFilename.to_string filename ;
        do_exec switch argv
    | None ->
        match ManagerDefault.find basename with
        | Some filename ->
            argv.(0) <- OpamFilename.to_string filename ;
            do_exec switch argv
        | None ->
            match find_in_all_switch basename with
            | [] ->
                fail ~rc:2
                  "the command %S can not be found in any OPAM switch."
                  (OpamFilename.Base.to_string basename)
            | versions ->
                let versions = List.sort compare versions in
                fail ~rc:2
                  "the command %S can not be found in the current OPAM switch.\
                  \ However, it is available in the following switches: %a.\n"
                  (OpamFilename.Base.to_string basename)
                  (Format.pp_print_list
                     ~pp_sep:Format.pp_print_space
                     (fun ppf s ->
                        Format.fprintf ppf "%s" (OpamSwitch.to_string s.name)))
                  versions
