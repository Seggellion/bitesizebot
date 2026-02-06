puts "Seeding LOTR market tickers..."

now = Time.current

tickers = [
  {
    name: "Mithril Works of Khazad-dûm",
    symbol: "MITR",
    price: 245.00,
    liquidity: 800,
    momentum: 0.15,
    description: "Rare metal extraction and refinement specialists once centered beneath the Misty Mountains."
  },
  {
    name: "Rivendell Artisan Guild",
    symbol: "RIVR",
    price: 182.50,
    liquidity: 900,
    momentum: 0.10,
    description: "High-end Elven craftsmanship, instruments, armor, and enchanted goods."
  },
  {
    name: "Shire Agricultural Cooperative",
    symbol: "SHIR",
    price: 42.75,
    liquidity: 1400,
    momentum: 0.05,
    description: "Pipe-weed, grains, produce, and comfort goods exported across Eriador."
  },
  {
    name: "Gondor Steel & Arms",
    symbol: "GOND",
    price: 131.20,
    liquidity: 1100,
    momentum: 0.08,
    description: "Mass-production weapons, armor, and fortification materials for the White City."
  },
  {
    name: "Rohan Horse Breeders Union",
    symbol: "ROHN",
    price: 96.40,
    liquidity: 1000,
    momentum: 0.12,
    description: "Elite horse breeding and cavalry logistics across the Mark."
  },
  {
    name: "Dale Merchant Consortium",
    symbol: "DALE",
    price: 88.90,
    liquidity: 1050,
    momentum: 0.07,
    description: "Trade hub linking Erebor, Lake-town, and eastern markets."
  },
  {
    name: "Erebor Gem & Gold Holdings",
    symbol: "EREB",
    price: 210.30,
    liquidity: 850,
    momentum: 0.14,
    description: "Precious metals and gem reserves reclaimed under the Lonely Mountain."
  },
  {
    name: "Lothlórien Silvan Textiles",
    symbol: "LOTH",
    price: 167.80,
    liquidity: 900,
    momentum: 0.09,
    description: "Lightweight Elven fabrics prized for stealth and durability."
  },
  {
    name: "Bree Trade & Transport",
    symbol: "BREE",
    price: 61.25,
    liquidity: 1300,
    momentum: 0.04,
    description: "Roadside logistics, inns, and caravan services at the crossroads of the West."
  },
  {
    name: "Grey Havens Shipwrights",
    symbol: "HAVN",
    price: 154.60,
    liquidity: 950,
    momentum: 0.06,
    description: "Advanced shipbuilding and long-distance maritime transport."
  },
  {
    name: "Isengard Industrial Works",
    symbol: "ISEN",
    price: 72.10,
    liquidity: 1200,
    momentum: -0.03,
    description: "Heavy industry, mills, and experimental metallurgy with political risk."
  },
  {
    name: "White Council Holdings",
    symbol: "WCON",
    price: 198.40,
    liquidity: 700,
    momentum: 0.11,
    description: "Strategic advisory, intelligence, and arcane research investments."
  },
  {
    name: "Mirkwood Timber Syndicate",
    symbol: "MIRK",
    price: 54.90,
    liquidity: 1400,
    momentum: 0.02,
    description: "Hardwood logging and forest products from the Greenwood."
  },
  {
    name: "Pelargir Shipyards",
    symbol: "PELG",
    price: 112.75,
    liquidity: 1050,
    momentum: 0.06,
    description: "River and coastal ship manufacturing for Gondorian fleets."
  },
  {
    name: "Harad Spice Exchange",
    symbol: "HRAD",
    price: 134.20,
    liquidity: 900,
    momentum: 0.13,
    description: "Exotic spices, dyes, and luxury goods from the southern lands."
  },
  {
    name: "Esgaroth Lake Trade",
    symbol: "LAKE",
    price: 69.35,
    liquidity: 1250,
    momentum: 0.05,
    description: "Fishing, trade barges, and mercantile exchange on Long Lake."
  },
  {
    name: "Numenorean Archives Ltd",
    symbol: "NUMA",
    price: 176.90,
    liquidity: 750,
    momentum: 0.07,
    description: "Historical records, lost technologies, and scholarly assets."
  },
  {
    name: "Ranger Supply Company",
    symbol: "RNGR",
    price: 58.60,
    liquidity: 1200,
    momentum: 0.04,
    description: "Survival gear, weapons, and logistics for the Dúnedain."
  },
  {
    name: "Umbar Corsair Holdings",
    symbol: "UMBR",
    price: 47.80,
    liquidity: 1500,
    momentum: -0.05,
    description: "High-risk maritime trade and privateering interests."
  },
  {
    name: "Valinor Relics Trust",
    symbol: "VALR",
    price: 265.00,
    liquidity: 600,
    momentum: 0.16,
    description: "Extremely rare artifacts and long-term mythic assets."
  },
  {
  name: "Southfarthing Pipe-weed Collective",
  symbol: "PIPE",
  price: 64.20,
  liquidity: 1600,
  momentum: 0.06,
  description: "The largest producer and exporter of pipe-weed in Middle-earth, supplying Bree, Gondor, and the Rangers of the North."
},
{
  name: "Longbottom Leaf Estates",
  symbol: "LEAF",
  price: 118.75,
  liquidity: 900,
  momentum: 0.11,
  description: "Premium aged pipe-weed grown in the Southfarthing, favored by connoisseurs and wizards."
}
]

tickers.each do |data|
  ticker = Ticker.create!(
    name: data[:name],
    symbol: data[:symbol],
    current_price: data[:price],
    previous_price: data[:price],
    buy_pressure: 0.0,
    sell_pressure: 0.0,
    liquidity: data[:liquidity],
    max_liquidity: data[:liquidity],
    momentum: data[:momentum],
    description: data[:description],
    created_at: now,
    updated_at: now
  )

  PriceHistory.create!(
    ticker_id: ticker.id,
    price: data[:price],
    open: data[:price] * 0.98,
    high: data[:price] * 1.03,
    low: data[:price] * 0.97,
    close: data[:price],
    volume: rand(200..800),
    created_at: now,
    updated_at: now
  )
end

puts "LOTR market seeded with #{tickers.size} tickers."
