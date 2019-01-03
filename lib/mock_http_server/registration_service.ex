defmodule MockHttpServer.RegistrationService do
  use GenServer

  @process_name __MODULE__
  @default_unknown_url_response { 999, [], "" }

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
  def init( :ok ) do
    map = Map.put( %{}, :unknown, @default_unknown_url_response )
    init_serial = 0
    { :ok, { map, init_serial } }
  end

  def handle_call( { :register, response }, _from, state = { url_map, request_serial } ) do
    tid = _generate_tid( state )
    { :reply, tid, { Map.put( url_map, tid, response ), request_serial + 1 } }
  end

  def handle_call( { :register, method, url, response }, _from, state = { url_map, request_serial } ) do
    tid = _generate_tid( state )
    new_url_map = _add_response_to_url_map( url_map, url, method, tid, response )

    { :reply, tid, { new_url_map, request_serial + 1 } }
  end

  def handle_call( { :register_default_action, response }, _from, { url_map, request_serial } ) do
    { :reply, :ok, { Map.put( url_map, :unknown, response ), request_serial } }
  end

  def handle_call( { :fetch, tid }, _from, state = { url_map, _ } ) do
    { :reply, Map.get( url_map, tid, url_map.unknown ), state }
  end

  def handle_call( { :fetch, method, url, nil }, _from, state = { url_map, _ } ) do
    first_tid = ( get_in( url_map, [ url, method ] ) || %{} )
                |> Map.keys
                |> Enum.sort
                |> Enum.at( 0 )
    response = get_in( url_map, [ url, method, first_tid ] ) || url_map.unknown

    { :reply, response, state }
  end

  def handle_call( { :fetch, method, url, tid }, _from, state = { url_map, _ } ) do
    { :reply, get_in( url_map, [ url, method, tid ] ) || url_map.unknown, state }
  end

  def handle_call( { :unregister, tid }, _from, { url_map, request_serial } ) do
    { :reply, :ok, { Map.delete( url_map, tid ), request_serial } }
  end

  def handle_call( { :get_registration_table }, _from, state = { url_map, _request_serial } ) do
    { :reply, url_map, state }
  end

  def handle_call( { :clear_registration_table }, _from, { _map, request_serial } ) do
    { :reply, :ok, { %{}, request_serial } }
  end

  def handle_call( :shutdown, _from, state ) do
    { :stop, :normal, :ok, state }
  end

  defp _generate_tid( _state = { _url_map, request_serial } ) do
    Integer.to_string( request_serial + 1 )
  end

  defp _add_response_to_url_map( url_map, url, method, tid, response ) do
    method_map = Map.get( url_map, url, %{} )
    tid_map = Map.get( method_map, method, %{} )
    tid_map = Map.put( tid_map, tid, response )
    method_map = Map.put( method_map, method, tid_map )
    Map.put( url_map, url, method_map )
  end
end
