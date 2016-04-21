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
  if ManagerSwitch.is_opam_system_switch switch then
    ManagerPath.find_in_path
      (OpamFilename.Base.of_string "ocamlc") >>= fun dirname ->
    let filename = dirname // name in
    if OpamFilename.exists filename then Some filename else None
  else
    let filename = ManagerSwitch.bin_dir switch // name in
    if OpamFilename.exists filename then Some filename else None

let find_in_all_switch config name =
  List.filter
    (fun switch -> find_in_switch switch name <> None)
    (ManagerSwitch.all config)

(** *)

let do_exec_opam config switch argv =
  match ManagerPath.find_in_path (OpamFilename.Base.of_string "opam") with
  | None -> fail ~rc:127 "\"opam\" not in PATH"
  | Some dirname ->
      let open OpamFilename.Op in
      let real_opam = dirname // "opam" in
      argv.(0) <- OpamFilename.to_string real_opam;
      Unix.putenv "PATH" ManagerPath.clean_path_str;
      ManagerSwitch.setup_minimal_env switch;
      try
        let cmd = argv.(0) in
        let args = List.tl (Array.to_list argv) in
        let rc =
          OpamProcess.run @@
          OpamProcess.command ~allow_stdin:true cmd args in
        if rc.OpamProcess.r_code = 0 then
          (* TODO: uniquement si argv contient une commande 'install'
                   ou un équivalent ?? *)
          ManagerWrapper.update_switch config switch;
        exit rc.OpamProcess.r_code
      with e ->
        fail ~rc:2
          "Exception while trying to execute %S:\n%s"
          argv.(0) (Printexc.to_string e)

let do_exec config switch argv =
  ManagerSwitch.setup_env switch;
  try Unix.execv argv.(0) argv
  with e ->
    fail ~rc:2
      "exception while executing %s: %S"
      argv.(0) (Printexc.to_string e)

let exec ?switch config argv =
  let basename = OpamFilename.basename (OpamFilename.of_string argv.(0)) in
  let is_opam = basename = OpamFilename.Base.of_string "opam" in
  let is_opam_init = is_opam && Array.length argv >= 2 && argv.(1) = "init" in
  let opam_argv = if is_opam then Some argv else None in
  let switch, src =
    match switch with
    | Some some ->
        assert (ManagerSwitch.is_valid some) ;
        some, None
    | None ->
        let switch, src = ManagerSwitch.current ?argv:opam_argv config in
        if not (is_opam_init || ManagerSwitch.is_valid switch) then begin
          match switch with
          | Opam_switch opam_switch ->
              ManagerSwitch.display_src src;
              OpamSwitch.not_installed
                (ManagerSwitch.opam_switch_name opam_switch)
        end;
        switch, Some src in
  if is_opam then
    do_exec_opam config switch argv
  else
    match find_in_switch switch basename with
    | Some filename ->
        argv.(0) <- OpamFilename.to_string filename;
        do_exec config switch argv
    | None ->
        match ManagerDefault.find config basename with
        | Some filename ->
            argv.(0) <- OpamFilename.to_string filename;
            do_exec config switch argv
        | None ->
            OpamStd.Option.iter ManagerSwitch.display_src src;
            match find_in_all_switch config basename with
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
                        Format.fprintf ppf "%s" (ManagerSwitch.name s)))
                  versions
