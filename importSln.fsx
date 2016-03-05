let iif f iftrue iffalse x = if f x then iftrue else iffalse
let flip f x y = f y x
let cnst x _ = x
module Option =
  let orDefault d = function Some v -> v | None -> d
module List =
  let rec by<'t> (n:int) (l:'t list) : 't list list =
    match l with
      | [] -> []
      | x::xs -> (l |> List.truncate n)::(by n xs)
  let init'<'t> : 't list -> 't list = List.rev >> List.tail >> List.rev
module String =
  let startswith (prefix:string) (s:string) = s.StartsWith prefix
  let endswith (suffix:string) (s:string) = s.EndsWith suffix
  let split (splitters:string list) (s:string) = s.Split (splitters |> Array.ofList, System.StringSplitOptions.None) |> Array.toList
  let trim (s:string) = s.Trim ()
  let replace (find:string) (replacement:string) (s:string) = s.Replace (find, replacement)
  let contains (find:string) (s:string) = s.Contains find
  let removePrefix (prefix:string) (s:string) = if startswith prefix s then s.Substring (prefix.Length) else s
  let removeSuffix (suffix:string) (s:string) = if endswith suffix s then s.Substring (0, s.Length - suffix.Length) else s
module Tuple =
  let mappend f x = x, f x
  let create x y = x, y
  let uncurry f (x, y) = f x y
  let first f (x, y) = (f x, y)
  let second f (x, y) = (x, f y)
  let twice (f, g) x = (f x, g x)
  let map (f, g) (x, y) = (f x, g y)
module Map =
  let appendToList<'k,'v when 'k : comparison> (k:'k) (vs:'v list) (m:Map<'k,'v list>) =
    let vs = m |> Map.tryFind k |> Option.orDefault [] |> List.append vs
    m |> Map.add k vs

module File =
  type T = T of string list with
    static member (+) (T parts1, T parts2) = T (parts1 @ parts2)
    static member (-) (T parts1, T parts2) =
      let rec go parts1 parts2 =
        match (parts1, parts2) with
          | [], [] -> []
          | xs, [] -> xs
          | x::xs, y::ys when x = y -> go xs ys
          | xs, ys -> xs |> List.append (ys |> List.map (cnst ".."))
      go parts1 parts2 |> T
  let toName (T parts) : string =
    match parts with
      | ""::_ -> ["/"]
      | _ -> []
    @ parts
    |> Array.ofList |> System.IO.Path.Combine
  let ofName (name:string) : T = String.split ["/"; "\\"] name |> T

  let currentDir = System.Environment.CurrentDirectory |> ofName
  let dir (T parts) : T = parts |> List.init' |> T
  let file (T parts) : T = parts |> List.last |> List.singleton |> T
  let absoluteTo : T -> T -> T = (+)
  let relativeTo : T -> T -> T = flip (-)
  let normalize : T -> T = absoluteTo currentDir >> toName >> System.IO.Path.GetFullPath >> ofName >> relativeTo currentDir
  let oneUp (T parts) : T = parts |> List.skip 1 |> T

  let resuffix (suffix:string) (t:T) : T =
    let file = ((file t |> toName |> String.split ["."] |> List.init')@[suffix]) |> String.concat "." |> ofName
    dir t + file

  let isIn (dir:T) (t:T) = match relativeTo dir t with | T (".."::_) -> false | _ -> true

  let read (t:T) : string list option = try t |> toName |> System.IO.File.ReadAllLines |> Seq.toList |> Some with _ -> None

module Project =
  type OutputType = | Library | Exe
  type Reference = | File of File.T | Assembly of string | Project of File.T
  type T = { OutputType: OutputType; Sources: File.T list; References: Reference list; Packages: string list }

  type Line = | Compile of string | Include of string | Reference of string | ProjectReference of string | OutputType of string | HintPath of string

  let ofFile (f:File.T) : T =
    let parseLines : string list -> Line list =
      List.choose (
        String.trim >> function
        | s when String.startswith "<Compile Include" s -> s |> String.split ["\""] |> List.item 1 |> Compile |> Some
        | s when String.startswith "<None Include" s -> s |> String.split ["\""] |> List.item 1 |> Include |> Some
        | s when String.startswith "<Reference Include" s -> s |> String.split ["\""] |> List.item 1 |> Reference |> Some
        | s when String.startswith "<ProjectReference Include" s -> s |> String.split ["\""] |> List.item 1 |> ProjectReference |> Some
        | s when String.startswith "<OutputType>" s -> s |> String.removePrefix "<OutputType>" |> String.removeSuffix "</OutputType>" |> OutputType |> Some
        | s when String.startswith "<HintPath>" s -> s |> String.removePrefix "<HintPath>" |> String.removeSuffix "</HintPath>" |> HintPath |> Some
        | _ -> None
        )
    let parsePackages : string list -> string list =
      List.map String.trim >> List.filter (String.startswith "<package id") >> List.map (String.split ["\""] >> List.item 1)

    let root = f |> File.dir
    let adjustPath = File.absoluteTo root >> File.relativeTo File.currentDir >> File.normalize
    let lines = f |> File.read |> Option.map (parseLines) |> Option.orDefault []
    let outputtype = lines |> List.tryPick (function | (OutputType s) -> s |> iif ((=) "Library") Library Exe |> Some | _ -> None) |> Option.orDefault Library
    let sources = lines |> List.choose (function | (Compile s) -> s |> File.ofName |> adjustPath |> Some | _ -> None)
    let projects = lines |> List.choose (function | (ProjectReference s) -> s |> File.ofName |> adjustPath |> Project |> Some | _ -> None)
    let references = lines |> List.by 2 |> List.choose (function | [(Reference s); (HintPath p)] -> p |> File.ofName |> adjustPath |> File |> Some | [(Reference s);_] | [(Reference s)] -> Assembly s |> Some | _ -> None)
    let nugets = (root + File.ofName "packages.config") |> File.read |> Option.map (parsePackages) |> Option.orDefault []

    { OutputType = outputtype; Sources = sources; References = projects@references; Packages = nugets }

module Solution =
  type T = { ProjectFiles: File.T list; NuGetRoot: File.T option }

  let ofFile (f:File.T) : T =
    let findProjects : string list -> File.T list =
      List.filter ( String.startswith "Project" ) >>
      List.choose ( String.split ["\""] >> List.tryFind (String.endswith ".fsproj") >> Option.map File.ofName )

    let repoLine : string list -> File.T option =
      List.filter ( String.contains "repositorypath" ) >>
      List.tryPick ( String.split ["\""] >> List.tryItem 3 >> Option.map File.ofName )

    let root = f |> File.dir
    let adjustPath = File.absoluteTo root >> File.relativeTo File.currentDir >> File.normalize
    let projects = f |> File.read |> Option.map (findProjects >> List.map adjustPath) |> Option.orDefault []
    let nugetroot = (root + (File.ofName "NuGet.config")) |> File.read |> Option.bind repoLine |> Option.map adjustPath
    { ProjectFiles = projects; NuGetRoot = nugetroot }

let projTo suff = File.resuffix suff

fsi.CommandLineArgs |> Array.toList |> List.filter (String.endswith ".sln") |> List.tryHead |> function
  | None -> stderr.WriteLine "Please provide a sln to import"; exit 1
  | Some sln ->
    let s = Solution.ofFile (File.ofName sln |> File.absoluteTo File.currentDir)
    let prs = s.ProjectFiles |> List.map (Tuple.twice (id, File.absoluteTo File.currentDir >> Project.ofFile))
    let nugets = prs |> List.collect (fun p -> (snd p).Packages) |> List.distinct |> List.filter ((<>) "FSharp.Core") |> List.sortByDescending String.length
    let nugetroot = s.NuGetRoot |> Option.orDefault (File.currentDir + File.ofName "packages")
    stdout.WriteLine "# Assemblies (dll)"
    prs
    |> List.filter (fun p -> (snd p).OutputType = Project.Library)
    |> List.iter (fun p -> (fst p) |> Tuple.twice (File.toName, projTo "dll" >> File.toName) |>
                           Tuple.uncurry (sprintf "%s = $(call FSHARP_mkDllTarget,%s)") |>
                           stdout.WriteLine)
    stdout.WriteLine ""
    stdout.WriteLine "# Assemblies (exe)"
    prs
    |> List.filter (fun p -> (snd p).OutputType = Project.Exe)
    |> List.iter (fun p -> (fst p) |> Tuple.twice (File.toName, projTo "exe" >> File.toName) |>
                           Tuple.uncurry (sprintf "%s = $(call FSHARP_mkExeTarget,%s)") |>
                           stdout.WriteLine)
    stdout.WriteLine ""
    stdout.WriteLine "# NuGet packages"
    nugets |> List.iter (Tuple.twice (id, id) >> Tuple.uncurry (sprintf "%s_NuGet = $(call NUGET_mkNuGetTarget,%s)") >> stdout.WriteLine)
    stdout.WriteLine ""
    stdout.WriteLine "# Dependencies (NuGet packages)"
    prs
    |> List.iter (Tuple.map (File.toName,
                             fun p ->
                               p.References
                               |> List.choose (function | (Project.File f) -> (if f |> File.isIn nugetroot then Some f else None) | _ -> None)
                               |> List.map (File.relativeTo nugetroot)
                               |> List.choose (fun f -> nugets |> List.tryPick (fun n -> if File.toName f |> String.startswith (n + ".") then Some (n, f) else None))
                               |> List.groupBy fst
                               |> List.map (Tuple.second (List.map (snd >> File.oneUp >> File.toName) >> String.concat " ") >> Tuple.uncurry (sprintf "$(call NUGET_mkNuGetContentsTarget,%s,%s)"))
                               |> String.concat " ") >>
                  Tuple.uncurry (sprintf "$(%s): %s") >>
                  stdout.WriteLine)
    stdout.WriteLine ""
    stdout.WriteLine "# Dependencies (source)"
    prs
    |> List.iter (Tuple.map (File.toName, fun p -> p.Sources |> List.map File.toName |> String.concat " ") >>
                  Tuple.uncurry (sprintf "$(%s): %s") >>
                  stdout.WriteLine)
    stdout.WriteLine ""
    stdout.WriteLine "# Dependencies (projects)"
    prs
    |> List.iter (Tuple.map (File.toName, fun p -> p.References |> List.choose (function | (Project.Project p) -> p |> File.toName |> sprintf "$(%s)" |> Some | _ -> None) |> String.concat " ") >>
                  Tuple.uncurry (sprintf "$(%s): %s") >>
                  stdout.WriteLine)
    stdout.WriteLine ""
    stdout.WriteLine ".PHONY: all"
    stdout.Write "all: "
    prs |> List.map (fst >> File.toName >> sprintf "$(%s)") |> String.concat " " |> stdout.WriteLine
