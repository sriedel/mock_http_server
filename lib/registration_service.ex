defmodule MockHttpServer.RegistrationService do
  use GenServer

  @process_name __MODULE__

  def start_link( opts \\ [] ) do
    { :ok, pid } = GenServer.start_link( __MODULE__, :ok, opts )
    Process.register( pid, @process_name )
  end

  # external API
  def register( response = { status_code, headers, body } ) do
    GenServer.call( @process_name, { :register, response } )
  end

  def register_default_action( response = { status_code, headers, body } ) do
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
end
