MockHttpServer
==============

A mock http server for unit tests, where responses can be triggered not only by
matching with a URL, but by optionally requesting a specific response with a
transaction id value in an HTTP request header.

Thus, multiple replies can be registered at once for a given URL, if need be.

A response can be triggered either by providing only the transaction id in an
HTTP header as returned during response registration, calling the url and method
provided during registration (if multiple replies are registered with this 
method/url combination, the first one registered will be returned), or a 
combination thereof, in order to trigger a specific response if multiple were
registered.

## Usage
Starting up the mock server:
    
    # starts the registration service
    MockHttpServer.RegistrationService.start\_link
    # start the http server and bind it to 127.0.0.1, port 8888, responding to http
    MockHttpServer.HttpServer.start( { 127, 0, 0, 1 }, 8888 )
   
Since the above only responds to http requests, mocking https urls will probably
not work as expected in a test environment. To circumvent this, it is recommended
to use different hostnames for your mocked http services in test vs production;
e.g. by providing these in config/config.exs and reading them during runtime
with Application.get\_env/2.


Register your responses:
  
    response_code = 200
    response_headers = [ { "x-my-header", "my value" } ]
    response_body = "I am a body"

    response = { response_code, response_headers, response_body }
    method = "POST" # defaults to GET if not provided
    url = "http://www.example.com/some/request/path"

    transaction_id = MockHttpServer.RegistrationService.register( method, url, response )
    # or using an implicit GET method
    transaction_id = MockHttpServer.RegistrationService.register( url, response )

Trigger a canned response to a query:

    use Plug.Test
    { returned_response_code,
      returned_response_headers,
      returned_response_body } = conn( :get, "/some/request/path", "" )
                                 |> put_req_header( "x-mock-tid", transaction_id )
                                 |> put_req_header( "host", "www.example.com" )
                                 |> MockHttpServer.HttpServer.call
                                 |> sent_resp

Or by using an http client:
    { returned_response_code,
      returned_response_headers,
      returned_response_body } = HTTPoison.get!( "http://www.example.com/some/request/path",
                                                 [ { "x-mock-tid", transaction_id } ] ) 

If no match can be found, a request will return
`{ 999, [ { "cache-control", "max-age=0, private, must-revalidate" } ], "" ]`.

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
