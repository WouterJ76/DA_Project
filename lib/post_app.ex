defmodule TwitterClone.PostApp do
  use GenServer
  require UUID

  @me __MODULE__

  #########
  ## API ##
  #########

  def start_link(_args) do
    GenServer.start_link(@me, :no_opts, name: @me)
  end

  def add(post), do: GenServer.call(@me, {:add, post})

  def get_all(), do: GenServer.call(@me, :get_all)

  def like(post_id), do: GenServer.cast(@me, {:like, post_id})

  def comment(post_id, user, comment), do: GenServer.cast(@me, {:comment, post_id, user, comment})

  ###############
  ## Callbacks ##
  ###############

  @impl true
  def init(:no_opts) do
    state = %{"e10d20c4-0663-4930-b172-c331646978f2" => {"test", 0, []}}
    {:ok, state}
  end

  @impl true
  def handle_call({:add, post}, _, state) do
    new_state = Map.put_new(state, UUID.uuid4(), {post, 0, []})
    {:reply, :posted, new_state}
  end

  @impl true
  def handle_call(:get_all, _, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:like, post_id}, state) do
    post = Map.fetch!(state, post_id)
    liked_post = {elem(post, 0), elem(post, 1) + 1, elem(post, 2)}
    new_state = Map.put(state, post_id, liked_post)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:comment, post_id, user, comment}, state) do
    post = Map.fetch!(state, post_id)
    commented_post = {elem(post, 0), elem(post, 1), elem(post, 2) ++ [{user, comment}]}
    new_state = Map.put(state, post_id, commented_post)
    {:noreply, new_state}
  end
end