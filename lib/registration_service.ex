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
    dict = HashDict.put( HashDict.new, :unknown, { 200, {}, "" } )
    { :ok, dict }
  end

  def handle_call( { :register, response }, _from, hash_dict ) do
    tid = :erlang.make_ref
    { :reply, tid, HashDict.put( hash_dict, tid, response ) }
  end

  def handle_call( { :register_default_action, response }, _from, hash_dict ) do
    { :reply, :ok, HashDict.put( hash_dict, :unknown, response ) }
  end

  def handle_call( { :fetch, tid }, _from, hash_dict ) do
    { :reply, HashDict.get( hash_dict, tid, HashDict.get( hash_dict, :unknown ) ), hash_dict }
  end

  def handle_call( { :unregister, tid }, _from, hash_dict ) do
    { :reply, :ok, HashDict.delete( hash_dict, tid ) }
  end

  def handle_call( :shutdown, _from, hash_dict ) do
    { :stop, :normal, :ok, hash_dict }
  end
end
