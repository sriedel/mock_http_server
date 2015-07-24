defmodule MockHttpServer.HttpServer do
  alias MockHttpServer.RegistrationService
  import Plug.Conn

  def init( options ) do
    options
  end

  def call( conn, _opts ) do
    conn 
    |> get_registered_response
    |> set_response_headers
    |> send_response
  end

  defp get_registered_response( conn ) do
    response = List.keyfind( conn.req_headers["X-Mock-TID"] ) 
               |> RegistrationService.fetch
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
