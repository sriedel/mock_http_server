defmodule MockHttpServerTest do
  use ExUnit.Case
  use Plug.Test
  import MockHttpServer.HttpServer

  test "requesting a set-up mocked test url by tid" do
    { :ok, _ } = MockHttpServer.RegistrationService.start_link
    response_code = 404
    response_headers = [ { "x-foo", "bar" } ]
    response_body = "I am a body"
    response = { response_code, response_headers, response_body }

    tid = MockHttpServer.RegistrationService.register( response )

    { true_response_code,
      true_response_headers,
      true_response_body } = conn( :get, "/some/path", "" ) 
                             |> put_req_header( "x-mock-tid", tid )
                             |> MockHttpServer.HttpServer.call
                             |> sent_resp
    MockHttpServer.RegistrationService.stop

    assert true_response_code == response_code
    assert true_response_body == response_body
    assert is_list( true_response_headers )
    { "x-foo", "bar" } = Enum.find( true_response_headers, nil, fn({k, _v}) -> "x-foo" == k end )
  end

  # test "requesting a non-mocked test url"
end
