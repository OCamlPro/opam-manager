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

type defaults =
  | Absolute of OpamFilename.t
  | Switch of opam_switch

val find: OpamFilename.Base.t -> OpamFilename.t option

val create: OpamFilename.Base.t -> defaults -> unit

val create_absolute: OpamFilename.Base.t -> unit

val list_absolute: unit -> OpamStd.String.Set.t
