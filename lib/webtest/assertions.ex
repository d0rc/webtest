defmodule Webtest.Assertions do

  import ExUnit.Assertions
  alias Webtest.Http.HttpResult, as: HttpResult

  def assert_http(result = HttpResult[], []), do: result
  def assert_http(result = HttpResult[], args) do
    args = cond do
      is_integer(args[:http_code]) ->
        expected_code = args[:http_code]
        actual_code = result.response.status_code
        assert actual_code == expected_code, expected_code, actual_code,
          prelude: "Expecting HTTP response code",
          assertion: "be equal (==) to"
        Keyword.delete(args, :http_code)

      is_binary(args[:location]) ->
        expected_location = args[:location]
        actual_location  = result.response.headers["Location"]
        assert actual_location == expected_location, expected_location, actual_location,
          prelude: "Expecting HTTP location",
          assertion: "be equal (==) to"
        Keyword.delete(args, :location)

      is_regex(args[:body_match]) ->
        match = args[:body_match]
        actual_body = result.response.body
        assert actual_body =~ match, actual_body, match,
          prelude: "Expecting HTTP body",
          assertion: "match (=~) to"
        Keyword.delete(args, :body_match)

      true -> result
    end
    assert_http(result, args)
  end

  def assert_json(result = HttpResult[], args) do
    access_fun = args[:access_fun]
    value = args[:value]
    {:ok, json} = JSEX.decode(result.response.body)

    #TODO: write better assertion error
    assert(access_fun.(json) == value)
    result
  end

  @doc """
    Test if certain arguments present in cookie named by 'name'

  ## Example usage:
    assert_cookie("PHPSESSID", [path: "/"])

  ## Example args:
    path: "/",
    name: "yandexuid",
    value: "9155064651381240629",
    domain: ".www.ya.ru",
    path: "/",
    secure: false, http_only: false, version: 0,
    comment: nil, comment_url: nil, discard: false,
    ports: nil,
    created_at: {{2013, 10, 8}, {13, 57, 8}}
    expiry: {{2023, 10, 6}, {13, 57, 8}}
  """
  def assert_cookie(result = HttpResult[], name, args \\ []) do

    cookie = Enum.find(result.cookies, fn(cookie) -> cookie.name == name end)
    assert(cookie, "Cookie '#{name}' is not present.")

    cookie = cookie.to_keywords

    Enum.each args, fn({key, expected}) ->
      actual = Keyword.get(cookie, key)
      assert(expected == actual, expected, actual,
        prelude: "Expecting cookie '#{name}' param '#{key}'",
        assertion: "be equal (==) to")
    end
    result
  end

end
