defmodule MockHttpServer do
  use Application

  def start( _type, _args ) do
    children = [ { MockHttpServer.RegistrationService, [] },
                 { MockHttpServer.HttpServer, [] } ]
    opts = [ strategy: :one_for_one, name: MockHttpServer.Supervisor ]
    Supervisor.start_link( children, opts )
  end
end
