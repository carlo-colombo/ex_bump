defmodule Bump do
  def to_iodata(%{size: %{height: height, width: width}} = canvas) do
    resolution = 2835
    info_header_size = 40
    offset = 14 + info_header_size

    padding_size = rem(width, 4)
    padding = List.duplicate(0, padding_size)

    pixel_data =
      canvas
      |> Canvas.pixel_data()
      |> Stream.chunk_every(width)
      |> Stream.map(&(&1 ++ padding))
      |> Enum.to_list()
      |> :binary.list_to_bin()

    size_of_file = byte_size(pixel_data) + offset

    header = <<
      0x42,
      0x4D,
      size_of_file::unsigned-little-integer-size(32),
      0x0::size(32),
      offset::unsigned-little-integer-size(32),
      info_header_size::unsigned-little-integer-size(32),
      width::unsigned-little-integer-size(32),
      # negative height signals that rows are top to bottom
      -height::unsigned-little-integer-size(32),
      # color plane
      1::unsigned-little-integer-size(16),
      # bits per pixel (color depth)
      24::unsigned-little-integer-size(16),
      # disable compression
      0x0::unsigned-little-integer-size(32),
      # size of image
      byte_size(pixel_data)::unsigned-little-integer-size(32),
      # horizontal resolution
      resolution::unsigned-little-integer-size(32),
      # vertical resolution
      resolution::unsigned-little-integer-size(32),
      # colors
      0x0::unsigned-little-integer-size(32),
      # important colors
      0x0::unsigned-little-integer-size(32)
    >>

    header <> pixel_data
  end

  def pixel_data(filename) do
    {:ok, filedata} = File.read(filename)

    <<0x42, 0x4D, _size_of_file::unsigned-little-integer-size(32), _unused::size(4)-binary,
      offset::unsigned-little-integer-size(32),
      _info_header_size::unsigned-little-integer-size(32),
      _height::unsigned-little-integer-size(32), width::unsigned-little-integer-size(32),
      _unused2::binary>> = filedata

    <<_header::size(offset)-binary, data::binary>> = filedata

    Stream.chunk(:binary.bin_to_list(data), 8)
    |> Stream.map(fn row -> Enum.slice(row, 0..(width * 3 - 1)) |> Enum.chunk(3) end)
    |> Enum.to_list()
  end
end
