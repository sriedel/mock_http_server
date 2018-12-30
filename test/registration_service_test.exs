defmodule MockHttpServerRegistrationTest do
  use ExUnit.Case

  test "starting and stopping the service" do
    assert { :ok, _ } = MockHttpServer.RegistrationService.start_link 
    assert MockHttpServer.RegistrationService in Process.registered
    assert :ok = MockHttpServer.RegistrationService.stop
    refute MockHttpServer.RegistrationService in Process.registered
  end

  test "registering a response without url" do
    registered_response = { 404, [], "not found" }
    { :ok, _ } = MockHttpServer.RegistrationService.start_link
    tid = MockHttpServer.RegistrationService.register( registered_response )
    assert ^registered_response = MockHttpServer.RegistrationService.fetch( tid )
    MockHttpServer.RegistrationService.stop
  end

  test "registering a response with an url containing only scheme and host" do
    default_response = { 999, [], "" }
    registered_response = { 404, [], "not found" }
    registered_url = "http://www.example.com"
    { :ok, _ } = MockHttpServer.RegistrationService.start_link
    tid = MockHttpServer.RegistrationService.register( registered_url, registered_response )
    assert ^registered_response = MockHttpServer.RegistrationService.fetch( registered_url, tid )
    assert ^default_response = MockHttpServer.RegistrationService.fetch( tid )
    assert ^default_response = MockHttpServer.RegistrationService.fetch( "https://www.example.com", tid )
    MockHttpServer.RegistrationService.stop
  end

  test "registering a response with a url containing scheme, host and path" do
    default_response = { 999, [], "" }
    registered_response = { 404, [], "not found" }
    registered_url = "http://www.example.com/some/path"
    { :ok, _ } = MockHttpServer.RegistrationService.start_link
    tid = MockHttpServer.RegistrationService.register( registered_url, registered_response )
    assert ^registered_response = MockHttpServer.RegistrationService.fetch( registered_url, tid )
    assert ^default_response = MockHttpServer.RegistrationService.fetch( tid )
    assert ^default_response = MockHttpServer.RegistrationService.fetch( "http://www.example.com", tid )
    assert ^default_response = MockHttpServer.RegistrationService.fetch( "http://www.example.com/some/other/path", tid )
    assert ^default_response = MockHttpServer.RegistrationService.fetch( "https://www.example.com/some/path", tid )
    MockHttpServer.RegistrationService.stop
  end

  test "registering a response with a url containing scheme, host and path and query" do
    default_response = { 999, [], "" }
    registered_response = { 404, [], "not found" }
    registered_url = "http://www.example.com/some/path?bar=baz"
    { :ok, _ } = MockHttpServer.RegistrationService.start_link
    tid = MockHttpServer.RegistrationService.register( registered_url, registered_response )
    assert ^registered_response = MockHttpServer.RegistrationService.fetch( registered_url, tid )
    assert ^default_response = MockHttpServer.RegistrationService.fetch( tid )
    assert ^default_response = MockHttpServer.RegistrationService.fetch( "http://www.example.com", tid )
    assert ^default_response = MockHttpServer.RegistrationService.fetch( "http://www.example.com/some/other/path", tid )
    assert ^default_response = MockHttpServer.RegistrationService.fetch( "https://www.example.com/some/path", tid )
    assert ^default_response = MockHttpServer.RegistrationService.fetch( "http://www.example.com/some/path?bar=quux", tid )
    MockHttpServer.RegistrationService.stop
  end

  test "fetching the default response if the tid is unknown" do
    default_response = { 999, [], "" }
    { :ok, _ } = MockHttpServer.RegistrationService.start_link
    assert ^default_response = MockHttpServer.RegistrationService.fetch( :i_dont_exist )
    MockHttpServer.RegistrationService.stop
  end

  test "registering a default response" do
    registered_response = { 404, [], "not found" }
    { :ok, _ } = MockHttpServer.RegistrationService.start_link
    :ok = MockHttpServer.RegistrationService.register_default_action( registered_response )
    assert ^registered_response = MockHttpServer.RegistrationService.fetch( :i_dont_exist )
    MockHttpServer.RegistrationService.stop
  end

  test "unregistering a response" do
    registered_response = { 404, [], "not found" }
    { :ok, _ } = MockHttpServer.RegistrationService.start_link
    tid = MockHttpServer.RegistrationService.register( registered_response )
    MockHttpServer.RegistrationService.unregister( tid )
    assert { 999, [], "" } = MockHttpServer.RegistrationService.fetch( tid )
    MockHttpServer.RegistrationService.stop
  end
end
