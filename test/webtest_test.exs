defmodule Webtest.Test do
  use ExUnit.Case, async: true
  use Webtest.Case

  @useragent_headers [{"User-Agent", "webtest"}]

  test "request has no errors" do
    Webtest.Http.get("https://api.github.com", @useragent_headers)
    |> assert_http http_code: 200
  end

  test "multistep request" do
    Webtest.Http.get("http://www.github.com", @useragent_headers)
    |> assert_http(http_code: 301, location: "https://github.com/")

    Webtest.Http.get("https://github.com", @useragent_headers)
    |> assert_http([http_code: 200, body_match: %r/Sign up for GitHub/])
  end

  test "Json parsing" do
    Webtest.Http.get("https://api.github.com", @useragent_headers)
    |> assert_http(http_code: 200)
    |> assert_json([
        access_fun: fn(json) -> json["current_user_url"] end,
        value: "https://api.github.com/user"
      ])
  end

  test "with reasonable timemout" do
    with_timeout 5000 do
      Webtest.Http.get("https://api.github.com", @useragent_headers)
    end
    |> assert_http(http_code: 200)
  end

  test "should fail because of unrealistic (50ms) timemout" do
    assert_raise Webtest.TimeoutError, "Timed out", fn ->
      with_timeout 50 do
        Webtest.Http.get("https://api.github.com", @useragent_headers)
      end
      |> assert_http(http_code: 200)
    end
  end

  test "with 2 retries and interval of 1000 ms between" do
    with_retries 2, 1000 do
      Webtest.Http.get("https://api.github.com", @useragent_headers)
      |> assert_http(http_code: 200)
    end
    |> assert_http(http_code: 200)
  end

  test "Yandex cookie presence" do
    Webtest.Http.get("http://www.ya.ru")
    |> assert_cookie("yandexuid")
  end

  test "Invalid cookie name" do
    assert_raise ExUnit.AssertionError, "Cookie 'googlecookie' is not present.", fn ->
      Webtest.Http.get("http://www.ya.ru")
      |> assert_cookie("googlecookie")
    end
  end

  test "Basic auth and cookie forwarding using session" do
    session = Webtest.Http.Session.init(username: "foo", password: "bar")
    {session, result} = session.get("http://www.ya.ru/")
    {session, result} = session.get("http://www.ya.ru/")
  end

end
