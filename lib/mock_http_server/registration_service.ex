defmodule MockHttpServer.RegistrationService do
  use GenServer

  @process_name __MODULE__
  @default_unknown_url_response { 999, [], "" }
  @initial_serial 0

  def start_link( _opts \\ [] ) do
    GenServer.start_link( __MODULE__, :ok, [ name: @process_name ] )
  end

  def stop do
    GenServer.call( @process_name, :shutdown )
  end

  # external API
  def register( response ) do
    GenServer.call( @process_name, { :register, response } )
  end

  def register( url, response ), do: register( "GET", url, response )

  def register( method, url, response ) do
    GenServer.call( @process_name, { :register, method, url, response } )
  end

  def register_default_action( response ) do
    GenServer.call( @process_name, { :register_default_action, response } )
  end

  def unregister( tid ) do
    GenServer.call( @process_name, { :unregister, tid } )
  end

  def fetch( tid ) do
    GenServer.call( @process_name, { :fetch, tid } )
  end

  def fetch( url, tid ), do: fetch( "GET", url, tid )

  def fetch( method, url, tid ) do
    GenServer.call( @process_name, { :fetch, method, url, tid } )
  end

  def registration_table, do: GenServer.call( @process_name, { :get_registration_table } )
  def clear, do: GenServer.call( @process_name, { :clear_registration_table } )

  # internal API
  def init( :ok ), do: { :ok, _initial_state() }

  def handle_call( { :register, response }, _from, state ) do
    tid = _generate_tid( state )

    { :reply, tid, _state_with_response_stored( state, tid, response ) }
  end

  def handle_call( { :register, method, url, response }, _from, state ) do
    tid = _generate_tid( state )

    { :reply, tid, _state_with_response_stored( state, url, method, tid, response ) }
  end

  def handle_call( { :register_default_action, response }, _from, state ) do
    { :reply, :ok, _state_with_new_default_response( state, response ) }
  end

  def handle_call( { :fetch, tid }, _from, state ) do
    { :reply, _retrieve_response_from_state( state, tid ), state }
  end

  def handle_call( { :fetch, method, url, nil }, _from, state ) do
    response = _retrieve_response_from_state( state, url, method )

    { :reply, response, state }
  end

  def handle_call( { :fetch, method, url, tid }, _from, state ) do
    { :reply, _retrieve_response_from_state( state, url, method, tid ), state }
  end

  def handle_call( { :unregister, tid }, _from, state ) do
    { :reply, :ok, _remove_response_from_state( state, tid ) }
  end

  def handle_call( { :get_registration_table }, _from, state ) do
    { :reply, _get_url_map_from_state( state ), state }
  end

  def handle_call( { :clear_registration_table }, _from, state ) do
    { :reply, :ok, _cleared_state( state ) }
  end

  def handle_call( :shutdown, _from, state ) do
    { :stop, :normal, :ok, state }
  end

  defp _generate_tid( _state = { _url_map, request_serial } ) do
    Integer.to_string( request_serial + 1 )
  end

  defp _state_with_response_stored( _state = { url_map, request_serial }, url, method, tid, response ) do
    new_url_map = _add_response_to_url_map( url_map, url, method, tid, response )

    { new_url_map, request_serial + 1 }
  end

  defp _state_with_response_stored( _state = { url_map, request_serial }, tid, response ) do
    { Map.put( url_map, tid, response ), request_serial + 1 }
  end

  defp _retrieve_response_from_state( _state = { url_map, _request_serial }, url, method ) do
    first_tid = ( get_in( url_map, [ url, method ] ) || %{} )
                |> Map.keys
                |> Enum.sort
                |> Enum.at( 0 )
    get_in( url_map, [ url, method, first_tid ] ) || url_map.unknown
  end

  defp _retrieve_response_from_state( _state = { url_map, _request_serial }, tid ), do: Map.get( url_map, tid, url_map.unknown )

  defp _retrieve_response_from_state( _state = { url_map, _request_serial }, url, method, tid ) do
    get_in( url_map, [ url, method, tid ] ) || url_map.unknown
  end

  defp _remove_response_from_state( _state = { url_map, request_serial }, tid ) do
    { Map.delete( url_map, tid ), request_serial }
  end

  defp _state_with_new_default_response( _state = { url_map, request_serial }, response ) do
    { Map.put( url_map, :unknown, response ), request_serial }
  end

  defp _initial_state do
    map = Map.put( %{}, :unknown, @default_unknown_url_response )
    { map, @initial_serial }
  end

  defp _get_url_map_from_state( _state = { url_map, _request_serial } ), do: url_map

  defp _cleared_state( _state = { _map, request_serial } ), do: { %{}, request_serial }

  defp _add_response_to_url_map( url_map, url, method, tid, response ) do
    method_map = Map.get( url_map, url, %{} )
    tid_map = Map.get( method_map, method, %{} )
    tid_map = Map.put( tid_map, tid, response )
    method_map = Map.put( method_map, method, tid_map )
    Map.put( url_map, url, method_map )
  end
end
