defmodule MockHttpServer.RegistrationState do
  alias __MODULE__, as: State

  @enforce_keys [ :url_map, :unregistered, :request_serial, :call_count_map ]
  defstruct [ :url_map, :unregistered, :request_serial, :call_count_map ]

  @initial_serial 0
  @default_unregistered_url_response { 999, [], "" }

  def new do
    %State{ url_map:        %{},
            unregistered:   @default_unregistered_url_response,
            request_serial: @initial_serial,
            call_count_map: %{} }
  end

  def clear( %State{ request_serial: serial, unregistered: unregistered_response } ) do
    %State{ url_map:        %{},
            unregistered:   unregistered_response,
            request_serial: serial,
            call_count_map: %{} }
  end

  def next_tid( %State{ request_serial: serial } ), do: Integer.to_string( serial + 1 )

  def set_default_response( %State{ url_map: url_map, request_serial: serial, call_count_map: call_count_map }, response ) do
    %State{ url_map:        url_map,
            unregistered:   response,
            request_serial: serial,
            call_count_map: call_count_map }
  end

  def set_response( %State{ url_map: url_map, unregistered: unregistered, request_serial: serial, call_count_map: call_count_map }, url, method, tid, response ) when is_list( response ) do
    new_url_map = _add_response_to_url_map( url_map, url, method, tid, response )
    new_call_count_map = _add_initial_call_count( call_count_map, tid )

    %State{ url_map:        new_url_map,
            unregistered:   unregistered,
            request_serial: serial + 1,
            call_count_map: new_call_count_map }
  end

  def set_response( state, url, method, tid, response ) do
    set_response( state, url, method, tid, [ response ] )
  end

  def remove_response( %State{ url_map: url_map, unregistered: unregistered, request_serial: serial, call_count_map: call_count_map }, tid ) do
    new_url_map = _remove_response_from_url_map( url_map, tid )
    new_call_count_map = _remove_tid_from_call_count( call_count_map, tid )

    %State{ url_map:        new_url_map,
            unregistered:   unregistered,
            request_serial: serial,
            call_count_map: new_call_count_map }
  end

  def increment_call_count( state = %State{}, nil ), do: state
  def increment_call_count( %State{ url_map: url_map, unregistered: unregistered, request_serial: serial, call_count_map: call_count_map }, tid ) do
    { _, new_call_count_map } = Map.get_and_update( call_count_map, tid, &( { &1, ( &1 || 0 ) + 1 } ) )

    %State{ url_map: url_map,
            unregistered: unregistered,
            request_serial: serial,
            call_count_map: new_call_count_map }
  end

  def find_first_tid( %State{ url_map: url_map }, url, method ) do
    ( get_in( url_map, [ url, method ] ) || %{} )
    |> Map.keys
    |> Enum.sort
    |> Enum.at( 0 )
  end
  
  def get_response( state = %State{ url_map: url_map, unregistered: unregistered }, tid ) do
    url_map
    |> Enum.find_value( unregistered, 
                        fn( { _url, method_map } ) ->
                          Enum.find_value( method_map, 
                                           fn( { _method, tid_map } ) ->
                                             Map.get( tid_map, tid )
                                           end )
                        end )
    |> _extract_response( state, tid )
  end

  def get_response( state = %State{ url_map: url_map, unregistered: unregistered }, url, method, tid ) do
    ( get_in( url_map, [ url, method, tid ] ) || unregistered )
    |> _extract_response( state, tid )
  end

  defp _extract_response( responses, %State{ call_count_map: call_count_map }, tid ) 
    when is_list( responses ) do
    current_call_count = Map.get( call_count_map, tid, 0 )
    Enum.at( responses, current_call_count, List.last( responses ) )
  end
  defp _extract_response( response, _state, _tid ), do: response

  def get_url_map( %State{ url_map: url_map } ), do: url_map

  defp _add_response_to_url_map( url_map, url, method, tid, response ) do
    method_map = Map.get( url_map, url, %{} )
    tid_map = Map.get( method_map, method, %{} )
    tid_map = Map.put( tid_map, tid, response )
    method_map = Map.put( method_map, method, tid_map )
    Map.put( url_map, url, method_map )
  end

  defp _remove_response_from_url_map( url_map, tid ) do
    Enum.map( url_map, fn( { url, method_map } ) ->
      filtered_method_map = Enum.map( method_map, fn( { method, tid_map } ) -> 
                              { method, Map.delete( tid_map, tid ) }
                            end )
                            |> Map.new  
      { url, filtered_method_map }
    end )
    |> Map.new
  end

  defp _add_initial_call_count( call_count_map, tid ) do
    Map.put( call_count_map, tid, 0 )
  end

  defp _remove_tid_from_call_count( call_count_map, tid ) do
    Map.delete( call_count_map, tid )
  end
end
