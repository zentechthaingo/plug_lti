defmodule Grade do
  import PlugLti
  @url "https://edge.edx.org/courses/course-v1:University_of_TorontoX+INQ101x+2T2015/xblock/block-v1:University_of_TorontoX+INQ101x+2T2015+type@lti+block@6aead9666027438ca67bd5fe031c8f47/handler_noauth/grade_handler"
  # @url "http://192.168.33.10/courses/edX/DemoX/Demo_Course/xblock/i4x:;_;_edX;_DemoX;_lti;_0b08a58e26724b5e9e194c0a9d1fffec/handler_noauth/grade_handler"
  @contents String.strip(File.read!("request.txt"))

  def main do
    method = "POST"
    param_base = proc_params(params)

    signature = [method, @url, param_base] 
      |> Enum.map(&(URI.encode_www_form/1))
      |> Enum.join("&")
      |> IO.inspect
      |> hmac_signature
      |> IO.inspect
    params = Map.put(params, "oauth_signature", signature)

    paramstr = params
    |> Enum.map(fn {k, v} -> "#{k}=\"#{
      URI.encode_www_form(PlugLti.ensure_string(v))
      }\"" end)
    |> Enum.join(",")
    |> IO.inspect
    HTTPoison.request(:post, @url , @contents, [{:Accept, "application/xml"}, {:Authorization, 
        "OAuth realm=\"\"," <> paramstr}])
    |> IO.inspect
  end

  def params do

%{"oauth_consumer_key"=>"test", "oauth_nonce"=>"3RrRU3FUwTxHEo35MwGKoB7BeUIZPUcst3ufzvo", "oauth_signature_method"=>"HMAC-SHA1", "oauth_timestamp" => "1434880106", "oauth_version" =>"1.0"}
    |> Enum.map(fn {x,y} -> {x, URI.decode_www_form(y) } end )
    |> Enum.into(%{})
    |> Map.put("oauth_body_hash", :crypto.hash(:sha, @contents) |> Base.encode64)
    # %{"oauth_consumer_key"     => "test",
    #   "oauth_nonce"            => nonce,
    #   "oauth_signature_method" => "HMAC-SHA1",
    #   "oauth_timestamp"        => timestamp,
    #   "oauth_version"          => "1.0",
  end

  def timestamp do
    {mgsec, sec, _mcs} = :os.timestamp

    mgsec * 1_000_000 + sec
  end
  def nonce do
    :crypto.rand_bytes(32) |> Base.encode64
  end
end
