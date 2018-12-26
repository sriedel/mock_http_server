MockHttpServer
==============

A mock http server for unit tests, where responses can be triggered not by
matching with a URL, but by requesting a specific response with a value in the
HTTP request headers.

## Usage
Starting up the mock server:

    MockHttpServer.RegistrationService.start\_link

Register your responses:
  
    response_code = 200
    response_headers = [ { "x-my-header", "my value" } ]
    response_body = "I am a body"

    transaction_id = MockHttpServer.RegistrationService.register( { response_code, response_headers, response_body } )

Trigger a canned response to a query:

    use Plug.Test
    { returned_response_code,
      returned_response_headers,
      returned_response_body } = conn( :get, "/some/path", "" )
                                 |> put_req_header( "x-mock-tid", transaction_id )
                                 |> MockHttpServer.HttpServer.call
                                 |> sent_resp

By default, a non-mocked request will return `{ 999, [ { "cache-control", "max-age=0, private, must-revalidate" } ], "" ]`.

This response can be changed by registering a default action:

  MockHttpServer.RegistrationService.register( { 404, [], "Whatcha talkin about, Willis?" } )
    { returned_response_code,
      returned_response_headers,
      returned_response_body } = conn( :get, "/some/path", "" )
                                 |> MockHttpServer.HttpServer.call
                                 |> sent_resp
    
    ^returned_response_code = 404
    ^returned_response_headers = [ { "cache-control", "max-age=0, private, must-revalidate" } ]
    ^returned_response_body = "Whatcha talkin about, Willis?"

When done, shut down the registration server:

    MockHttpServer.RegistrationService.stop
