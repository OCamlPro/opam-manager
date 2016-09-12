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

open ManagerMisc

let () =
  if Array.length Sys.argv >= 2 &&
     Sys.argv.(0) = "opam" && Sys.argv.(1) = "manager" then begin
    match ManagerDefault.find (OpamFilename.Base.of_string "opam-manager") with
    | None ->
        fail ~rc:127 "\"opam-manager\" not in \"%s\""
          (OpamFilename.Dir.to_string ManagerPath.defaults_dir)
    | Some real_cmd ->
        let real_cmd = OpamFilename.to_string real_cmd in
        let argv = Array.make (Array.length Sys.argv - 1) real_cmd in
        Array.blit Sys.argv 2 argv 1 (Array.length Sys.argv - 2) ;
        Unix.execv real_cmd argv
  end

let () =
  try ManagerExec.exec Sys.argv
  with OpamStd.Sys.Exit x -> exit x
