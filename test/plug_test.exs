defmodule PlugEtsCache.PlugTest do
  use ExUnit.Case, async: true
  use Plug.Test

  test "replies with cached content if present" do
    request = %Plug.Conn{request_path: "/test", query_string: ""}
    PlugEtsCache.Store.set(request, "text/plain; charset=utf-8", "Hello cache")

    conn =
      conn(:get, "/test")
      |> PlugEtsCache.Plug.call(PlugEtsCache.Plug.init(nil))

    assert conn.resp_body == "Hello cache"
    assert {"content-type", "text/plain; charset=utf-8"} in conn.resp_headers
    assert conn.state == :sent
    assert conn.status == 200
  end

  test "does not double set charset in response headers" do
    request = %Plug.Conn{request_path: "/test.xml", query_string: ""}
    PlugEtsCache.Store.set(request, "application/xml; charset=utf-8", "<xml>hello</xml>")

    conn =
      conn(:get, "/test.xml")
      |> PlugEtsCache.Plug.call(PlugEtsCache.Plug.init(nil))

    assert conn.resp_body == "<xml>hello</xml>"
    assert {"content-type", "application/xml; charset=utf-8"} in conn.resp_headers
    assert conn.state == :sent
    assert conn.status == 200
  end

  test "return conn if not present" do
    conn =
      conn(:get, "/test2")
      |> PlugEtsCache.Plug.call(PlugEtsCache.Plug.init(nil))

    assert conn.state == :unset
    assert conn.status == nil
    assert conn.resp_body == nil
    refute {"content-type", "text/plain; charset=utf-8"} in conn.resp_headers
  end

  test "accept cache key function in options" do
    opts = [cache_key: &cache_key/1]
    request = %Plug.Conn{request_path: "/optiontest", query_string: "foo=bar"}
    PlugEtsCache.Store.set(request, "text/plain; charset=utf-8", "cached response", opts)

    conn = :get
    |> conn("/optiontest?foo=bar")
    |> PlugEtsCache.Plug.call(PlugEtsCache.Plug.init(opts))

    assert conn.resp_body ==  "cached response"
    assert {"content-type", "text/plain; charset=utf-8"} in conn.resp_headers
    assert conn.state == :sent
    assert conn.status == 200
  end

  defp cache_key(conn) do
    conn.query_string
  end
end
