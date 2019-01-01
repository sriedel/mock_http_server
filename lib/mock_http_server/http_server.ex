defmodule MockHttpServer.HttpServer do
  alias MockHttpServer.RegistrationService
  import Plug.Conn

  @default_ip   { 127, 0, 0, 1 }
  @default_port 4444

  def start_link( opts \\ [] ) do
    ip = Keyword.get( opts, :ip )
    port = Keyword.get( opts, :port )
    start( ip || @default_ip, port || @default_port )
  end

  def start( ip, port ) when is_tuple( ip ) and is_integer( port ) do
    Plug.Cowboy.http( __MODULE__, [], port: port, ip: ip )
  end

  def init( options ), do: options

  def call( conn, _opts \\ [] ) do
    conn 
    |> get_registered_response
    |> set_response_headers
    |> send_response
  end

  def child_spec( opts ) do
    %{ id:       __MODULE__,
       start:    { __MODULE__, :start_link, [opts] },
       type:     :worker,
       restart:  :permanent,
       shutdown: 100 }
  end

  defp get_registered_response( conn ) do
    { _header_name, tid } = List.keyfind( conn.req_headers, "x-mock-tid", 0, { nil, nil } )
    response = RegistrationService.fetch( conn.method, request_url( conn ), tid )
    { conn, response }
  end

  defp set_response_headers( { conn, response = { _status_code, headers, _body } } ) do
    conn = Enum.reduce( headers, 
                        conn, 
                        fn( { key, value }, conn ) -> 
                          put_resp_header( conn, key, value ) 
                        end )
    { conn, response }
  end

  defp send_response( { conn, { status_code, _headers, body } } ) do
    send_resp( conn, status_code, body )
  end
end
