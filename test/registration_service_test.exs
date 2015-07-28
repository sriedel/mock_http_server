defmodule MockHttpServerRegistrationTest do
  use ExUnit.Case

  test "starting and stopping the service" do
    assert { :ok, _ } = MockHttpServer.RegistrationService.start_link 
    assert MockHttpServer.RegistrationService in Process.registered
    assert :ok = MockHttpServer.RegistrationService.stop
    refute MockHttpServer.RegistrationService in Process.registered
  end

  test "registering a response" do
    registered_response = { 404, [], "not found" }
    { :ok, _ } = MockHttpServer.RegistrationService.start_link
    tid = MockHttpServer.RegistrationService.register( registered_response )
    assert ^registered_response = MockHttpServer.RegistrationService.fetch( tid )
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
    refute ^registered_response = MockHttpServer.RegistrationService.fetch( tid )
    MockHttpServer.RegistrationService.stop
  end
end
