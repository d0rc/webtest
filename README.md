# Webtest

Web testing framework designed to be easy to use, lightweight, self-contained and `mix` compatible.


Basic example. Test tries two times sleeping 1s between attempts to get http code 200 from given url. This could be usefull in case test needs to wait for some event to happen. For example some other test to finish operations leaving DB in some state.


```elixir
defmodule TestOne do
  use ExUnit.Case, async: true
  use Webtest.Case
  
  test "with 2 retries and interval of 1000 ms between" do
    with_retries 2, 1000 do
      Webtest.Http.get("https://api.github.com", @useragent_headers)
      |> assert_http(http_code: 200)
    end
    |> assert_http(http_code: 200)
  end
end
```


Async-safe sessions are also supported:


```elixir
defmodule TestTwo do
  use ExUnit.Case, async: true
  use Webtest.Case

  test "Basic auth and cookie forwarding using session" do
    session = Webtest.Http.Session.init(username: "foo", password: "bar")
    {session, result} = session.get("http://www.ya.ru/")
    {session, result} = session.get("http://www.ya.ru/")
  end
end
```


More examples could be found at `test/webtest_test.exs`.