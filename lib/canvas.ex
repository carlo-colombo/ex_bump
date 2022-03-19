defmodule Size do
  defstruct height: 0, width: 0
end

defmodule Canvas do
  defstruct [:pixels, :size]

  def new(%Size{height: height, width: width} = size) do
    %Canvas{pixels: List.duplicate(%Color{}, height * width), size: size}
  end

  def put(canvas, coords, color \\ Color.named(:white))

  def put(%Canvas{size: %{width: width, height: height}}, {x, y}, _)
      when x >= width or y >= height do
    raise Enum.OutOfBoundsError
  end

  def put(%Canvas{pixels: pixels, size: size}, {x, y}, color) do
    %Canvas{
      pixels: put_in(pixels, [Access.at!(x * size.width + y)], color),
      size: size
    }
  end

  def fill(canvas, color: color) do
    %Canvas{canvas | pixels: List.duplicate(color, length(canvas.pixels))}
  end

  def pixel_data(canvas) do
    Enum.map(canvas.pixels, &Color.to_list/1)
  end
end

defimpl Inspect, for: Canvas do
  def inspect(canvas, _) do
    "%Canvas{pixels: PIXEL_DATA, size: #{inspect(canvas.size)}}"
  end
end
