defmodule MockHttpServer.RegistrationService do
  use GenServer
  alias MockHttpServer.RegistrationState, as: State

  @process_name __MODULE__

  def start_link( _opts \\ [] ) do
    GenServer.start_link( __MODULE__, :ok, [ name: @process_name ] )
  end

  def stop do
    GenServer.call( @process_name, :shutdown )
  end

  # external API
  def register( url, response ), do: register( "GET", url, response )

  def register( method, url, response ) do
    GenServer.call( @process_name, { :register, method, url, response } )
  end

  def register_default_action( response ) do
    GenServer.call( @process_name, { :register_default_action, response } )
  end

  def unregister( tid ), do: GenServer.call( @process_name, { :unregister, tid } )

  def fetch( tid ), do: GenServer.call( @process_name, { :fetch, tid } )
  def fetch( url, tid ), do: fetch( "GET", url, tid )
  def fetch( method, url, tid ), do: GenServer.call( @process_name, { :fetch, method, url, tid } )

  def registration_table, do: GenServer.call( @process_name, { :get_registration_table } )
  def clear, do: GenServer.call( @process_name, { :clear_registration_table } )

  # internal API
  def init( :ok ), do: { :ok, State.new() }

  def handle_call( { :register, method, url, response }, _from, state ) do
    tid = State.next_tid( state )

    { :reply, tid, State.set_response( state, url, method, tid, response ) }
  end

  def handle_call( { :register_default_action, response }, _from, state ) do
    { :reply, :ok, State.set_default_response( state, response ) }
  end

  def handle_call( { :fetch, tid }, _from, state ) do
    { :reply, State.get_response( state, tid ), state }
  end

  def handle_call( { :fetch, method, url, nil }, _from, state ) do
    response = State.get_response( state, url, method )

    { :reply, response, state }
  end

  def handle_call( { :fetch, method, url, tid }, _from, state ) do
    { :reply, State.get_response( state, url, method, tid ), state }
  end

  def handle_call( { :unregister, tid }, _from, state ) do
    { :reply, :ok, State.remove_response( state, tid ) }
  end

  def handle_call( { :get_registration_table }, _from, state ) do
    { :reply, State.get_url_map( state ), state }
  end

  def handle_call( { :clear_registration_table }, _from, state ) do
    { :reply, :ok, State.clear( state ) }
  end

  def handle_call( :shutdown, _from, state ) do
    { :stop, :normal, :ok, state }
  end
end
