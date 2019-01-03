defmodule MockHttpServer.RegistrationState do
  alias __MODULE__, as: State

  @enforce_keys [ :url_map, :request_serial ]
  defstruct [ :url_map, :request_serial ]

  @initial_serial 0
  @default_unknown_url_response { 999, [], "" }

  def new do
    %State{ url_map: _initial_url_map(), request_serial: @initial_serial }
  end

  def clear( %State{ request_serial: serial } ), do: %State{ url_map: _initial_url_map(), request_serial: serial }

  def next_tid( %State{ request_serial: serial } ), do: Integer.to_string( serial + 1 )

  def set_response( %State{ url_map: url_map, request_serial: serial }, url, method, tid, response ) do
    new_url_map = _add_response_to_url_map( url_map, url, method, tid, response )

    %State{ url_map: new_url_map, request_serial: serial + 1 }
  end

  def set_response( %State{ url_map: url_map, request_serial: serial }, tid, response ) do
    %State{ url_map: Map.put( url_map, tid, response ), request_serial: serial + 1 }
  end
  
  def get_response( %State{ url_map: url_map }, url, method ) do
    first_tid = ( get_in( url_map, [ url, method ] ) || %{} )
                |> Map.keys
                |> Enum.sort
                |> Enum.at( 0 )
    get_in( url_map, [ url, method, first_tid ] ) || url_map.unknown
  end

  def get_response( %State{ url_map: url_map }, tid ), do: Map.get( url_map, tid, url_map.unknown )

  def get_response( %State{ url_map: url_map }, url, method, tid ) do
    get_in( url_map, [ url, method, tid ] ) || url_map.unknown
  end

  def remove_response( %State{ url_map: url_map, request_serial: serial }, tid ) do
    %State{ url_map: Map.delete( url_map, tid ), request_serial: serial }
  end

  def set_default_response( %State{ url_map: url_map, request_serial: serial }, response ) do
    %State{ url_map: Map.put( url_map, :unknown, response ), request_serial: serial }
  end

  def get_url_map( %State{ url_map: url_map } ), do: url_map

  defp _initial_url_map, do: %{ unknown: @default_unknown_url_response }

  defp _add_response_to_url_map( url_map, url, method, tid, response ) do
    method_map = Map.get( url_map, url, %{} )
    tid_map = Map.get( method_map, method, %{} )
    tid_map = Map.put( tid_map, tid, response )
    method_map = Map.put( method_map, method, tid_map )
    Map.put( url_map, url, method_map )
  end
end
