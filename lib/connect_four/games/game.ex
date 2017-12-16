defmodule ConnectFour.Games.Game do
  @derive [Poison.Encoder]
  alias ConnectFour.Games.{Game, Board}
  require Logger

  @type state :: :not_started | :in_play | :finished

  defstruct [
    id: nil,
    red: nil,
    black: nil,
    last: nil,
    turns: [],
    status: :not_started,
    winner: nil,
    board: Board.new
  ]

  def move(%{board: board, turns: turns} = game, player_id, {_col, _color} = turn) do
    board = board |> Board.drop_checker(turn)
    game = %{game | board: board, last: player_id, turns: [turn | turns]}
    winner = nil

    {:ok, %{game | winner: winner}}
  end

  def move(%{last: player_id}, player_id, _column), do: {:foul, "Not player's turn"}
  def move(%{red: player_id} = game, player_id, column), do: move(game, player_id, {column, :red})
  def move(%{black: player_id} = game, player_id, column), do: move(game, player_id, {column, :black})
  def move(%{black: black, red: red}, player_id, _column), do: {:foul, "Player not playing"}

  def add_player(%Game{red: nil} = game, player_id), do: %{game | red: player_id}
  def add_player(%Game{black: nil} = game, player_id), do: %{game | black: player_id}
  def add_player(%Game{} = game, _player_id), do: game

  def which_player(%Game{red: player_id}, player_id), do: :red
  def which_player(%Game{black: player_id}, player_id), do: :black
  def which_player(%Game{}, _player_id), do: nil

  def winner(%Game{board: board}), do: winner(board)
  def winner(%Board{last: nil}), do: nil
  def winner(%Board{cells: cells, last: last} = board) do
    column_winner(cells, last) || row_winner(cells, last)
  end

  defp column_winner(_cells, {row, _col, _color}) when row + 1 < 4, do: nil
  defp column_winner(_cells, {_row, _col, :empty}), do: nil
  defp column_winner(cells, {_row, _col, color} = checker) do
    column_winner(cells, checker, color, 1)
  end
  defp column_winner(cells, {_, _, color}, color, 4), do: color
  defp column_winner(cells, {row, col, color} , color, count) do
    column_winner(cells, Board.checker(cells, {row-1, col}), color, count+1)
  end
  defp column_winner(_cells, _checker, _color, _count), do: nil

  defp row_winner(cells, {row, _col, :empty}), do: nil
  defp row_winner(cells, {_row, _col, color} = checker) do
    row_winner(cells, leftmost_color_checker(cells, checker), color, 1)
  end
  defp row_winner(cells, {_, _, color}, color, 4), do: color
  defp row_winner(cells, {row, col, color}, color, count) do
    row_winner(cells, Board.checker(cells, {row, col+1}), color, count+1)
  end
  defp row_winner(_cells, _checker, _color, _count), do: nil

  defp leftmost_color_checker(cells, {_row, col, _color} = checker) when col == 0, do: checker
  defp leftmost_color_checker(cells, {row, col, color}) do
    col_left = col-1
    case Board.checker(cells, {row, col_left}) do
      {row, col_left, color} ->
        leftmost_color_checker(cells, {row, col_left, color})
      _ ->
        {row, col, color}
    end
  end
end

defimpl Poison.Encoder, for: ConnectFour.Games.Game do
  @moduledoc """
  Implements Poison.Encoder for Board
  """
  def encode(%ConnectFour.Games.Game{turns: turns} = game, _options)  do
    turns = for {col, color} <- turns, do: %{col: col, color: color}
    Poison.encode!(%{game | turns: turns} |> Map.from_struct)
  end

  def encode(game, _options) do
    raise Poison.EncodeError, value: game
  end
end
