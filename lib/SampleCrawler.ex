defmodule SimpleCrawler do
  def run do
     seed_url = IO.gets("urlを入力してください")
     |> String.trim()
     Agent.start_link fn -> [] end, name: :crawled_result

     crawl(seed_url, seed_url)

     result = Agent.get :crawled_result, &(&1)
     Agent.stop :crawled_result
     IO.inspect(result)
     save(result,"aaa")
     save2(result,"bbb")
  end

   defp crawl(target_url, seed_url) do
     crawled_link_list = Agent.get :crawled_result, fn list -> Enum.map(list, &(&1[:url])) end
     if !Enum.member?(crawled_link_list, target_url) do
       IO.puts "access: #{target_url}"
       %HTTPoison.Response{body: body} = HTTPoison.get!(target_url)

       document = Floki.parse_document! body
       page_info = document
                   |> parse_text
                   |> Map.merge(%{url: target_url})
       un_crawled_link_list = document
                              |> parse_same_host_links(URI.parse(seed_url).host)
                              |> Enum.filter(&!Enum.member?(crawled_link_list, &1))

       Agent.update(:crawled_result, &([page_info | &1]))
       Enum.map(un_crawled_link_list, &(crawl(&1, seed_url)))
    end
  end

  defp parse_same_host_links(document, host) do
     document
     |> Floki.find("a")
     |> Floki.attribute("href")
     |> Enum.filter(& &1)
     |> Enum.map(&URI.parse &1)
     |> Enum.filter(& &1.host == host)
     |> Enum.map(&to_absolute_uri &1, host)
     |> Enum.filter(&Regex.match?(~r/^(http|https)/, &1.scheme))
     |> Enum.map(&URI.to_string &1)
   end

  defp to_absolute_uri(uri, host) do
     case uri.host do
       nil -> URI.merge(host, uri)
       _ -> uri
     end
  end

   defp parse_text(document) do
     text = document
             |> Floki.find("body")
             |> Floki.text
     %{text: text}
   end
   def save(result,filename) do
     binary=:erlang.term_to_binary(result)
     File.write(filename,binary)
   end


   def save2(result, filename) do
      result
      |> CSV.Encoding.Encoder.encode(headers: true)
      |> Enum.to_list
      |> (&IO.write(filename, &1)).()
    end

   def load(filename) do
     {status,binary} = File.read(filename)
     case status do
       :ok -> :erlang.binary_to_term(binary)
       :error -> "ファイル名が間違っています"
     end
   end
 end
