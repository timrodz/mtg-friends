fur =
  [
    "Beige",
    "Black",
    "Blue",
    "Blurple",
    "Brown",
    "Camo",
    "Cartoon",
    "Cheetah",
    "Cybear Brown",
    "Dalmatian",
    "Fur Asm",
    "Gold",
    "Green",
    "Grey",
    "Honeycomb",
    "Ice Cream",
    "Light Blue",
    "Orange",
    "Pink",
    "Purple",
    "Raspberry Ripple",
    "Red",
    "Silver",
    "Tie Dye",
    "Tiger",
    "White Polar",
    "Yellow",
    "Zebra"
  ]

eyes = [
  "ASM",
  "Bitcoin",
  "Blue",
  "Brown",
  "Cartoon",
  "Cat Blue",
  "Cat Brown",
  "Cybear",
  "Cybear Green",
  "Demon",
  "Dollar",
  "Glowing Blue",
  "Glowing Green",
  "Glowing Red",
  "Gold",
  "Green",
  "Green & Bloodshot",
  "Purple",
  "Red",
  "Reptile Green",
  "Reptile Yellow",
  "Silver",
  "Yellow"
]

{:ok, file} = File.open("hello", [:write])

IO.binwrite(
  file,
  fur
  |> Enum.flat_map(fn f ->
    eyes |> Enum.map(fn e -> IO.puts(~c"{\"Fur\": \"#{f}\", \"Eyes\": \"#{e}\"},") end)
  end)
)

File.close(file)
