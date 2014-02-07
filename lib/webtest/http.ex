
defrecord Webtest.Http.Session, [cookies: nil, options: [], last_response: nil] do

  @doc """
    args = [
      username: "myname",
      password: "mypassword",
      debug: true
    ]
  """
  def init(args) do

    cookies = Keyword.get args, :cookies, CookieJar.new
    options = Keyword.get args, :options, []

    username = args[:username]
    password = args[:password]

    if String.valid?(username) and String.valid?(password) do
      options = Dict.put options, :basic_auth, {username, password}
    end

    unless nil? args[:debug] do
      options = Dict.put options, :debug, args[:debug]
    end

    new(options: options, cookies: cookies)
  end

  #session.get
  def get(url, headers \\ [], options \\ [], session) do
    result = Webtest.Http.get(url, session.headers(url) ++ headers, session.options ++ options)
    if result.cookies do
      session = session.update(cookies: add_cookies(session.cookies, result.cookies.get_cookies(url)))
    end
    {session.update(last_response: result), result}
  end

  # session.post
  def post(url, body, headers \\ [], options \\ [], session) do
    result = Webtest.Http.post(url, body, session.headers(url) ++ headers, session.options ++ options)
    if result.cookies do
      session = session.update(cookies: add_cookies(session.cookies, result.cookies.get_cookies(url)))
    end
    {session.update(last_response: result), result}
  end

  # session.headers(url)
  def headers(url, session) do
    if Enumerable.count(session.cookies) > 0 do
      ["Cookie": session.cookies.get_cookie_header(url)]
    else
      []
    end
  end

  defp add_cookies(jar, cookies) do
    Enum.reduce(cookies, jar, fn(cookie, acc) -> acc.add_cookie(cookie) end)
  end
end


defmodule Webtest.Http do
  @moduledoc """

    Wrapper around HTTPoison

  """
  defrecord HttpResult, url: nil, cookies: nil, response: nil, time: 0

  def get(url, headers \\ [], options \\ []),         do: request(:get, url, "", headers, options)
  def put(url, body, headers \\ [], options \\ []),   do: request(:put, url, body, headers, options)
  def head(url, headers \\ [], options \\ []),        do: request(:head, url, "", headers, options)
  def post(url, body, headers \\ [], options \\ []),  do: request(:post, url, body, headers, options)
  def patch(url, body, headers \\ [], options \\ []), do: request(:patch, url, body, headers, options)
  def delete(url, headers \\ [], options \\ []),      do: request(:delete, url, "", headers, options)
  def options(url, headers \\ [], options \\ []),     do: request(:options, url, "", headers, options)


  @doc """
    Using gzip compression and parsing cookies by default.
  """
  def request(method, url, body \\ "", headers \\ [], options \\ []) do

    if options[:debug] do
      IO.write "[DEBUG] Http.request.method:\t"
      IO.inspect method
      IO.write "[DEBUG] Http.request.URL:\t"
      IO.inspect url
      IO.write "[DEBUG] Http.request.body:\t"
      IO.inspect body
      IO.write "[DEBUG] Http.request.headers:\t"
      IO.inspect headers
      IO.write "[DEBUG] Http.request.options:\t"
      IO.inspect options
    end

    {time, response} = :timer.tc fn ->
      headers = Enum.map(headers, fn 
        {head, defs} when is_atom(head) -> {ensure_binary(head), defs}
        {head, defs} -> {head, defs}
      end)
      HTTPoison.request(method, url, body, headers ++ [{"Accept-Encoding", "gzip,deflate"}], options)
    end

    if options[:debug] do
      IO.write "[DEBUG] Http.response.headers:\t"
      IO.inspect response.headers
    end

    response = case response.headers["Content-Encoding"] do
      "gzip" -> response.update body: :zlib.gunzip response.body
      nil    -> response
    end

    setcookie_header = find_setcookie_header(response.headers)

    cookies = unless nil? setcookie_header do
      converted_headers = convert_setcookie_headers(setcookie_header)
      CookieJar.new.set_cookies_from_headers(url, converted_headers)
    end

    HttpResult[url: url, response: response, cookies: cookies, time: time]
  end

  defp ensure_binary(atom) when is_atom(atom), do: atom_to_binary(atom)
  defp ensure_binary(binary) when is_binary(binary), do: binary

  # Set-Cookie, set-cookie, Set-cookie, SET-COOKIE, etc...
  defp find_setcookie_header(headers) do
    headers 
      |> Stream.filter(fn {key, _} -> String.downcase(key) == "set-cookie" end) 
      |> Enum.map(fn {_, value} -> value end)
  end

  defp convert_setcookie_headers(headers) when is_list(headers) do
    Enum.map(headers, fn(set_cookie_entry) -> {"Set-Cookie", set_cookie_entry} end)
  end

  defp convert_setcookie_headers(headers) when is_binary(headers) do
    [{"Set-Cookie", headers}]
  end

end
