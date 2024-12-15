defmodule Chatbot do
  use GenServer

  @api_base "http://localhost:11434/v1"

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    {:ok, Map.put(state, :history, [])}
  end

  # CLI Commands

  def model(model_name) do
    GenServer.call(__MODULE__, {:set_model, model_name})
  end

  def ask(prompt) do
    GenServer.call(__MODULE__, {:ask, prompt})
  end

  def list do
    case HTTPoison.get("#{@api_base}/models") do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        body |> Jason.decode!() |> Enum.map(& &1["name"])
      {:error, _} ->
        IO.puts("Failed to fetch models.")
    end
  end

  def show(model_name) do
    case HTTPoison.get("#{@api_base}/models/#{model_name}") do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        IO.puts(Jason.encode!(Jason.decode!(body), pretty: true))
      {:error, _} ->
        IO.puts("Failed to fetch model details.")
    end
  end

  def pull(model_name) do
    case HTTPoison.post("#{@api_base}/models/pull", Jason.encode!(%{"name" => model_name}),
      [{"Content-Type", "application/json"}]) do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        IO.puts("Successfully downloaded model #{model_name}.")
      {:error, _} ->
        IO.puts("Failed to download model #{model_name}.")
    end
  end

  def history do
    GenServer.call(__MODULE__, :history)
  end

  # GenServer Callbacks

def handle_call({:ask, prompt}, _from, %{history: history} = state) do
  case HTTPoison.post("#{@api_base}/chat", Jason.encode!(%{"prompt" => prompt}), [{"Content-Type", "application/json"}]) do
    {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
      response = Jason.decode!(body)["response"]

      # Dodaj zapytanie i odpowiedź do historii
      updated_history = [%{prompt: prompt, response: response} | history]

      # Odpowiedz klientowi i zaktualizuj stan
      {:reply, response, %{state | history: updated_history}}

    {:error, %HTTPoison.Error{reason: reason}} ->
      {:reply, {:error, reason}, state}
  end
end

  def handle_call({:ask, prompt}, _from, %{model: model_name} = state) do
    case HTTPoison.post(
           "#{@api_base}/models/#{model_name}/chat",
           Jason.encode!(%{"prompt" => prompt}),
           [{"Content-Type", "application/json"}]
         ) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        response = Jason.decode!(body)["response"]
        updated_history = [%{prompt: prompt, response: response} | state.history]
        {:reply, response, %{state | history: updated_history}}

      {:error, _} ->
        {:reply, "Failed to communicate with model #{model_name}.", state}
    end
  end

  def handle_call(:history, _from, state) do
    {:reply, Enum.reverse(state.history), state}
  end
end