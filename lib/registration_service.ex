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
    dict = HashDict.put( HashDict.new, :unknown, { 999, [], "" } )
    init_serial = 0
    { :ok, { dict, init_serial } }
  end

  def handle_call( { :register, response }, _from, { hash_dict, request_serial } ) do
    tid = ( request_serial + 1 ) |> Integer.to_string
    { :reply, tid, { HashDict.put( hash_dict, tid, response ), tid } }
  end

  def handle_call( { :register_default_action, response }, _from, { hash_dict, request_serial } ) do
    { :reply, :ok, { HashDict.put( hash_dict, :unknown, response ), request_serial } }
  end

  def handle_call( { :fetch, tid }, _from, state = { hash_dict, _ } ) do
    IO.inspect tid
    IO.inspect hash_dict
    { :reply, HashDict.get( hash_dict, tid, HashDict.get( hash_dict, :unknown ) ), state }
  end

  def handle_call( { :unregister, tid }, _from, { hash_dict, request_serial } ) do
    { :reply, :ok, { HashDict.delete( hash_dict, tid ), request_serial } }
  end

  def handle_call( :shutdown, _from, state ) do
    { :stop, :normal, :ok, state }
  end
end
