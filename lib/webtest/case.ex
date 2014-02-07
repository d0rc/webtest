defexception Webtest.RetryError, message: "Have no retries left"
defexception Webtest.TimeoutError, message: "Timed out"

defmodule Webtest.Case do

  @moduledoc """

    This module is designed to be used in other modules.

    ## Example
      defmodule MyTest do
        use Webtest.Case
        test "Everything working fine" do
          ...
        end
      end
  """
  defmacro __using__(_opts \\ []) do
    quote do
      import Webtest.Case
      import Webtest.Assertions
      import Webtest.Http
    end
  end

  @doc """
    timeout - timeout in ms (1000ms = 1s)

    with_timeout 1000 do
      ...code that should complete within 1000ms...
    end
  """
  defmacro with_timeout(timeout, contents) do
    contents =
      case contents do
        [do: body] -> body
        _ -> contents
      end
    quote do: with_timeout_do(unquote(timeout), fn -> unquote(contents) end)
  end

  @doc """
    retries - number of attempts to make
    interval - timeout in ms after each failure

    with_retries 10, 1000 do
      ...code that will be executed with 10 retries and 1 second timeout after each failure..
    end
  """
  defmacro with_retries(retries, interval \\ 0, contents) do
    contents =
      case contents do
        [do: body] -> body
        _ -> contents
      end
    quote do: with_retries_do(unquote(retries), unquote(interval), fn -> unquote(contents) end)
  end


  def with_timeout_do(timeout, func) do
    current_pid = self
    spawned_pid = spawn fn ->
      send(current_pid,
        try do
          {:completed, func.(), self}
        rescue error ->
          {:exception, error, self}
        end)
    end

    receive do
      {:completed, result, ^spawned_pid} -> result
      {:exception, exception, ^spawned_pid} -> raise exception
      after timeout -> raise Webtest.TimeoutError
    end
  end


  @retriable_exceptions [ExUnit.AssertionError, ExUnit.ExpectationError,
                         Webtest.RetryError, Webtest.TimeoutError]

  def with_retries_do(0, _interval, _func), do: raise Webtest.RetryError
  def with_retries_do(retries, interval, func) when retries > 0 do
    try do
      func.()
    rescue
      error ->
        name = error.__record__(:name)
        unless name in @retriable_exceptions do
          raise error
        end
        :timer.sleep(interval)
        with_retries_do(retries - 1, interval, func)
    end
  end

end
