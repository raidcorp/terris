defmodule Mix.Tasks.Terris.Update do
  use Mix.Task

  require Logger

  @endpoint "https://restcountries.eu/rest/v2/all"

  alias HTTPoison.Response

  @shortdoc "Updates countries data if available"
  def run(_args) do
    HTTPoison.start()

    @endpoint
    |> HTTPoison.get!()
    |> process!()
  end

  defp process!(%Response{status_code: 200, body: body}) do
    hash = hash(body)

    unless File.dir?(data_path(hash)) do
      create_files!(hash, body)
      update_meta!(hash)
      Logger.info("Countries updated #{hash}")
    else
      Logger.info("Already up to date")
    end
  end

  defp process!(response) do
    Logger.warn("Could not process the response: #{inspect(response)}")
  end

  defp create_files!(hash, body) do
    path = data_path(hash, "_.json")
    create_and_write!(path, body)

    countries = Jason.decode!(body)

    countries
    |> Enum.group_by(& &1["alpha3Code"])
    |> Enum.each(&write_chunk!(hash, &1))
  end

  defp update_meta!(hash) do
    path = "priv/data/meta.json"
    content = File.read!(path)
    metadata = Jason.decode!(content)

    versions =
      metadata
      |> Map.get(:avaiable, %{})
      |> Map.put(hash, DateTime.now!("Etc/UTC"))

    content =
      metadata
      |> Map.put("available", versions)
      |> Map.put("current", hash)
      |> Jason.encode!(pretty: true)

    File.write!(path, content)
  end

  defp write_chunk!(hash, {code, [country | _]}) do
    encoded = Jason.encode!(country, pretty: true)

    path = data_path(hash, "#{code}.json")
    create_and_write!(path, encoded)
  end

  defp create_and_write!(path, data) do
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, data)
  end

  defp data_path(hash, name \\ "") do
    Path.join(["priv/data", hash, name])
  end

  defp hash(content) do
    :crypto.hash(:sha, content)
    |> Base.encode16()
    |> String.downcase()
  end
end
