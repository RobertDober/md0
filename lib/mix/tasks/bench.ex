defmodule Mix.Tasks.Bench do

  use Mix.Task

  @shortdoc "Run benchmarks on all or designated scanners"

  @moduledoc """
  Run benchamarks on the input file 

  All benchmarks are run unless specific benchmarks are chosen with

      --rgx
      --macro
      --manual
      --table
  """

  @all_scanners [
    macro: nil,
    manual: Md0.ManualScanner,
    rgx: Md0.RgxScanner,
    table: Md0.MacroScanner,
  ]

  @impl true
  def run(args) do 
    args
    |> parse()
    |> process()
  end
  
  defp bench_scanner(filename, {scanner_name,_}, warmup \\ false) do
    with scanner <- Keyword.get(@all_scanners, scanner_name) do
      with content <- get_content(File.read(filename), filename) do
        if scanner do
          if warmup do
            scanner.scan_document(content)
          else
            timed("scanning with #{scanner} scanner", fn -> scanner.scan_document(content) end)
          end
        end
      end
    end
  end


  defp get_content({:ok, content},_), do: content
  defp get_content({:error, reason},filename) do
    IO.puts(:stderr, "#{filename}: #{:file.format_error(reason)}")
    exit(1)
  end

  defp map_scanner(with_value, {scanner, _}), do: {scanner, with_value}

  defp parse(args) do
    parse = OptionParser.parse(args, strict: switches())
    case  parse  do
      { [ {:help, true } | _ ],  _, _ } -> :help
      { options, [ filename ],  [] }  -> {filename, options}
      { _, _, errors }  -> errors
    end
  end

  defp process(:help) do
    IO.puts(:stderr, @moduledoc)
  end
  defp process(:version) do
    with {:ok, version} = :application.get_key(:md0, :vsn) |> IO.inspect, do: IO.puts(:stderr, version)
  end
  defp process([_|_]=errors), do: IO.puts(:stderr, "The following switches are undefined: #{inspect(errors)}")
  defp process({filename, []}), do: process({filename, @all_scanners})
  defp process({filename, scanners}) do
    Enum.each(scanners, &bench_scanner(filename, &1, true))
    Enum.each(scanners, &bench_scanner(filename, &1))
  end

  defp switches() do
    [
      {:help, :boolean} |
      Enum.map(@all_scanners, &map_scanner(:boolean, &1))
    ]
  end

  defp timed(title, fun) do
    IO.puts "START: #{title}"
    start_time = Time.utc_now
    fun.() # |> IO.inspect
    ellapsed_us = Time.diff(Time.utc_now, start_time, :microsecond)
    IO.puts "DURATION: #{ellapsed_us}"
  end
end
