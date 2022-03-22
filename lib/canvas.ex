defmodule Size do
  defstruct height: 0, width: 0

  def new({x, y}), do: %Size{height: y, width: x}
end

defmodule Canvas do
  defstruct [:pixels, :size]

  def new(%Size{height: height, width: width} = size, color \\ Color.named(:black)) do
    %Canvas{
      pixels:
        :array.new(
          size: height * width,
          default: Color.to_list(color),
          fixed: true
        ),
      size: size
    }
  end

  def put(canvas, coords, color \\ Color.named(:white))

  def put(%Canvas{size: %{width: width, height: height} = size}, {x, y}, _)
      when x >= width or y >= height do
    raise Canvas.OutOfBoundError, coords: {x, y}, size: size
  end

  def put(%Canvas{pixels: pixels, size: size}, {x, y}, color) do
    %Canvas{
      pixels: :array.set(x + size.width * y, Color.to_list(color), pixels),
      size: size
    }
  end

  def pixel_data(canvas) do
    :array.to_list(canvas.pixels)
  end

  def line(canvas, a, b, color \\ Color.named(:white))
  def line(canvas, {x0, y0}, {x1, y1}, _) when x0 == x1 and y0 == y1, do: canvas
  def line(canvas, {x0, y0}, {x1, y1}, color) do
    {a, b, c, d, flip} =
      if abs(x0 - x1) > abs(y0 - y1) do
        {x0, x1, y0, y1, false}
      else
        {y0, y1, x0, x1, true}
      end

    delta = b - a

    Range.new(a, b)
    |> Enum.reduce(canvas, fn x, canvas ->
      t = (x - a) / delta
      y = trunc(c * (1 - t) + d * t)

      put(
        canvas,
        if not flip do
          {x, y}
        else
          {y, x}
        end,
        color
      )
    end)
  end

  def flip(%Canvas{pixels: pixels} = canvas) do
    %Size{width: width} = canvas.size

    pixels =
      pixels
      |> :array.to_list()
      |> Stream.chunk_every(width)
      |> Enum.reverse()
      |> (fn l -> :array.from_list(l) end).()

    %Canvas{canvas | pixels: pixels}
  end

  defmodule OutOfBoundError do
    defexception [:message]

    @impl true
    def exception(coords: coords, size: size) do
      msg = "Out of bound (#{inspect(size)}): #{inspect(coords)}"
      %OutOfBoundError{message: msg}
    end
  end
end

defimpl Inspect, for: Canvas do
  def inspect(canvas, _) do
    "%Canvas{pixels: PIXEL_DATA, size: #{inspect(canvas.size)}}"
  end
end
