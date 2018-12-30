defmodule MockHttpServerRegistrationTest do
  use ExUnit.Case
  alias MockHttpServer.RegistrationService

  test "starting and stopping the service" do
    assert { :ok, _ } = RegistrationService.start_link 
    assert RegistrationService in Process.registered
    assert :ok = RegistrationService.stop
    refute RegistrationService in Process.registered
  end

  test "registering a response without url" do
    registered_response = { 404, [], "not found" }
    { :ok, _ } = RegistrationService.start_link
    tid = RegistrationService.register( registered_response )
    assert ^registered_response = RegistrationService.fetch( tid )
    RegistrationService.stop
  end

  test "registering a response with an url containing only scheme and host" do
    default_response = { 999, [], "" }
    registered_response = { 404, [], "not found" }
    registered_url = "http://www.example.com"
    { :ok, _ } = RegistrationService.start_link
    tid = RegistrationService.register( registered_url, registered_response )
    assert ^registered_response = RegistrationService.fetch( registered_url, tid )
    assert ^default_response = RegistrationService.fetch( tid )
    assert ^default_response = RegistrationService.fetch( "https://www.example.com", tid )
    RegistrationService.stop
  end

  test "registering a response with a url containing scheme, host and path" do
    default_response = { 999, [], "" }
    registered_response = { 404, [], "not found" }
    registered_url = "http://www.example.com/some/path"
    { :ok, _ } = RegistrationService.start_link
    tid = RegistrationService.register( registered_url, registered_response )
    assert ^registered_response = RegistrationService.fetch( registered_url, tid )
    assert ^default_response = RegistrationService.fetch( tid )
    assert ^default_response = RegistrationService.fetch( "http://www.example.com", tid )
    assert ^default_response = RegistrationService.fetch( "http://www.example.com/some/other/path", tid )
    assert ^default_response = RegistrationService.fetch( "https://www.example.com/some/path", tid )
    RegistrationService.stop
  end

  test "registering a response with a url containing scheme, host and path and query" do
    default_response = { 999, [], "" }
    registered_response = { 404, [], "not found" }
    registered_url = "http://www.example.com/some/path?bar=baz"
    { :ok, _ } = RegistrationService.start_link
    tid = RegistrationService.register( registered_url, registered_response )
    assert ^registered_response = RegistrationService.fetch( registered_url, tid )
    assert ^default_response = RegistrationService.fetch( tid )
    assert ^default_response = RegistrationService.fetch( "http://www.example.com", tid )
    assert ^default_response = RegistrationService.fetch( "http://www.example.com/some/other/path", tid )
    assert ^default_response = RegistrationService.fetch( "https://www.example.com/some/path", tid )
    assert ^default_response = RegistrationService.fetch( "http://www.example.com/some/path?bar=quux", tid )
    RegistrationService.stop
  end

  test "fetching the default response if the tid is unknown" do
    default_response = { 999, [], "" }
    { :ok, _ } = RegistrationService.start_link
    assert ^default_response = RegistrationService.fetch( :i_dont_exist )
    RegistrationService.stop
  end

  test "registering a default response" do
    registered_response = { 404, [], "not found" }
    { :ok, _ } = RegistrationService.start_link
    :ok = RegistrationService.register_default_action( registered_response )
    assert ^registered_response = RegistrationService.fetch( :i_dont_exist )
    RegistrationService.stop
  end

  test "unregistering a response" do
    registered_response = { 404, [], "not found" }
    { :ok, _ } = RegistrationService.start_link
    tid = RegistrationService.register( registered_response )
    RegistrationService.unregister( tid )
    assert { 999, [], "" } = RegistrationService.fetch( tid )
    RegistrationService.stop
  end
end
