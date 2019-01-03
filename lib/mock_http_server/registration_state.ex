defmodule MockHttpServer.RegistrationState do
  alias __MODULE__, as: State

  @enforce_keys [ :url_map, :unregistered, :request_serial ]
  defstruct [ :url_map, :unregistered, :request_serial ]

  @initial_serial 0
  @default_unregistered_url_response { 999, [], "" }

  def new do
    %State{ url_map:        %{},
            unregistered:   @default_unregistered_url_response,
            request_serial: @initial_serial }
  end

  def clear( %State{ request_serial: serial, unregistered: unregistered_response } ) do
    %State{ url_map:        %{},
            unregistered:   unregistered_response,
            request_serial: serial }
  end

  def next_tid( %State{ request_serial: serial } ), do: Integer.to_string( serial + 1 )

  def set_default_response( %State{ url_map: url_map, request_serial: serial }, response ) do
    %State{ url_map:        url_map,
            unregistered:   response,
            request_serial: serial }
  end

  def set_response( %State{ url_map: url_map, unregistered: unregistered, request_serial: serial }, url, method, tid, response ) do
    new_url_map = _add_response_to_url_map( url_map, url, method, tid, response )

    %State{ url_map:        new_url_map,
            unregistered:   unregistered,
            request_serial: serial + 1 }
  end

  def set_response( %State{ url_map: url_map, unregistered: unregistered, request_serial: serial }, tid, response ) do
    %State{ url_map:        Map.put( url_map, tid, response ),
            unregistered:   unregistered,
            request_serial: serial + 1 }
  end

  def remove_response( %State{ url_map: url_map, unregistered: unregistered, request_serial: serial }, tid ) do
    %State{ url_map:        Map.delete( url_map, tid ),
            unregistered:   unregistered,
            request_serial: serial }
  end
  
  def get_response( %State{ url_map: url_map, unregistered: unregistered }, url, method ) do
    first_tid = ( get_in( url_map, [ url, method ] ) || %{} )
                |> Map.keys
                |> Enum.sort
                |> Enum.at( 0 )
    get_in( url_map, [ url, method, first_tid ] ) || unregistered
  end

  def get_response( %State{ url_map: url_map, unregistered: unregistered }, tid ), do: Map.get( url_map, tid, unregistered )

  def get_response( %State{ url_map: url_map, unregistered: unregistered }, url, method, tid ) do
    get_in( url_map, [ url, method, tid ] ) || unregistered
  end

  def get_url_map( %State{ url_map: url_map } ), do: url_map

  defp _add_response_to_url_map( url_map, url, method, tid, response ) do
    method_map = Map.get( url_map, url, %{} )
    tid_map = Map.get( method_map, method, %{} )
    tid_map = Map.put( tid_map, tid, response )
    method_map = Map.put( method_map, method, tid_map )
    Map.put( url_map, url, method_map )
  end
end
