defmodule Crawler do

  def crawl(url) do
  {:ok, html} = HTTPoison.get(url)
  {:ok, document} = Floki.parse_document(html.body)
  document
  |> Floki.find("a")
  |> Floki.attribute("href")
  |> parse_same_host_links(URI.parse(url).host)
  end

  def crawl2(document) do
    IO.puts(document)
    Enum.map(document, fn x -> crawl(x) end)

  end

  def parse_same_host_links(document, host) do
    document
    |> Enum.filter(& &1)
    |> Enum.map(&URI.parse &1)
    |> Enum.filter(& &1.host == host)
    |> Enum.map(&to_absolute_uri &1, host)
    |> Enum.filter(&Regex.match?(~r/^(http|https)/, &1.scheme))
    |> Enum.map(&URI.to_string &1)
  end

  def to_absolute_uri(uri, host) do
    case uri.host do
      nil -> URI.merge(host, uri)
      _ -> uri
    end
  end
end
