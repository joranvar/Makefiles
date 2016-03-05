let iif f iftrue iffalse x = if f x then iftrue else iffalse
let flip f x y = f y x
module Option =
  let orDefault d = function Some v -> v | None -> d
module String =
  let startswith (prefix:string) (s:string) = s.StartsWith prefix
  let endswith (suffix:string) (s:string) = s.EndsWith suffix
  let split (splitter:string) (s:string) = s.Split ([|splitter|], System.StringSplitOptions.None) |> Array.toList
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
module Tuples =
  let fmap (f, g) (x1, y1) (x2, y2) = (f x1 x2, g y1 y2)
module Map =
  let appendToList<'k,'v when 'k : comparison> (k:'k) (vs:'v list) (m:Map<'k,'v list>) =
    let vs = m |> Map.tryFind k |> Option.orDefault [] |> List.append vs
    m |> Map.add k vs

let projects (sln:string) =
  let root = System.IO.Path.GetDirectoryName sln
  System.IO.File.ReadLines sln
  |> Seq.filter ( String.startswith "Project" )
  |> Seq.choose ( String.split "\"" >>
                  List.tryFind (String.endswith ".fsproj") )
  |> Seq.map (System.IO.Path.Combine << Array.append [|root|] << Array.ofList << String.split "\\")
  |> Seq.toList

type Dependency = | Source | Copy | NuGet | Project
type Output = | Library | Exe
type ProjectInfo = (Dependency * string) list * Output * Map<string, string list>
type ProjectInfoLine = | Dependency of Dependency * string | OutputType of Output | HintPath of string

let sources (proj:string) : ProjectInfo =
  try
  let root = System.IO.Path.GetDirectoryName proj
  let addRoot s = s |> String.split "\\" |> Array.ofList |> Array.append [|root|] |> System.IO.Path.Combine |> System.IO.Path.GetFullPath |> String.removePrefix (System.Environment.CurrentDirectory + "/")
  let lines =
    System.IO.File.ReadAllLines proj
    |> Seq.choose ( String.trim >> function
                    | s when String.startswith "<Compile Include" s -> s |> String.split "\"" |> List.item 1 |> Tuple.create Source |> Dependency |> Some
                    | s when String.startswith "<None Include" s -> s |> String.split "\"" |> List.item 1 |> Tuple.create Copy |> Dependency |> Some
                    | s when String.startswith "<Reference Include" s -> s |> String.split "\"" |> List.item 1 |> Tuple.create NuGet |> Dependency |> Some
                    | s when String.startswith "<ProjectReference Include" s -> s |> String.split "\"" |> List.item 1 |> Tuple.create Project |> Dependency |> Some
                    | s when String.startswith "<OutputType" s -> s |> iif (String.contains "Library") Library Exe |> OutputType |> Some
                    | s when String.startswith "<HintPath>" s -> s |> String.removePrefix "<HintPath>" |> String.removeSuffix "</HintPath>" |> HintPath |> Some
                    | _ -> None
                  )
  lines |> Seq.choose (function Dependency (NuGet, s) -> Some (NuGet, s) | Dependency (d, s) -> Some (d, addRoot s) | _ -> None) |> Seq.toList
  , lines |> Seq.pick (function OutputType o -> Some o | _ -> None)
  , lines |> Seq.choose (function HintPath s -> Some (addRoot s) | _ -> None) |> Seq.map (flip Tuple.create []) |> Map.ofSeq
  with e -> stderr.WriteLine (string e); [], Library, Map.empty

let projTo suff = String.split "/" >> List.last >> String.replace "fsproj" suff

fsi.CommandLineArgs |> Array.toList |> List.filter (String.endswith ".sln") |> List.tryHead |> function
  | None -> stderr.WriteLine "Please provide a sln to import"; exit 1
  | Some sln ->
    let prs, hintmaps =
      projects sln
      |> List.map ( Tuple.mappend sources )
      |> List.map (fun (pr, (sources, output, hintmap)) -> [(pr, (sources, output))], hintmap)
      |> List.reduce (Tuples.fmap (List.append, Map.fold (fun acc key values -> acc |> Map.appendToList key values)))
    stdout.WriteLine "# Assemblies (dll)"
    prs
    |> List.filter (snd >> snd >> (=) Library)
    |> List.iter (fst >> Tuple.twice (id, projTo "dll") >>
                  Tuple.uncurry (sprintf "%s = $(call FSHARP_mkDllTarget,%s)") >>
                  stdout.WriteLine)
    stdout.WriteLine ""
    stdout.WriteLine "# Assemblies (exe)"
    prs
    |> List.filter (snd >> snd >> (=) Exe)
    |> List.iter (fst >> Tuple.twice (id, projTo "exe") >>
                  Tuple.uncurry (sprintf "%s = $(call FSHARP_mkExeTarget,%s)") >>
                  stdout.WriteLine)
    stdout.WriteLine ""
    stdout.WriteLine "# Dependencies (source)"
    prs
    |> List.iter (Tuple.second (fst >> List.filter (fst >> (=) Source) >> List.map snd >> String.concat " ") >>
                  Tuple.uncurry (sprintf "$(%s): %s") >>
                  stdout.WriteLine)
    stdout.WriteLine ""
    stdout.WriteLine "# Dependencies (projects)"
    prs
    |> List.iter (Tuple.second (fst >> List.filter (fst >> (=) Project) >> List.map (snd >> sprintf "$(%s)") >> String.concat " ") >>
                  Tuple.uncurry (sprintf "$(%s): %s") >>
                  stdout.WriteLine)
    stdout.WriteLine ""
    stdout.WriteLine ".PHONY: all"
    stdout.Write "all: "
    prs |> List.map (fst >> sprintf "$(%s)") |> String.concat " " |> stdout.WriteLine
