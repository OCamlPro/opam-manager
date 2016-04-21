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

let load () =
  let file = ManagerPath.config_file in
  if OpamFile.exists file then
    OpamFilename.with_flock `Lock_read
      (OpamFile.filename file)
      (fun () -> Some (ManagerFile.Config.read file))
  else
    None

let write conf =
  let file = ManagerPath.config_file in
  OpamFilename.mkdir (OpamFilename.dirname (OpamFile.filename file));
  OpamFilename.with_flock `Lock_write
    (OpamFile.filename file)
    (fun () -> ManagerFile.Config.write file conf)
