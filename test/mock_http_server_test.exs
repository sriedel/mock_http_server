defmodule MockHttpServerTest do
  use ExUnit.Case
  use Plug.Test

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

  test "requesting a non-mocked test url" do
    { :ok, _ } = MockHttpServer.RegistrationService.start_link

    { true_response_code,
      true_response_headers,
      true_response_body } = conn( :get, "/some/path", "" ) 
                             |> MockHttpServer.HttpServer.call
                             |> sent_resp
    
    MockHttpServer.RegistrationService.stop

    assert true_response_code == 999
    assert true_response_headers == [ { "cache-control", "max-age=0, private, must-revalidate" } ]
    assert true_response_body == ""
  end

  test "requesting a non-mocked test url after changing the default response" do
    { :ok, _ } = MockHttpServer.RegistrationService.start_link
    default_response_code = 404
    default_response_headers = []
    default_response_body = "Foo"

    default_response = { default_response_code, default_response_headers, default_response_body }

    MockHttpServer.RegistrationService.register_default_action( default_response )
    { mocked_response_code,
      mocked_response_headers,
      mocked_response_body } = conn( :get, "/some/path", "" ) 
                               |> MockHttpServer.HttpServer.call
                               |> sent_resp
    
    MockHttpServer.RegistrationService.stop

    assert mocked_response_code == default_response_code
    assert mocked_response_headers == [ { "cache-control", "max-age=0, private, must-revalidate" } ]
    assert mocked_response_body == default_response_body
  end
end
