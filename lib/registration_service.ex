defmodule MockHttpServer.RegistrationService do
  use GenServer

  @process_name __MODULE__

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

  def register_default_action( response ) do
    GenServer.call( @process_name, { :register_default_action, response } )
  end

  def unregister( tid ) do
    GenServer.call( @process_name, { :unregister, tid } )
  end

  def fetch( tid ) do
    GenServer.call( @process_name, { :fetch, tid } )
  end

  # internal API
  def init( :ok ) do
    map = Map.put( %{}, :unknown, { 999, [], "" } )
    init_serial = 0
    { :ok, { map, init_serial } }
  end

  def handle_call( { :register, response }, _from, { map, request_serial } ) do
    tid = ( request_serial + 1 ) |> Integer.to_string
    { :reply, tid, { Map.put( map, tid, response ), tid } }
  end

  def handle_call( { :register_default_action, response }, _from, { map, request_serial } ) do
    { :reply, :ok, { Map.put( map, :unknown, response ), request_serial } }
  end

  def handle_call( { :fetch, tid }, _from, state = { map, _ } ) do
    # IO.inspect tid
    # IO.inspect hash_dict
    { :reply, Map.get( map, tid, Map.get( map, :unknown ) ), state }
  end

  def handle_call( { :unregister, tid }, _from, { map, request_serial } ) do
    { :reply, :ok, { Map.delete( map, tid ), request_serial } }
  end

  def handle_call( :shutdown, _from, state ) do
    { :stop, :normal, :ok, state }
  end
end
