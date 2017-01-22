defmodule Trellifier.PageController do
  use Trellifier.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
