# app/services/shopify_service.rb

class ShopifyService
  def initialize
    @shop_domain = Setting.get("shopify_shop_url") # e.g. "your-store.myshopify.com"
    @token = Setting.get("shopify_storefront_access_token")
    @api_version = "2025-01"
  end

  def query(query)
    uri = URI.parse("https://#{@shop_domain}/api/#{@api_version}/graphql.json")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    headers = {
      "Content-Type" => "application/json",
      "X-Shopify-Storefront-Access-Token" => @token
    }

    request = Net::HTTP::Post.new(uri.request_uri, headers)
    request.body = { query: query }.to_json

    response = http.request(request)
    JSON.parse(response.body)
  end

  def verify_permissions
    result = query("{ shop { name } }")

    if result["data"]
      puts "✅ Connected to Shopify: #{result["data"]["shop"]["name"]}"
    else
      raise "❌ ACCESS_DENIED: #{result["errors"]}"
    end
  end

  def verify_permissions
    query_string = <<-GRAPHQL
      {
        shop {
          name
        }
      }
    GRAPHQL

  response = query(query_string)
    if response.code == 200 && response.body["data"]
      puts "Shopify Storefront API connection successful. Shop Name: #{response.body['data']['shop']['name']}"
    else
      raise "ACCESS_DENIED: Ensure the access token has the required permissions."
    end
  end

  def fetch_products
    query_string = <<-GRAPHQL
    {
      products(first: 20) {
        edges {
          node {
            id
            title
            handle
            variants(first: 3) {
              edges {
                node {
                  id
                  title
                  price {
                    amount
                    currencyCode
                  }
                  image {
                    src: transformedSrc
                    altText
                  }
                }
              }
            }
          }
        }
      }
    }
  GRAPHQL

  result = query(query_string)
  if result["data"] && result["data"]["cartCreate"]
    result["data"]["cartCreate"]["cart"]
  else
    raise "❌ Shopify FetchProducts failed: #{result["errors"] || 'Unknown error'}"
  end

    result["data"]["products"]["edges"]
  end

  def fetch_product_by_handle(handle)
    query_string = <<-GRAPHQL
    {
      productByHandle(handle: "#{handle}") {
        id
        title
        handle
        descriptionHtml
        images(first: 10) {
          edges {
            node {
              src
              altText
            }
          }
        }
        variants(first: 100) {
          edges {
            node {
              id
              title
              price {
                amount
                currencyCode
              }
              image {
                src
                altText
              }
            }
          }
        }
      }
    }
  GRAPHQL
  
  result = query(query_string)
  
  if result["data"] && result["data"]["productByHandle"]
    result["data"]["productByHandle"]
  else
    raise "❌ Shopify FetchProductByHandle
     failed: #{result["errors"] || 'Unknown error'}"
  end
  
  end

def create_cart(minecraft_uuid)
  query_string = <<-GRAPHQL
    mutation {
      cartCreate(input: {
        attributes: [
          { key: "minecraft_uuid", value: "#{minecraft_uuid}" }
        ]
      }) {
        cart {
          id
        }
      }
    }
  GRAPHQL

  result = query(query_string)

  
  if result["data"] && result["data"]["cartCreate"]
    result["data"]["cartCreate"]["cart"]
  else
    raise "❌ Shopify cartCreate failed: #{result["errors"] || 'Unknown error'}"
  end
end

def add_to_cart(cart_id, variant_id)
  global_variant_id = Base64.strict_encode64("gid://shopify/ProductVariant/#{variant_id}")
  cart_gid = cart_id.is_a?(Hash) ? cart_id["id"] : cart_id

  query_string = <<-GRAPHQL
    mutation {
      cartLinesAdd(cartId: "#{cart_gid}", lines: [{quantity: 1, merchandiseId: "#{global_variant_id}"}]) {
        cart {
          id
          lines(first: 10) {
            edges {
              node {
                quantity
                merchandise {
                  ... on ProductVariant {
                    id
                    title
                    price {
                      amount
                      currencyCode
                    }
                    product {
                      title
                      handle
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  GRAPHQL

  result = query(query_string)
  result.dig("data")
end



  def remove_from_cart(cart_id, line_id)
      cart_gid = cart_id.is_a?(Hash) ? cart_id["id"] : cart_id

    query_string = <<-GRAPHQL
      mutation {
        cartLinesRemove(cartId: "#{cart_gid}", lineIds: ["#{line_id}"]) {
          cart {
            id
            lines(first: 10) {
              edges {
                node {
                  id
                  quantity
                  merchandise {
                    ... on ProductVariant {
                      id
                      title
                      price {
                        amount
                        currencyCode
                      }
                      product {
                        title
                        handle
                        featuredImage {
                          url
                          altText
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    GRAPHQL

    result = query(query_string) 

    result["data"]["cartLinesRemove"]["cart"]
  end



def fetch_cart(cart_id)

    cart_gid = cart_id.is_a?(Hash) ? cart_id["id"] : cart_id

  query_string = <<-GRAPHQL
    {
      cart(id: "#{cart_gid}") {
        id
        checkoutUrl
        lines(first: 10) {
          edges {
            node {
              id
              quantity
              merchandise {
                ... on ProductVariant {
                  id
                  title
                  price {
                    amount
                    currencyCode
                  }
                  product {
                    title
                    handle
                    featuredImage {
                      url
                      altText
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  GRAPHQL

  result = query(query_string) # ✅ fixed: calling your local method
  
  result.dig("data", "cart")
end

end
